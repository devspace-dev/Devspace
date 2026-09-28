-- =============================================================================
-- PHASE A: AURA BACKUP & READ-ONLY REBUILD PREVIEW
-- File: supabase/patches/aura-01-backup-and-preview.sql
--
-- SAFE TO RUN:
--   1. Creates timestamped backup tables (`users_aura_backup_<YYYYMMDD_HH24MISS>`
--      and `aura_ledger_backup_<YYYYMMDD_HH24MISS>`) plus canonical backup copies
--      (`public.users_aura_backup` and `public.aura_ledger_backup`) for rollback.
--   2. Does NOT modify or delete any rows in `public.users` or `public.aura_ledger`.
--   3. Returns two read-only result sets:
--      - Result Set 1: Per-user comparison of current `users.aura` vs rebuilt
--        Arena-only total, sorted by biggest drop.
--      - Result Set 2: Every distinct `action` in `public.aura_ledger` with row
--        counts, point sums, and `COUNTS` vs `EXCLUDED` status.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4a) CREATE BACKUP TABLES (WITH TIMESTAMP SUFFIX + CANONICAL ALIAS TABLES)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_suffix text := to_char(timezone('utc', now()), 'YYYYMMDD_HH24MISS');
  v_users_backup_table text := format('public.users_aura_backup_%s', v_suffix);
  v_ledger_backup_table text := format('public.aura_ledger_backup_%s', v_suffix);
BEGIN
  -- 1. Timestamped backup of users (id, aura, aura_points)
  EXECUTE format(
    'CREATE TABLE %s AS SELECT id, aura, aura_points, now() AS backed_up_at FROM public.users',
    v_users_backup_table
  );
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', v_users_backup_table);
  EXECUTE format('REVOKE ALL ON TABLE %s FROM public, anon, authenticated', v_users_backup_table);

  -- 2. Timestamped full copy of aura_ledger
  EXECUTE format(
    'CREATE TABLE %s AS SELECT *, now() AS backed_up_at FROM public.aura_ledger',
    v_ledger_backup_table
  );
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', v_ledger_backup_table);
  EXECUTE format('REVOKE ALL ON TABLE %s FROM public, anon, authenticated', v_ledger_backup_table);

  -- 3. Canonical latest backup tables (`public.users_aura_backup` & `public.aura_ledger_backup`)
  --    so `aura-04-rollback.sql` can reference a deterministic table name.
  DROP TABLE IF EXISTS public.users_aura_backup;
  CREATE TABLE public.users_aura_backup AS
  SELECT id, aura, aura_points, now() AS backed_up_at
  FROM public.users;
  ALTER TABLE public.users_aura_backup ENABLE ROW LEVEL SECURITY;
  REVOKE ALL ON TABLE public.users_aura_backup FROM public, anon, authenticated;

  DROP TABLE IF EXISTS public.aura_ledger_backup;
  CREATE TABLE public.aura_ledger_backup AS
  SELECT *, now() AS backed_up_at
  FROM public.aura_ledger;
  ALTER TABLE public.aura_ledger_backup ENABLE ROW LEVEL SECURITY;
  REVOKE ALL ON TABLE public.aura_ledger_backup FROM public, anon, authenticated;

  RAISE NOTICE 'Created backup tables: %, %, public.users_aura_backup, public.aura_ledger_backup',
    v_users_backup_table, v_ledger_backup_table;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4b) READ-ONLY PREVIEW: CURRENT users.aura vs REBUILT ARENA-ONLY TOTAL
--     Allowed actions:
--       - complete_daily_mission
--       - attempt_daily_mission
--       - mission_solved
--       - practice_question
--       - practice_complete
--       - arena_duel
--     Sorted by biggest drop (`aura_drop DESC`).
-- -----------------------------------------------------------------------------
WITH rebuilt_totals AS (
  SELECT
    al.user_id,
    COALESCE(SUM(al.points), 0)::bigint AS rebuilt_aura,
    COUNT(*)::bigint AS counted_ledger_rows
  FROM public.aura_ledger al
  WHERE al.action IN (
    'complete_daily_mission',
    'attempt_daily_mission',
    'mission_solved',
    'practice_question',
    'practice_complete',
    'arena_duel'
  )
  GROUP BY al.user_id
)
SELECT
  u.id AS user_id,
  u.handle,
  u.name,
  COALESCE(u.aura, 0)::bigint AS current_users_aura,
  COALESCE(u.aura_points, 0)::bigint AS current_users_aura_points,
  COALESCE(rt.rebuilt_aura, 0)::bigint AS new_rebuilt_aura,
  (COALESCE(u.aura, 0)::bigint - COALESCE(rt.rebuilt_aura, 0)::bigint) AS aura_drop,
  (COALESCE(rt.rebuilt_aura, 0)::bigint - COALESCE(u.aura, 0)::bigint) AS net_change,
  COALESCE(rt.counted_ledger_rows, 0)::bigint AS counted_ledger_rows
FROM public.users u
LEFT JOIN rebuilt_totals rt ON rt.user_id = u.id
ORDER BY
  (COALESCE(u.aura, 0)::bigint - COALESCE(rt.rebuilt_aura, 0)::bigint) DESC,
  COALESCE(u.aura, 0) DESC,
  u.created_at ASC;

-- -----------------------------------------------------------------------------
-- 4c) READ-ONLY AUDIT: EVERY DISTINCT ACTION IN aura_ledger (COUNTS vs EXCLUDED)
-- -----------------------------------------------------------------------------
SELECT
  al.action,
  CASE
    WHEN al.action IN (
      'complete_daily_mission',
      'attempt_daily_mission',
      'mission_solved',
      'practice_question',
      'practice_complete',
      'arena_duel'
    ) THEN 'COUNTS'
    ELSE 'EXCLUDED'
  END AS status,
  COUNT(*)::bigint AS row_count,
  COUNT(DISTINCT al.user_id)::bigint AS distinct_users,
  COALESCE(SUM(al.points), 0)::bigint AS total_points,
  MIN(al.points) AS min_points,
  MAX(al.points) AS max_points
FROM public.aura_ledger al
GROUP BY al.action
ORDER BY
  status ASC,
  total_points DESC,
  row_count DESC;
