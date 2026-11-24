-- ==============================================================================
-- DEVSPACE VERIFICATION CHECK 05: BADGES VERIFICATION
-- File: supabase/checks/05_badges_verify.sql
-- Run this in Supabase SQL Editor.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- TEST 1: IDEMPOTENCY (Run sync_my_badges twice in succession)
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_test_uid uuid;
  v_res1 jsonb;
  v_res2 jsonb;
  v_count_before integer;
  v_count_after integer;
  v_dup_count integer;
BEGIN
  SELECT id INTO v_test_uid FROM public.users LIMIT 1;
  IF v_test_uid IS NULL THEN
    RAISE NOTICE 'No users found in database to test';
    RETURN;
  END IF;

  RAISE NOTICE '--- Testing with user_id: % ---', v_test_uid;

  v_res1 := public.sync_my_badges(v_test_uid);
  SELECT count(*) INTO v_count_before FROM public.user_badges WHERE user_id = v_test_uid;

  -- Run second time immediately
  v_res2 := public.sync_my_badges(v_test_uid);
  SELECT count(*) INTO v_count_after FROM public.user_badges WHERE user_id = v_test_uid;

  IF v_count_before = v_count_after THEN
    RAISE NOTICE '[PASS] Idempotency: Count before (%) equals count after (%). No duplicate rows created.', v_count_before, v_count_after;
  ELSE
    RAISE WARNING '[FAIL] Idempotency: Count mismatch! Before: %, After: %', v_count_before, v_count_after;
  END IF;

  -- Check duplicate constraint
  SELECT count(*) INTO v_dup_count
  FROM (
    SELECT badge_key, count(*)
    FROM public.user_badges
    WHERE user_id = v_test_uid
    GROUP BY badge_key
    HAVING count(*) > 1
  ) dups;

  IF v_dup_count = 0 THEN
    RAISE NOTICE '[PASS] Unique constraint: 0 duplicate badge_keys for test user.';
  ELSE
    RAISE WARNING '[FAIL] Found % duplicate badge_keys!', v_dup_count;
  END IF;

  -- Verify second run returns 0 newly_awarded_keys
  IF jsonb_array_length(v_res2->'newly_awarded_keys') = 0 THEN
    RAISE NOTICE '[PASS] Second sync returned 0 newly awarded badges as expected.';
  ELSE
    RAISE WARNING '[FAIL] Second sync awarded badges on second run: %', v_res2->'newly_awarded_keys';
  END IF;
END $$;


-- ------------------------------------------------------------------------------
-- TEST 2: VERIFY DIRECT CLIENT INSERT IS REJECTED BY RLS
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_test_uid uuid;
  v_insert_failed boolean := false;
BEGIN
  SELECT id INTO v_test_uid FROM public.users LIMIT 1;
  IF v_test_uid IS NULL THEN
    RETURN;
  END IF;

  -- Switch to authenticated role context
  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claim.sub', v_test_uid::text, true);

  BEGIN
    INSERT INTO public.user_badges (user_id, badge_key, badge_name)
    VALUES (v_test_uid, 'hacked_badge', 'Hacked Badge');
  EXCEPTION WHEN insufficient_privilege OR others THEN
    v_insert_failed := true;
  END;

  RESET ROLE;

  IF v_insert_failed THEN
    RAISE NOTICE '[PASS] Direct client INSERT was successfully rejected by RLS.';
  ELSE
    RAISE WARNING '[FAIL] Direct client INSERT succeeded! RLS is not properly blocking client writes!';
  END IF;
END $$;


-- ------------------------------------------------------------------------------
-- TEST 3: VERIFY EARNED BADGES MATCH THE EXACT RULES FOR TEST USER
-- ------------------------------------------------------------------------------
WITH test_user AS (
  SELECT id AS user_id FROM public.users LIMIT 1
),
metrics AS (
  SELECT
    u.user_id,
    (SELECT count(*) FROM public.user_practice_completions WHERE user_id = u.user_id) AS total_practice,
    (SELECT count(*) FROM public.user_practice_completions WHERE user_id = u.user_id AND question_id LIKE 'noob_%') AS noob_count,
    (SELECT count(*) FROM public.user_practice_completions WHERE user_id = u.user_id AND question_id LIKE 'easy_%') AS easy_count,
    (SELECT count(*) FROM public.user_practice_completions WHERE user_id = u.user_id AND question_id LIKE 'med_%') AS med_count,
    (SELECT count(*) FROM public.user_practice_completions WHERE user_id = u.user_id AND question_id LIKE 'hard_%') AS hard_count,
    (SELECT greatest(coalesce(current_streak, 0), coalesce(longest_streak, 0)) FROM public.users WHERE id = u.user_id) AS streak,
    (SELECT count(*) FROM public.arena_matches WHERE status = 'finished' AND (
      (player1_id = u.user_id AND coalesce(player1_score, 0) > coalesce(player2_score, 0)) OR
      (player2_id = u.user_id AND coalesce(player2_score, 0) > coalesce(player1_score, 0))
    )) AS duel_wins,
    (SELECT count(*) FROM public.posts WHERE user_id = u.user_id) AS post_count,
    (SELECT count(*) FROM public.follows WHERE following_id = u.user_id) AS follower_count
  FROM test_user u
)
SELECT
  m.*,
  (SELECT array_agg(badge_key ORDER BY awarded_at) FROM public.user_badges WHERE user_id = m.user_id) AS actual_earned_badges
FROM metrics m;


-- ------------------------------------------------------------------------------
-- TEST 4: INSPECT SYNC FUNCTION OUTPUT (Progress & Next Badge)
-- ------------------------------------------------------------------------------
SELECT public.sync_my_badges(id) AS sync_payload
FROM public.users
LIMIT 1;
