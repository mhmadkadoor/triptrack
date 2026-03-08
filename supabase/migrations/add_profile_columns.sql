-- Add avatar_url and payment_info to profiles table
-- These fields allow users to customize their profile and share payment details for settlements.

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS avatar_url text,
ADD COLUMN IF NOT EXISTS payment_info text;
