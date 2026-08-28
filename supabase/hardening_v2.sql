-- DEVSPACE SUPABASE HARDENING & STABILITY V2 MIGRATION

-- ══════════════════════════════════════════════════════════════════════════
-- 1. PRACTICE MODE AURA INTEGRITY & IDEMPOTENT RPC
-- ══════════════════════════════════════════════════════════════════════════

-- Create user_practice_completions table to track practice questions completed per user
create table if not exists public.user_practice_completions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  question_id text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(user_id, question_id)
);

alter table public.user_practice_completions enable row level security;

drop policy if exists "Users can read own practice completions" on public.user_practice_completions;
create policy "Users can read own practice completions" on public.user_practice_completions
  for select to authenticated using (auth.uid() = user_id);

-- Atomic RPC Function for Practice Completion & Score Awarding
create or replace function public.submit_practice_completion(
  p_question_id text,
  p_aura_reward integer default 5
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_already_completed boolean;
  v_new_aura bigint;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Check if already completed (idempotency check)
  select exists (
    select 1 from public.user_practice_completions
    where user_id = v_user_id and question_id = p_question_id
  ) into v_already_completed;

  if not v_already_completed then
    -- Record completion
    insert into public.user_practice_completions (user_id, question_id)
    values (v_user_id, p_question_id);

    -- Increment user aura server-side
    update public.users
    set aura = coalesce(aura, 0) + p_aura_reward,
        updated_at = now()
    where id = v_user_id
    returning aura into v_new_aura;
  else
    select coalesce(aura, 0) into v_new_aura from public.users where id = v_user_id;
  end if;

  return jsonb_build_object(
    'already_completed', v_already_completed,
    'aura', v_new_aura
  );
end;
$$;


-- ══════════════════════════════════════════════════════════════════════════
-- 2. MONTHLY AURA RESET & SERVER-SIDE IDEMPOTENCY GUARD
-- ══════════════════════════════════════════════════════════════════════════

create table if not exists public.system_settings (
  key text primary key,
  value text not null,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.system_settings enable row level security;
drop policy if exists "System settings viewable by authenticated" on public.system_settings;
create policy "System settings viewable by authenticated" on public.system_settings
  for select to authenticated using (true);

-- Server-side Monthly Reset RPC (Idempotent)
create or replace function public.perform_monthly_aura_reset()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current_month text;
  v_last_reset text;
begin
  v_current_month := to_char(now(), 'YYYY-MM');

  select value into v_last_reset
  from public.system_settings
  where key = 'last_monthly_aura_reset_key';

  -- Idempotency check: if already reset for this month, do nothing
  if v_last_reset = v_current_month then
    return;
  end if;

  -- Reset monthly aura for all users
  update public.users set aura_points = 0;

  -- Record reset month
  insert into public.system_settings (key, value, updated_at)
  values ('last_monthly_aura_reset_key', v_current_month, now())
  on conflict (key) do update set value = EXCLUDED.value, updated_at = EXCLUDED.updated_at;
end;
$$;

-- Revoke direct client execution from authenticated/anon roles
revoke execute on function public.perform_monthly_aura_reset() from authenticated, anon;


-- ══════════════════════════════════════════════════════════════════════════
-- 3. FEED SPAM & POST RATE LIMITING TRIGGER
-- ══════════════════════════════════════════════════════════════════════════

create or replace function public.check_post_rate_limit()
returns trigger
language plpgsql
security definer
as $$
declare
  v_recent_count integer;
begin
  -- Check post count in the last 60 seconds for current user
  select count(*) into v_recent_count
  from public.posts
  where user_id = auth.uid()
    and created_at > (now() - interval '60 seconds');

  if v_recent_count >= 5 then
    raise exception 'Rate limit exceeded: Maximum 5 posts per minute allowed.'
      using errcode = '42299';
  end if;

  return new;
end;
$$;

drop trigger if exists tr_check_post_rate_limit on public.posts;
create trigger tr_check_post_rate_limit
  before insert on public.posts
  for each row
  execute function public.check_post_rate_limit();


-- ══════════════════════════════════════════════════════════════════════════
-- 4. LEADERBOARD PERFORMANCE MATERIALIZED VIEW
-- ══════════════════════════════════════════════════════════════════════════

create materialized view if not exists public.mv_leaderboard_rankings as
select
  id,
  name,
  handle,
  avatar,
  college,
  aura,
  aura_points,
  row_number() over (order by coalesce(aura, 0) desc) as global_rank
from public.users;

create unique index if not exists idx_mv_leaderboard_id on public.mv_leaderboard_rankings(id);
