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
alter table public.users add column if not exists is_admin boolean default false;

create table if not exists public.founder_devices (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  device_id text not null,
  label text default '',
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  unique (user_id, device_id),
  unique (device_id)
);

alter table public.founder_devices add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.founder_devices add column if not exists device_id text;
alter table public.founder_devices add column if not exists label text default '';
alter table public.founder_devices add column if not exists is_active boolean default true;
alter table public.founder_devices add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());
alter table public.founder_devices add column if not exists updated_at timestamp with time zone default timezone('utc'::text, now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'founder_devices_user_id_device_id_key'
  ) then
    alter table public.founder_devices
      add constraint founder_devices_user_id_device_id_key unique (user_id, device_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'founder_devices_device_id_key'
  ) then
    alter table public.founder_devices
      add constraint founder_devices_device_id_key unique (device_id);
  end if;
end
$$;

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

create table if not exists public.bookmarks (
  id uuid default gen_random_uuid() primary key,
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.bookmarks add column if not exists post_id uuid references public.posts(id) on delete cascade;
alter table public.bookmarks add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.bookmarks add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'bookmarks_post_id_user_id_key'
  ) then
    alter table public.bookmarks
      add constraint bookmarks_post_id_user_id_key unique (post_id, user_id);
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
  parent_reply_id uuid references public.question_replies(id) on delete cascade,
  replying_to_user_id uuid references public.users(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.question_replies add column if not exists question_id uuid references public.questions(id) on delete cascade;
alter table public.question_replies add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.question_replies add column if not exists content text not null default '';
alter table public.question_replies add column if not exists parent_reply_id uuid references public.question_replies(id) on delete cascade;
alter table public.question_replies add column if not exists replying_to_user_id uuid references public.users(id) on delete set null;
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

create table if not exists public.conversations (
  id uuid default gen_random_uuid() primary key,
  participants uuid[] not null,
  participant_key text,
  last_message text,
  last_message_at timestamp with time zone,
  last_message_sender_id uuid references public.users(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.conversations add column if not exists participants uuid[];
alter table public.conversations add column if not exists participant_key text;
alter table public.conversations add column if not exists last_message text;
alter table public.conversations add column if not exists last_message_at timestamp with time zone;
alter table public.conversations add column if not exists last_message_sender_id uuid references public.users(id) on delete set null;
alter table public.conversations add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());
alter table public.conversations add column if not exists updated_at timestamp with time zone default timezone('utc'::text, now());

create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id uuid references public.users(id) on delete cascade,
  content text not null,
  is_read boolean default false,
  read_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table public.messages add column if not exists conversation_id uuid references public.conversations(id) on delete cascade;
alter table public.messages add column if not exists sender_id uuid references public.users(id) on delete cascade;
alter table public.messages add column if not exists content text;
alter table public.messages add column if not exists is_read boolean default false;
alter table public.messages add column if not exists read_at timestamp with time zone;
alter table public.messages add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'conversations_exactly_two_participants'
  ) then
    alter table public.conversations
      add constraint conversations_exactly_two_participants
      check (coalesce(array_length(participants, 1), 0) = 2);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'conversations_distinct_participants'
  ) then
    alter table public.conversations
      add constraint conversations_distinct_participants
      check (participants[1] is distinct from participants[2]);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'messages_content_not_blank'
  ) then
    alter table public.messages
      add constraint messages_content_not_blank
      check (length(btrim(coalesce(content, ''))) > 0);
  end if;
end
$$;

with normalized_conversations as (
  select
    c.id,
    c.created_at,
    c.last_message_at,
    string_agg(participant::text, ':' order by participant::text) as participant_key
  from public.conversations c
  cross join lateral unnest(c.participants) as participant
  where coalesce(array_length(c.participants, 1), 0) = 2
    and c.participants[1] is distinct from c.participants[2]
  group by c.id, c.created_at, c.last_message_at
),
ranked_conversations as (
  select
    id,
    participant_key,
    first_value(id) over (
      partition by participant_key
      order by coalesce(last_message_at, created_at) desc, created_at asc, id asc
    ) as canonical_id
  from normalized_conversations
)
update public.messages m
set conversation_id = ranked_conversations.canonical_id
from ranked_conversations
where m.conversation_id = ranked_conversations.id
  and ranked_conversations.id <> ranked_conversations.canonical_id;

