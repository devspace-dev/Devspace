create extension if not exists pgcrypto;

create table if not exists public.missions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  type text not null,
  tech_stack text not null default 'general',
  question text not null,
  options jsonb,
  correct_answer text,
  link text,
  points_reward integer not null default 20,
  publish_date date not null,
  is_active boolean not null default true,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint missions_type_check check (type in ('coding', 'mcq', 'oneword')),
  constraint missions_points_reward_check check (points_reward >= 0),
  constraint missions_payload_check check (
    (
      type = 'coding'
      and coalesce(trim(link), '') <> ''
    ) or (
      type = 'mcq'
      and jsonb_typeof(coalesce(options, '[]'::jsonb)) = 'array'
      and jsonb_array_length(coalesce(options, '[]'::jsonb)) >= 2
      and coalesce(trim(correct_answer), '') <> ''
    ) or (
      type = 'oneword'
      and coalesce(trim(correct_answer), '') <> ''
    )
  )
);

create table if not exists public.user_missions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  mission_id uuid not null references public.missions(id) on delete cascade,
  assigned_date date not null,
  selected_tech_stack text not null default 'general',
  completed boolean not null default false,
  answer_submitted text,
  submission_link text,
  is_correct boolean,
  completed_at timestamp with time zone,
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone('utc'::text, now()),
  constraint user_missions_one_per_day unique (user_id, assigned_date)
);

create index if not exists idx_missions_publish_stack
  on public.missions(publish_date, lower(tech_stack))
  where is_active = true;

create unique index if not exists idx_missions_active_publish_stack_unique
  on public.missions(publish_date, lower(tech_stack))
  where is_active = true;

create index if not exists idx_user_missions_lookup
  on public.user_missions(user_id, assigned_date desc);

create index if not exists idx_user_missions_mission
  on public.user_missions(mission_id);

