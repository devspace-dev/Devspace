-- ==========================================
-- RANDOM MATCHMAKING POOL
-- ==========================================

create table public.matchmaking_pool (
    user_id uuid primary key references public.users(id) on delete cascade,
    category text not null,
    mode text not null,
    created_at timestamptz default now() not null
);

-- RLS
alter table public.matchmaking_pool enable row level security;
create policy "Users can manage their own pool entry"
on public.matchmaking_pool for all
using (auth.uid() = user_id);

create policy "Users can view the pool"
on public.matchmaking_pool for select
using (true);

-- RPC for atomic matchmaking
create or replace function find_match(
  p_user_id uuid,
  p_category text,
  p_mode text
) returns uuid as $$
declare
  v_opponent_id uuid;
  v_duel_id uuid;
begin
  -- Try to find an opponent and lock the row
  select user_id into v_opponent_id
  from public.matchmaking_pool
  where category = p_category 
    and mode = p_mode 
    and user_id != p_user_id
  order by created_at asc
  limit 1
  for update skip locked;

  if v_opponent_id is not null then
    -- Found an opponent! Delete them from the pool
    delete from public.matchmaking_pool where user_id = v_opponent_id;
    
    -- Create the live duel
    insert into public.live_duels (category, player1_id, player2_id, status)
    values (p_category, v_opponent_id, p_user_id, 'in_progress')
    returning id into v_duel_id;
    
    return v_duel_id;
  else
    -- No opponent found, insert self into pool
    insert into public.matchmaking_pool (user_id, category, mode)
    values (p_user_id, p_category, p_mode)
    on conflict (user_id) do update 
    set category = p_category, mode = p_mode, created_at = now();
    
    return null;
  end if;
end;
$$ language plpgsql security definer;
