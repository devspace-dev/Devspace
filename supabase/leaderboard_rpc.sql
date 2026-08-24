-- DevSpace Leaderboard RPC & Optimization Script

-- 1. Create index for fast time-based ledger lookups
CREATE INDEX IF NOT EXISTS idx_aura_ledger_created_at_user_id 
  ON public.aura_ledger (created_at DESC, user_id);

-- 2. Stored procedure to fetch leaderboard by timeframe ('weekly', 'monthly', 'all_time') with optional college filter
CREATE OR REPLACE FUNCTION public.get_aura_leaderboard(
  p_timeframe text DEFAULT 'all_time',
  p_college text DEFAULT NULL,
  p_limit integer DEFAULT 100
)
RETURNS TABLE (
  id uuid,
  name text,
  handle text,
  avatar text,
  role text,
  year text,
  branch text,
  building text,
  stack text,
  bio text,
  college text,
  github_handle text,
  profile_completed boolean,
  is_admin boolean,
  aura bigint,
  created_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_since timestamp with time zone;
BEGIN
  IF p_timeframe = 'weekly' THEN
    v_since := NOW() - INTERVAL '7 days';
  ELSIF p_timeframe = 'monthly' THEN
    v_since := DATE_TRUNC('month', CURRENT_DATE);
  ELSE
    v_since := NULL;
  END IF;

  IF v_since IS NOT NULL THEN
    RETURN QUERY
    WITH timeframe_scores AS (
      SELECT 
        al.user_id,
        COALESCE(SUM(al.points), 0)::bigint AS period_aura
      FROM public.aura_ledger al
      WHERE al.created_at >= v_since
      GROUP BY al.user_id
    )
    SELECT 
      u.id,
      u.name,
      u.handle,
      u.avatar,
      u.role,
      u.year,
      u.branch,
      u.building,
      u.stack,
      u.bio,
      u.college,
      u.github_handle,
      u.profile_completed,
      u.is_admin,
      ts.period_aura AS aura,
      u.created_at
    FROM public.users u
    INNER JOIN timeframe_scores ts ON u.id = ts.user_id
    WHERE (p_college IS NULL OR p_college = '' OR u.college = p_college)
      AND ts.period_aura > 0
    ORDER BY ts.period_aura DESC, u.aura DESC
    LIMIT p_limit;
  ELSE
    RETURN QUERY
    SELECT 
      u.id,
      u.name,
      u.handle,
      u.avatar,
      u.role,
      u.year,
      u.branch,
      u.building,
      u.stack,
      u.bio,
      u.college,
      u.github_handle,
      u.profile_completed,
      u.is_admin,
      u.aura::bigint AS aura,
      u.created_at
    FROM public.users u
    WHERE (p_college IS NULL OR p_college = '' OR u.college = p_college)
    ORDER BY u.aura DESC
    LIMIT p_limit;
  END IF;
END;
$$;
