-- Create a new public storage bucket for avatars
-- We use ON CONFLICT to avoid errors if the bucket already exists.
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- NOTE: storage.objects already has RLS enabled by default. Only the owner can alter it.
-- We skip ALTER TABLE to avoid permissions errors (42501).

-- Drop existing policies to avoid conflicts if re-running
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Avatar Upload" ON storage.objects;
DROP POLICY IF EXISTS "Avatar Update" ON storage.objects;

-- Allow public read access to avatars
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );

-- Allow authenticated users to upload their own avatar
-- We'll use the user ID as the filename for simplicity (avatars/{userId}.jpg)
-- The check ensures the file name matches the user ID.
CREATE POLICY "Avatar Upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update/overwrite their own avatar
CREATE POLICY "Avatar Update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