with normalized_conversations as (
  select
    c.id,
    c.created_at,
    c.last_message_at,
    string_agg(participant::text, ':' order by participant::text) as participant_key
  from public.conversations c
  cross join lateral unnest(c.participants) as participant
  where coalesce(array_length(c.participants, 1), 0) = 2
    and c.participants[1] is distinct from c.participants[2]
  group by c.id, c.created_at, c.last_message_at
),
ranked_conversations as (
  select
    id,
    participant_key,
    first_value(id) over (
      partition by participant_key
      order by coalesce(last_message_at, created_at) desc, created_at asc, id asc
    ) as canonical_id
  from normalized_conversations
)
delete from public.conversations c
using ranked_conversations
where c.id = ranked_conversations.id
  and ranked_conversations.id <> ranked_conversations.canonical_id;

create index if not exists idx_posts_user_id on public.posts(user_id);
create index if not exists idx_posts_created_at on public.posts(created_at desc);
create index if not exists idx_posts_quote_post_id on public.posts(quote_post_id);
create index if not exists idx_comments_post_id on public.comments(post_id);
create index if not exists idx_likes_post_id on public.likes(post_id);
create index if not exists idx_bookmarks_user_id on public.bookmarks(user_id);
create index if not exists idx_bookmarks_post_id on public.bookmarks(post_id);
create index if not exists idx_bookmarks_created_at on public.bookmarks(created_at desc);
create index if not exists idx_follows_follower_id on public.follows(follower_id);
create index if not exists idx_follows_following_id on public.follows(following_id);
create index if not exists idx_questions_user_id on public.questions(user_id);
create index if not exists idx_questions_created_at on public.questions(created_at desc);
create index if not exists idx_questions_solved_reply_id on public.questions(solved_reply_id);
create index if not exists idx_question_replies_question_id on public.question_replies(question_id);
create index if not exists idx_question_replies_user_id on public.question_replies(user_id);
create index if not exists idx_question_replies_parent_reply_id on public.question_replies(parent_reply_id);
create index if not exists idx_question_replies_replying_to_user_id on public.question_replies(replying_to_user_id);
create index if not exists idx_question_replies_created_at on public.question_replies(created_at desc);
create index if not exists idx_question_votes_question_id on public.question_votes(question_id);
create index if not exists idx_question_votes_user_id on public.question_votes(user_id);
create unique index if not exists idx_conversations_participant_key
  on public.conversations(participant_key);
create index if not exists idx_conversations_last_message_at
  on public.conversations(last_message_at desc nulls last, created_at desc);
create index if not exists idx_messages_conversation_created_at
  on public.messages(conversation_id, created_at asc);
create index if not exists idx_messages_unread_lookup
  on public.messages(conversation_id, is_read, created_at desc);
create index if not exists idx_messages_sender_id
  on public.messages(sender_id);

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

create or replace function public.sync_follow_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  follower_user_id uuid;
  following_user_id uuid;
begin
  follower_user_id := coalesce(new.follower_id, old.follower_id);
  following_user_id := coalesce(new.following_id, old.following_id);

  if follower_user_id is not null then
    update public.users
    set following = (
      select count(*)
      from public.follows
      where follower_id = follower_user_id
    )
    where id = follower_user_id;
  end if;

  if following_user_id is not null then
    update public.users
    set followers = (
      select count(*)
      from public.follows
      where following_id = following_user_id
    )
    where id = following_user_id;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_sync_follow_counts on public.follows;

create trigger trg_sync_follow_counts
after insert or delete
on public.follows
for each row
execute function public.sync_follow_counts();

update public.users as u
set following = (
  select count(*)
  from public.follows f
  where f.follower_id = u.id
),
followers = (
  select count(*)
  from public.follows f
  where f.following_id = u.id
);

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
alter table public.bookmarks enable row level security;
alter table public.comments enable row level security;
alter table public.questions enable row level security;
alter table public.question_replies enable row level security;
alter table public.question_votes enable row level security;
alter table public.notifications enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

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
      and tablename = 'notifications'
      and policyname = 'notifications_update_recipient'
  ) then
    create policy notifications_update_recipient
      on public.notifications
      for update
      to authenticated
      using (auth.uid() = to_uid)
      with check (auth.uid() = to_uid);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'conversations'
      and policyname = 'conversations_select_participant'
  ) then
    create policy conversations_select_participant
      on public.conversations
      for select
      to authenticated
      using (auth.uid() = any(participants));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'messages'
      and policyname = 'messages_select_participant'
  ) then
    create policy messages_select_participant
      on public.messages
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.conversations c
          where c.id = conversation_id
            and auth.uid() = any(c.participants)
        )
      );
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
      and tablename = 'bookmarks'
      and policyname = 'bookmarks_select_owner'
  ) then
    create policy bookmarks_select_owner
      on public.bookmarks
      for select
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
      and tablename = 'bookmarks'
      and policyname = 'bookmarks_insert_owner'
  ) then
    create policy bookmarks_insert_owner
      on public.bookmarks
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
      and tablename = 'bookmarks'
      and policyname = 'bookmarks_delete_owner'
  ) then
    create policy bookmarks_delete_owner
      on public.bookmarks
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

