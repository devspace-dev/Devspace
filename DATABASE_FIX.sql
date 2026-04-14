-- DEVSPACE SUPABASE DATABASE FIX
-- Run this in the Supabase SQL Editor to ensure all tables and columns are correct.

-- 1. EXTENSIONS
create extension if not exists pgcrypto;

-- 2. USERS TABLE
create table if not exists public.users (
  id uuid references auth.users not null primary key,
  name text,
  email text unique,
  handle text unique,
  avatar text,
  color bigint default 0,
  aura bigint default 0,
  aura_points bigint default 0,
  role text default 'Student',
  year text default '',
  branch text default '',
  building text default '',
  stack text[] default '{}'::text[],
  followers bigint default 0,
  following bigint default 0,
  bio text default '',
  college text default '',
  github_handle text default '',
  profile_completed boolean default false,
  is_admin boolean default false,
  current_streak integer default 0,
  longest_streak integer default 0,
  last_challenge_completed_on date,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- Ensure all columns exist (in case table was created previously)
alter table public.users add column if not exists aura_points bigint default 0;
alter table public.users add column if not exists is_admin boolean default false;
alter table public.users add column if not exists current_streak integer default 0;
alter table public.users add column if not exists longest_streak integer default 0;
alter table public.users add column if not exists last_challenge_completed_on date;
alter table public.users add column if not exists github_handle text default '';
alter table public.users add column if not exists profile_completed boolean default false;

-- 3. MESSAGING TABLES
create table if not exists public.conversations (
  id uuid default gen_random_uuid() primary key,
  participants uuid[] not null,
  last_message text,
  last_message_at timestamp with time zone default timezone('utc'::text, now()),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id uuid references public.users(id) on delete cascade,
  recipient_id uuid references public.users(id) on delete cascade,
  content text not null,
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Ensure recipient_id exists
alter table public.messages add column if not exists recipient_id uuid references public.users(id) on delete cascade;

-- 4. CHALLENGES TABLES
create table if not exists public.challenges (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text not null default '',
  difficulty text not null default 'easy',
  tech_stack text not null default 'General',
  points_reward integer not null default 20,
  publish_date date not null default (timezone('utc'::text, now())::date),
  is_active boolean not null default true,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  constraint challenges_difficulty_check check (difficulty in ('easy', 'medium', 'hard'))
);

create table if not exists public.user_challenges (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  challenge_id uuid references public.challenges(id) on delete cascade not null,
  assigned_date date not null default timezone('utc'::text, now())::date,
  selected_tech_stack text not null default 'General',
  submission_text text default '',
  submission_link text default '',
  completed boolean not null default false,
  completed_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  unique (user_id, assigned_date)
);

-- 5. REALTIME ENABLEMENT
-- Step 1: Create the publication if it doesn't exist
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end
$$;

-- Step 2: Add tables to the publication
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.conversations;
alter publication supabase_realtime add table public.users;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.notifications;

-- 6. INDEXES FOR PERFORMANCE
create index if not exists idx_messages_conversation_id on public.messages(conversation_id);
create index if not exists idx_user_challenges_lookup on public.user_challenges(user_id, assigned_date);
create index if not exists idx_challenges_publish_date on public.challenges(publish_date);

-- 7. RLS POLICIES (Simplified for common use)
alter table public.users enable row level security;
alter table public.messages enable row level security;
alter table public.conversations enable row level security;

-- Drop existing to avoid conflicts
drop policy if exists "Users can see all profiles" on public.users;
create policy "Users can see all profiles" on public.users for select to authenticated using (true);

drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile" on public.users for update to authenticated using (auth.uid() = id);

drop policy if exists "Users can see their own conversations" on public.conversations;
create policy "Users can see their own conversations" on public.conversations for select to authenticated using (auth.uid() = any(participants));

drop policy if exists "Users can send messages to their conversations" on public.messages;
create policy "Users can send messages to their conversations" on public.messages for insert to authenticated with check (
  exists (
    select 1 from public.conversations 
    where id = conversation_id and auth.uid() = any(participants)
  )
);

drop policy if exists "Users can see messages in their conversations" on public.messages;
create policy "Users can see messages in their conversations" on public.messages for select to authenticated using (
  exists (
    select 1 from public.conversations 
    where id = conversation_id and auth.uid() = any(participants)
  )
);
