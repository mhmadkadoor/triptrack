-- Allow settlements (is_settlement = true) even on locked/finished trips
-- Drop the policy created by prevent_expenses_on_locked_trips.sql
DROP POLICY IF EXISTS "Create expenses for joined trips" ON expenses;

-- Recreate policy with lock check EXCEPT for settlements
CREATE POLICY "Create expenses for joined trips"
ON expenses FOR INSERT
WITH CHECK (
  -- 1. Must be a member of the trip
  EXISTS (
    SELECT 1 FROM trip_members
    WHERE trip_members.trip_id = expenses.trip_id
    AND trip_members.user_id = auth.uid()
  )
  -- 2. Either it is a settlement OR (Trip must be active and unlocked)
  AND (
    expenses.is_settlement = true 
    OR 
    EXISTS (
      SELECT 1 FROM trips
      WHERE trips.id = expenses.trip_id
      AND trips.phase = 'active'
      AND trips.is_locked = false
    )
  )
);