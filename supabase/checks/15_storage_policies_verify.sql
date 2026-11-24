-- ==============================================================================
-- DEVSPACE STORAGE RLS POLICIES VERIFICATION CHECK (Read-Only)
-- File: supabase/checks/15_storage_policies_verify.sql
-- Run this in Supabase SQL Editor to verify storage.objects policies.
-- ==============================================================================

SELECT
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects';
