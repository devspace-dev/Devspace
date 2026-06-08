-- ==========================================
-- DUEL REQUESTS & MATCHMAKING
-- ==========================================

create type duel_request_status as enum ('pending', 'accepted', 'declined', 'cancelled');

create table public.duel_requests (
    id uuid primary key default gen_random_uuid(),
    sender_id uuid not null references public.users(id) on delete cascade,
    receiver_id uuid not null references public.users(id) on delete cascade,
    category text not null, -- e.g., 'COMBAT', 'LOGIC'
    mode text not null, -- e.g., 'Live Duel'
    status duel_request_status default 'pending' not null,
    created_at timestamptz default now() not null,
    updated_at timestamptz default now() not null
);

-- Enable Realtime for duel_requests so users can listen for invites
alter publication supabase_realtime add table public.duel_requests;

-- RLS for duel_requests
alter table public.duel_requests enable row level security;

create policy "Users can view requests they sent or received"
on public.duel_requests for select
using (auth.uid() = sender_id or auth.uid() = receiver_id);

create policy "Users can create requests they send"
on public.duel_requests for insert
with check (auth.uid() = sender_id);

create policy "Users can update requests they received (to accept/decline) or sent (cancel)"
on public.duel_requests for update
using (auth.uid() = receiver_id or auth.uid() = sender_id);

-- ==========================================
-- LIVE DUELS (GAME STATE)
-- ==========================================
create type duel_status as enum ('waiting', 'in_progress', 'completed', 'abandoned');

create table public.live_duels (
    id uuid primary key default gen_random_uuid(),
    request_id uuid references public.duel_requests(id) on delete set null,
    category text not null,
    player1_id uuid not null references public.users(id),
    player2_id uuid not null references public.users(id),
    player1_score int default 0,
    player2_score int default 0,
    status duel_status default 'waiting' not null,
    winner_id uuid references public.users(id),
    created_at timestamptz default now() not null,
    updated_at timestamptz default now() not null
);

-- Enable Realtime for live_duels
alter publication supabase_realtime add table public.live_duels;

-- RLS for live_duels
alter table public.live_duels enable row level security;

create policy "Players can view their duels"
on public.live_duels for select
using (auth.uid() = player1_id or auth.uid() = player2_id);

create policy "Players can insert duels upon request acceptance"
on public.live_duels for insert
with check (auth.uid() = player1_id or auth.uid() = player2_id);

create policy "System/Players can update their duel state"
on public.live_duels for update
using (auth.uid() = player1_id or auth.uid() = player2_id);
