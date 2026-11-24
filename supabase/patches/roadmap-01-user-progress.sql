-- ==============================================================================
-- DevSpace Roadmap User Progress Schema
-- Idempotent patch for tracking user roadmap node completions (0 Aura awarded)
-- ==============================================================================

create table if not exists public.user_roadmap_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  roadmap_id text not null,
  node_id text not null,
  status text not null check (status in ('in_progress', 'completed')),
  completed_at timestamp with time zone default timezone('utc'::text, now()),
  unique (user_id, roadmap_id, node_id)
);

create index if not exists idx_user_roadmap_progress_user
  on public.user_roadmap_progress(user_id);

create index if not exists idx_user_roadmap_progress_roadmap
  on public.user_roadmap_progress(roadmap_id);

alter table public.user_roadmap_progress enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_roadmap_progress'
      and policyname = 'user_roadmap_progress_owner_rw'
  ) then
    create policy user_roadmap_progress_owner_rw
      on public.user_roadmap_progress
      for all
      to authenticated
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end;
$$;

grant select, insert, update, delete on public.user_roadmap_progress to authenticated;
grant all on public.user_roadmap_progress to service_role;
revoke all on public.user_roadmap_progress from anon, public;
