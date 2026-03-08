-- Add updated_at column to profiles if it matches missing
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
