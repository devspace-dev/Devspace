-- =============================================================================
-- DEVSPACE AURA REDESIGN — PHASE B (FILE 4 OF 4): EMERGENCY ROLLBACK
-- File: supabase/patches/aura-04-rollback.sql
--
-- Run this ONLY if you need to restore users.aura and users.aura_points
-- from the snapshot created in aura-01-backup-and-preview.sql.
-- =============================================================================

begin;

do $$
begin
  if to_regclass('public.users_aura_backup') is null then
    raise exception 'Cannot rollback: public.users_aura_backup table does not exist.';
  end if;
end;
$$;

update public.users u
set aura = b.aura,
    aura_points = b.aura_points,
    updated_at = timezone('utc'::text, now())
from public.users_aura_backup b
where u.id = b.id;

commit;

select
  u.id,
  u.handle,
  u.name,
  u.aura as restored_aura,
  u.aura_points as restored_aura_points
from public.users u
order by coalesce(u.aura, 0) desc, u.handle asc;
