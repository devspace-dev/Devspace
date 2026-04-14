-- DEVSPACE NOTIFICATIONS FIX
-- Run this in the Supabase SQL Editor to enable automatic notification generation.

-- 1. NOTIFICATIONS TABLE (Ensure it exists with correct columns)
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

alter table public.notifications add column if not exists question_id uuid references public.questions(id) on delete set null;


-- Ensure RLS is enabled
alter table public.notifications enable row level security;

-- RLS Policy: Users can only see their own notifications
drop policy if exists "Users can see their own notifications" on public.notifications;
create policy "Users can see their own notifications" on public.notifications
  for select to authenticated using (auth.uid() = to_uid);

-- RLS Policy: Users can update their own notifications (to mark as read)
drop policy if exists "Users can update their own notifications" on public.notifications;
create policy "Users can update their own notifications" on public.notifications
  for update to authenticated using (auth.uid() = to_uid);

-- 2. UPDATE LIKE_POST_WITH_AURA TO SEND NOTIFICATION
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

  -- Removed restriction: Users can now like their own posts
  -- if post_owner_id = actor_id then
  --   raise exception 'You cannot like your own post';
  -- end if;

  select coalesce(name, handle, 'Someone') into actor_name from public.users where id = actor_id;

  insert into public.likes(post_id, user_id)
  values (p_post_id, actor_id)
  on conflict (post_id, user_id) do nothing;

  if not found then
    raise exception 'Post already liked';
  end if;

  perform public.sync_post_like_count(p_post_id);

  -- Only award aura and send notification if it's NOT the user's own post
  if post_owner_id != actor_id then
    perform public.award_aura(
      post_owner_id,
      'receive_like',
      2,
      'post_like',
      p_post_id::text,
      actor_id,
      jsonb_build_object('postId', p_post_id)
    );

    -- SEND NOTIFICATION
    insert into public.notifications(to_uid, from_uid, type, post_id, message)
    values (post_owner_id, actor_id, 'like', p_post_id, actor_name || ' liked your post');
  end if;

  return jsonb_build_object('liked', true);
end;
$$;

-- 3. UPDATE ADD_COMMENT_WITH_AURA TO SEND NOTIFICATION
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

  -- SEND NOTIFICATION to post owner if it's not the same person
  if post_owner_id <> actor_id then
    insert into public.notifications(to_uid, from_uid, type, post_id, message)
    values (post_owner_id, actor_id, 'comment', p_post_id, actor_name || ' commented on your post');
  end if;

  return new_comment_id;
end;
$$;

-- 4. UPDATE MARK_QUESTION_REPLY_SOLVED TO SEND NOTIFICATION
create or replace function public.mark_question_reply_solved(
  p_question_id uuid,
  p_reply_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  question_owner_id uuid;
  existing_solved_reply_id uuid;
  reply_owner_id uuid;
  actor_name text;
begin
  select user_id, solved_reply_id
  into question_owner_id, existing_solved_reply_id
  from public.questions
  where id = p_question_id;

  if question_owner_id is null then
    raise exception 'Question not found';
  end if;

  if auth.uid() <> question_owner_id then
    raise exception 'Only the question owner can mark a reply as solved';
  end if;

  select user_id
  into reply_owner_id
  from public.question_replies
  where id = p_reply_id
    and question_id = p_question_id;

  if reply_owner_id is null then
    raise exception 'Reply does not belong to this question';
  end if;

  if existing_solved_reply_id is not null then
    raise exception 'This question is already solved';
  end if;

  select coalesce(name, handle, 'Someone') into actor_name from public.users where id = question_owner_id;

  update public.questions
  set solved_reply_id = p_reply_id
  where id = p_question_id;

  perform public.award_aura(
    reply_owner_id,
    'answer_accepted',
    15,
    'accepted_answer',
    p_reply_id::text,
    question_owner_id,
    jsonb_build_object('questionId', p_question_id)
  );

  -- SEND NOTIFICATION to reply owner
  if reply_owner_id <> question_owner_id then
    insert into public.notifications(to_uid, from_uid, type, message)
    values (reply_owner_id, question_owner_id, 'solved', actor_name || ' marked your answer as the solution!');
  end if;

  return p_reply_id;
end;
$$;

-- 5. TRIGGER FOR FOLLOW NOTIFICATIONS
create or replace function public.push_follow_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  follower_name text;
begin
  select coalesce(name, handle, 'Someone')
  into follower_name
  from public.users
  where id = new.follower_id;

  insert into public.notifications(to_uid, from_uid, type, message)
  values (
    new.following_id,
    new.follower_id,
    'follow',
    follower_name || ' started following you'
  );

  return new;
end;
$$;

drop trigger if exists trg_push_follow_notification on public.follows;
create trigger trg_push_follow_notification
after insert on public.follows
for each row
execute function public.push_follow_notification();

-- 6. ENABLE REALTIME FOR NOTIFICATIONS
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' 
    and schemaname = 'public' 
    and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
