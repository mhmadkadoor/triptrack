-- Fix missing currency column in expenses table

-- Add currency column to expenses table.
-- We default to 'USD' or you can make it nullable. 
-- Since trips have a base_currency, expenses usually inherit that.

ALTER TABLE expenses 
ADD COLUMN currency text NOT NULL DEFAULT 'USD';

-- Optional: If you want to backfill existing expenses with their trip's currency:
/*
UPDATE expenses e
SET currency = t.base_currency
FROM trips t
WHERE e.trip_id = t.id;
*/