alter table public.users add column if not exists aura_points bigint default 0;
alter table public.users add column if not exists current_streak integer default 0;
alter table public.users add column if not exists longest_streak integer default 0;
alter table public.users add column if not exists last_challenge_completed_on date;
alter table public.users add column if not exists is_admin boolean default false;
alter table public.users add column if not exists updated_at timestamp with time zone default timezone('utc'::text, now());

update public.users
set aura_points = coalesce(aura_points, aura, 0),
    aura = coalesce(aura_points, aura, 0),
    current_streak = coalesce(current_streak, 0),
    longest_streak = coalesce(longest_streak, 0);

create or replace function public.sync_user_aura_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.aura_points is null and new.aura is not null then
      new.aura_points := new.aura;
    elsif new.aura is null and new.aura_points is not null then
      new.aura := new.aura_points;
    end if;
  elsif new.aura_points is null and new.aura is not null then
    new.aura_points := new.aura;
  elsif new.aura is null and new.aura_points is not null then
    new.aura := new.aura_points;
  elsif new.aura_points is distinct from old.aura_points then
    new.aura := new.aura_points;
  elsif new.aura is distinct from old.aura then
    new.aura_points := new.aura;
  end if;

  new.updated_at := timezone('utc'::text, now());
  return new;
end;
$$;

drop trigger if exists trg_sync_user_aura_columns on public.users;

create trigger trg_sync_user_aura_columns
before insert or update on public.users
for each row
execute function public.sync_user_aura_columns();

create or replace function public.get_aura_level(points bigint)
returns text
language sql
immutable
as $$
  select case
    when coalesce(points, 0) < 500 then 'Beginner'
    when coalesce(points, 0) < 2000 then 'Builder'
    when coalesce(points, 0) < 5000 then 'Hacker'
    else 'Elite'
  end;
$$;

