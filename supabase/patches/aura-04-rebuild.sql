-- =============================================================================
-- DEVSPACE AURA REDESIGN — PHASE B (FILE 3 OF 4): ONE-TIME AURA REBUILD
-- File: supabase/patches/aura-04-rebuild.sql
--
-- Pre-requisite:
--   supabase/patches/aura-01-backup-and-preview.sql MUST have been run first
--   so that public.users_aura_backup and public.aura_ledger_backup exist.
--
-- What this script does:
--   1. Verifies that public.users_aura_backup exists and is non-empty.
--   2. Recomputes and sets users.aura and users.aura_points for every user
--      to COALESCE(SUM(al.points), 0) for the 6 allowed Arena actions:
--        - 'practice_question'
--        - 'practice_complete'
--        - 'complete_daily_mission'
--        - 'attempt_daily_mission'
--        - 'mission_solved'
--        - 'arena_duel'
--   3. Outputs the post-rebuild verification table confirming
--      users.aura == users.aura_points == ledger_sum for all users.
-- =============================================================================

begin;

do $$
declare
  v_backup_count bigint := 0;
begin
  if to_regclass('public.users_aura_backup') is null then
    raise exception 'Safety check failed: public.users_aura_backup does not exist. Run aura-01-backup-and-preview.sql first.';
  end if;

  select count(*) into v_backup_count from public.users_aura_backup;
  if v_backup_count = 0 then
    raise exception 'Safety check failed: public.users_aura_backup is empty.';
  end if;
end;
$$;

with rebuilt_totals as (
  select
    u.id as user_id,
    coalesce(sum(al.points), 0)::bigint as arena_aura
  from public.users u
  left join public.aura_ledger al
    on al.user_id = u.id
   and al.action in (
     'practice_question',
     'practice_complete',
     'complete_daily_mission',
     'attempt_daily_mission',
     'mission_solved',
     'arena_duel'
   )
  group by u.id
)
update public.users u
set aura = rt.arena_aura,
    aura_points = rt.arena_aura,
    updated_at = timezone('utc'::text, now())
from rebuilt_totals rt
where u.id = rt.user_id
  and (
    coalesce(u.aura, -1) <> rt.arena_aura
    or coalesce(u.aura_points, -1) <> rt.arena_aura
  );

commit;

-- Verification query: confirm 100% sync between users.aura, users.aura_points, and aura_ledger
with ledger_check as (
  select
    u.id,
    u.handle,
    u.name,
    coalesce(u.aura, 0)::bigint as users_aura,
    coalesce(u.aura_points, 0)::bigint as users_aura_points,
    coalesce(sum(al.points), 0)::bigint as allowed_ledger_sum
  from public.users u
  left join public.aura_ledger al
    on al.user_id = u.id
   and al.action in (
     'practice_question',
     'practice_complete',
     'complete_daily_mission',
     'attempt_daily_mission',
     'mission_solved',
     'arena_duel'
   )
  group by u.id, u.handle, u.name, u.aura, u.aura_points
)
select
  handle,
  name,
  users_aura,
  users_aura_points,
  allowed_ledger_sum,
  (users_aura = allowed_ledger_sum and users_aura_points = allowed_ledger_sum) as in_sync
from ledger_check
order by users_aura desc, handle asc;
