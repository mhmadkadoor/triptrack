-- Fix DELETE policy for shopping_items to allow members to delete items they have claimed
-- This enables the "Bought It" flow where a member converts a claimed item to an expense (which deletes the item).

-- Drop the old restrictive policy
DROP POLICY IF EXISTS "Leaders delete items" ON shopping_items;

-- Create new policy allowing Leaders OR the Claimer to delete
CREATE POLICY "Allow delete if leader or claimer" ON shopping_items
    FOR DELETE
    USING (
        -- 1. Is Leader
        (auth.uid() IN (
            SELECT user_id FROM trip_members 
            WHERE trip_id = shopping_items.trip_id 
            AND role = 'leader'
        ))
        OR
        -- 2. Is the person who claimed it
        (auth.uid() = claimed_by)
    );
