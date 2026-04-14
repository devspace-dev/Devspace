-- Create pull requests table
create table if not exists public.question_pull_requests (
  id uuid default gen_random_uuid() primary key,
  question_id uuid references public.questions(id) on delete cascade not null,
  user_id uuid references public.users(id) on delete cascade not null,
  status text default 'pending', -- pending, accepted, rejected
  message text not null default '',
  created_at timestamp with time zone default timezone('utc'::text, now()),
  unique(question_id, user_id)
);

alter table public.question_pull_requests
  add column if not exists question_id uuid references public.questions(id) on delete cascade;
alter table public.question_pull_requests
  add column if not exists user_id uuid references public.users(id) on delete cascade;
alter table public.question_pull_requests
  add column if not exists status text not null default 'pending';
alter table public.question_pull_requests
  add column if not exists message text not null default '';
alter table public.question_pull_requests
  add column if not exists created_at timestamp with time zone default timezone('utc'::text, now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'question_pull_requests_question_id_user_id_key'
  ) then
    alter table public.question_pull_requests
      add constraint question_pull_requests_question_id_user_id_key unique (question_id, user_id);
  end if;
end
$$;

create index if not exists idx_question_pull_requests_question_id
  on public.question_pull_requests(question_id);
create index if not exists idx_question_pull_requests_user_id
  on public.question_pull_requests(user_id);
create index if not exists idx_question_pull_requests_status
  on public.question_pull_requests(status);
create index if not exists idx_question_pull_requests_created_at
  on public.question_pull_requests(created_at desc);

alter table public.question_pull_requests enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'question_pull_requests'
      and policyname = 'question_pull_requests_select_authenticated'
  ) then
    create policy question_pull_requests_select_authenticated
      on public.question_pull_requests
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
      and tablename = 'question_pull_requests'
      and policyname = 'question_pull_requests_insert_owner'
  ) then
    create policy question_pull_requests_insert_owner
      on public.question_pull_requests
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
      and tablename = 'question_pull_requests'
      and policyname = 'question_pull_requests_update_question_owner'
  ) then
    create policy question_pull_requests_update_question_owner
      on public.question_pull_requests
      for update
      to authenticated
      using (
        exists (
          select 1
          from public.questions
          where public.questions.id = question_pull_requests.question_id
            and public.questions.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1
          from public.questions
          where public.questions.id = question_pull_requests.question_id
            and public.questions.user_id = auth.uid()
        )
      );
  end if;
end
$$;

-- Function to check if a user can reply to a question
create or replace function public.can_user_reply(p_question_id uuid, p_user_id uuid)
returns boolean as $$
declare
  is_asker boolean;
  is_accepted_pr boolean;
begin
  -- Check if user is the asker
  select exists (
    select 1 from public.questions where id = p_question_id and user_id = p_user_id
  ) into is_asker;

  if is_asker then
    return true;
  end if;

  -- Check if user has an accepted PR
  select exists (
    select 1 from public.question_pull_requests
    where question_id = p_question_id 
    and user_id = p_user_id 
    and status = 'accepted'
  ) into is_accepted_pr;

  return is_accepted_pr;
end;
$$ language plpgsql security definer set search_path = public;

-- Trigger/Constraint or RLS could be used here, but for simplicity we'll handle it in the application logic
-- and maybe add a check in the add_question_reply RPC if we had one.
-- Since we are using direct inserts from SupabaseService, we should add a check there.