create table if not exists public.aura_ledger (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  action text not null,
  points integer not null,
  reference_type text not null,
  reference_id text not null,
  source_user_id uuid references public.users(id) on delete set null,
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

create unique index if not exists idx_aura_ledger_dedupe
  on public.aura_ledger(user_id, action, reference_type, reference_id, coalesce(source_user_id, '00000000-0000-0000-0000-000000000000'::uuid));
create index if not exists idx_aura_ledger_user_created_at
  on public.aura_ledger(user_id, created_at desc);

create table if not exists public.rate_limit_events (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  action text not null,
  reference_id text,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

create index if not exists idx_rate_limit_events_lookup
  on public.rate_limit_events(user_id, action, created_at desc);

create table if not exists public.events (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text not null default '',
  required_aura bigint not null default 0,
  link text not null default '',
  type text not null default 'event',
  is_active boolean not null default true,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  constraint events_type_check check (type in ('hackathon', 'event'))
);

alter table public.events add column if not exists is_active boolean not null default true;

create table if not exists public.user_events (
  user_id uuid references public.users(id) on delete cascade not null,
  event_id uuid references public.events(id) on delete cascade not null,
  unlocked boolean not null default false,
  unlocked_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()),
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  primary key (user_id, event_id)
);

create index if not exists idx_events_required_aura on public.events(required_aura);

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

create index if not exists idx_challenges_publish_date on public.challenges(publish_date);

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

create index if not exists idx_challenges_stack_active
  on public.challenges(tech_stack, is_active);
create index if not exists idx_user_challenges_user_date
  on public.user_challenges(user_id, assigned_date desc);

create table if not exists public.user_badges (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  badge_key text not null,
  badge_name text not null,
  awarded_at timestamp with time zone default timezone('utc'::text, now()),
  unique (user_id, badge_key)
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at := timezone('utc'::text, now());
  return new;
end;
$$;

drop trigger if exists trg_touch_events_updated_at on public.events;
create trigger trg_touch_events_updated_at
before update on public.events
for each row
execute function public.touch_updated_at();

drop trigger if exists trg_touch_user_events_updated_at on public.user_events;
create trigger trg_touch_user_events_updated_at
before update on public.user_events
for each row
execute function public.touch_updated_at();

drop trigger if exists trg_touch_challenges_updated_at on public.challenges;
create trigger trg_touch_challenges_updated_at
before update on public.challenges
for each row
execute function public.touch_updated_at();

drop trigger if exists trg_touch_user_challenges_updated_at on public.user_challenges;
create trigger trg_touch_user_challenges_updated_at
before update on public.user_challenges
for each row
execute function public.touch_updated_at();

update public.conversations
set participants = normalized.sorted_participants,
    participant_key = normalized.participant_key,
    updated_at = coalesce(updated_at, timezone('utc'::text, now()))
from (
  select
    id,
    array_agg(participant order by participant::text) as sorted_participants,
    string_agg(participant::text, ':' order by participant::text) as participant_key
  from public.conversations c
  cross join lateral unnest(c.participants) as participant
  group by id
) as normalized
where public.conversations.id = normalized.id
  and coalesce(array_length(public.conversations.participants, 1), 0) = 2
  and public.conversations.participants[1] is distinct from public.conversations.participants[2]
  and (
    public.conversations.participant_key is null
    or public.conversations.participant_key <> normalized.participant_key
  );

update public.conversations
set last_message = latest_message.last_message,
    last_message_at = latest_message.last_message_at,
    last_message_sender_id = latest_message.last_message_sender_id
from (
  select distinct on (m.conversation_id)
    m.conversation_id,
    left(trim(m.content), 280) as last_message,
    m.created_at as last_message_at,
    m.sender_id as last_message_sender_id
  from public.messages m
  order by m.conversation_id, m.created_at desc, m.id desc
) as latest_message
where public.conversations.id = latest_message.conversation_id
  and (
    public.conversations.last_message is distinct from latest_message.last_message
    or public.conversations.last_message_at is distinct from latest_message.last_message_at
    or public.conversations.last_message_sender_id is distinct from latest_message.last_message_sender_id
  );

create or replace function public.normalize_direct_message_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  sorted_participants uuid[];
begin
  if coalesce(array_length(new.participants, 1), 0) <> 2 then
    raise exception 'Direct conversations must include exactly two participants';
  end if;

  if new.participants[1] is null or new.participants[2] is null then
    raise exception 'Conversation participants are required';
  end if;

  if new.participants[1] = new.participants[2] then
    raise exception 'You cannot create a conversation with yourself';
  end if;

  select array_agg(participant order by participant::text)
  into sorted_participants
  from unnest(new.participants) as participant;

  new.participants := sorted_participants;
  new.participant_key := sorted_participants[1]::text || ':' || sorted_participants[2]::text;

  if new.created_at is null then
    new.created_at := timezone('utc'::text, now());
  end if;

  new.updated_at := timezone('utc'::text, now());
  return new;
end;
$$;

drop trigger if exists trg_normalize_direct_message_conversation on public.conversations;
create trigger trg_normalize_direct_message_conversation
before insert or update on public.conversations
for each row
execute function public.normalize_direct_message_conversation();

create or replace function public.sync_message_read_state()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_read and (tg_op = 'INSERT' or coalesce(old.is_read, false) = false) then
    new.read_at := coalesce(new.read_at, timezone('utc'::text, now()));
  elsif not coalesce(new.is_read, false) then
    new.read_at := null;
  end if;

  if new.created_at is null then
    new.created_at := timezone('utc'::text, now());
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_message_read_state on public.messages;
create trigger trg_sync_message_read_state
before insert or update on public.messages
for each row
execute function public.sync_message_read_state();

create or replace function public.sync_conversation_last_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
  set last_message = left(trim(new.content), 280),
      last_message_at = coalesce(new.created_at, timezone('utc'::text, now())),
      last_message_sender_id = new.sender_id,
      updated_at = timezone('utc'::text, now())
  where id = new.conversation_id;

  return new;
end;
$$;

drop trigger if exists trg_sync_conversation_last_message on public.messages;
create trigger trg_sync_conversation_last_message
after insert on public.messages
for each row
execute function public.sync_conversation_last_message();

create or replace function public.push_direct_message_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient_id uuid;
  sender_name text;
begin
  select participant
  into recipient_id
  from public.conversations c
  cross join lateral unnest(c.participants) as participant
  where c.id = new.conversation_id
    and participant <> new.sender_id
  limit 1;

  if recipient_id is null then
    return new;
  end if;

  select coalesce(nullif(trim(name), ''), 'Someone')
  into sender_name
  from public.users
  where id = new.sender_id;

  insert into public.notifications(to_uid, from_uid, type, message)
  values (
    recipient_id,
    new.sender_id,
    'message',
    sender_name || ' sent you a message'
  );

  return new;
end;
$$;

drop trigger if exists trg_push_direct_message_notification on public.messages;
create trigger trg_push_direct_message_notification
after insert on public.messages
for each row
execute function public.push_direct_message_notification();

create or replace function public.get_or_create_direct_conversation(
  p_other_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  existing_conversation public.conversations%rowtype;
  created_conversation public.conversations%rowtype;
  sorted_participants uuid[];
  conversation_participant_key text;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  if p_other_user_id is null then
    raise exception 'A recipient is required';
  end if;

  if p_other_user_id = actor_id then
    raise exception 'You cannot message yourself';
  end if;

  if not exists (
    select 1
    from public.users
    where id = p_other_user_id
  ) then
    raise exception 'Recipient not found';
  end if;

  select array_agg(participant order by participant::text)
  into sorted_participants
  from unnest(array[actor_id, p_other_user_id]) as participant;

  conversation_participant_key := sorted_participants[1]::text || ':' || sorted_participants[2]::text;

  select *
  into existing_conversation
  from public.conversations
  where public.conversations.participant_key = conversation_participant_key
  limit 1;

  if existing_conversation.id is not null then
    return to_jsonb(existing_conversation);
  end if;

  insert into public.conversations(participants)
  values (sorted_participants)
  on conflict (participant_key) do update
    set participant_key = excluded.participant_key
  returning * into created_conversation;

  return to_jsonb(created_conversation);
end;
$$;

grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;

create or replace function public.send_direct_message(
  p_conversation_id uuid,
  p_content text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  conversation_row public.conversations%rowtype;
  new_message public.messages%rowtype;
  trimmed_content text;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  trimmed_content := trim(coalesce(p_content, ''));
  if trimmed_content = '' then
    raise exception 'Message cannot be empty';
  end if;

  select *
  into conversation_row
  from public.conversations
  where id = p_conversation_id;

  if conversation_row.id is null then
    raise exception 'Conversation not found';
  end if;

  if not actor_id = any(conversation_row.participants) then
    raise exception 'You are not allowed to send messages to this conversation';
  end if;

  perform public.register_rate_limited_action(
    'send_direct_message',
    180,
    3600,
    p_conversation_id::text
  );

  insert into public.messages(conversation_id, sender_id, content)
  values (p_conversation_id, actor_id, trimmed_content)
  returning * into new_message;

  return to_jsonb(new_message);
end;
$$;

grant execute on function public.send_direct_message(uuid, text) to authenticated;

create or replace function public.mark_conversation_messages_read(
  p_conversation_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  conversation_row public.conversations%rowtype;
  updated_count integer := 0;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into conversation_row
  from public.conversations
  where id = p_conversation_id;

  if conversation_row.id is null then
    raise exception 'Conversation not found';
  end if;

  if not actor_id = any(conversation_row.participants) then
    raise exception 'You are not allowed to read this conversation';
  end if;

  update public.messages
  set is_read = true,
      read_at = timezone('utc'::text, now())
  where conversation_id = p_conversation_id
    and sender_id <> actor_id
    and coalesce(is_read, false) = false;

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

grant execute on function public.mark_conversation_messages_read(uuid) to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) then
    create publication supabase_realtime;
  end if;
end
$$;

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
      and tablename = 'users'
  ) then
    execute 'alter publication supabase_realtime add table public.users';
  end if;
end
$$;

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
      and tablename = 'notifications'
  ) then
    execute 'alter publication supabase_realtime add table public.notifications';
  end if;
end
$$;

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
      and tablename = 'conversations'
  ) then
    execute 'alter publication supabase_realtime add table public.conversations';
  end if;
end
$$;

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
      and tablename = 'messages'
  ) then
    execute 'alter publication supabase_realtime add table public.messages';
  end if;
