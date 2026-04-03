-- DEVSPACE MESSAGING FIX
-- Run this in the Supabase SQL Editor to enable direct messaging functionality.

-- 1. MESSAGING TABLES
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

-- Ensure all columns exist
alter table public.conversations add column if not exists participant_key text;
alter table public.conversations add column if not exists last_message text;
alter table public.conversations add column if not exists last_message_at timestamp with time zone;
alter table public.conversations add column if not exists last_message_sender_id uuid references public.users(id) on delete set null;

create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id uuid references public.users(id) on delete cascade,
  content text not null,
  is_read boolean default false,
  read_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Ensure all columns exist
alter table public.messages add column if not exists is_read boolean default false;
alter table public.messages add column if not exists read_at timestamp with time zone;

-- 2. INDEXES
create unique index if not exists idx_conversations_participant_key on public.conversations(participant_key);
create index if not exists idx_messages_conversation_id on public.messages(conversation_id);
create index if not exists idx_messages_unread_lookup on public.messages(conversation_id, is_read);

-- 3. TRIGGERS & FUNCTIONS
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
  select array_agg(participant order by participant::text)
  into sorted_participants
  from unnest(new.participants) as participant;
  new.participants := sorted_participants;
  new.participant_key := sorted_participants[1]::text || ':' || sorted_participants[2]::text;
  new.updated_at := timezone('utc'::text, now());
  return new;
end;
$$;

drop trigger if exists trg_normalize_direct_message_conversation on public.conversations;
create trigger trg_normalize_direct_message_conversation
before insert or update on public.conversations
for each row
execute function public.normalize_direct_message_conversation();

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

-- 4. RPCs
create or replace function public.get_or_create_direct_conversation(p_other_user_id uuid)
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
  if actor_id is null then raise exception 'Authentication required'; end if;
  if p_other_user_id = actor_id then raise exception 'You cannot message yourself'; end if;

  select array_agg(participant order by participant::text)
  into sorted_participants
  from unnest(array[actor_id, p_other_user_id]) as participant;
  conversation_participant_key := sorted_participants[1]::text || ':' || sorted_participants[2]::text;

  select * into existing_conversation from public.conversations
  where public.conversations.participant_key = conversation_participant_key limit 1;

  if existing_conversation.id is not null then return to_jsonb(existing_conversation); end if;

  insert into public.conversations(participants) values (sorted_participants)
  returning * into created_conversation;
  return to_jsonb(created_conversation);
end;
$$;

create or replace function public.send_direct_message(p_conversation_id uuid, p_content text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  new_message public.messages%rowtype;
begin
  actor_id := auth.uid();
  if actor_id is null then raise exception 'Authentication required'; end if;
  if trim(coalesce(p_content, '')) = '' then raise exception 'Message cannot be empty'; end if;

  insert into public.messages(conversation_id, sender_id, content)
  values (p_conversation_id, actor_id, trim(p_content))
  returning * into new_message;
  return to_jsonb(new_message);
end;
$$;

create or replace function public.mark_conversation_messages_read(p_conversation_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  updated_count integer := 0;
begin
  actor_id := auth.uid();
  update public.messages set is_read = true, read_at = timezone('utc'::text, now())
  where conversation_id = p_conversation_id and sender_id <> actor_id and is_read = false;
  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

-- Grant permissions
grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;
grant execute on function public.send_direct_message(uuid, text) to authenticated;
grant execute on function public.mark_conversation_messages_read(uuid) to authenticated;

-- 5. RLS
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

drop policy if exists "Conversations select" on public.conversations;
create policy "Conversations select" on public.conversations for select to authenticated using (auth.uid() = any(participants));

drop policy if exists "Messages select" on public.messages;
create policy "Messages select" on public.messages for select to authenticated using (
  exists (select 1 from public.conversations where id = conversation_id and auth.uid() = any(participants))
);

drop policy if exists "Messages insert" on public.messages;
create policy "Messages insert" on public.messages for insert to authenticated with check (
  exists (select 1 from public.conversations where id = conversation_id and auth.uid() = any(participants))
);

-- 6. REALTIME
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.conversations;
