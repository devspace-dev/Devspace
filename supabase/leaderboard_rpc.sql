-- DevSpace Leaderboard & Practice Q&A Aura RPC Script

-- 1. Create index for fast time-based and action-filtered ledger lookups
CREATE INDEX IF NOT EXISTS idx_aura_ledger_created_at_user_id 
  ON public.aura_ledger (created_at DESC, user_id);

-- 2. Authoritative RPC for Arena Practice Mode Q&A rewards
-- Awards Easy: 5, Medium: 10, Hard: 15, Ultra: 20 when a user answers a practice question correctly
CREATE OR REPLACE FUNCTION public.complete_practice_question(
  p_question_id text,
  p_points integer
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_id uuid;
  v_valid_points integer;
  v_awarded boolean;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Enforce valid Practice Mode difficulty rewards: Easy (5), Medium (10), Hard (15), Ultra (20)
  v_valid_points := CASE
    WHEN p_points IN (5, 10, 15, 20) THEN p_points
    WHEN p_points <= 5 THEN 5
    WHEN p_points <= 10 THEN 10
    WHEN p_points <= 15 THEN 15
    ELSE 20
  END;

  v_awarded := public.award_aura(
    v_actor_id,
    'practice_question',
    v_valid_points,
    'practice_qa',
    p_question_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'awarded', v_awarded,
    'points', v_valid_points,
    'questionId', p_question_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_practice_question(text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_practice_question(text, integer) TO service_role;

-- 3. Stored procedure to fetch Leaderboard by board type ('monthly' or 'all_time')
-- and scope ('Global' when p_college is NULL/empty, 'College' when p_college is specified).
-- Only counts Aura from:
--   1. Q&A Solution & Arena Practice Mode (Easy: 5, Medium: 10, Hard: 15, Ultra: 20)
--   2. Daily Mission (+20 solved, +5 attempt)
--   3. Combat Section (arena_duel)
CREATE OR REPLACE FUNCTION public.get_aura_leaderboard(
  p_timeframe text DEFAULT 'monthly',
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
SET search_path = public
AS $$
DECLARE
  v_month_start timestamp with time zone;
  v_month_end timestamp with time zone;
BEGIN
  IF p_timeframe = 'monthly' OR p_timeframe = 'weekly' THEN
    -- Monthly board starts at 0 at the start of every calendar month and resets at the end of the month
    v_month_start := DATE_TRUNC('month', timezone('utc'::text, NOW()));
    v_month_end := v_month_start + INTERVAL '1 month';

    RETURN QUERY
    WITH monthly_scores AS (
      SELECT 
        al.user_id,
        COALESCE(SUM(al.points), 0)::bigint AS period_aura
      FROM public.aura_ledger al
      WHERE al.created_at >= v_month_start
        AND al.created_at < v_month_end
        AND al.action IN (
          -- 1. Q&A Solution & Arena Practice Mode
          'practice_question',
          'qa_solution',
          'answer_accepted',
          'solve_question',
          -- 2. Daily Mission (+20 solved, +5 attempt)
          'complete_daily_mission',
          'attempt_daily_mission',
          'complete_daily_challenge',
          'daily_challenge',
          'daily_mission_attempt',
          'mission_solved',
          'mission_attempted',
          'challenge_solved',
          'challenge_attempted',
          -- 3. Combat Section
          'arena_duel'
        )
      GROUP BY al.user_id
    )
    SELECT 
      u.id,
      u.name,
      u.handle,
      u.avatar,
      u.role::text,
      u.year,
      u.branch,
      u.building,
      u.stack::text,
      u.bio,
      u.college,
      u.github_handle,
      u.profile_completed,
      u.is_admin,
      COALESCE(ms.period_aura, 0)::bigint AS aura,
      u.created_at
    FROM public.users u
    LEFT JOIN monthly_scores ms ON u.id = ms.user_id
    WHERE (p_college IS NULL OR p_college = '' OR u.college = p_college)
    ORDER BY COALESCE(ms.period_aura, 0) DESC, u.aura DESC, u.created_at ASC
    LIMIT p_limit;
  ELSE
    -- All-Time board stores total points earned by the user across all time
    RETURN QUERY
    WITH all_time_scores AS (
      SELECT 
        al.user_id,
        COALESCE(SUM(al.points), 0)::bigint AS total_aura
      FROM public.aura_ledger al
      WHERE al.action IN (
        -- 1. Q&A Solution & Arena Practice Mode
        'practice_question',
        'qa_solution',
        'answer_accepted',
        'solve_question',
        -- 2. Daily Mission (+20 solved, +5 attempt)
        'complete_daily_mission',
        'attempt_daily_mission',
        'complete_daily_challenge',
        'daily_challenge',
        'daily_mission_attempt',
        'mission_solved',
        'mission_attempted',
        'challenge_solved',
        'challenge_attempted',
        -- 3. Combat Section
        'arena_duel'
      )
      GROUP BY al.user_id
    )
    SELECT 
      u.id,
      u.name,
      u.handle,
      u.avatar,
      u.role::text,
      u.year,
      u.branch,
      u.building,
      u.stack::text,
      u.bio,
      u.college,
      u.github_handle,
      u.profile_completed,
      u.is_admin,
      GREATEST(COALESCE(ats.total_aura, 0), COALESCE(u.aura, 0))::bigint AS aura,
      u.created_at
    FROM public.users u
    LEFT JOIN all_time_scores ats ON u.id = ats.user_id
    WHERE (p_college IS NULL OR p_college = '' OR u.college = p_college)
    ORDER BY GREATEST(COALESCE(ats.total_aura, 0), COALESCE(u.aura, 0)) DESC, u.created_at ASC
    LIMIT p_limit;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_aura_leaderboard(text, text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_aura_leaderboard(text, text, integer) TO service_role;
