-- Add allow_self_exclusion column to trips table
alter table trips add column allow_self_exclusion boolean default true;
