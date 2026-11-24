-- ============================================================================
-- 07_events.sql
-- READ-ONLY DIAGNOSTIC CHECK FOR EVENTS TABLE, RECENT SYNC DATA & RLS POLICIES
-- ============================================================================

-- 1. Check Events Table Columns
select 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
from information_schema.columns
where table_schema = 'public' 
  and table_name = 'events'
order by ordinal_position;

-- 2. Check Active RLS Policies on Events Table
select 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public' 
  and tablename = 'events';

-- 3. Total Event Counts & Breakdown
select 
  count(*) as total_events,
  count(*) filter (where is_active = true) as active_events,
  count(*) filter (where is_active = false) as inactive_events,
  count(*) filter (where end_date is not null and end_date < now()) as expired_by_end_date,
  count(*) filter (where end_date is not null and end_date >= now()) as future_by_end_date,
  count(*) filter (where end_date is null) as null_end_date
from public.events;

-- 4. 10 Newest Events (by created_at)
select 
  id,
  type,
  title,
  coalesce(organizer, 'Unknown') as organizer,
  date,
  end_date,
  is_active,
  created_at,
  substring(link from 1 for 40) as link_preview
from public.events
order by created_at desc
limit 10;

-- 5. 10 Oldest Events (by created_at)
select 
  id,
  type,
  title,
  coalesce(organizer, 'Unknown') as organizer,
  date,
  end_date,
  is_active,
  created_at,
  substring(link from 1 for 40) as link_preview
from public.events
order by created_at asc
limit 10;
