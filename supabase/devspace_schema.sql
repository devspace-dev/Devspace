create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid references auth.users not null primary key,
  name text,
  email text unique,
  handle text unique,
  avatar text,
  color bigint default 0,
  aura bigint default 0,
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
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.users add column if not exists name text;
alter table public.users add column if not exists email text;
alter table public.users add column if not exists handle text;
alter table public.users add column if not exists avatar text;
alter table public.users add column if not exists color bigint default 0;
alter table public.users add column if not exists aura bigint default 0;
alter table public.users add column if not exists role text default 'Student';
alter table public.users add column if not exists year text default '';
alter table public.users add column if not exists branch text default '';
alter table public.users add column if not exists building text default '';
alter table public.users add column if not exists stack text[] default '{}'::text[];
alter table public.users add column if not exists followers bigint default 0;
alter table public.users add column if not exists following bigint default 0;
alter table public.users add column if not exists bio text default '';
alter table public.users add column if not exists college text default '';
alter table public.users add column if not exists github_handle text default '';
alter table public.users add column if not exists profile_completed boolean default false;
alter table public.users add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'users_email_key'
  ) then
    alter table public.users add constraint users_email_key unique (email);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'users_handle_key'
  ) then
    alter table public.users add constraint users_handle_key unique (handle);
  end if;
end
$$;

create table if not exists public.posts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade,
  content text default '',
  tags text[] default '{}'::text[],
  image_url text default '',
  quote_post_id uuid references public.posts(id) on delete set null,
  likes_count bigint default 0,
  comments_count bigint default 0,
  reposts_count bigint default 0,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.posts add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.posts add column if not exists content text default '';
alter table public.posts add column if not exists tags text[] default '{}'::text[];
alter table public.posts add column if not exists image_url text default '';
alter table public.posts add column if not exists quote_post_id uuid references public.posts(id) on delete set null;
alter table public.posts add column if not exists likes_count bigint default 0;
alter table public.posts add column if not exists comments_count bigint default 0;
alter table public.posts add column if not exists reposts_count bigint default 0;
alter table public.posts add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

