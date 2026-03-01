-- Create settlements table
create table settlements (
  id uuid default gen_random_uuid() primary key,
  trip_id uuid references trips(id) not null,
  from_user_id uuid references auth.users(id) not null,
  to_user_id uuid references auth.users(id) not null,
  amount numeric not null check (amount > 0),
  status text not null default 'pending' check (status in ('pending', 'sent', 'confirmed')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Policies
alter table settlements enable row level security;

-- Policy: Anyone in the trip can view settlements
create policy "Trip members can view settlements"
on settlements for select
using (
  exists (
    select 1 from trip_members
    where trip_members.trip_id = settlements.trip_id
    and trip_members.user_id = auth.uid()
  )
);

-- Policy: Trip leaders can insert settlements
create policy "Trip leaders can insert settlements"
on settlements for insert
with check (
  exists (
    select 1 from trip_members
    where trip_members.trip_id = settlements.trip_id
    and trip_members.user_id = auth.uid()
    and trip_members.role = 'leader'
  )
);

-- Policy: Payer (from_user) can update status to 'sent'
create policy "Debtor can mark as sent"
on settlements for update
using (
  auth.uid() = from_user_id
)
with check (
  status = 'sent'
);

-- Policy: Payee (to_user) can update status to 'confirmed'
create policy "Creditor can mark as confirmed"
on settlements for update
using (
  auth.uid() = to_user_id
)
with check (
  status = 'confirmed'
);
