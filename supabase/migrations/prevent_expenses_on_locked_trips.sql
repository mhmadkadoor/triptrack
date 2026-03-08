-- Enforce trip lock status for expense creation
-- Prevent adding expenses to trips that are locked or settled.

-- Drop the old policy so we can redefine it with stricter conditions.
DROP POLICY IF EXISTS "Create expenses for joined trips" ON expenses;

-- Recreate policy with lock check
CREATE POLICY "Create expenses for joined trips"
ON expenses FOR INSERT
WITH CHECK (
  -- 1. Must be a member of the trip
  EXISTS (
    SELECT 1 FROM trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
  )
  -- 2. Trip must be active and unlocked
  AND EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = expenses.trip_id
    AND trips.phase = 'active'
    AND trips.is_locked = false
  )
);
