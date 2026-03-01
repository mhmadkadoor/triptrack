-- Enable RLS on ledger tables
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_participants ENABLE ROW LEVEL SECURITY;

-- Policy: View Expenses
-- Allow users to view expenses if they are a member of the trip.
CREATE POLICY "View expenses for joined trips" 
ON expenses FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM trip_members 
    WHERE trip_members.trip_id = expenses.trip_id 
    AND trip_members.user_id = auth.uid()
  )
);

-- Policy: Create Expenses
-- Allow users to insert expenses if they are a member of the trip.
-- Note: 'WITH CHECK' enforces that the new row also satisfies the condition.
CREATE POLICY "Create expenses for joined trips" 
ON expenses FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM trip_members 
    WHERE trip_members.trip_id = expenses.trip_id 
    AND trip_members.user_id = auth.uid()
  )
);

-- Policy: View Expense Participants
-- Allow seeing participants if you can see the expense (i.e. you are in the trip).
-- We can join back to expenses -> trip_members.
CREATE POLICY "View expense participants" 
ON expense_participants FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM expenses 
    JOIN trip_members ON expenses.trip_id = trip_members.trip_id
    WHERE expenses.id = expense_participants.expense_id
    AND trip_members.user_id = auth.uid()
  )
);

-- Policy: Insert Expense Participants
-- Allow inserting participants. Usually happens when creating an expense.
-- We check if the user is a member of the trip associated with the expense.
CREATE POLICY "Insert expense participants" 
ON expense_participants FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM expenses 
    JOIN trip_members ON expenses.trip_id = trip_members.trip_id
    WHERE expenses.id = expense_participants.expense_id
    AND trip_members.user_id = auth.uid()
  )
);
