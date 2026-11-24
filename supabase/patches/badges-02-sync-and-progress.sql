-- ============================================================================
-- Patch: badges-02-sync-and-progress.sql
-- Purpose: Complete server-computed badge system (11 badges, zero aura, progress calculation)
-- Stage: Stage 1 (Badge Backend)
-- Notes:
--   - Idempotent: safe to run multiple times with ON CONFLICT DO NOTHING
--   - Server-computed SECURITY DEFINER function: sync_my_badges(p_user_id)
--   - ZERO Aura: does not award or modify any aura points
--   - Read-only RLS: clients can view earned badges; direct client insert/update/delete is blocked
--   - Calculates accurate progress towards all 11 badges and computes the "next badge"
-- ============================================================================

-- 1. Ensure user_badges table exists with correct schema
CREATE TABLE IF NOT EXISTS public.user_badges (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  badge_key text NOT NULL,
  badge_name text NOT NULL,
  awarded_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  UNIQUE (user_id, badge_key)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user_id
  ON public.user_badges(user_id);

CREATE INDEX IF NOT EXISTS idx_user_badges_key
  ON public.user_badges(badge_key);

-- 2. Configure RLS: Read-only for authenticated & anon; direct mutations disallowed
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_badges_select_all ON public.user_badges;
DROP POLICY IF EXISTS user_badges_select_owner ON public.user_badges;

CREATE POLICY user_badges_select_all
  ON public.user_badges
  FOR SELECT
  TO authenticated, anon
  USING (true);

-- Ensure no direct client insert/update/delete policies exist
DROP POLICY IF EXISTS user_badges_insert_owner ON public.user_badges;
DROP POLICY IF EXISTS user_badges_update_owner ON public.user_badges;
DROP POLICY IF EXISTS user_badges_delete_owner ON public.user_badges;


-- 3. Server-computed Badge Synchronization & Progress Function
CREATE OR REPLACE FUNCTION public.sync_my_badges(
  p_user_id uuid DEFAULT null
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_practice_count integer := 0;
  v_easy_count integer := 0;
  v_med_count integer := 0;
  v_hard_count integer := 0;
  v_ultra_count integer := 0;
  v_streak integer := 0;
  v_duel_wins integer := 0;
  v_post_count integer := 0;
  v_follower_count integer := 0;

  v_newly_awarded text[] := '{}'::text[];
  v_earned_keys text[] := '{}'::text[];
  v_progress jsonb;
  v_next_badge jsonb := null;
  v_highest_percent numeric := -1;
  v_new_key text;
BEGIN
  -- Authenticate caller
  v_user_id := coalesce(p_user_id, auth.uid());
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User ID or authenticated session required';
  END IF;

  -- Security check: authenticated users can only sync their own badges
  IF auth.role() = 'authenticated' AND p_user_id IS NOT NULL AND p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Forbidden: cannot sync badges for another user';
  END IF;

  -- --------------------------------------------------------------------------
  -- 1. Gather Metric Data from Source Tables
  -- --------------------------------------------------------------------------

  -- Practice question completions (total and per-tier, 20 questions each)
  SELECT
    count(*),
    count(*) FILTER (WHERE question_id LIKE 'noob_%'),
    count(*) FILTER (WHERE question_id LIKE 'easy_%'),
    count(*) FILTER (WHERE question_id LIKE 'med_%'),
    count(*) FILTER (WHERE question_id LIKE 'hard_%')
  INTO
    v_practice_count,
    v_easy_count,
    v_med_count,
    v_hard_count,
    v_ultra_count
  FROM public.user_practice_completions
  WHERE user_id = v_user_id;

  -- Daily mission streak from users table
  SELECT greatest(coalesce(current_streak, 0), coalesce(longest_streak, 0))
  INTO v_streak
  FROM public.users
  WHERE id = v_user_id;
  v_streak := coalesce(v_streak, 0);

  -- Arena duel wins (status = 'finished' and caller strictly beat opponent score; ties do not count)
  SELECT count(*)
  INTO v_duel_wins
  FROM public.arena_matches
  WHERE status = 'finished'
    AND (
      (player1_id = v_user_id AND coalesce(player1_score, 0) > coalesce(player2_score, 0)) OR
      (player2_id = v_user_id AND coalesce(player2_score, 0) > coalesce(player1_score, 0))
    );

  -- Community posts count
  SELECT count(*)
  INTO v_post_count
  FROM public.posts
  WHERE user_id = v_user_id;

  -- Followers count (people who follow this user)
  SELECT count(*)
  INTO v_follower_count
  FROM public.follows
  WHERE following_id = v_user_id;

  -- --------------------------------------------------------------------------
  -- 2. Evaluate & Award Eligible Badges (0 Aura, Idempotent)
  -- --------------------------------------------------------------------------

  -- Badge 1: First Solve (target: 1 solve)
  IF v_practice_count >= 1 THEN
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'first_practice_solve', 'First Solve')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 2: Easy Cleared (target: 20 noob_ questions)
  IF v_easy_count >= 20 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'practice_easy_cleared', 'Easy Cleared')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 3: Medium Cleared (target: 20 easy_ questions)
  IF v_med_count >= 20 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'practice_medium_cleared', 'Medium Cleared')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 4: Hard Cleared (target: 20 med_ questions)
  IF v_hard_count >= 20 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'practice_hard_cleared', 'Hard Cleared')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 5: Ultra Cleared (target: 20 hard_ questions)
  IF v_ultra_count >= 20 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'practice_ultra_cleared', 'Ultra Cleared')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 6: 3-Day Streak (target: 3 days)
  IF v_streak >= 3 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'streak_3_days', '3-Day Streak')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 7: 7-Day Streak (target: 7 days)
  IF v_streak >= 7 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'streak_7_days', '7-Day Streak')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 8: First Win (target: 1 duel win)
  IF v_duel_wins >= 1 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'first_duel_win', 'First Win')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 9: Duelist (target: 10 duel wins)
  IF v_duel_wins >= 10 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'duel_winner_x10', 'Duelist')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 10: First Post (target: 1 post)
  IF v_post_count >= 1 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'first_post', 'First Post')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- Badge 11: Connector (target: 10 followers)
  IF v_follower_count >= 10 THEN
    v_new_key := NULL;
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_user_id, 'connector_x10', 'Connector')
    ON CONFLICT (user_id, badge_key) DO NOTHING
    RETURNING badge_key INTO v_new_key;
    IF v_new_key IS NOT NULL THEN v_newly_awarded := array_append(v_newly_awarded, v_new_key); END IF;
  END IF;

  -- --------------------------------------------------------------------------
  -- 3. Gather Complete Earned Badges
  -- --------------------------------------------------------------------------
  SELECT coalesce(array_agg(badge_key ORDER BY awarded_at ASC), '{}'::text[])
  INTO v_earned_keys
  FROM public.user_badges
  WHERE user_id = v_user_id;

  -- --------------------------------------------------------------------------
  -- 4. Build Progress Map & Determine "Next Badge"
  -- --------------------------------------------------------------------------
  v_progress := jsonb_build_object(
    'first_practice_solve', jsonb_build_object(
      'name', 'First Solve',
      'current', least(v_practice_count, 1),
      'target', 1,
      'completed', ('first_practice_solve' = ANY(v_earned_keys)),
      'percent', round(least(v_practice_count::numeric / 1.0, 1.0), 3)
    ),
    'practice_easy_cleared', jsonb_build_object(
      'name', 'Easy Cleared',
      'current', least(v_easy_count, 20),
      'target', 20,
      'completed', ('practice_easy_cleared' = ANY(v_earned_keys)),
      'percent', round(least(v_easy_count::numeric / 20.0, 1.0), 3)
    ),
    'practice_medium_cleared', jsonb_build_object(
      'name', 'Medium Cleared',
      'current', least(v_med_count, 20),
      'target', 20,
      'completed', ('practice_medium_cleared' = ANY(v_earned_keys)),
      'percent', round(least(v_med_count::numeric / 20.0, 1.0), 3)
    ),
    'practice_hard_cleared', jsonb_build_object(
      'name', 'Hard Cleared',
      'current', least(v_hard_count, 20),
      'target', 20,
      'completed', ('practice_hard_cleared' = ANY(v_earned_keys)),
      'percent', round(least(v_hard_count::numeric / 20.0, 1.0), 3)
    ),
    'practice_ultra_cleared', jsonb_build_object(
      'name', 'Ultra Cleared',
      'current', least(v_ultra_count, 20),
      'target', 20,
      'completed', ('practice_ultra_cleared' = ANY(v_earned_keys)),
      'percent', round(least(v_ultra_count::numeric / 20.0, 1.0), 3)
    ),
    'streak_3_days', jsonb_build_object(
      'name', '3-Day Streak',
      'current', least(v_streak, 3),
      'target', 3,
      'completed', ('streak_3_days' = ANY(v_earned_keys)),
      'percent', round(least(v_streak::numeric / 3.0, 1.0), 3)
    ),
    'streak_7_days', jsonb_build_object(
      'name', '7-Day Streak',
      'current', least(v_streak, 7),
      'target', 7,
      'completed', ('streak_7_days' = ANY(v_earned_keys)),
      'percent', round(least(v_streak::numeric / 7.0, 1.0), 3)
    ),
    'first_duel_win', jsonb_build_object(
      'name', 'First Win',
      'current', least(v_duel_wins, 1),
      'target', 1,
      'completed', ('first_duel_win' = ANY(v_earned_keys)),
      'percent', round(least(v_duel_wins::numeric / 1.0, 1.0), 3)
    ),
    'duel_winner_x10', jsonb_build_object(
      'name', 'Duelist',
      'current', least(v_duel_wins, 10),
      'target', 10,
      'completed', ('duel_winner_x10' = ANY(v_earned_keys)),
      'percent', round(least(v_duel_wins::numeric / 10.0, 1.0), 3)
    ),
    'first_post', jsonb_build_object(
      'name', 'First Post',
      'current', least(v_post_count, 1),
      'target', 1,
      'completed', ('first_post' = ANY(v_earned_keys)),
      'percent', round(least(v_post_count::numeric / 1.0, 1.0), 3)
    ),
    'connector_x10', jsonb_build_object(
      'name', 'Connector',
      'current', least(v_follower_count, 10),
      'target', 10,
      'completed', ('connector_x10' = ANY(v_earned_keys)),
      'percent', round(least(v_follower_count::numeric / 10.0, 1.0), 3)
    )
  );

  -- Select next badge: unearned badge with highest percent (if tied, smallest target)
  SELECT jsonb_build_object(
    'badge_key', item.key,
    'badge_name', item.value->>'name',
    'current', (item.value->>'current')::int,
    'target', (item.value->>'target')::int,
    'percent', (item.value->>'percent')::numeric
  )
  INTO v_next_badge
  FROM jsonb_each(v_progress) item
  WHERE (item.value->>'completed')::boolean = false
  ORDER BY (item.value->>'percent')::numeric DESC, (item.value->>'target')::int ASC
  LIMIT 1;

  -- --------------------------------------------------------------------------
  -- 5. Return Consolidated Payload
  -- --------------------------------------------------------------------------
  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'earned_badge_keys', to_jsonb(v_earned_keys),
    'newly_awarded_keys', to_jsonb(v_newly_awarded),
    'progress', v_progress,
    'next_badge', v_next_badge
  );
END;
$$;

-- 4. Permissions
REVOKE ALL ON FUNCTION public.sync_my_badges(uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.sync_my_badges(uuid) TO authenticated, service_role;
