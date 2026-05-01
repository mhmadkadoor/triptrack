-- Add is_expense_editing_locked column
ALTER TABLE trips ADD COLUMN IF NOT EXISTS is_expense_editing_locked BOOLEAN DEFAULT FALSE;
