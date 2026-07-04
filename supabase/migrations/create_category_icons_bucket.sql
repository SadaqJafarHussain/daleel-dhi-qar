-- Create public storage bucket for category icons
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'category_icons',
  'category_icons',
  true,
  5242880, -- 5MB
  ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access
CREATE POLICY "Public read category icons"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'category_icons');

-- Allow authenticated users (admin) to upload
CREATE POLICY "Authenticated upload category icons"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'category_icons');

-- Allow authenticated users to update/replace
CREATE POLICY "Authenticated update category icons"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'category_icons');

-- Allow authenticated users to delete
CREATE POLICY "Authenticated delete category icons"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'category_icons');
