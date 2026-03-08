-- Function to delete a user's account and all associated data cleanly
-- Returns void
-- SECURITY DEFINER allows this function to bypass RLS and even delete from auth.users (if the definer has permissions)
-- IMPORTANT: This function permanently deletes data.

CREATE OR REPLACE FUNCTION delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth 
AS $$
DECLARE
    requesting_user_id uuid;
BEGIN
    -- Get the ID of the user calling the function
    requesting_user_id := auth.uid();
    
    IF requesting_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 1. Identify trips where the user is the ONLY leader.
    -- We delete these completely because a trip needs a leader.
    -- Logic: Find trips where this user is a leader, and there are NO other leaders.
    
    DELETE FROM trips t
    WHERE t.id IN (
        SELECT tm.trip_id
        FROM trip_members tm
        WHERE tm.user_id = requesting_user_id
        AND tm.role = 'leader'
        AND NOT EXISTS (
            SELECT 1
            FROM trip_members other_tm
            WHERE other_tm.trip_id = tm.trip_id
            AND other_tm.role = 'leader'
            AND other_tm.user_id != requesting_user_id
        )
    );

    -- 1.5. Reassign ownership of leftover trips
    -- For trips where the user is 'created_by' but which were NOT deleted above (e.g. have other leaders),
    -- we must change 'created_by' to avoid Foreign Key violations when the user is deleted.
    
    -- A. Delete trips created by this user that have NO other members at all (dead trips)
    DELETE FROM trips 
    WHERE created_by = requesting_user_id 
    AND NOT EXISTS (
        SELECT 1 FROM trip_members tm 
        WHERE tm.trip_id = trips.id 
        AND tm.user_id != requesting_user_id
    );

    -- B. Transfer ownership of surviving trips to another member (preferring leaders)
    UPDATE trips
    SET created_by = (
        SELECT tm.user_id
        FROM trip_members tm
        WHERE tm.trip_id = trips.id
        AND tm.user_id != requesting_user_id
        ORDER BY (tm.role = 'leader') DESC, tm.joined_at ASC
        LIMIT 1
    )
    WHERE created_by = requesting_user_id;

    -- 2. Clean up user's footprint in remaining trips.
    -- Since we deleted the sole-leader trips above, any remaining trips this user is part of 
    -- MUST have another leader (or the user is just a member/viewer).
    
    -- Remove from expense splits
    DELETE FROM expense_participants WHERE user_id = requesting_user_id;

    -- Remove expenses paid by this user
    -- (This effectively deletes the expense record. Since expenses are tied to trips, 
    -- and we are only deleting expenses in TO-BE-KEPT trips, the trip total will change.)
    DELETE FROM expenses WHERE paid_by = requesting_user_id;

    -- Remove from settlements (both as sender and receiver)
    DELETE FROM settlements WHERE from_user_id = requesting_user_id OR to_user_id = requesting_user_id;

    -- Remove trip membership
    DELETE FROM trip_members WHERE user_id = requesting_user_id;

    -- 3. Delete Profile
    DELETE FROM profiles WHERE id = requesting_user_id;

    -- 4. Delete Auth User 
    -- This requires the function to run with privileges that can delete from auth.users
    -- Usually 'postgres' or similar superuser.
    DELETE FROM auth.users WHERE id = requesting_user_id;

END;
$$;
