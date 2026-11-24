-- ==============================================================================
-- DEVSPACE VERIFICATION CHECK 02: PART B SOLO AURA TRACE
-- File: supabase/checks/02_part_b_solo_aura_trace.sql
-- Run this in Supabase SQL Editor (read-only queries).
-- ==============================================================================

-- 1. Last 20 practice-related rows in public.aura_ledger
SELECT
  id,
  user_id,
  action,
  points,
  reference_type,
  reference_id,
  created_at,
  metadata
FROM public.aura_ledger
WHERE action IN ('practice_question', 'practice_complete')
   OR reference_type LIKE '%practice%'
ORDER BY created_at DESC
LIMIT 20;

-- 2. Count of rows by action in public.aura_ledger for the last 7 days
SELECT
  action,
  COUNT(*) AS row_count,
  COALESCE(SUM(points), 0) AS total_points,
  MIN(created_at) AS earliest,
  MAX(created_at) AS latest
FROM public.aura_ledger
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY action
ORDER BY row_count DESC;

-- 3. Check for practice completions in user_practice_completions WITHOUT matching aura_ledger row
SELECT
  upc.id AS completion_id,
  upc.user_id,
  upc.question_id,
  upc.created_at AS completed_at
FROM public.user_practice_completions upc
LEFT JOIN public.aura_ledger al
  ON al.user_id = upc.user_id
  AND al.reference_id = upc.question_id
  AND al.action = 'practice_question'
WHERE al.id IS NULL
ORDER BY upc.created_at DESC
LIMIT 20;

-- 4. Count of missing ledger entries for user_practice_completions
SELECT
  COUNT(*) AS total_completions,
  COUNT(al.id) AS completions_with_ledger,
  COUNT(*) - COUNT(al.id) AS completions_missing_ledger
FROM public.user_practice_completions upc
LEFT JOIN public.aura_ledger al
  ON al.user_id = upc.user_id
  AND al.reference_id = upc.question_id
  AND al.action = 'practice_question';

-- 5. Deep-dive comparison for the most active user (or test user)
--    Side-by-side: users.aura, sum of allowed ledger rows, monthly leaderboard value, all-time leaderboard value
WITH target_user AS (
  SELECT id, handle, name, college, aura, aura_points
  FROM public.users
  ORDER BY aura DESC
  LIMIT 1
),
ledger_sum AS (
  SELECT
    al.user_id,
    COALESCE(SUM(al.points), 0)::bigint AS allowed_ledger_total
  FROM public.aura_ledger al
  WHERE al.action IN (
    'practice_question',
    'practice_complete',
    'complete_daily_mission',
    'attempt_daily_mission',
    'mission_solved',
    'arena_duel'
  )
  GROUP BY al.user_id
),
monthly_ledger_sum AS (
  SELECT
    al.user_id,
    COALESCE(SUM(al.points), 0)::bigint AS monthly_ledger_total
  FROM public.aura_ledger al
  WHERE al.action IN (
    'practice_question',
    'practice_complete',
    'complete_daily_mission',
    'attempt_daily_mission',
    'mission_solved',
    'arena_duel'
  )
  AND al.created_at >= DATE_TRUNC('month', timezone('utc'::text, NOW()))
  GROUP BY al.user_id
)
SELECT
  tu.id AS user_id,
  tu.handle,
  tu.name,
  tu.college,
  tu.aura AS users_table_aura,
  tu.aura_points AS users_table_aura_points,
  COALESCE(ls.allowed_ledger_total, 0) AS all_time_allowed_ledger_sum,
  COALESCE(mls.monthly_ledger_total, 0) AS monthly_allowed_ledger_sum
FROM target_user tu
LEFT JOIN ledger_sum ls ON tu.id = ls.user_id
LEFT JOIN monthly_ledger_sum mls ON tu.id = mls.user_id;

-- 6. Test what get_aura_leaderboard returns for the top 5
SELECT *
FROM public.get_aura_leaderboard(NULL, 5, 'monthly');

SELECT *
FROM public.get_aura_leaderboard(NULL, 5, 'all_time');
