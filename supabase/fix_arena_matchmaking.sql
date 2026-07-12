-- =====================================================================
-- FIX ARENA MATCHMAKING: RLS POLICIES & ATOMIC MATCHMAKING FUNCTION
-- Run this in your Supabase SQL Editor to enable reliable matchmaking.
-- =====================================================================

-- 1. Enable Row Level Security (RLS) on arena_matches
alter table public.arena_matches enable row level security;

-- 2. Drop existing policies on arena_matches to prevent conflicts
drop policy if exists "Players can view their duels" on public.arena_matches;
drop policy if exists "Players can insert duels" on public.arena_matches;
drop policy if exists "Players can update their duel state" on public.arena_matches;
drop policy if exists "Users can view relevant arena matches" on public.arena_matches;
drop policy if exists "Users can create arena matches" on public.arena_matches;
drop policy if exists "Users can update their own arena matches" on public.arena_matches;
drop policy if exists "Users can delete their own arena matches" on public.arena_matches;

-- 3. Create fresh, robust RLS policies
create policy "Users can view relevant arena matches"
on public.arena_matches for select
using (
  auth.uid() = player1_id 
  or auth.uid() = player2_id 
  or status = 'waiting'
);

create policy "Users can create arena matches"
on public.arena_matches for insert
with check (
  auth.uid() = player1_id
);

create policy "Users can update their own arena matches"
on public.arena_matches for update
using (
  auth.uid() = player1_id 
  or auth.uid() = player2_id 
  or (status = 'waiting' and player2_id is null)
);

create policy "Users can delete their own arena matches"
on public.arena_matches for delete
using (
  auth.uid() = player1_id
);

-- 4. Create an atomic SQL function (RPC) for finding and joining a match.
-- Running this function as "security definer" bypasses RLS during the search
-- to find a match, and uses "FOR UPDATE SKIP LOCKED" to prevent race conditions.
create or replace function find_arena_match(
  p_user_id uuid,
  p_mode text
) returns uuid as $$
declare
  v_match_id uuid;
begin
  -- Find the oldest waiting match for this mode created by someone else
  select id into v_match_id
  from public.arena_matches
  where mode = p_mode
    and status = 'waiting'
    and player1_id != p_user_id
    and player2_id is null
  order by created_at asc
  limit 1
  for update skip locked;

  if v_match_id is not null then
    -- Atomically assign current user to player2 and set status to playing
    update public.arena_matches
    set player2_id = p_user_id,
        status = 'playing',
        updated_at = now()
    where id = v_match_id;
    
    return v_match_id;
  else
    return null;
  end if;
end;
$$ language plpgsql security definer;

-- 5. Enable Realtime Replication for arena_matches
do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'arena_matches'
  ) then
    execute 'alter publication supabase_realtime add table public.arena_matches';
  end if;
end;
$$;

