-- ==============================================================================
-- DEVSPACE STORAGE RLS POLICIES NOTE
-- File: supabase/patches/15_storage_policies.sql
-- Note: In hosted Supabase, table storage.objects is owned by supabase_storage_admin.
-- Direct ALTER TABLE / CREATE POLICY via SQL editor as role postgres will return
-- 42501 (must be owner of table objects).
--
-- YOU DO NOT NEED TO RUN THIS SCRIPT!
-- The client-side fix in profile_setup_screen.dart already formats avatar paths as
-- 'profiles/<uid>.<timestamp>.jpg', which strictly satisfies the existing active
-- policy (name LIKE 'profiles/' || auth.uid() || '.%').
--
-- If you ever wish to edit storage policies manually, configure them through the
-- Supabase Dashboard UI under: Storage -> Configuration / Policies.
-- ==============================================================================

BEGIN;

-- 1. Ensure storage.objects has RLS enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2. Drop legacy restrictive policies
DROP POLICY IF EXISTS "Users can upload own scoped media" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own scoped media" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own scoped media" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile photos" ON storage.objects;

-- 3. INSERT policy: Allow authenticated users to upload to their own scoped paths
CREATE POLICY "Users can upload own scoped media" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    (
      bucket_id = 'images'
      AND (
        name LIKE ('posts/' || auth.uid()::text || '/%')
        OR name LIKE ('profiles/' || auth.uid()::text || '.%')
        OR name LIKE ('profiles/' || auth.uid()::text || '_%')
        OR name LIKE ('profiles/' || auth.uid()::text || '/%')
        OR name LIKE ('covers/' || auth.uid()::text || '.%')
        OR name LIKE ('covers/' || auth.uid()::text || '_%')
        OR name LIKE ('covers/' || auth.uid()::text || '/%')
        OR name LIKE 'chat/%'
        OR name LIKE 'events/%'
      )
    )
    OR (
      bucket_id = 'documents'
      AND name LIKE ('documents/' || auth.uid()::text || '/%')
    )
  );

-- 4. UPDATE policy: Allow authenticated users to update/overwrite their own media
CREATE POLICY "Users can update own scoped media" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    (
      bucket_id = 'images'
      AND (
        owner = auth.uid()
        OR name LIKE ('posts/' || auth.uid()::text || '/%')
        OR name LIKE ('profiles/' || auth.uid()::text || '.%')
        OR name LIKE ('profiles/' || auth.uid()::text || '_%')
        OR name LIKE ('profiles/' || auth.uid()::text || '/%')
        OR name LIKE ('covers/' || auth.uid()::text || '.%')
        OR name LIKE ('covers/' || auth.uid()::text || '_%')
        OR name LIKE ('covers/' || auth.uid()::text || '/%')
        OR name LIKE 'chat/%'
        OR name LIKE 'events/%'
      )
    )
    OR (
      bucket_id = 'documents'
      AND (
        owner = auth.uid()
        OR name LIKE ('documents/' || auth.uid()::text || '/%')
      )
    )
  )
  WITH CHECK (
    (
      bucket_id = 'images'
      AND (
        owner = auth.uid()
        OR name LIKE ('posts/' || auth.uid()::text || '/%')
        OR name LIKE ('profiles/' || auth.uid()::text || '.%')
        OR name LIKE ('profiles/' || auth.uid()::text || '_%')
        OR name LIKE ('profiles/' || auth.uid()::text || '/%')
        OR name LIKE ('covers/' || auth.uid()::text || '.%')
        OR name LIKE ('covers/' || auth.uid()::text || '_%')
        OR name LIKE ('covers/' || auth.uid()::text || '/%')
        OR name LIKE 'chat/%'
        OR name LIKE 'events/%'
      )
    )
    OR (
      bucket_id = 'documents'
      AND (
        owner = auth.uid()
        OR name LIKE ('documents/' || auth.uid()::text || '/%')
      )
    )
  );

-- 5. DELETE policy: Allow authenticated users to delete their own media
CREATE POLICY "Users can delete own scoped media" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    (
      bucket_id = 'images'
      AND (
        owner = auth.uid()
        OR name LIKE ('posts/' || auth.uid()::text || '/%')
        OR name LIKE ('profiles/' || auth.uid()::text || '.%')
        OR name LIKE ('profiles/' || auth.uid()::text || '_%')
        OR name LIKE ('profiles/' || auth.uid()::text || '/%')
        OR name LIKE ('covers/' || auth.uid()::text || '.%')
        OR name LIKE ('covers/' || auth.uid()::text || '_%')
        OR name LIKE ('covers/' || auth.uid()::text || '/%')
        OR name LIKE 'chat/%'
        OR name LIKE 'events/%'
      )
    )
    OR (
      bucket_id = 'documents'
      AND (
        owner = auth.uid()
        OR name LIKE ('documents/' || auth.uid()::text || '/%')
      )
    )
  );

COMMIT;
