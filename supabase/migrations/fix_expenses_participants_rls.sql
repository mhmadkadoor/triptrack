-- Enable RLS on expense_participants
alter table expense_participants enable row level security;

-- DELETE Policy
-- Allow users to remove themselves OR leaders to remove anyone
create policy "Users can remove themselves or leaders can remove anyone"
on expense_participants
for delete
using (
  auth.uid() = user_id -- Self-removal
  or exists (
    select 1 from expenses e
    join trip_members tm on e.trip_id = tm.trip_id
    where e.id = expense_participants.expense_id
    and tm.user_id = auth.uid()
    and tm.role = 'leader'
  )
);

-- INSERT Policy
-- Allow users to add themselves OR leaders to add anyone
create policy "Users can add themselves or leaders can add anyone"
on expense_participants
for insert
with check (
  auth.uid() = user_id -- Self-addition
  or exists (
    select 1 from expenses e
    join trip_members tm on e.trip_id = tm.trip_id
    where e.id = expense_participants.expense_id
    and tm.user_id = auth.uid()
    and tm.role = 'leader'
  )
);
