-- =============================================================================
-- DEVSPACE AURA REDESIGN — PHASE B (FILE 1 OF 4): WRITE-PATH HARDENING
-- File: supabase/patches/aura-02-write-path.sql
--
-- What this script does:
--   1. Drops all existing overloads of:
--        - public.award_aura
--        - public.submit_practice_completion
--        - public.complete_practice_question
--        - public.complete_daily_challenge
--        - public.resolve_arena_match
--        - public.perform_monthly_aura_reset
--      and drops the unused materialized view public.mv_leaderboard_rankings.
--   2. Recreates the single internal public.award_aura(...) function and
--      revokes EXECUTE from public, anon, and authenticated (service_role and
--      postgres SECURITY DEFINER RPCs only).
--   3. Recreates public.submit_practice_completion(p_question_id text) with
--      server-side prefix -> points mapping:
--        noob_ = 5, easy_ = 10, med_ = 15, hard_ = 20
--      and strict once-per-user-per-question idempotency via
--      public.user_practice_completions.
--   4. Updates public.submit_daily_mission(...) and public.review_daily_mission(...)
--      so Daily Mission awards strictly +20 (correct) or +5 (wrong attempt)
--      once per user per mission, with zero streak bonus aura.
--   5. Recreates public.resolve_arena_match(p_match_id uuid) with a single
--      signature that reads stored match scores, computes correct answers
--      (score / 15), and awards +5 per correct answer ONLY to the winner
--      (or both players on a tie with correct_answers > 0), once per match.
--   6. Updates public.mark_question_reply_solved(uuid, uuid) so marking a Q&A
--      reply solved no longer awards any aura (Rule 4).
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. DROP ALL LEGACY / CONFLICTING OVERLOADS & UNUSED MATERIALIZED VIEW
-- -----------------------------------------------------------------------------
drop materialized view if exists public.mv_leaderboard_rankings;

do $$
declare
  fn_record record;
begin
  for fn_record in
    select
      n.nspname as schema_name,
      p.proname as function_name,
      pg_get_function_identity_arguments(p.oid) as identity_args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'award_aura',
        'submit_practice_completion',
        'complete_practice_question',
        'complete_daily_challenge',
        'resolve_arena_match',
        'perform_monthly_aura_reset'
      )
  loop
    execute format(
      'drop function if exists %I.%I(%s);',
      fn_record.schema_name,
      fn_record.function_name,
      fn_record.identity_args
    );
  end loop;
end;
$$;


