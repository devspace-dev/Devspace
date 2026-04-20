-- DEVSPACE SOCIAL FIX V2
-- This script fixes the issues with liking/commenting and the role list mismatch.
-- Run this in the Supabase SQL Editor.

-- 1. FIX USER TABLE SCHEMA
-- Convert role from text to text[] to match Flutter's List<String> roles
do $$
begin
  if (select data_type from information_schema.columns where table_schema = 'public' and table_name = 'users' and column_name = 'role') = 'text' then
    -- Convert single text value to a single-element array
    alter table public.users alter column role type text[] using array[role];
    alter table public.users alter column role set default '{}'::text[];
  end if;
end $$;

-- Sync aura and aura_points columns
alter table public.users add column if not exists aura bigint default 0;
alter table public.users add column if not exists aura_points bigint default 0;

-- 2. FIX NOTIFICATIONS TABLE
create table if not exists public.notifications (
  id uuid default gen_random_uuid() primary key,
  to_uid uuid references public.users(id) on delete cascade,
  from_uid uuid references public.users(id) on delete cascade,
  type text default '',
  post_id uuid references public.posts(id) on delete set null,
  question_id uuid references public.questions(id) on delete set null,
  message text default '',
  read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Ensure RLS is enabled on notifications
alter table public.notifications enable row level security;

-- RLS Policy: Users can see their own notifications
drop policy if exists "Users can see their own notifications" on public.notifications;
create policy "Users can see their own notifications" on public.notifications
  for select to authenticated using (auth.uid() = to_uid);

-- RLS Policy: Users can update their own notifications
drop policy if exists "Users can update their own notifications" on public.notifications;
create policy "Users can update their own notifications" on public.notifications
  for update to authenticated using (auth.uid() = to_uid);

-- 3. FIX SOCIAL TABLE RLS POLICIES
-- Posts Policies
alter table public.posts enable row level security;
drop policy if exists "Allow select for authenticated" on public.posts;
create policy "Allow select for authenticated" on public.posts for select to authenticated using (true);
drop policy if exists "Allow insert for owner" on public.posts;
create policy "Allow insert for owner" on public.posts for insert to authenticated with check (auth.uid() = user_id);

-- Likes Policies
alter table public.likes enable row level security;
drop policy if exists "Allow select for authenticated" on public.likes;
create policy "Allow select for authenticated" on public.likes for select to authenticated using (true);
drop policy if exists "Allow insert for owner" on public.likes;
create policy "Allow insert for owner" on public.likes for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "Allow delete for owner" on public.likes;
create policy "Allow delete for owner" on public.likes for delete to authenticated using (auth.uid() = user_id);

-- Comments Policies
alter table public.comments enable row level security;
drop policy if exists "Allow select for authenticated" on public.comments;
create policy "Allow select for authenticated" on public.comments for select to authenticated using (true);
drop policy if exists "Allow insert for owner" on public.comments;
create policy "Allow insert for owner" on public.comments for insert to authenticated with check (auth.uid() = user_id);

-- 4. UPDATE RPC FUNCTIONS
-- Fix like_post_with_aura to handle both aura columns and notifications correctly
create or replace function public.like_post_with_aura(p_post_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  post_owner_id uuid;
  actor_name text;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select user_id
  into post_owner_id
  from public.posts
  where id = p_post_id;

  if post_owner_id is null then
    raise exception 'Post not found';
  end if;

  select coalesce(name, handle, 'Someone') into actor_name from public.users where id = actor_id;

  -- Rate limit (120 likes per hour)
  perform public.register_rate_limited_action('like_post', 120, 3600, p_post_id::text);

  insert into public.likes(post_id, user_id)
  values (p_post_id, actor_id)
  on conflict (post_id, user_id) do nothing;

  if not found then
    raise exception 'Post already liked';
  end if;

  -- Sync count
  perform public.sync_post_like_count(p_post_id);

  -- Award aura and notify if not self
  if post_owner_id != actor_id then
    -- award_aura function handles updating both aura and aura_points if written correctly
    -- but we'll be explicit here just in case award_aura is old
    perform public.award_aura(
      post_owner_id,
      'receive_like',
      2,
      'post_like',
      p_post_id::text,
      actor_id,
      jsonb_build_object('postId', p_post_id)
    );

    insert into public.notifications(to_uid, from_uid, type, post_id, message)
    values (post_owner_id, actor_id, 'like', p_post_id, actor_name || ' liked your post');
  end if;

  return jsonb_build_object('liked', true);
end;
$$;

-- Fix add_comment_with_aura
create or replace function public.add_comment_with_aura(
  p_post_id uuid,
  p_content text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  post_owner_id uuid;
  actor_name text;
  new_comment_id uuid;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  if coalesce(trim(p_content), '') = '' then
    raise exception 'Comment cannot be empty';
  end if;

  select user_id into post_owner_id from public.posts where id = p_post_id;
  select coalesce(name, handle, 'Someone') into actor_name from public.users where id = actor_id;

  perform public.register_rate_limited_action('create_comment', 60, 3600, p_post_id::text);

  insert into public.comments(post_id, user_id, content)
  values (p_post_id, actor_id, trim(p_content))
  returning id into new_comment_id;

  perform public.sync_post_comment_count(p_post_id);

  perform public.award_aura(
    actor_id,
    'create_comment',
    3,
    'comment',
    new_comment_id::text
  );

  -- Notify post owner
  if post_owner_id != actor_id then
    insert into public.notifications(to_uid, from_uid, type, post_id, message)
    values (post_owner_id, actor_id, 'comment', p_post_id, actor_name || ' commented on your post');
  end if;

  return new_comment_id;
end;
$$;

-- Fix award_aura to update both columns for safety
create or replace function public.award_aura(
  p_user_id uuid,
  p_action text,
  p_points integer,
  p_reference_type text,
  p_reference_id text,
  p_source_user_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.aura_ledger(
    user_id,
    action,
    points,
    reference_type,
    reference_id,
    source_user_id,
    metadata
  )
  values (
    p_user_id,
    p_action,
    p_points,
    p_reference_type,
    p_reference_id,
    p_source_user_id,
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict do nothing;

  if found then
    update public.users
    set aura = coalesce(aura, 0) + p_points,
        aura_points = coalesce(aura_points, 0) + p_points
    where id = p_user_id;
    return true;
  end if;

  return false;
end;
$$;
