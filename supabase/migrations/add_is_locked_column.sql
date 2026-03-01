-- Add is_locked column to trips table if it doesn't exist
alter table trips add column if not exists is_locked boolean default false;
