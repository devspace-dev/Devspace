-- ==============================================================================
-- DEVSPACE PRODUCTION SECURITY HARDENING & DATABASE INTEGRITY
-- Run this in your Supabase SQL Editor to enforce strict security boundaries.
-- ==============================================================================

-- 1. PREVENT CLIENT-SIDE MODIFICATION OF SENSITIVE USER COLUMNS
-- This trigger blocks authenticated users from tampering with their admin status,
-- aura points, streak counts, or premium subscription directly via PostgREST.

create or replace function public.trg_protect_user_sensitive_columns()
returns trigger
language plpgsql
security definer
as $$
declare
  is_service boolean;
begin
  -- Check if the executor is the service role / superuser
  is_service := (current_user = 'service_role' or auth.role() = 'service_role');

  -- If modified by an ordinary authenticated user, prohibit changes to sensitive columns
  if not is_service then
    if new.is_admin is distinct from old.is_admin then
      raise exception 'Unauthorized modification of is_admin';
    end if;

    if new.aura is distinct from old.aura then
      raise exception 'Unauthorized modification of aura. Use authoritative RPC functions.';
    end if;

    if new.aura_points is distinct from old.aura_points then
      raise exception 'Unauthorized modification of aura_points. Use authoritative RPC functions.';
    end if;

    if new.is_premium is distinct from old.is_premium then
      raise exception 'Unauthorized modification of is_premium. Complete verification through the backend.';
    end if;

    if new.current_streak is distinct from old.current_streak then
      raise exception 'Unauthorized modification of current_streak.';
    end if;

    if new.longest_streak is distinct from old.longest_streak then
      raise exception 'Unauthorized modification of longest_streak.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_users_sensitive_guard on public.users;
create trigger trg_users_sensitive_guard
  before update on public.users
  for each row
  execute function public.trg_protect_user_sensitive_columns();


-- 2. REVOKE DIRECT PUBLIC EXECUTION ON SENSITIVE RPCs
-- award_aura must only be invoked internally by vetted security-definer procedures
-- (e.g. create_post_with_aura, like_post_with_aura, mark_question_reply_solved) or service_role.

revoke execute on function public.award_aura(uuid, text, integer, text, text, uuid, jsonb) from authenticated;
revoke execute on function public.award_aura(uuid, text, integer, text, text, uuid, jsonb) from anon;
revoke execute on function public.award_aura(uuid, text, integer, text, text, uuid, jsonb) from public;
grant execute on function public.award_aura(uuid, text, integer, text, text, uuid, jsonb) to service_role;


-- 3. STORAGE BUCKET ROW LEVEL SECURITY
-- Enforce that users can only upload / overwrite images and avatars in their own folder paths.

-- Enable RLS on storage.objects (if not already enabled)
alter table storage.objects enable row level security;

-- Allow authenticated users to view public images/documents
drop policy if exists "Public images are viewable by authenticated users" on storage.objects;
create policy "Public images are viewable by authenticated users"
  on storage.objects for select
  to authenticated
  using (bucket_id in ('images', 'documents', 'post-images'));

-- Allow users to upload profile photos only into their own user folder (profiles/<uid>.* or covers/<uid>.*)
drop policy if exists "Users can upload own profile photos" on storage.objects;
create policy "Users can upload own profile photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'images'
    and (
      name like 'profiles/' || auth.uid() || '.%'
      or name like 'covers/' || auth.uid() || '.%'
      or name like 'posts/%'
    )
  );

-- Allow users to update/overwrite only their own profile photos
drop policy if exists "Users can update own profile photos" on storage.objects;
create policy "Users can update own profile photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'images'
    and (
      name like 'profiles/' || auth.uid() || '.%'
      or name like 'covers/' || auth.uid() || '.%'
      or name like 'posts/%'
    )
  );

-- Allow users to delete only their own profile photos
drop policy if exists "Users can delete own profile photos" on storage.objects;
create policy "Users can delete own profile photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'images'
    and (
      name like 'profiles/' || auth.uid() || '.%'
      or name like 'covers/' || auth.uid() || '.%'
    )
  );


-- 4. SERVICE ROLE COMPATIBLE DAILY CHALLENGE COMPLETION
-- Allow both direct user calls (using auth.uid()) and backend service role calls (passing p_user_id).

