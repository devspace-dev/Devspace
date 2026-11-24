-- ==============================================================================
-- DEVSPACE VERIFICATION CHECK 06: LEADERBOARD & RANKING AUDIT
-- File: supabase/checks/06_rank_check.sql
-- Read-only SQL checks. Run in Supabase SQL Editor (all at once or block-by-block).
-- Before running Blocks 3 and 4, replace the two placeholder literals:
--   'REPLACE_WITH_COLLEGE_NAME'
--   '00000000-0000-0000-0000-000000000000'
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- BLOCK 1: Inspect distinct college strings (exact vs normalized) & nulls
-- Use an exact `college` value from this output in Block 3.
-- ------------------------------------------------------------------------------
SELECT
  COALESCE(NULLIF(college, ''), '<NULL_OR_EMPTY>') AS exact_college,
  LOWER(TRIM(COALESCE(college, ''))) AS normalized_college,
  LENGTH(COALESCE(college, '')) AS char_len,
  COUNT(*) AS user_count,
  COUNT(*) FILTER (WHERE COALESCE(aura, 0) > 0) AS nonzero_users_aura_count
FROM public.users
GROUP BY 1, 2, 3
ORDER BY user_count DESC, exact_college ASC;

-- ------------------------------------------------------------------------------
-- BLOCK 2: Monthly Global Top 15 — SQL Competition Rank vs App List Rank vs RPC
-- Mirrors public.get_aura_leaderboard(NULL, 15, 'monthly') (UTC calendar month)
-- and compares against what RanksScreen computes (index + 1) and users.aura.
-- ------------------------------------------------------------------------------
WITH month_bounds AS (
  SELECT
    DATE_TRUNC('month', timezone('utc'::text, NOW())) AS v_month_start,
    DATE_TRUNC('month', timezone('utc'::text, NOW())) + INTERVAL '1 month' AS v_month_end
),
monthly_scores AS (
  SELECT
    al.user_id,
    COALESCE(SUM(al.points), 0)::bigint AS period_aura
  FROM public.aura_ledger al
  CROSS JOIN month_bounds mb
  WHERE al.created_at >= mb.v_month_start
    AND al.created_at < mb.v_month_end
    AND al.action IN (
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
    COALESCE(ms.period_aura, 0)::bigint AS sql_monthly_aura,
    RANK() OVER (ORDER BY COALESCE(ms.period_aura, 0) DESC) AS sql_comp_rank,
    DENSE_RANK() OVER (ORDER BY COALESCE(ms.period_aura, 0) DESC) AS sql_dense_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ms.period_aura, 0) DESC, u.created_at ASC) AS app_row_num
  FROM public.users u
  LEFT JOIN monthly_scores ms ON u.id = ms.user_id
),
rpc_rows AS (
  SELECT
    r.id,
    r.aura::bigint AS rpc_monthly_aura,
    ROW_NUMBER() OVER () AS rpc_pos
  FROM public.get_aura_leaderboard(NULL, 15, 'monthly') r
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
  s.sql_monthly_aura,
  rr.rpc_monthly_aura,
  s.users_table_aura,
  (s.sql_monthly_aura = 0) AS is_zero_aura
FROM sql_ranked s
LEFT JOIN rpc_rows rr ON rr.id = s.id
WHERE s.app_row_num <= 15
ORDER BY s.app_row_num ASC;

-- ------------------------------------------------------------------------------
-- BLOCK 3: Monthly Single-College Top 15 + Normalization Collision Check
-- Replace 'REPLACE_WITH_COLLEGE_NAME' below with an exact value from Block 1.
-- ------------------------------------------------------------------------------
WITH params AS (
  SELECT 'REPLACE_WITH_COLLEGE_NAME'::text AS target_college
),
month_bounds AS (
  SELECT
    DATE_TRUNC('month', timezone('utc'::text, NOW())) AS v_month_start,
    DATE_TRUNC('month', timezone('utc'::text, NOW())) + INTERVAL '1 month' AS v_month_end
),
monthly_scores AS (
  SELECT
    al.user_id,
    COALESCE(SUM(al.points), 0)::bigint AS period_aura
  FROM public.aura_ledger al
  CROSS JOIN month_bounds mb
  WHERE al.created_at >= mb.v_month_start
    AND al.created_at < mb.v_month_end
    AND al.action IN (
      'practice_question',
      'practice_complete',
      'complete_daily_mission',
      'attempt_daily_mission',
      'mission_solved',
      'arena_duel'
    )
  GROUP BY al.user_id
),
exact_college_ranked AS (
  SELECT
    u.id,
    u.name,
    u.handle,
    u.college,
    u.created_at,
    COALESCE(u.aura, 0)::bigint AS users_table_aura,
    COALESCE(ms.period_aura, 0)::bigint AS sql_monthly_aura,
    RANK() OVER (ORDER BY COALESCE(ms.period_aura, 0) DESC) AS sql_comp_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ms.period_aura, 0) DESC, u.created_at ASC) AS app_row_num,
    (SELECT COUNT(*) FROM public.users u2 CROSS JOIN params p2
     WHERE LOWER(TRIM(COALESCE(u2.college, ''))) = LOWER(TRIM(p2.target_college))
       AND COALESCE(u2.college, '') <> p2.target_college) AS missed_normalization_variants
  FROM public.users u
  CROSS JOIN params p
  LEFT JOIN monthly_scores ms ON u.id = ms.user_id
  WHERE u.college = p.target_college
),
rpc_college AS (
  SELECT
    r.id,
    r.aura::bigint AS rpc_monthly_aura,
    ROW_NUMBER() OVER () AS rpc_pos
  FROM params p
  CROSS JOIN LATERAL public.get_aura_leaderboard(p.target_college, 15, 'monthly') r
)
SELECT
  e.sql_comp_rank,
  e.app_row_num AS app_displayed_rank,
  (e.sql_comp_rank <> e.app_row_num) AS tie_rank_mismatch,
  rc.rpc_pos,
  e.id,
  e.name,
  e.handle,
  e.college,
  e.sql_monthly_aura,
  rc.rpc_monthly_aura,
  e.users_table_aura,
  (e.sql_monthly_aura = 0) AS is_zero_aura,
  e.missed_normalization_variants
