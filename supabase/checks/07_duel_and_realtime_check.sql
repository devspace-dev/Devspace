-- ==============================================================================
-- DEVSPACE VERIFICATION CHECK 07: DUELS, REALTIME & ALL-TIME LEADERBOARD (Q1-Q3)
-- File: supabase/checks/07_duel_and_realtime_check.sql
-- Read-only SQL checks for Bug A (Q1 & Q2) and Bug B all-time top 15 (Q3).
-- Run in Supabase SQL Editor and paste results if not yet captured.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- QUERY 1A: Inspect live columns of public.arena_matches and public.duel_requests
-- ------------------------------------------------------------------------------
SELECT
  table_name,
  ordinal_position,
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('duel_requests', 'arena_matches')
ORDER BY table_name, ordinal_position;

-- ------------------------------------------------------------------------------
-- QUERY 1B: Recent duel_requests joined with matching arena_matches & notifications
-- ------------------------------------------------------------------------------
SELECT
  dr.id AS request_id,
  dr.sender_id,
  dr.receiver_id,
  dr.category,
  dr.mode,
  dr.status AS request_status,
  dr.created_at AS request_created_at,
  dr.updated_at AS request_updated_at,
  am.id AS match_id,
  am.status AS match_status,
  am.player1_id,
  am.player2_id,
  am.player1_score,
  am.player2_score,
  COUNT(n.id) AS invite_notification_count
FROM public.duel_requests dr
LEFT JOIN public.arena_matches am ON am.id = dr.id
LEFT JOIN public.notifications n
  ON n.post_id::text = dr.id::text
 AND n.type = 'duel_invite'
GROUP BY
  dr.id, dr.sender_id, dr.receiver_id, dr.category, dr.mode, dr.status,
  dr.created_at, dr.updated_at,
  am.id, am.status, am.player1_id, am.player2_id, am.player1_score, am.player2_score
ORDER BY dr.created_at DESC
LIMIT 25;

-- ------------------------------------------------------------------------------
-- QUERY 1C: Recent/latest rows in public.arena_matches directly (friend or random)
-- ------------------------------------------------------------------------------
SELECT
  id,
  mode,
  status,
  player1_id,
  player2_id,
  player1_score,
  player2_score
FROM public.arena_matches
LIMIT 25;

-- ------------------------------------------------------------------------------
-- QUERY 1D: Live definitions of resolve_arena_match and get_aura_leaderboard
-- Confirms whether aura-02-write-path.sql or devspace_schema.sql is deployed.
-- ------------------------------------------------------------------------------
SELECT
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS identity_args,
  pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('resolve_arena_match', 'get_aura_leaderboard', 'find_arena_match');

-- ------------------------------------------------------------------------------
-- QUERY 2: supabase_realtime publication membership & REPLICA IDENTITY
-- Filtered UPDATE subscriptions (id=eq.<uuid>) require tables in supabase_realtime.
-- ------------------------------------------------------------------------------
SELECT
  c.relname AS table_name,
  c.relreplident AS replica_identity_code,
  CASE c.relreplident
    WHEN 'd' THEN 'default (PK only)'
    WHEN 'n' THEN 'nothing'
    WHEN 'f' THEN 'full'
    WHEN 'i' THEN 'index'
    ELSE c.relreplident::text
  END AS replica_identity,
  EXISTS (
    SELECT 1
    FROM pg_publication_tables pt
    WHERE pt.pubname = 'supabase_realtime'
      AND pt.schemaname = 'public'
      AND pt.tablename = c.relname
  ) AS in_supabase_realtime
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('duel_requests', 'arena_matches', 'live_duels', 'notifications', 'users')
ORDER BY c.relname;

-- Also list every table currently in supabase_realtime:
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY schemaname, tablename;

-- ------------------------------------------------------------------------------
-- QUERY 3: All-Time Top 15 SQL Comparison (Competition Rank vs App List Index vs RPC)
-- ------------------------------------------------------------------------------
WITH all_time_scores AS (
  SELECT
    al.user_id,
    COALESCE(SUM(al.points), 0)::bigint AS period_aura
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
sql_ranked AS (
  SELECT
    u.id,
    u.name,
    u.handle,
    u.college,
    u.created_at,
    COALESCE(u.aura, 0)::bigint AS users_table_aura,
    COALESCE(ats.period_aura, 0)::bigint AS sql_all_time_aura,
    RANK() OVER (ORDER BY COALESCE(ats.period_aura, 0) DESC) AS sql_comp_rank,
    DENSE_RANK() OVER (ORDER BY COALESCE(ats.period_aura, 0) DESC) AS sql_dense_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ats.period_aura, 0) DESC, u.created_at ASC) AS app_row_num
  FROM public.users u
  LEFT JOIN all_time_scores ats ON u.id = ats.user_id
),
rpc_rows AS (
  SELECT
    r.id,
    r.aura::bigint AS rpc_all_time_aura,
    ROW_NUMBER() OVER () AS rpc_pos
  FROM public.get_aura_leaderboard(NULL, 15, 'all_time') r
)
SELECT
  s.sql_comp_rank,
  s.app_row_num AS app_displayed_rank,
  (s.sql_comp_rank <> s.app_row_num) AS tie_rank_mismatch,
  rr.rpc_pos,
  s.id,
  s.name,
  s.handle,
  s.college,
  s.sql_all_time_aura,
  rr.rpc_all_time_aura,
  s.users_table_aura,
  (s.sql_all_time_aura <> s.users_table_aura) AS users_aura_differs_from_ledger,
  (s.sql_all_time_aura = 0) AS is_zero_aura
FROM sql_ranked s
LEFT JOIN rpc_rows rr ON rr.id = s.id
WHERE s.app_row_num <= 15
ORDER BY s.app_row_num ASC;
