-- ==============================================================================
-- DEVSPACE OPTIONAL HELPER PATCH: EXACT RANK FOR CALLERS OUTSIDE TOP 100
-- File: supabase/patches/leaderboard-01-rank-helper.sql
--
-- Additive read-only helper RPC. Does NOT modify get_aura_leaderboard,
-- award_aura, submit_daily_mission, resolve_arena_match,
-- submit_practice_completion, or any RLS/storage policies.
--
-- Returns:
--   rank         -> Standard competition rank (1, 2, 2, 4) among users with aura > 0,
--                   or NULL (Unranked) if caller has 0 aura in the requested scope/timeframe.
--   aura         -> Caller's Monthly (UTC) or All-Time allowed-ledger aura.
--   total_ranked -> Count of users with aura > 0 in the requested scope/timeframe.
-- ==============================================================================

create or replace function public.get_my_leaderboard_rank(
  p_college text default null,
  p_timeframe text default 'monthly'
)
returns table (
  rank bigint,
  aura bigint,
  total_ranked bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_month_start timestamp with time zone;
  v_month_end timestamp with time zone;
  v_is_monthly boolean;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return;
  end if;

  v_is_monthly := (coalesce(lower(trim(p_timeframe)), 'monthly') in ('monthly', 'weekly'));
  v_month_start := date_trunc('month', timezone('utc'::text, now()));
  v_month_end := v_month_start + interval '1 month';

  return query
  with scoped_users as (
    select u.id
    from public.users u
    where (p_college is null or trim(p_college) = '' or u.college = p_college)
  ),
  scores as (
    select
      al.user_id,
      coalesce(sum(al.points), 0)::bigint as score
    from public.aura_ledger al
    join scoped_users su on su.id = al.user_id
    where al.action in (
      'practice_question',
      'practice_complete',
      'complete_daily_mission',
      'attempt_daily_mission',
      'mission_solved',
      'arena_duel'
    )
      and (
        not v_is_monthly
        or (al.created_at >= v_month_start and al.created_at < v_month_end)
      )
    group by al.user_id
    having coalesce(sum(al.points), 0) > 0
  ),
  my_score as (
    select coalesce((select s.score from scores s where s.user_id = v_user_id), 0)::bigint as val
  )
  select
    case
      when ms.val <= 0 then null::bigint
      else (select count(*) + 1 from scores s where s.score > ms.val)::bigint
    end as rank,
    ms.val as aura,
    (select count(*) from scores)::bigint as total_ranked
  from my_score ms;
end;
$$;

revoke all on function public.get_my_leaderboard_rank(text, text) from public, anon;
grant execute on function public.get_my_leaderboard_rank(text, text) to authenticated, service_role;
