ALTER TABLE public.expenses
ADD COLUMN IF NOT EXISTS is_settlement BOOLEAN DEFAULT false;
