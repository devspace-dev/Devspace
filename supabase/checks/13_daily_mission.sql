-- ============================================================================
-- 13_daily_mission.sql
-- READ-ONLY DIAGNOSTIC CHECK FOR DAILY MISSIONS & ASSIGNMENT DATA
-- ============================================================================

-- 1. Current Date Context (UTC vs IST / Asia/Kolkata)
select
  timezone('utc'::text, now()) as current_utc_timestamp,
  timezone('utc'::text, now())::date as current_utc_date,
  timezone('Asia/Kolkata'::text, now()) as current_ist_timestamp,
  timezone('Asia/Kolkata'::text, now())::date as current_ist_date;

-- 2. Schema Check: Columns and Data Types for Missions & User Missions Tables
select 
  table_name,
  column_name, 
  data_type, 
  is_nullable, 
  column_default
from information_schema.columns
where table_schema = 'public' 
  and table_name in ('missions', 'user_missions', 'challenges', 'user_challenges')
order by table_name, ordinal_position;

-- 3. Today's Published Missions (Checking missions published for today in IST or UTC)
select
  id,
  title,
  type,
  tech_stack,
  publish_date,
  is_active,
  points_reward,
  created_at
from public.missions
where publish_date in (
  (timezone('Asia/Kolkata'::text, now()))::date,
  (timezone('utc'::text, now()))::date
)
order by publish_date desc;

-- 4. Recent Missions (Last 7 Days) to verify schedule and published inventory
select
  id,
  title,
  type,
  tech_stack,
  publish_date,
  is_active,
  created_at
from public.missions
order by publish_date desc, created_at desc
limit 10;

-- 5. User Assignment / Submission Rows for the Last 3 Days
select
  um.id as user_mission_id,
  um.user_id,
  um.mission_id,
  um.assigned_date,
  um.completed,
  um.completed_at,
  um.is_correct,
  um.review_status,
  m.title as mission_title,
  m.publish_date as mission_publish_date
from public.user_missions um
left join public.missions m on m.id = um.mission_id
where um.assigned_date >= (timezone('Asia/Kolkata'::text, now())::date - 3)
order by um.assigned_date desc, um.created_at desc
limit 20;

-- 6. Also check public.challenges / user_challenges if used as fallback
select
  c.id as challenge_id,
  c.title,
  c.publish_date,
  c.is_active
from public.challenges c
order by c.publish_date desc
limit 5;