-- -----------------------------------------------------------------------------
-- 2. SINGLE INTERNAL public.award_aura FUNCTION (NOT CALLABLE BY CLIENTS)
-- -----------------------------------------------------------------------------
create or replace function public.award_aura(
  p_user_id uuid,
  p_action text,
  p_points integer,
  p_reference_type text,
  p_reference_id text,
  p_source_user_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null or coalesce(p_points, 0) <= 0 then
    return false;
  end if;

  insert into public.aura_ledger(
    user_id,
    action,
    points,
    reference_type,
    reference_id,
    source_user_id,
    metadata
  )
  values (
    p_user_id,
    p_action,
    p_points,
    p_reference_type,
    p_reference_id,
    p_source_user_id,
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict do nothing;

  if found then
    update public.users
    set aura = coalesce(aura, 0) + p_points,
        aura_points = coalesce(aura_points, 0) + p_points
    where id = p_user_id;
    return true;
  end if;

  return false;
end;
$$;

revoke execute on function public.award_aura(uuid, text, integer, text, text, uuid, jsonb) from public, anon, authenticated;
grant execute on function public.award_aura(uuid, text, integer, text, text, uuid, jsonb) to service_role;


-- -----------------------------------------------------------------------------
-- 3. PRACTICE MODE RPC: public.submit_practice_completion(p_question_id text)
--    Rule 2:
--      noob_ -> +5 (Easy display label)
--      easy_ -> +10 (Medium display label)
--      med_  -> +15 (Hard display label)
--      hard_ -> +20 (Ultra display label)
--    Once per question per user. Server decides reward from prefix.
-- -----------------------------------------------------------------------------
create or replace function public.submit_practice_completion(
  p_question_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_clean_id text;
  v_reward integer;
  v_inserted_id uuid;
  v_awarded boolean := false;
  v_new_aura bigint := 0;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  v_clean_id := trim(coalesce(p_question_id, ''));
  if v_clean_id = '' then
    raise exception 'Practice question_id is required';
  end if;

  if v_clean_id like 'noob_%' then
    v_reward := 5;
  elsif v_clean_id like 'easy_%' then
    v_reward := 10;
  elsif v_clean_id like 'med_%' then
    v_reward := 15;
  elsif v_clean_id like 'hard_%' then
    v_reward := 20;
  else
    raise exception 'Invalid practice question_id prefix: %', v_clean_id;
  end if;

  insert into public.user_practice_completions (user_id, question_id)
  values (v_user_id, v_clean_id)
  on conflict (user_id, question_id) do nothing
  returning id into v_inserted_id;

  if v_inserted_id is not null then
    v_awarded := public.award_aura(
      v_user_id,
      'practice_question',
      v_reward,
      'practice_qa',
      v_clean_id,
      null,
      jsonb_build_object('question_id', v_clean_id, 'reward', v_reward)
    );
  end if;

  select coalesce(aura, 0)
  into v_new_aura
  from public.users
  where id = v_user_id;

  return jsonb_build_object(
    'already_completed', (v_inserted_id is null),
    'points_awarded', case when v_awarded then v_reward else 0 end,
    'aura', coalesce(v_new_aura, 0)
  );
end;
$$;

grant execute on function public.submit_practice_completion(text) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 4. DAILY MISSION RPC: public.submit_daily_mission(...)
--    Rule 1:
--      Correct +20, Attempt (wrong) +5. Once per user per mission.
--      Zero streak bonus aura.
-- -----------------------------------------------------------------------------
create or replace function public.submit_daily_mission(
  p_answer_submitted text default '',
  p_submission_link text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  today_local date;
  assignment_row public.user_missions%rowtype;
  mission_row public.missions%rowtype;
  previous_completion date;
  next_streak integer;
  next_longest integer;
  normalized_answer text;
  normalized_correct_answer text;
  is_answer_correct boolean := false;
  awarded_points integer := 0;
  v_new_aura bigint := 0;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  today_local := timezone('Asia/Kolkata'::text, now())::date;

  select *
  into assignment_row
  from public.user_missions
  where user_id = actor_id
    and assigned_date = today_local
  for update;

  -- Auto-assign today's mission if not yet assigned for this user today
  if assignment_row.id is null then
    begin
      perform public.assign_daily_mission(null);
    exception
      when others then
        null;
    end;

    select *
    into assignment_row
    from public.user_missions
    where user_id = actor_id
      and assigned_date = today_local
    for update;
  end if;

  if assignment_row.id is null then
    raise exception 'No daily mission assigned for today';
  end if;

  if assignment_row.completed then
    raise exception 'Mission already completed for today';
  end if;

  select *
  into mission_row
  from public.missions
  where id = assignment_row.mission_id;

  if mission_row.id is null then
    raise exception 'Mission not found';
  end if;

  normalized_answer := lower(trim(coalesce(p_answer_submitted, '')));
  normalized_correct_answer := lower(trim(coalesce(mission_row.correct_answer, '')));

  if mission_row.type <> 'mcq' then
    raise exception 'Only MCQ daily missions are supported';
  end if;

  if normalized_answer = '' then
    raise exception 'An answer is required for the daily mission';
  end if;

  is_answer_correct := (normalized_answer = normalized_correct_answer);
  awarded_points := case
    when is_answer_correct then 20
    else 5
  end;

  update public.user_missions
  set answer_submitted = nullif(trim(coalesce(p_answer_submitted, '')), ''),
      submission_link = null,
      is_correct = is_answer_correct,
      completed = true,
      completed_at = timezone('utc'::text, now()),
      updated_at = timezone('utc'::text, now())
  where id = assignment_row.id;

  if is_answer_correct then
    perform public.award_aura(
      actor_id,
      'complete_daily_mission',
      20,
      'daily_mission',
      assignment_row.id::text
    );

    select last_challenge_completed_on
    into previous_completion
    from public.users
    where id = actor_id;

    if previous_completion = today_local - 1 then
      select coalesce(current_streak, 0) + 1,
             greatest(coalesce(longest_streak, 0), coalesce(current_streak, 0) + 1)
      into next_streak, next_longest
      from public.users
      where id = actor_id;
    else
      next_streak := 1;
      select greatest(coalesce(longest_streak, 0), 1)
      into next_longest
      from public.users
      where id = actor_id;
    end if;

    update public.users
    set current_streak = next_streak,
        longest_streak = next_longest,
        last_challenge_completed_on = today_local
    where id = actor_id;
  else
    perform public.award_aura(
      actor_id,
      'attempt_daily_mission',
      5,
      'daily_mission_attempt',
      assignment_row.id::text
    );
  end if;

  select coalesce(aura, 0)
  into v_new_aura
  from public.users
  where id = actor_id;

  return jsonb_build_object(
    'assignmentId', assignment_row.id,
    'missionId', mission_row.id,
    'type', mission_row.type,
    'completed', true,
    'isCorrect', is_answer_correct,
    'is_correct', is_answer_correct,
    'pointsAwarded', awarded_points,
    'points_awarded', awarded_points,
    'aura', coalesce(v_new_aura, 0)
  );
end;
$$;

grant execute on function public.submit_daily_mission(text, text) to authenticated, service_role;


create or replace function public.review_daily_mission(
  p_assignment_id uuid,
  p_is_correct boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  actor_is_admin boolean := false;
  assignment_row public.user_missions%rowtype;
  mission_row public.missions%rowtype;
  awarded_points integer := 0;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select is_admin
  into actor_is_admin
  from public.users
  where id = actor_id;

  if coalesce(actor_is_admin, false) = false then
    raise exception 'Only admins can review mission submissions';
  end if;

  select *
  into assignment_row
  from public.user_missions
  where id = p_assignment_id
  for update;

  if assignment_row.id is null then
    raise exception 'Mission assignment not found';
  end if;

  select *
  into mission_row
  from public.missions
  where id = assignment_row.mission_id;

  if mission_row.id is null then
    raise exception 'Mission not found';
  end if;

  if mission_row.type <> 'coding' then
    raise exception 'Only coding missions can be reviewed manually';
  end if;

  if assignment_row.completed then
    raise exception 'Mission already completed';
  end if;

  update public.user_missions
  set is_correct = p_is_correct,
      completed = p_is_correct,
      completed_at = case
        when p_is_correct then timezone('utc'::text, now())
        else null
      end,
      reviewed_by = actor_id,
      reviewed_at = timezone('utc'::text, now()),
      updated_at = timezone('utc'::text, now())
  where id = p_assignment_id;

  if p_is_correct then
    awarded_points := 20;

    perform public.award_aura(
      assignment_row.user_id,
      'complete_daily_mission',
      awarded_points,
      'daily_mission',
      assignment_row.id::text
    );
  end if;

  return jsonb_build_object(
    'assignmentId', assignment_row.id,
    'missionId', mission_row.id,
    'completed', p_is_correct,
    'isCorrect', p_is_correct,
    'pointsAwarded', awarded_points,
    'reviewedBy', actor_id
  );
end;
$$;

grant execute on function public.review_daily_mission(uuid, boolean) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 5. COMBAT / DUEL RPC: public.resolve_arena_match(p_match_id uuid)
--    Rule 3:
--      REFLEX MODE and CODE COMBAT both store 15 points per correct answer.
--      +5 aura per correct answer ((stored_score / 15) * 5), awarded ONLY
--      to the winner (higher score). Loser gets 0.
--      On a tie, both players qualify if correct_answers > 0.
--      Never negative. Once per match per player.
-- -----------------------------------------------------------------------------
create or replace function public.resolve_arena_match(
  p_match_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid;
  v_match public.arena_matches%rowtype;
  v_is_player1 boolean;
  v_my_score integer := 0;
  v_opp_score integer := 0;
  v_opp_id uuid;
  v_correct_answers integer := 0;
  v_qualifies boolean := false;
  v_points integer := 0;
  v_awarded boolean := false;
  v_new_aura bigint := 0;
begin
  v_actor_id := auth.uid();
  if v_actor_id is null then
    raise exception 'Authentication required';
  end if;

  if p_match_id is null then
    raise exception 'Match ID is required';
  end if;

  select *
  into v_match
  from public.arena_matches
  where id = p_match_id
  for update;

  if v_match.id is null then
    raise exception 'Arena match not found';
  end if;

  if v_actor_id <> v_match.player1_id and (v_match.player2_id is null or v_actor_id <> v_match.player2_id) then
    raise exception 'Caller is not a participant in this arena match';
  end if;

  v_is_player1 := (v_actor_id = v_match.player1_id);
  if v_is_player1 then
    v_my_score := greatest(coalesce(v_match.player1_score, 0), 0);
    v_opp_score := greatest(coalesce(v_match.player2_score, 0), 0);
    v_opp_id := v_match.player2_id;
  else
    v_my_score := greatest(coalesce(v_match.player2_score, 0), 0);
    v_opp_score := greatest(coalesce(v_match.player1_score, 0), 0);
    v_opp_id := v_match.player1_id;
  end if;

  if coalesce(v_match.status, '') <> 'finished' then
    update public.arena_matches
    set status = 'finished'
    where id = p_match_id;
  end if;

  -- Each correct answer in both REFLEX MODE and CODE COMBAT adds +15 to score.
  -- Cap at 30 correct answers (150 aura max) as a server-side sanity bound.
  v_correct_answers := least(greatest(v_my_score / 15, 0), 30);

  -- Winner (my_score > opp_score) or Tie (my_score = opp_score) qualifies if correct_answers > 0
  v_qualifies := (v_my_score >= v_opp_score) and (v_correct_answers > 0);
  v_points := case
    when v_qualifies then (v_correct_answers * 5)
    else 0
  end;

  if v_points > 0 then
    v_awarded := public.award_aura(
      v_actor_id,
      'arena_duel',
      v_points,
      'arena_match',
      p_match_id::text,
      null,
      jsonb_build_object(
        'mode', v_match.mode,
        'my_score', v_my_score,
        'opp_score', v_opp_score,
        'correct_answers', v_correct_answers,
        'opponent_id', v_opp_id
      )
    );
  end if;

  select coalesce(aura, 0)
  into v_new_aura
  from public.users
  where id = v_actor_id;

  return jsonb_build_object(
    'success', true,
    'won', v_qualifies,
    'is_tie', (v_my_score = v_opp_score),
    'correct_answers', v_correct_answers,
    'points_awarded', case when v_awarded then v_points else 0 end,
    'already_resolved', (v_points > 0 and not v_awarded),
    'aura', coalesce(v_new_aura, 0)
  );
end;
$$;

grant execute on function public.resolve_arena_match(uuid) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 6. Q&A SOLVED REPLY RPC: public.mark_question_reply_solved(uuid, uuid)
--    Rule 4: NOTHING outside Arena awards aura. Marking a reply solved updates
--    questions.solved_reply_id only and awards 0 aura.
-- -----------------------------------------------------------------------------
create or replace function public.mark_question_reply_solved(
  p_question_id uuid,
  p_reply_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  question_owner_id uuid;
  existing_solved_reply_id uuid;
  reply_owner_id uuid;
begin
  select user_id, solved_reply_id
  into question_owner_id, existing_solved_reply_id
  from public.questions
  where id = p_question_id;

  if question_owner_id is null then
    raise exception 'Question not found';
  end if;

  if auth.uid() <> question_owner_id then
    raise exception 'Only the question owner can mark a reply as solved';
  end if;

  select user_id
  into reply_owner_id
  from public.question_replies
  where id = p_reply_id
    and question_id = p_question_id;

  if reply_owner_id is null then
    raise exception 'Reply does not belong to this question';
  end if;

  if existing_solved_reply_id is not null then
    if existing_solved_reply_id = p_reply_id then
      return existing_solved_reply_id;
    end if;

    raise exception 'This question is already solved';
  end if;

  update public.questions
  set solved_reply_id = p_reply_id
  where id = p_question_id;

  return p_reply_id;
end;
$$;

grant execute on function public.mark_question_reply_solved(uuid, uuid) to authenticated, service_role;

commit;
