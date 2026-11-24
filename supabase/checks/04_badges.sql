-- ==============================================================================
-- DEVSPACE VERIFICATION CHECK 04: BADGES SYSTEM STATE
-- File: supabase/checks/04_badges.sql
-- Run this in Supabase SQL Editor (read-only queries).
-- ==============================================================================

-- 1. Check if user_badges table exists and show its columns
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'user_badges'
ORDER BY ordinal_position;

-- 2. Check indexes on user_badges
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'user_badges';

-- 3. Check RLS status and policies on user_badges
SELECT
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled
FROM pg_class c
WHERE c.relnamespace = 'public'::regnamespace
  AND c.relname = 'user_badges';

SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'user_badges';

-- 4. Check if sync_my_badges function exists and show its definition
SELECT
  p.proname AS function_name,
  pg_get_function_arguments(p.oid) AS arguments,
  pg_get_function_result(p.oid) AS return_type,
  p.prosecdef AS is_security_definer,
  p.prosrc AS source_code
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('sync_my_badges', 'sync_badges');

-- 5. Safe table presence & row count (safe even if table does not exist)
SELECT relname AS table_name, n_live_tup AS row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public' AND relname = 'user_badges';