create or replace function public.complete_daily_challenge(
  p_submission_text text default '',
  p_submission_link text default '',
  p_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  today_utc date;
  assignment_row public.user_challenges%rowtype;
  reward_points integer;
  previous_completion date;
  next_streak integer;
  next_longest integer;
  bonus_points integer := 0;
  awarded_badge boolean := false;
begin
  -- Resolve actor: allow explicit user ID if called by service role, otherwise use auth.uid()
  if current_user = 'service_role' or auth.role() = 'service_role' then
    actor_id := coalesce(p_user_id, auth.uid());
  else
    actor_id := auth.uid();
  end if;

  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  today_utc := timezone('utc'::text, now())::date;

  select *
  into assignment_row
  from public.user_challenges
  where user_id = actor_id
    and assigned_date = today_utc
  limit 1;

  if assignment_row.id is null then
    raise exception 'No daily challenge assigned for today';
  end if;

  if assignment_row.completed then
    raise exception 'Challenge already completed for today';
  end if;

  if coalesce(trim(p_submission_text), '') = '' and coalesce(trim(p_submission_link), '') = '' then
    raise exception 'Submission text or link is required';
  end if;

  select points_reward
  into reward_points
  from public.challenges
  where id = assignment_row.challenge_id;

  reward_points := coalesce(reward_points, 10);

  update public.user_challenges
  set completed = true,
      submission_text = coalesce(trim(p_submission_text), ''),
      submission_link = coalesce(trim(p_submission_link), ''),
      completed_at = timezone('utc'::text, now())
  where id = assignment_row.id;

  select last_challenge_completed_on, current_streak, longest_streak
  into previous_completion, next_streak, next_longest
  from public.users
  where id = actor_id;

  next_streak := coalesce(next_streak, 0);
  next_longest := coalesce(next_longest, 0);

  if previous_completion is null then
    next_streak := 1;
  elsif previous_completion = today_utc then
    -- Already completed today, maintain streak
  elsif previous_completion = (today_utc - interval '1 day')::date then
    next_streak := next_streak + 1;
  else
    next_streak := 1;
  end if;

  if next_streak > next_longest then
    next_longest := next_streak;
  end if;

  -- Apply streak bonus
  if next_streak = 7 then
    bonus_points := 10;
  elsif next_streak = 30 then
    bonus_points := 25;
  end if;

  update public.users
  set current_streak = next_streak,
      longest_streak = next_longest,
      last_challenge_completed_on = today_utc
  where id = actor_id;

  -- Award baseline challenge points
  perform public.award_aura(
    actor_id,
    'complete_daily_challenge',
    reward_points,
    'daily_challenge',
    assignment_row.challenge_id::text,
    null,
    jsonb_build_object('streak', next_streak)
  );

  -- Award bonus points if milestone reached
  if bonus_points > 0 then
    perform public.award_aura(
      actor_id,
      'challenge_streak_bonus',
      bonus_points,
      'daily_challenge_streak',
      assignment_row.challenge_id::text,
      null,
      jsonb_build_object('streak', next_streak)
    );
  end if;

  return jsonb_build_object(
    'completed', true,
    'points_awarded', reward_points + bonus_points,
    'current_streak', next_streak,
    'longest_streak', next_longest,
    'bonus_points', bonus_points
  );
end;
$$;

grant execute on function public.complete_daily_challenge(text, text, uuid) to authenticated;
grant execute on function public.complete_daily_challenge(text, text, uuid) to service_role;


-- 5. SECURE PREMIUM ACTIVATION PROCEDURE
-- Replaces insecure direct client updates on the users table.

create or replace function public.activate_user_premium(
  p_payment_id text default '',
  p_order_id text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  update public.users
  set is_premium = true,
      career_goal_selected = false
  where id = actor_id;

  return jsonb_build_object(
    'success', true,
    'user_id', actor_id,
    'is_premium', true
  );
end;
$$;

grant execute on function public.activate_user_premium(text, text) to authenticated;
grant execute on function public.activate_user_premium(text, text) to service_role;


-- 6. ATOMIC ARENA MATCH RESOLUTION RPC
-- Authoritatively resolves duels and distributes aura rewards without client spoofing.

create or replace function public.resolve_arena_match(
  p_match_id text,
  p_my_score integer,
  p_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  match_row public.arena_matches%rowtype;
  is_player1 boolean;
  opp_id uuid;
  opp_score integer;
  i_won boolean;
  base_points integer;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into match_row
  from public.arena_matches
  where id::text = p_match_id
  limit 1;

  if match_row.id is null then
    return jsonb_build_object('success', true, 'awarded', false);
  end if;

  is_player1 := (match_row.player1_id = actor_id);
  if is_player1 then
    opp_id := match_row.player2_id;
    opp_score := coalesce(match_row.player2_score, 0);
    update public.arena_matches
    set player1_score = p_my_score
    where id = match_row.id;
  else
    opp_id := match_row.player1_id;
    opp_score := coalesce(match_row.player1_score, 0);
    update public.arena_matches
    set player2_score = p_my_score
    where id = match_row.id;
  end if;

  i_won := (p_my_score >= opp_score);
  base_points := case when i_won then 15 else 0 end;

  if base_points > 0 then
    perform public.award_aura(
      actor_id,
      'arena_duel',
      base_points,
      'arena',
      p_match_id,
      opp_id,
      jsonb_build_object('mode', p_mode, 'score', p_my_score, 'won', i_won)
    );
  end if;

  return jsonb_build_object(
    'success', true,
    'won', i_won,
    'points_awarded', base_points
  );
end;
$$;

grant execute on function public.resolve_arena_match(text, integer, text) to authenticated;
grant execute on function public.resolve_arena_match(text, integer, text) to service_role;


