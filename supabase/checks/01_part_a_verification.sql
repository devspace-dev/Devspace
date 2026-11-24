-- ==============================================================================
-- DEVSPACE VERIFICATION CHECK 01: PART A VERIFICATION
-- File: supabase/checks/01_part_a_verification.sql
-- Run this in Supabase SQL Editor (read-only queries).
-- ==============================================================================

-- 1. Check storage.objects policies (chat/% and events/%)
SELECT
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 2. Check public.messages policies (UPDATE/DELETE and roles)
SELECT
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'messages';

-- 3. Check RLS on users_aura_backup and aura_ledger_backup
SELECT
  relname,
  relrowsecurity AS rls_enabled,
  relforcerowsecurity AS rls_forced
FROM pg_class
WHERE relname IN ('users_aura_backup', 'aura_ledger_backup', 'arena_matches', 'user_practice_completions');

-- 4. Check function privileges on award_aura, review_daily_mission, and aura functions
SELECT
  routine_name,
  grantee,
  privilege_type
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND routine_name IN ('award_aura', 'review_daily_mission', 'submit_practice_completion', 'submit_daily_mission', 'resolve_arena_match', 'get_aura_leaderboard')
ORDER BY routine_name, grantee;

-- 5. Definition and security of review_daily_mission
SELECT
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'review_daily_mission';

-- 6. Check arena_matches policies and columns
SELECT
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'arena_matches';

-- 7. Premium teardown check: functions, tables, and columns
SELECT
  'function' AS kind,
  p.proname AS name
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'activate_user_premium'
UNION ALL
SELECT
  'table' AS kind,
  tablename AS name
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'premium_questions'
UNION ALL
SELECT
  'column' AS kind,
  column_name AS name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND column_name IN ('is_premium', 'career_goal', 'career_goal_selected');

-- 8. Check signatures and overloads for core Aura functions
SELECT
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS identity_arguments,
  pg_get_function_result(p.oid) AS return_type,
  COUNT(*) OVER (PARTITION BY p.proname) AS overload_count
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'award_aura',
    'submit_practice_completion',
    'submit_daily_mission',
    'resolve_arena_match',
    'get_aura_leaderboard'
  )
ORDER BY p.proname;

-- 9. Full definitions of core Aura functions (for exact comparison)
SELECT
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS signature,
  pg_get_functiondef(p.oid) AS source_code
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'award_aura',
    'submit_practice_completion',
    'submit_daily_mission',
    'resolve_arena_match',
    'get_aura_leaderboard'
  )
ORDER BY p.proname;

-- 10. Sync check: count of users where users.aura differs from allowed ledger sum, and users.aura vs aura_points
WITH allowed_ledger AS (
  SELECT
    user_id,
    COALESCE(SUM(points), 0)::bigint AS allowed_ledger_total
  FROM public.aura_ledger
  WHERE action IN (
    'practice_question',
    'practice_complete',
    'complete_daily_mission',
    'attempt_daily_mission',
    'mission_solved',
    'arena_duel'
  )
  GROUP BY user_id
)
SELECT
  COUNT(*) FILTER (WHERE COALESCE(u.aura, 0) <> COALESCE(al.allowed_ledger_total, 0)) AS users_with_aura_mismatch,
  COUNT(*) FILTER (WHERE COALESCE(u.aura, 0) <> COALESCE(u.aura_points, 0)) AS users_with_aura_points_mismatch,
  COUNT(*) AS total_users
FROM public.users u
LEFT JOIN allowed_ledger al ON u.id = al.user_id;

-- 11. Check public.notifications structure (message_id and unique index)
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'notifications'
  AND column_name = 'message_id';

SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'notifications'
  AND indexname = 'idx_notifications_message_id_unique';

-- 12. Check all triggers on public.messages and public.notifications
SELECT
  event_object_table AS table_name,
  trigger_name,
  action_timing,
  event_manipulation AS event,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN ('messages', 'notifications')
ORDER BY event_object_table, trigger_name;

-- 13. Definition of push_direct_message_notification trigger function
SELECT
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'push_direct_message_notification';
