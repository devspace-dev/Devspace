-- ==============================================================================
-- DevSpace Roadmap Selection Schema (Stage 1)
-- Table: public.user_roadmaps
-- Purpose: Tracks each user's active and saved roadmap selections, starting level,
--          and committed weekly study hours without awarding Aura or writing fake progress.
-- ==============================================================================

create table if not exists public.user_roadmaps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  roadmap_id text not null,
  status text not null check (status in ('active', 'saved')),
  level text not null check (level in ('beginner', 'basics', 'comfortable')),
  weekly_hours int not null check (weekly_hours in (3, 6, 10)),
  started_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  unique (user_id, roadmap_id)
);

-- Index for fast user queries
create index if not exists idx_user_roadmaps_user 
  on public.user_roadmaps(user_id);

-- Enforce exactly ONE active roadmap per user via partial unique index
create unique index if not exists idx_user_roadmaps_one_active 
  on public.user_roadmaps(user_id) 
  where (status = 'active');

-- Enable Row Level Security
alter table public.user_roadmaps enable row level security;

-- Owner-only policy: authenticated users can only view, create, edit, or delete their own rows
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_roadmaps'
      and policyname = 'user_roadmaps_owner_rw'
  ) then
    create policy user_roadmaps_owner_rw
      on public.user_roadmaps
      for all
      to authenticated
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end;
$$;

-- Table permissions
grant select, insert, update, delete on public.user_roadmaps to authenticated;
grant all on public.user_roadmaps to service_role;
revoke all on public.user_roadmaps from anon, public;