create table if not exists public.follows (
  id uuid default gen_random_uuid() primary key,
  follower_id uuid references public.users(id) on delete cascade,
  following_id uuid references public.users(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.follows add column if not exists follower_id uuid references public.users(id) on delete cascade;
alter table public.follows add column if not exists following_id uuid references public.users(id) on delete cascade;
alter table public.follows add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'follows_follower_id_following_id_key'
  ) then
    alter table public.follows add constraint follows_follower_id_following_id_key unique (follower_id, following_id);
  end if;
end
$$;

create table if not exists public.likes (
  id uuid default gen_random_uuid() primary key,
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.likes add column if not exists post_id uuid references public.posts(id) on delete cascade;
alter table public.likes add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.likes add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'likes_post_id_user_id_key'
  ) then
    alter table public.likes add constraint likes_post_id_user_id_key unique (post_id, user_id);
  end if;
end
$$;

create table if not exists public.comments (
  id uuid default gen_random_uuid() primary key,
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  content text not null default '',
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.comments add column if not exists post_id uuid references public.posts(id) on delete cascade;
alter table public.comments add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.comments add column if not exists content text not null default '';
alter table public.comments add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

create table if not exists public.questions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade,
  title text not null default '',
  body text not null default '',
  tags text[] default '{}'::text[],
  upvotes_count bigint default 0,
  replies_count bigint default 0,
  solved_reply_id uuid,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.questions add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.questions add column if not exists title text not null default '';
alter table public.questions add column if not exists body text not null default '';
alter table public.questions add column if not exists tags text[] default '{}'::text[];
alter table public.questions add column if not exists upvotes_count bigint default 0;
alter table public.questions add column if not exists replies_count bigint default 0;
alter table public.questions add column if not exists solved_reply_id uuid;
alter table public.questions add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

create table if not exists public.question_replies (
  id uuid default gen_random_uuid() primary key,
  question_id uuid references public.questions(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  content text not null default '',
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.question_replies add column if not exists question_id uuid references public.questions(id) on delete cascade;
alter table public.question_replies add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.question_replies add column if not exists content text not null default '';
alter table public.question_replies add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

create table if not exists public.question_votes (
  id uuid default gen_random_uuid() primary key,
  question_id uuid references public.questions(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.question_votes add column if not exists question_id uuid references public.questions(id) on delete cascade;
alter table public.question_votes add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.question_votes add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'question_votes_question_id_user_id_key'
  ) then
    alter table public.question_votes
      add constraint question_votes_question_id_user_id_key unique (question_id, user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'questions_solved_reply_id_fkey'
  ) then
    alter table public.questions
      add constraint questions_solved_reply_id_fkey
      foreign key (solved_reply_id)
      references public.question_replies(id)
      on delete set null;
  end if;
end
$$;

create table if not exists public.notifications (
  id uuid default gen_random_uuid() primary key,
  to_uid uuid references public.users(id) on delete cascade,
  from_uid uuid references public.users(id) on delete cascade,
  type text default '',
  post_id uuid references public.posts(id) on delete set null,
  message text default '',
  read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.notifications add column if not exists to_uid uuid references public.users(id) on delete cascade;
alter table public.notifications add column if not exists from_uid uuid references public.users(id) on delete cascade;
alter table public.notifications add column if not exists type text default '';
alter table public.notifications add column if not exists post_id uuid references public.posts(id) on delete set null;
alter table public.notifications add column if not exists message text default '';
alter table public.notifications add column if not exists read boolean default false;
alter table public.notifications add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

create index if not exists idx_posts_user_id on public.posts(user_id);
create index if not exists idx_posts_created_at on public.posts(created_at desc);
create index if not exists idx_posts_quote_post_id on public.posts(quote_post_id);
create index if not exists idx_comments_post_id on public.comments(post_id);
create index if not exists idx_likes_post_id on public.likes(post_id);
create index if not exists idx_follows_follower_id on public.follows(follower_id);
create index if not exists idx_follows_following_id on public.follows(following_id);
create index if not exists idx_questions_user_id on public.questions(user_id);
create index if not exists idx_questions_created_at on public.questions(created_at desc);
create index if not exists idx_questions_solved_reply_id on public.questions(solved_reply_id);
create index if not exists idx_question_replies_question_id on public.question_replies(question_id);
create index if not exists idx_question_replies_user_id on public.question_replies(user_id);
create index if not exists idx_question_replies_created_at on public.question_replies(created_at desc);
create index if not exists idx_question_votes_question_id on public.question_votes(question_id);
create index if not exists idx_question_votes_user_id on public.question_votes(user_id);

create or replace function public.sync_repost_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' and old.quote_post_id is not null then
    update public.posts
    set reposts_count = (
      select count(*)
      from public.posts
      where quote_post_id = old.quote_post_id
    )
    where id = old.quote_post_id;
  elsif tg_op = 'UPDATE'
     and old.quote_post_id is not null
     and old.quote_post_id is distinct from new.quote_post_id then
    update public.posts
    set reposts_count = (
      select count(*)
      from public.posts
      where quote_post_id = old.quote_post_id
    )
    where id = old.quote_post_id;
  end if;

  if tg_op in ('INSERT', 'UPDATE') and new.quote_post_id is not null then
    update public.posts
    set reposts_count = (
      select count(*)
      from public.posts
      where quote_post_id = new.quote_post_id
    )
    where id = new.quote_post_id;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_sync_repost_counts on public.posts;

create trigger trg_sync_repost_counts
after insert or update of quote_post_id or delete
on public.posts
for each row
execute function public.sync_repost_counts();

create or replace function public.sync_question_upvote_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_question_id uuid;
begin
  target_question_id := coalesce(new.question_id, old.question_id);

  update public.questions
  set upvotes_count = (
    select count(*)
    from public.question_votes
    where question_id = target_question_id
  )
  where id = target_question_id;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_sync_question_upvote_counts on public.question_votes;

create trigger trg_sync_question_upvote_counts
after insert or delete
on public.question_votes
for each row
execute function public.sync_question_upvote_counts();

create or replace function public.sync_question_reply_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_question_id uuid;
begin
  target_question_id := coalesce(new.question_id, old.question_id);

  update public.questions
  set replies_count = (
    select count(*)
    from public.question_replies
    where question_id = target_question_id
  )
  where id = target_question_id;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_sync_question_reply_counts on public.question_replies;

create trigger trg_sync_question_reply_counts
after insert or delete
on public.question_replies
for each row
execute function public.sync_question_reply_counts();

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
    if existing_solved_reply_id = p_reply_id then
      return existing_solved_reply_id;
    end if;

    raise exception 'This question is already solved';
  end if;

  update public.questions
  set solved_reply_id = p_reply_id
  where id = p_question_id;

  update public.users
  set aura = aura + 20
  where id = reply_owner_id;

  return p_reply_id;
end;
$$;

grant execute on function public.mark_question_reply_solved(uuid, uuid) to authenticated;

alter table public.users enable row level security;
alter table public.posts enable row level security;
alter table public.follows enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.questions enable row level security;
alter table public.question_replies enable row level security;
alter table public.question_votes enable row level security;
alter table public.notifications enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'users_select_authenticated'
  ) then
    create policy users_select_authenticated
      on public.users
      for select
      to authenticated
      using (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'questions'
      and policyname = 'questions_select_authenticated'
  ) then
    create policy questions_select_authenticated
      on public.questions
      for select
      to authenticated
      using (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'questions'
      and policyname = 'questions_insert_owner'
  ) then
    create policy questions_insert_owner
      on public.questions
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'question_replies'
      and policyname = 'question_replies_select_authenticated'
  ) then
    create policy question_replies_select_authenticated
      on public.question_replies
      for select
      to authenticated
      using (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'question_replies'
      and policyname = 'question_replies_insert_owner'
  ) then
    create policy question_replies_insert_owner
      on public.question_replies
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'question_votes'
      and policyname = 'question_votes_select_authenticated'
  ) then
    create policy question_votes_select_authenticated
      on public.question_votes
      for select
      to authenticated
      using (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'question_votes'
      and policyname = 'question_votes_insert_owner'
  ) then
    create policy question_votes_insert_owner
      on public.question_votes
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'question_votes'
      and policyname = 'question_votes_delete_owner'
  ) then
    create policy question_votes_delete_owner
      on public.question_votes
      for delete
      to authenticated
      using (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'users_insert_own_profile'
  ) then
    create policy users_insert_own_profile
      on public.users
      for insert
      to authenticated
      with check (auth.uid() = id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'users_update_own_profile'
  ) then
    create policy users_update_own_profile
      on public.users
      for update
      to authenticated
      using (auth.uid() = id)
      with check (auth.uid() = id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'posts'
      and policyname = 'posts_select_authenticated'
  ) then
    create policy posts_select_authenticated
      on public.posts
      for select
      to authenticated
      using (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'posts'
      and policyname = 'posts_insert_authenticated'
  ) then
    create policy posts_insert_authenticated
      on public.posts
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'posts'
      and policyname = 'posts_update_owner'
  ) then
    create policy posts_update_owner
      on public.posts
      for update
      to authenticated
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'follows'
      and policyname = 'follows_select_authenticated'
  ) then
    create policy follows_select_authenticated
      on public.follows
      for select
      to authenticated
      using (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'follows'
      and policyname = 'follows_insert_owner'
  ) then
    create policy follows_insert_owner
      on public.follows
      for insert
      to authenticated
      with check (auth.uid() = follower_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'follows'
      and policyname = 'follows_delete_owner'
  ) then
    create policy follows_delete_owner
      on public.follows
      for delete
      to authenticated
      using (auth.uid() = follower_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'likes'
      and policyname = 'likes_select_authenticated'
  ) then
    create policy likes_select_authenticated
      on public.likes
      for select
      to authenticated
      using (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'likes'
      and policyname = 'likes_insert_owner'
  ) then
    create policy likes_insert_owner
      on public.likes
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'likes'
      and policyname = 'likes_delete_owner'
  ) then
    create policy likes_delete_owner
      on public.likes
      for delete
      to authenticated
      using (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'comments'
      and policyname = 'comments_select_authenticated'
  ) then
    create policy comments_select_authenticated
      on public.comments
      for select
      to authenticated
      using (true);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'comments'
      and policyname = 'comments_insert_owner'
  ) then
    create policy comments_insert_owner
      on public.comments
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'notifications'
      and policyname = 'notifications_select_recipient'
  ) then
    create policy notifications_select_recipient
      on public.notifications
      for select
      to authenticated
      using (auth.uid() = to_uid);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'notifications'
      and policyname = 'notifications_insert_sender'
  ) then
    create policy notifications_insert_sender
      on public.notifications
      for insert
      to authenticated
      with check (auth.uid() = from_uid);
  end if;
end
$$;