alter table public.missions enable row level security;
alter table public.user_missions enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'missions'
      and policyname = 'missions_select_authenticated'
  ) then
    create policy missions_select_authenticated
      on public.missions
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
      and tablename = 'missions'
      and policyname = 'missions_insert_admin'
  ) then
    create policy missions_insert_admin
      on public.missions
      for insert
      to authenticated
      with check (
        exists (
          select 1
          from public.users
          where id = auth.uid()
            and is_admin = true
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
      and tablename = 'missions'
      and policyname = 'missions_update_admin'
  ) then
    create policy missions_update_admin
      on public.missions
      for update
      to authenticated
      using (
        exists (
          select 1
          from public.users
          where id = auth.uid()
            and is_admin = true
        )
      )
      with check (
        exists (
          select 1
          from public.users
          where id = auth.uid()
            and is_admin = true
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
      and tablename = 'user_missions'
      and policyname = 'user_missions_select_owner'
  ) then
    create policy user_missions_select_owner
      on public.user_missions
      for select
      to authenticated
      using (auth.uid() = user_id);
  end if;
end
$$;

create or replace function public.assign_daily_mission(
  p_requested_stack text default null
)
returns public.user_missions
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  today_utc date;
  selected_stack text;
  existing_assignment public.user_missions%rowtype;
  chosen_mission_id uuid;
  created_assignment public.user_missions%rowtype;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  today_utc := timezone('utc'::text, now())::date;

  select *
  into existing_assignment
  from public.user_missions
  where user_id = actor_id
    and assigned_date = today_utc;

  if existing_assignment.id is not null then
    return existing_assignment;
  end if;

  select coalesce(
    nullif(trim(p_requested_stack), ''),
    nullif(trim(stack[1]), ''),
    'general'
  )
  into selected_stack
  from public.users
  where id = actor_id;

  selected_stack := coalesce(selected_stack, 'general');

  select id
  into chosen_mission_id
  from public.missions
  where is_active = true
    and publish_date = today_utc
    and lower(tech_stack) = lower(selected_stack)
  limit 1;

  if chosen_mission_id is null then
    select id
    into chosen_mission_id
    from public.missions
    where is_active = true
      and publish_date = today_utc
      and lower(tech_stack) = 'general'
    limit 1;
  end if;

  if chosen_mission_id is null then
    raise exception 'No active mission is available for today';
  end if;

  insert into public.user_missions (
    user_id,
    mission_id,
    assigned_date,
    selected_tech_stack
  )
  values (
    actor_id,
    chosen_mission_id,
    today_utc,
    selected_stack
  )
  returning * into created_assignment;

  return created_assignment;
end;
$$;

grant execute on function public.assign_daily_mission(text) to authenticated;

create or replace function public.submit_daily_mission(
  p_answer_submitted text default '',
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
  assignment_row public.user_missions%rowtype;
  mission_row public.missions%rowtype;
  normalized_answer text;
  normalized_correct_answer text;
  is_answer_correct boolean := false;
  should_complete boolean := false;
  awarded_points integer := 0;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  today_utc := timezone('utc'::text, now())::date;

  select *
  into assignment_row
  from public.user_missions
  where user_id = actor_id
    and assigned_date = today_utc
  for update;

  if assignment_row.id is null then
    raise exception 'No daily mission assigned for today';
  end if;

  if assignment_row.completed then
    raise exception 'Mission already completed for today';
  end if;

  select *
  into mission_row
  from public.missions
  where id = assignment_row.mission_id;

  if mission_row.id is null then
    raise exception 'Mission not found';
  end if;

  normalized_answer := lower(trim(coalesce(p_answer_submitted, '')));
  normalized_correct_answer := lower(trim(coalesce(mission_row.correct_answer, '')));

  if mission_row.type = 'coding' then
    if normalized_answer = '' and trim(coalesce(p_submission_link, '')) = '' then
      raise exception 'Submission text or link is required for coding missions';
    end if;

    is_answer_correct := true;
    should_complete := true;
  elsif mission_row.type = 'mcq' then
    if normalized_answer = '' then
      raise exception 'An answer is required for MCQ missions';
    end if;

    is_answer_correct := normalized_answer = normalized_correct_answer;
    should_complete := is_answer_correct;
  elsif mission_row.type = 'oneword' then
    if normalized_answer = '' then
      raise exception 'An answer is required for one-word missions';
    end if;

    is_answer_correct := normalized_answer = normalized_correct_answer;
    should_complete := is_answer_correct;
  else
    raise exception 'Unsupported mission type';
  end if;

  update public.user_missions
  set answer_submitted = nullif(trim(coalesce(p_answer_submitted, '')), ''),
      submission_link = nullif(trim(coalesce(p_submission_link, '')), ''),
      is_correct = is_answer_correct,
      completed = should_complete,
      completed_at = case
        when should_complete then timezone('utc'::text, now())
        else null
      end,
      updated_at = timezone('utc'::text, now())
  where id = assignment_row.id;

  if should_complete then
    awarded_points := coalesce(mission_row.points_reward, 0);

    perform public.award_aura(
      actor_id,
      'complete_daily_mission',
      awarded_points,
      'daily_mission',
      assignment_row.id::text
    );
  end if;

  return jsonb_build_object(
    'assignmentId', assignment_row.id,
    'missionId', mission_row.id,
    'type', mission_row.type,
    'completed', should_complete,
    'isCorrect', is_answer_correct,
    'pointsAwarded', awarded_points
  );
end;
$$;

grant execute on function public.submit_daily_mission(text, text) to authenticated;

create or replace function public.review_daily_mission(
  p_assignment_id uuid,
  p_is_correct boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  actor_is_admin boolean := false;
  assignment_row public.user_missions%rowtype;
  mission_row public.missions%rowtype;
  awarded_points integer := 0;
begin
  actor_id := auth.uid();
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select is_admin
  into actor_is_admin
  from public.users
  where id = actor_id;

  if coalesce(actor_is_admin, false) = false then
    raise exception 'Only admins can review mission submissions';
  end if;

  select *
  into assignment_row
  from public.user_missions
  where id = p_assignment_id
  for update;

  if assignment_row.id is null then
    raise exception 'Mission assignment not found';
  end if;

  select *
  into mission_row
  from public.missions
  where id = assignment_row.mission_id;

  if mission_row.id is null then
    raise exception 'Mission not found';
  end if;

  if mission_row.type <> 'coding' then
    raise exception 'Only coding missions can be reviewed manually';
  end if;

  if assignment_row.completed then
    raise exception 'Mission already completed';
  end if;

  update public.user_missions
  set is_correct = p_is_correct,
      completed = p_is_correct,
      completed_at = case
        when p_is_correct then timezone('utc'::text, now())
        else null
      end,
      reviewed_by = actor_id,
      reviewed_at = timezone('utc'::text, now()),
      updated_at = timezone('utc'::text, now())
  where id = p_assignment_id;

  if p_is_correct then
    awarded_points := coalesce(mission_row.points_reward, 0);

    perform public.award_aura(
      assignment_row.user_id,
      'complete_daily_mission',
      awarded_points,
      'daily_mission',
      assignment_row.id::text
    );
  end if;

  return jsonb_build_object(
    'assignmentId', assignment_row.id,
    'missionId', mission_row.id,
    'completed', p_is_correct,
    'isCorrect', p_is_correct,
    'pointsAwarded', awarded_points,
    'reviewedBy', actor_id
  );
end;
$$;

grant execute on function public.review_daily_mission(uuid, boolean) to authenticated;
