-- ============================================================================
-- 12_events_dates.sql
-- READ-ONLY CHECK FOR EVENTS TABLE COLUMNS AND DATE BOUNDARIES
-- ============================================================================

-- 1. Check Events Table Columns and Data Types
select 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
from information_schema.columns
where table_schema = 'public' 
  and table_name = 'events'
order by ordinal_position;

-- 2. Min and Max Values for All Date-Related Columns
select
  min(date) as min_date_text,
  max(date) as max_date_text,
  min(end_date) as min_end_date_text,
  max(end_date) as max_end_date_text,
  min(created_at) as min_created_at,
  max(created_at) as max_created_at,
  min(updated_at) as min_updated_at,
  max(updated_at) as max_updated_at
from public.events;

-- 3. Sample 5 Active Events with Dates
select
  id,
  title,
  type,
  date,
  end_date,
  is_active,
  created_at
from public.events
where is_active = true
limit 5;
