-- Allow authenticated users to search/read trips (necessary for joining via invite code)
create policy "Authenticated users can select trips"
on trips for select
to authenticated
using (true);