end
$$;

create or replace function public.register_rate_limited_action(
  p_action text,
  p_limit integer,
  p_window_seconds integer,
  p_reference_id text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  recent_count integer;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select count(*)
  into recent_count
  from public.rate_limit_events
  where user_id = actor_id
    and action = p_action
    and created_at >= timezone('utc'::text, now()) - make_interval(secs => p_window_seconds);

  if recent_count >= p_limit then
    raise exception 'Rate limit exceeded for %', p_action;
  end if;

  insert into public.rate_limit_events(user_id, action, reference_id)
  values (actor_id, p_action, p_reference_id);
end;
$$;

grant execute on function public.register_rate_limited_action(text, integer, integer, text) to authenticated;

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
    set aura_points = coalesce(aura_points, 0) + p_points
    where id = p_user_id;
    return true;
  end if;

  return false;
end;
$$;

grant execute on function public.award_aura(uuid, text, integer, text, text, uuid, jsonb) to authenticated;

create or replace function public.sync_post_like_count(p_post_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.posts
  set likes_count = (
    select count(*)
    from public.likes
    where post_id = p_post_id
  )
  where id = p_post_id;
$$;

create or replace function public.sync_post_comment_count(p_post_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.posts
  set comments_count = (
    select count(*)
    from public.comments
    where post_id = p_post_id
  )
  where id = p_post_id;
$$;

grant execute on function public.sync_post_like_count(uuid) to authenticated;
grant execute on function public.sync_post_comment_count(uuid) to authenticated;

drop function if exists public.create_post_with_aura(text, text[], text, uuid);

create or replace function public.create_post_with_aura(
  p_content text,
  p_tags text[] default '{}'::text[],
  p_image_url text default '',
  p_quote_post_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  new_post_id uuid;
  normalized_quote_post_id uuid;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  if coalesce(trim(p_content), '') = '' and coalesce(trim(p_image_url), '') = '' then
    raise exception 'Post content or image is required';
  end if;

  if nullif(trim(coalesce(p_quote_post_id, '')), '') is not null then
    if trim(p_quote_post_id) !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      raise exception 'Quoted post reference is invalid';
    end if;

    normalized_quote_post_id := trim(p_quote_post_id)::uuid;
  end if;

  perform public.register_rate_limited_action('create_post', 20, 3600, null);

  insert into public.posts(user_id, content, tags, image_url, quote_post_id)
  values (
    actor_id,
    coalesce(trim(p_content), ''),
    coalesce(p_tags, '{}'::text[]),
    coalesce(trim(p_image_url), ''),
    normalized_quote_post_id
  )
  returning id into new_post_id;

  perform public.award_aura(
    actor_id,
    'create_post',
    10,
    'post',
    new_post_id::text
  );

  return new_post_id;
end;
$$;

grant execute on function public.create_post_with_aura(text, text[], text, text) to authenticated;

create or replace function public.like_post_with_aura(p_post_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  post_owner_id uuid;
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

  -- if post_owner_id = actor_id then
  --   raise exception 'You cannot like your own post';
  -- end if;

  perform public.register_rate_limited_action('like_post', 120, 3600, p_post_id::text);

  insert into public.likes(post_id, user_id)
  values (p_post_id, actor_id)
  on conflict (post_id, user_id) do nothing;

  if not found then
    raise exception 'Post already liked';
  end if;

  perform public.sync_post_like_count(p_post_id);

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
  end if;

  return jsonb_build_object('liked', true);
end;
$$;

grant execute on function public.like_post_with_aura(uuid) to authenticated;

create or replace function public.unlike_post(p_post_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  delete from public.likes
  where post_id = p_post_id
    and user_id = actor_id;

  perform public.sync_post_like_count(p_post_id);

  return jsonb_build_object('liked', false);
end;
$$;

grant execute on function public.unlike_post(uuid) to authenticated;

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
  new_comment_id uuid;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  if coalesce(trim(p_content), '') = '' then
    raise exception 'Comment cannot be empty';
  end if;

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

  return new_comment_id;
end;
$$;

grant execute on function public.add_comment_with_aura(uuid, text) to authenticated;

create or replace function public.list_events_with_eligibility()
returns table (
  id uuid,
  title text,
  description text,
  required_aura bigint,
  link text,
  type text,
  unlocked boolean,
  locked boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  actor_aura bigint;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select coalesce(aura_points, aura, 0)
  into actor_aura
  from public.users
  where id = actor_id;

  insert into public.user_events(user_id, event_id, unlocked, unlocked_at)
  select
    actor_id,
    e.id,
    actor_aura >= e.required_aura,
    case when actor_aura >= e.required_aura then timezone('utc'::text, now()) else null end
  from public.events e
  where e.is_active = true
  on conflict (user_id, event_id) do update
  set unlocked = excluded.unlocked,
      unlocked_at = case
        when excluded.unlocked and public.user_events.unlocked_at is null then excluded.unlocked_at
        else public.user_events.unlocked_at
      end,
      updated_at = timezone('utc'::text, now());

  return query
  select
    e.id,
    e.title,
    e.description,
    e.required_aura,
    e.link,
    e.type,
    (actor_aura >= e.required_aura) as unlocked,
    not (actor_aura >= e.required_aura) as locked
  from public.events e
  where e.is_active = true
  order by e.required_aura asc, e.created_at desc;
end;
$$;

grant execute on function public.list_events_with_eligibility() to authenticated;

create or replace function public.assign_daily_challenge(
  p_requested_stack text default null
)
returns public.user_challenges
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  today_utc date;
  user_stack_value text;
  selected_stack text;
  existing_assignment public.user_challenges%rowtype;
  chosen_challenge_id uuid;
  created_assignment public.user_challenges%rowtype;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  today_utc := timezone('utc'::text, now())::date;

  select *
  into existing_assignment
  from public.user_challenges
  where user_id = actor_id
    and assigned_date = today_utc;

  if existing_assignment.id is not null then
    return existing_assignment;
  end if;

  select coalesce(nullif(p_requested_stack, ''), nullif(stack[1], ''), 'General')
  into user_stack_value
  from public.users
  where id = actor_id;

  selected_stack := coalesce(user_stack_value, 'General');

  select id
  into chosen_challenge_id
  from public.challenges
  where is_active = true
    and publish_date = today_utc
    and lower(tech_stack) = lower(selected_stack)
  order by created_at desc
  limit 1;

  if chosen_challenge_id is null then
    select id
    into chosen_challenge_id
    from public.challenges
    where is_active = true
      and publish_date = today_utc
      and lower(tech_stack) = 'general'
    order by created_at desc
    limit 1;
  end if;

  if chosen_challenge_id is null then
    select id
    into chosen_challenge_id
    from public.challenges
    where is_active = true
      and publish_date = today_utc
    order by created_at desc
    limit 1;
  end if;

  if chosen_challenge_id is null then
    raise exception 'No active challenge is available for today';
  end if;

  insert into public.user_challenges(
    user_id,
    challenge_id,
    assigned_date,
    selected_tech_stack
  )
  values (
    actor_id,
    chosen_challenge_id,
    today_utc,
    selected_stack
  )
  returning * into created_assignment;

  return created_assignment;
end;
$$;

grant execute on function public.assign_daily_challenge(text) to authenticated;

create or replace function public.complete_daily_challenge(
  p_submission_text text default '',
  p_submission_link text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  today_utc date;
  assignment_row public.user_challenges%rowtype;
  reward_points integer;
  previous_completion date;
  next_streak integer;
  next_longest integer;
  bonus_points integer := 0;
  awarded_badge boolean := false;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  today_utc := timezone('utc'::text, now())::date;

  select *
  into assignment_row
  from public.user_challenges
  where user_id = actor_id
    and assigned_date = today_utc
  limit 1;

  if assignment_row.id is null then
    raise exception 'No daily challenge assigned for today';
  end if;

  if assignment_row.completed then
    raise exception 'Challenge already completed for today';
  end if;

  if coalesce(trim(p_submission_text), '') = '' and coalesce(trim(p_submission_link), '') = '' then
    raise exception 'Submission text or link is required';
  end if;

  select points_reward
  into reward_points
  from public.challenges
  where id = assignment_row.challenge_id;

  update public.user_challenges
  set completed = true,
      completed_at = timezone('utc'::text, now()),
      submission_text = coalesce(trim(p_submission_text), ''),
      submission_link = coalesce(trim(p_submission_link), '')
  where id = assignment_row.id;

  perform public.award_aura(
    actor_id,
    'complete_daily_challenge',
    coalesce(reward_points, 20),
    'daily_challenge',
    assignment_row.id::text
  );

  select last_challenge_completed_on
  into previous_completion
  from public.users
  where id = actor_id;

  if previous_completion = today_utc - 1 then
    select coalesce(current_streak, 0) + 1, greatest(coalesce(longest_streak, 0), coalesce(current_streak, 0) + 1)
    into next_streak, next_longest
    from public.users
    where id = actor_id;
  else
    next_streak := 1;
    select greatest(coalesce(longest_streak, 0), 1)
    into next_longest
    from public.users
    where id = actor_id;
  end if;

  update public.users
  set current_streak = next_streak,
      longest_streak = next_longest,
      last_challenge_completed_on = today_utc
  where id = actor_id;

  if next_streak = 3 then
    bonus_points := 10;
    perform public.award_aura(
      actor_id,
      'three_day_streak_bonus',
      bonus_points,
      'streak_bonus',
      today_utc::text
    );
  elsif next_streak = 7 then
    bonus_points := 25;
    perform public.award_aura(
      actor_id,
      'seven_day_streak_bonus',
      bonus_points,
      'streak_bonus',
      today_utc::text
    );

    insert into public.user_badges(user_id, badge_key, badge_name)
    values (actor_id, 'seven_day_streak', '7 Day Streak')
    on conflict (user_id, badge_key) do nothing;

    awarded_badge := true;
  end if;

  return jsonb_build_object(
    'completed', true,
    'currentStreak', next_streak,
    'longestStreak', next_longest,
    'bonusPoints', bonus_points,
    'badgeAwarded', awarded_badge
  );
end;
$$;

grant execute on function public.complete_daily_challenge(text, text) to authenticated;

create or replace function public.refresh_user_streak_if_needed()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  last_completion date;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select last_challenge_completed_on
  into last_completion
  from public.users
  where id = actor_id;

  if last_completion is null or last_completion < timezone('utc'::text, now())::date - 1 then
    update public.users
    set current_streak = 0
    where id = actor_id;
  end if;

  return (
    select jsonb_build_object(
      'currentStreak', current_streak,
      'longestStreak', longest_streak,
      'lastChallengeCompletedOn', last_challenge_completed_on,
      'auraPoints', aura_points,
      'level', public.get_aura_level(aura_points)
    )
    from public.users
    where id = actor_id
  );
end;
$$;

grant execute on function public.refresh_user_streak_if_needed() to authenticated;

create or replace function public.get_user_aura_summary(p_user_id uuid default auth.uid())
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
begin
  target_user_id := coalesce(p_user_id, auth.uid());
  if target_user_id is null then
    raise exception 'Authentication required';
  end if;

  return (
    select jsonb_build_object(
      'userId', u.id,
      'auraPoints', coalesce(u.aura_points, u.aura, 0),
      'level', public.get_aura_level(coalesce(u.aura_points, u.aura, 0)),
      'currentStreak', coalesce(u.current_streak, 0),
      'longestStreak', coalesce(u.longest_streak, 0),
      'lastChallengeCompletedOn', u.last_challenge_completed_on,
      'badges', coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'key', badge_key,
              'name', badge_name,
              'awardedAt', awarded_at
            )
          )
          from public.user_badges
          where user_id = u.id
        ),
        '[]'::jsonb
      )
    )
    from public.users u
    where u.id = target_user_id
  );
end;
$$;

grant execute on function public.get_user_aura_summary(uuid) to authenticated;

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

  perform public.award_aura(
    reply_owner_id,
    'answer_accepted',
    15,
    'accepted_answer',
    p_reply_id::text,
    question_owner_id,
    jsonb_build_object('questionId', p_question_id)
  );

  return p_reply_id;
end;
$$;

grant execute on function public.mark_question_reply_solved(uuid, uuid) to authenticated;

alter table public.aura_ledger enable row level security;
alter table public.rate_limit_events enable row level security;
alter table public.events enable row level security;
alter table public.user_events enable row level security;
alter table public.challenges enable row level security;
alter table public.user_challenges enable row level security;
alter table public.user_badges enable row level security;
alter table public.founder_devices enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'aura_ledger'
      and policyname = 'aura_ledger_select_owner'
  ) then
    create policy aura_ledger_select_owner
      on public.aura_ledger
      for select
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
      and tablename = 'founder_devices'
      and policyname = 'founder_devices_select_owner'
  ) then
    create policy founder_devices_select_owner
      on public.founder_devices
      for select
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
      and tablename = 'rate_limit_events'
      and policyname = 'rate_limit_events_select_owner'
  ) then
    create policy rate_limit_events_select_owner
      on public.rate_limit_events
      for select
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
      and tablename = 'events'
      and policyname = 'events_select_authenticated'
  ) then
    create policy events_select_authenticated
      on public.events
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
      and tablename = 'events'
      and policyname = 'events_insert_authenticated'
  ) then
    create policy events_insert_authenticated
      on public.events
      for insert
      to authenticated
      with check (auth.uid() = created_by or created_by is null);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_events'
      and policyname = 'user_events_select_owner'
  ) then
    create policy user_events_select_owner
      on public.user_events
      for select
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
      and tablename = 'challenges'
      and policyname = 'challenges_select_authenticated'
  ) then
    create policy challenges_select_authenticated
      on public.challenges
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
      and tablename = 'user_challenges'
      and policyname = 'user_challenges_select_owner'
  ) then
    create policy user_challenges_select_owner
      on public.user_challenges
      for select
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
      and tablename = 'user_badges'
      and policyname = 'user_badges_select_owner'
  ) then
    create policy user_badges_select_owner
      on public.user_badges
      for select
      to authenticated
      using (auth.uid() = user_id);
  end if;
end
$$;