FROM exact_college_ranked e
LEFT JOIN rpc_college rc ON rc.id = e.id
WHERE e.app_row_num <= 15
ORDER BY e.app_row_num ASC;

-- ------------------------------------------------------------------------------
-- BLOCK 4: Specific User Rank Audit (Profile vs Monthly vs All-Time, Global & College)
-- Replace '00000000-0000-0000-0000-000000000000' below with a real public.users.id UUID.
-- ------------------------------------------------------------------------------
WITH params AS (
  SELECT '00000000-0000-0000-0000-000000000000'::uuid AS target_user_id
),
bounds AS (
  SELECT
    DATE_TRUNC('month', timezone('utc'::text, NOW())) AS utc_month_start,
    DATE_TRUNC('month', timezone('utc'::text, NOW())) + INTERVAL '1 month' AS utc_month_end,
    DATE_TRUNC('month', timezone('Asia/Kolkata'::text, NOW())) AS ist_month_start_local
),
ledger_agg AS (
  SELECT
    al.user_id,
    COALESCE(SUM(al.points), 0)::bigint AS all_ledger_points,
    COALESCE(SUM(al.points) FILTER (
      WHERE al.action IN (
        'practice_question', 'practice_complete',
        'complete_daily_mission', 'attempt_daily_mission',
        'mission_solved', 'arena_duel'
      )
    ), 0)::bigint AS allowed_all_time_aura,
    COALESCE(SUM(al.points) FILTER (
      WHERE al.created_at >= b.utc_month_start
        AND al.created_at < b.utc_month_end
        AND al.action IN (
          'practice_question', 'practice_complete',
          'complete_daily_mission', 'attempt_daily_mission',
          'mission_solved', 'arena_duel'
        )
    ), 0)::bigint AS allowed_monthly_utc_aura,
    COALESCE(SUM(al.points) FILTER (
      WHERE timezone('Asia/Kolkata'::text, al.created_at) >= b.ist_month_start_local
        AND al.action IN (
          'practice_question', 'practice_complete',
          'complete_daily_mission', 'attempt_daily_mission',
          'mission_solved', 'arena_duel'
        )
    ), 0)::bigint AS allowed_monthly_ist_aura
  FROM public.aura_ledger al
  CROSS JOIN bounds b
  GROUP BY al.user_id
),
all_users AS (
  SELECT
    u.id,
    u.name,
    u.handle,
    u.college,
    u.created_at,
    COALESCE(u.aura, 0)::bigint AS users_table_aura,
    COALESCE(l.all_ledger_points, 0)::bigint AS all_ledger_points,
    COALESCE(l.allowed_all_time_aura, 0)::bigint AS allowed_all_time_aura,
    COALESCE(l.allowed_monthly_utc_aura, 0)::bigint AS allowed_monthly_utc_aura,
    COALESCE(l.allowed_monthly_ist_aura, 0)::bigint AS allowed_monthly_ist_aura,
    RANK() OVER (ORDER BY COALESCE(l.allowed_monthly_utc_aura, 0) DESC) AS monthly_global_comp_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(l.allowed_monthly_utc_aura, 0) DESC, u.created_at ASC) AS monthly_global_app_pos,
    RANK() OVER (ORDER BY COALESCE(l.allowed_all_time_aura, 0) DESC) AS all_time_global_comp_rank,
    ROW_NUMBER() OVER (ORDER BY COALESCE(l.allowed_all_time_aura, 0) DESC, u.created_at ASC) AS all_time_global_app_pos
  FROM public.users u
  LEFT JOIN ledger_agg l ON l.user_id = u.id
),
target AS (
  SELECT * FROM all_users WHERE id = (SELECT target_user_id FROM params)
),
college_users AS (
  SELECT
    au.*,
    RANK() OVER (ORDER BY au.allowed_monthly_utc_aura DESC) AS monthly_college_comp_rank,
    ROW_NUMBER() OVER (ORDER BY au.allowed_monthly_utc_aura DESC, au.created_at ASC) AS monthly_college_app_pos,
    RANK() OVER (ORDER BY au.allowed_all_time_aura DESC) AS all_time_college_comp_rank,
    ROW_NUMBER() OVER (ORDER BY au.allowed_all_time_aura DESC, au.created_at ASC) AS all_time_college_app_pos
  FROM all_users au
  CROSS JOIN target t
  WHERE NULLIF(TRIM(COALESCE(t.college, '')), '') IS NOT NULL
    AND au.college = t.college
),
profile_rank AS (
  SELECT
    CASE
      WHEN NULLIF(TRIM(COALESCE(t.college, '')), '') IS NULL THEN NULL
      ELSE (
        SELECT COUNT(*) + 1
        FROM public.users u2
        WHERE u2.college = t.college
          AND COALESCE(u2.aura, 0) > t.users_table_aura
      )
    END AS get_user_college_rank_result
  FROM target t
),
rpc_monthly_global AS (
  SELECT r.id, r.aura::bigint AS rpc_aura, ROW_NUMBER() OVER () AS rpc_pos
  FROM public.get_aura_leaderboard(NULL, 100, 'monthly') r
),
rpc_monthly_college AS (
  SELECT r.id, r.aura::bigint AS rpc_aura, ROW_NUMBER() OVER () AS rpc_pos
  FROM target t
  CROSS JOIN LATERAL public.get_aura_leaderboard(NULLIF(t.college, ''), 100, 'monthly') r
),
rpc_all_time_college AS (
  SELECT r.id, r.aura::bigint AS rpc_aura, ROW_NUMBER() OVER () AS rpc_pos
  FROM target t
  CROSS JOIN LATERAL public.get_aura_leaderboard(NULLIF(t.college, ''), 100, 'all_time') r
)
SELECT
  t.id,
  t.name,
  t.handle,
  t.college,
  t.users_table_aura,
  t.all_ledger_points,
  t.allowed_all_time_aura,
  t.allowed_monthly_utc_aura,
  t.allowed_monthly_ist_aura,
  pr.get_user_college_rank_result AS profile_college_rank_shown,
  cu.monthly_college_comp_rank,
  cu.monthly_college_app_pos,
  rmc.rpc_pos AS rpc_monthly_college_pos_top100,
  rmc.rpc_aura AS rpc_monthly_college_aura,
  cu.all_time_college_comp_rank,
  cu.all_time_college_app_pos,
  rac.rpc_pos AS rpc_all_time_college_pos_top100,
  rac.rpc_aura AS rpc_all_time_college_aura,
  t.monthly_global_comp_rank,
  t.monthly_global_app_pos,
  rmg.rpc_pos AS rpc_monthly_global_pos_top100,
  t.all_time_global_comp_rank,
  t.all_time_global_app_pos,
  (cu.monthly_college_app_pos IS NULL OR cu.monthly_college_app_pos > 100) AS hidden_from_monthly_college_bottom_sheet,
  (t.monthly_global_app_pos > 100) AS hidden_from_monthly_global_bottom_sheet
FROM target t
CROSS JOIN profile_rank pr
LEFT JOIN college_users cu ON cu.id = t.id
LEFT JOIN rpc_monthly_global rmg ON rmg.id = t.id
LEFT JOIN rpc_monthly_college rmc ON rmc.id = t.id
LEFT JOIN rpc_all_time_college rac ON rac.id = t.id;
