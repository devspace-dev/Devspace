-- FIX FOR MESSAGING RECIPIENT_ID ERROR
-- Run this in the Supabase SQL Editor to fix the "null value in column recipient_id" error.

-- 1. Ensure the recipient_id column exists
alter table public.messages add column if not exists recipient_id uuid references public.users(id) on delete cascade;

-- 2. Update the send_direct_message function to automatically find and set the recipient_id
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
  v_recipient_id uuid;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  trimmed_content := trim(coalesce(p_content, ''));
  if trimmed_content = '' then
    raise exception 'Message cannot be empty';
  end if;

  -- Get conversation details
  select *
  into conversation_row
  from public.conversations
  where id = p_conversation_id;

  if conversation_row.id is null then
    raise exception 'Conversation not found';
  end if;

  -- Security check
  if not actor_id = any(conversation_row.participants) then
    raise exception 'You are not allowed to send messages to this conversation';
  end if;

  -- Find the recipient (the other participant in the direct conversation)
  select participant
  into v_recipient_id
  from unnest(conversation_row.participants) as participant
  where participant <> actor_id
  limit 1;

  if v_recipient_id is null then
    raise exception 'Recipient not found in conversation';
  end if;

  -- Optional: Rate limiting
  -- perform public.register_rate_limited_action('send_direct_message', 180, 3600, p_conversation_id::text);

  -- Insert the message with recipient_id populated
  insert into public.messages(conversation_id, sender_id, recipient_id, content)
  values (p_conversation_id, actor_id, v_recipient_id, trimmed_content)
  returning * into new_message;

  return to_jsonb(new_message);
end;
$$;

grant execute on function public.send_direct_message(uuid, text) to authenticated;
