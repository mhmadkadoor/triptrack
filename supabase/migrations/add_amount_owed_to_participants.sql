-- Fix missing amount_owed column in expense_participants table

-- Add amount_owed column to expense_participants table.
-- It should be a numeric/double type. 
-- We'll default it to 0 for existing rows if any, but ideally it should be calculated.
-- Making it nullable or defaulting to 0 is safe for migration.

ALTER TABLE expense_participants 
ADD COLUMN amount_owed numeric NOT NULL DEFAULT 0;

-- Also check if is_paid exists, just in case.
ALTER TABLE expense_participants 
ADD COLUMN IF NOT EXISTS is_paid boolean NOT NULL DEFAULT false;
