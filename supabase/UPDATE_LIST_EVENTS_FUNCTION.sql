-- SQL Patch: Update list_events_with_eligibility function to support banner_url, date, location, end_date and organizer.
-- Run this script in the Supabase SQL Editor.

create or replace function public.list_events_with_eligibility()
returns table (
  id uuid,
  title text,
  description text,
  required_aura bigint,
  link text,
  type text,
  unlocked boolean,
  locked boolean,
  banner_url text,
  date text,
  end_date timestamptz,
  location text,
  organizer text
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

  select coalesce(u.aura_points, u.aura, 0)
  into actor_aura
  from public.users u
  where u.id = actor_id;

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
    not (actor_aura >= e.required_aura) as locked,
    e.banner_url,
    e.date,
    e.end_date,
    e.location,
    e.organizer
  from public.events e
  where e.is_active = true
  order by e.required_aura asc, e.created_at desc;
end;
$$;

grant execute on function public.list_events_with_eligibility() to authenticated;
