-- 1. Create the shopping_items table
CREATE TABLE shopping_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL CHECK (char_length(item_name) > 0),
    added_by UUID NOT NULL REFERENCES auth.users(id),
    claimed_by UUID REFERENCES auth.users(id), -- Only null or a valid user
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Enable RLS
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;

-- 3. Create Policies

-- SELECT: Any member of the trip can view items
CREATE POLICY "View shopping items" ON shopping_items
    FOR SELECT
    USING (
        auth.uid() IN (
            SELECT user_id FROM trip_members WHERE trip_id = shopping_items.trip_id
        )
    );

-- INSERT: Only leaders can add items
CREATE POLICY "Leaders insert items" ON shopping_items
    FOR INSERT
    WITH CHECK (
        auth.uid() IN (
            SELECT user_id FROM trip_members 
            WHERE trip_id = shopping_items.trip_id 
            AND role = 'leader'
        )
    );

-- DELETE: Only leaders can delete items
CREATE POLICY "Leaders delete items" ON shopping_items
    FOR DELETE
    USING (
        auth.uid() IN (
            SELECT user_id FROM trip_members 
            WHERE trip_id = shopping_items.trip_id 
            AND role = 'leader'
        )
    );

-- UPDATE: Members can claim/unclaim (update claimed_by only)
-- NOTE: Preventing `item_name` changes requires a trigger or separate column grants. 
-- However, standard Supabase RLS allows row-level access. 
-- We allow UPDATE if user is a member. We rely on API/Client or a Trigger for column safety.
-- To strictly enforce access via RLS for the ROW update permission:
CREATE POLICY "Members update items" ON shopping_items
    FOR UPDATE
    USING (
        auth.uid() IN (
            SELECT user_id FROM trip_members WHERE trip_id = shopping_items.trip_id
        )
    )
    WITH CHECK (
        auth.uid() IN (
            SELECT user_id FROM trip_members WHERE trip_id = shopping_items.trip_id
        )
    );

-- OPTIONAL Trigger to prevent `item_name` or `added_by` changes by non-leaders
-- This enforces: "they cannot change the item_name"
CREATE OR REPLACE FUNCTION check_shopping_update()
RETURNS TRIGGER AS $$
BEGIN
    -- If the user is NOT a leader...
    IF NOT EXISTS (
        SELECT 1 FROM trip_members 
        WHERE user_id = auth.uid() 
        AND trip_id = OLD.trip_id 
        AND role = 'leader'
    ) THEN
        -- ...prevent changing item_name or added_by
        IF OLD.item_name IS DISTINCT FROM NEW.item_name THEN
            RAISE EXCEPTION 'Only leaders can change item names';
        END IF;
        IF OLD.added_by IS DISTINCT FROM NEW.added_by THEN
             RAISE EXCEPTION 'Cannot change who added the item';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_shopping_changes
    BEFORE UPDATE ON shopping_items
    FOR EACH ROW
    EXECUTE FUNCTION check_shopping_update();
