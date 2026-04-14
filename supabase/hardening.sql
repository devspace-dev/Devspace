-- DEVSPACE SUPABASE HARDENING & RLS POLICIES
-- This script enforces strict security for production launch.

-- 1. ENABLE RLS ON ALL TABLES
alter table public.users enable row level security;
alter table public.posts enable row level security;
alter table public.follows enable row level security;
alter table public.likes enable row level security;
alter table public.bookmarks enable row level security;
alter table public.comments enable row level security;
alter table public.questions enable row level security;
alter table public.question_replies enable row level security;
alter table public.question_votes enable row level security;
alter table public.notifications enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

-- 2. USERS (PROFILES)
drop policy if exists "Profiles are viewable by everyone" on public.users;
create policy "Profiles are viewable by everyone" on public.users
  for select to authenticated using (true);

drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile" on public.users
  for update to authenticated using (auth.uid() = id)
  with check (auth.uid() = id);

-- 3. POSTS
drop policy if exists "Posts are viewable by everyone" on public.posts;
create policy "Posts are viewable by everyone" on public.posts
  for select to authenticated using (true);

drop policy if exists "Users can create posts" on public.posts;
create policy "Users can create posts" on public.posts
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Users can update own posts" on public.posts;
create policy "Users can update own posts" on public.posts
  for update to authenticated using (auth.uid() = user_id);

drop policy if exists "Users can delete own posts" on public.posts;
create policy "Users can delete own posts" on public.posts
  for delete to authenticated using (auth.uid() = user_id);

-- 4. MESSAGES & CONVERSATIONS
drop policy if exists "Conversations viewable by participants" on public.conversations;
create policy "Conversations viewable by participants" on public.conversations
  for select to authenticated using (auth.uid() = any(participants));

drop policy if exists "Messages viewable by participants" on public.messages;
create policy "Messages viewable by participants" on public.messages
  for select to authenticated using (
    exists (
      select 1 from public.conversations 
      where id = conversation_id and auth.uid() = any(participants)
    )
  );

drop policy if exists "Users can send messages" on public.messages;
create policy "Users can send messages" on public.messages
  for insert to authenticated with check (
    auth.uid() = sender_id AND
    exists (
      select 1 from public.conversations 
      where id = conversation_id and auth.uid() = any(participants)
    )
  );

-- 5. FIELD VALIDATION
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'users_handle_length'
  ) then
    alter table public.users add constraint users_handle_length check (char_length(handle) >= 3 and char_length(handle) <= 25);
  end if;

  -- Ensure old post content length constraint is removed if it exists
  if exists (
    select 1
    from pg_constraint
    where conname = 'posts_content_length'
  ) then
    alter table public.posts drop constraint posts_content_length;
  end if;
end
$$;

