-- ============================================================================
-- 08_roadmap.sql
-- READ-ONLY DIAGNOSTIC CHECK FOR USER_ROADMAP_PROGRESS TABLE & RLS POLICIES
-- ============================================================================

-- 1. Check if user_roadmap_progress table exists and inspect columns
select 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
from information_schema.columns
where table_schema = 'public' 
  and table_name = 'user_roadmap_progress'
order by ordinal_position;

-- 2. Check unique constraints, primary keys, and foreign keys
select 
  tc.constraint_name, 
  tc.constraint_type, 
  kcu.column_name
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu 
  on tc.constraint_name = kcu.constraint_name
  and tc.table_schema = kcu.table_schema
where tc.table_schema = 'public' 
  and tc.table_name = 'user_roadmap_progress'
order by tc.constraint_type, kcu.ordinal_position;

-- 3. Check existing indexes
select 
  indexname, 
  indexdef
from pg_indexes
where schemaname = 'public' 
  and tablename = 'user_roadmap_progress';

-- 4. Check if Row Level Security (RLS) is enabled
select 
  relname as table_name,
  relrowsecurity as rls_enabled,
  relforcerowsecurity as rls_forced
from pg_class
where relname = 'user_roadmap_progress'
  and relnamespace = 'public'::regnamespace;

-- 5. Inspect all RLS policies on user_roadmap_progress
select 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_expression,
  with_check as with_check_expression
from pg_policies
where schemaname = 'public' 
  and tablename = 'user_roadmap_progress';

-- 6. Check total rows and distribution by roadmap_id
select 
  coalesce(roadmap_id, 'TOTAL') as roadmap,
  status,
  count(*) as completed_node_count
from public.user_roadmap_progress
group by rollup(roadmap_id, status);

-- 7. Check if user_roadmaps table exists (for Stage 1 selection table)
select 
  table_name, 
  table_type
from information_schema.tables
where table_schema = 'public' 
  and table_name = 'user_roadmaps';
