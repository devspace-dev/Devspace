-- =============================================================================
-- DEVSPACE AURA REDESIGN — PHASE B (FILE 2 OF 4): LEADERBOARD RPC
-- File: supabase/patches/aura-03-leaderboard.sql
--
-- What this script does:
--   1. Drops all existing overloads of public.get_aura_leaderboard.
--   2. Creates the single canonical function:
--        public.get_aura_leaderboard(
--          p_college text default null,
--          p_limit integer default 100,
--          p_timeframe text default 'monthly'
--        )
--   3. Uses ONLY the 6 allowed Arena ledger actions:
--        - 'practice_question'
--        - 'practice_complete'
--        - 'complete_daily_mission'
--        - 'attempt_daily_mission'
--        - 'mission_solved'
--        - 'arena_duel'
--   4. 'monthly' = UTC calendar month (DATE_TRUNC('month', timezone('utc', now()))).
--   5. 'all_time' = COALESCE(SUM(al.points), 0) from public.aura_ledger for the
--      6 allowed actions (never uses GREATEST(ledger, users.aura)).
-- =============================================================================

begin;

-- Drop all existing overloads of public.get_aura_leaderboard
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
      and p.proname = 'get_aura_leaderboard'
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

create index if not exists idx_aura_ledger_created_at_user_id
  on public.aura_ledger (created_at desc, user_id);

create or replace function public.get_aura_leaderboard(
  p_college text default null,
  p_limit integer default 100,
  p_timeframe text default 'monthly'
)
returns table (
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
language plpgsql
security definer
set search_path = public
as $$
declare
  v_month_start timestamp with time zone;
  v_month_end timestamp with time zone;
begin
  if lower(coalesce(p_timeframe, 'monthly')) in ('monthly', 'weekly') then
    v_month_start := date_trunc('month', timezone('utc'::text, now()));
    v_month_end := v_month_start + interval '1 month';

    return query
    with monthly_scores as (
      select
        al.user_id,
        coalesce(sum(al.points), 0)::bigint as period_aura
      from public.aura_ledger al
      where al.created_at >= v_month_start
        and al.created_at < v_month_end
        and al.action in (
          'practice_question',
          'practice_complete',
          'complete_daily_mission',
          'attempt_daily_mission',
          'mission_solved',
          'arena_duel'
        )
      group by al.user_id
    )
    select
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
      coalesce(ms.period_aura, 0)::bigint as aura,
      u.created_at
    from public.users u
    left join monthly_scores ms on u.id = ms.user_id
    where (p_college is null or trim(p_college) = '' or u.college = p_college)
    order by coalesce(ms.period_aura, 0) desc, coalesce(u.aura, 0) desc, u.created_at asc
    limit greatest(coalesce(p_limit, 100), 1);
  else
    return query
    with all_time_scores as (
      select
        al.user_id,
        coalesce(sum(al.points), 0)::bigint as total_aura
      from public.aura_ledger al
      where al.action in (
        'practice_question',
        'practice_complete',
        'complete_daily_mission',
        'attempt_daily_mission',
        'mission_solved',
        'arena_duel'
      )
      group by al.user_id
    )
    select
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
      coalesce(ats.total_aura, 0)::bigint as aura,
      u.created_at
    from public.users u
    left join all_time_scores ats on u.id = ats.user_id
    where (p_college is null or trim(p_college) = '' or u.college = p_college)
    order by coalesce(ats.total_aura, 0) desc, u.created_at asc
    limit greatest(coalesce(p_limit, 100), 1);
  end if;
end;
$$;

grant execute on function public.get_aura_leaderboard(text, integer, text) to authenticated, service_role;

commit;
