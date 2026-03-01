-- FIX: RLS Policy for trip_members
-- Allow Leaders to remove members from their trip

create policy "Leaders can delete members"
on trip_members
for delete
using (
  exists (
    select 1 from trip_members leader
    where leader.trip_id = trip_members.trip_id
    and leader.user_id = auth.uid()
    and leader.role = 'leader'
  )
);
