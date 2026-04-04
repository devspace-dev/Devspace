-- Create pull requests table
create table question_pull_requests (
  id uuid default gen_random_uuid() primary key,
  question_id uuid references questions(id) on delete cascade not null,
  user_id uuid references users(id) on delete cascade not null,
  status text default 'pending', -- pending, accepted, rejected
  message text not null default '',
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(question_id, user_id)
);

-- Function to check if a user can reply to a question
create or replace function can_user_reply(p_question_id uuid, p_user_id uuid)
returns boolean as $$
declare
  is_asker boolean;
  is_accepted_pr boolean;
begin
  -- Check if user is the asker
  select exists (
    select 1 from questions where id = p_question_id and user_id = p_user_id
  ) into is_asker;

  if is_asker then
    return true;
  end if;

  -- Check if user has an accepted PR
  select exists (
    select 1 from question_pull_requests 
    where question_id = p_question_id 
    and user_id = p_user_id 
    and status = 'accepted'
  ) into is_accepted_pr;

  return is_accepted_pr;
end;
$$ language plpgsql security definer;

-- Trigger/Constraint or RLS could be used here, but for simplicity we'll handle it in the application logic
-- and maybe add a check in the add_question_reply RPC if we had one.
-- Since we are using direct inserts from SupabaseService, we should add a check there.
