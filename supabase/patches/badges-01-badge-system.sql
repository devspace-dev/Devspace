-- ============================================================================
-- Patch: badges-01-badge-system.sql
-- Purpose: Complete server-computed badge system (11 badges, zero aura)
-- Area: Area 4 (Badges)
-- Notes:
--   - Idempotent: can be executed repeatedly with ON CONFLICT DO NOTHING
--   - Server-computed SECURITY DEFINER function: sync_my_badges(p_user_id)
--   - ZERO Aura: does not award or modify any aura points
--   - Read-only RLS policy: all authenticated and anon users can view earned badges
--   - Direct user insert/update/delete is rejected by RLS
-- ============================================================================

-- 1. Ensure user_badges table exists with correct schema
create table if not exists public.user_badges (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  badge_key text not null,
  badge_name text not null,
  awarded_at timestamp with time zone default timezone('utc'::text, now()),
  unique (user_id, badge_key)
);

create index if not exists idx_user_badges_user_id
  on public.user_badges(user_id);

-- 2. Configure RLS: Read-only for everyone; direct user mutations disallowed
alter table public.user_badges enable row level security;

drop policy if exists user_badges_select_owner on public.user_badges;
drop policy if exists user_badges_select_all on public.user_badges;

create policy user_badges_select_all
  on public.user_badges
  for select
  to authenticated, anon
  using (true);

-- 3. Idempotent Badge Sync Function
create or replace function public.sync_my_badges(
  p_user_id uuid default null
)
returns setof public.user_badges
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_practice_count integer := 0;
  v_easy_count integer := 0;
  v_med_count integer := 0;
  v_hard_count integer := 0;
  v_ultra_count integer := 0;
  v_streak integer := 0;
  v_duel_wins integer := 0;
  v_accepted_replies integer := 0;
  v_is_top_10 boolean := false;
begin
  v_user_id := coalesce(p_user_id, auth.uid());
  if v_user_id is null then
    raise exception 'User ID or authenticated session required';
  end if;

  -- 1. Practice counts
  select count(*) into v_practice_count
  from public.user_practice_completions
  where user_id = v_user_id;

  select count(*) into v_easy_count
  from public.user_practice_completions
  where user_id = v_user_id and question_id like 'noob_%';

  select count(*) into v_med_count
  from public.user_practice_completions
  where user_id = v_user_id and question_id like 'easy_%';

  select count(*) into v_hard_count
  from public.user_practice_completions
  where user_id = v_user_id and question_id like 'med_%';

  select count(*) into v_ultra_count
  from public.user_practice_completions
  where user_id = v_user_id and question_id like 'hard_%';

  -- 2. Streak
  select greatest(coalesce(current_streak, 0), coalesce(longest_streak, 0)) into v_streak
  from public.users
  where id = v_user_id;

  -- 3. Arena duel wins
  select count(*) into v_duel_wins
  from public.arena_matches
  where winner_id = v_user_id and status = 'completed';

  -- 4. Accepted Q&A replies
  select count(*) into v_accepted_replies
  from public.questions q
  where q.solved_reply_id is not null
    and q.solved_reply_id in (
      select r.id from public.question_replies r where r.user_id = v_user_id
    );

  -- 5. Monthly Top 10 leaderboard
  select exists (
    select 1
    from public.get_aura_leaderboard(null, 10, 'monthly') lb
    where lb.id = v_user_id
  ) into v_is_top_10;

  -- ========================================================================
  -- AWARDS (0 AURA, ON CONFLICT DO NOTHING)
  -- ========================================================================

  -- Badge 1: First Practice Solve
  if v_practice_count >= 1 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'first_practice_solve', 'First Practice Solve')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 2: Easy Cleared (all 10 questions)
  if v_easy_count >= 10 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'practice_easy_cleared', 'Easy Cleared')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 3: Medium Cleared (all 10 questions)
  if v_med_count >= 10 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'practice_medium_cleared', 'Medium Cleared')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 4: Hard Cleared (all 10 questions)
  if v_hard_count >= 10 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'practice_hard_cleared', 'Hard Cleared')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 5: Ultra Cleared (all 10 questions)
  if v_ultra_count >= 10 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'practice_ultra_cleared', 'Ultra Cleared')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 6: 3-Day Streak
  if coalesce(v_streak, 0) >= 3 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'streak_3_days', '3-Day Streak')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 7: 7-Day Streak
  if coalesce(v_streak, 0) >= 7 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'streak_7_days', '7-Day Streak')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 8: First Combat Win
  if v_duel_wins >= 1 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'first_duel_win', 'First Combat Win')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 9: Combat Veteran (10 wins)
  if v_duel_wins >= 10 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'duel_winner_x10', 'Combat Veteran')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 10: Solution Master
  if v_accepted_replies >= 1 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'accepted_answer', 'Solution Master')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Badge 11: Aura Elite (Top 10 Monthly)
  if v_is_top_10 then
    insert into public.user_badges (user_id, badge_key, badge_name)
    values (v_user_id, 'top_10_aura', 'Aura Elite')
    on conflict (user_id, badge_key) do nothing;
  end if;

  -- Return all earned badges for the user
  return query
  select *
  from public.user_badges
  where user_id = v_user_id
  order by awarded_at asc;
end;
$$;

revoke all on function public.sync_my_badges(uuid) from public, anon;
grant execute on function public.sync_my_badges(uuid) to authenticated, service_role;
