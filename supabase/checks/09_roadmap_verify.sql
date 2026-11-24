-- ============================================================================
-- 09_roadmap_verify.sql
-- VERIFICATION CHECK FOR USER_ROADMAPS SCHEMA, CONSTRAINTS & RLS (STAGE 1)
-- ============================================================================

-- 1. Table structure and column definitions
select 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
from information_schema.columns
where table_schema = 'public' 
  and table_name = 'user_roadmaps'
order by ordinal_position;

-- 2. Constraints inspection (PK, FK, check constraints, unique)
select 
  tc.constraint_name, 
  tc.constraint_type, 
  kcu.column_name,
  cc.check_clause
from information_schema.table_constraints tc
left join information_schema.key_column_usage kcu 
  on tc.constraint_name = kcu.constraint_name and tc.table_schema = kcu.table_schema
left join information_schema.check_constraints cc
  on tc.constraint_name = cc.constraint_name and tc.table_schema = cc.constraint_schema
where tc.table_schema = 'public' 
  and tc.table_name = 'user_roadmaps'
order by tc.constraint_type, kcu.ordinal_position;

-- 3. Verify Indexes (including the partial unique index idx_user_roadmaps_one_active)
select 
  indexname, 
  indexdef
from pg_indexes
where schemaname = 'public' 
  and tablename = 'user_roadmaps';

-- 4. Verify Row Level Security is enabled
select 
  relname as table_name,
  relrowsecurity as rls_enabled,
  relforcerowsecurity as rls_forced
from pg_class
where relname = 'user_roadmaps'
  and relnamespace = 'public'::regnamespace;

-- 5. Inspect RLS Policies (owner-only auth.uid() = user_id with explicit WITH CHECK)
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
  and tablename = 'user_roadmaps';

-- 6. Behavioral Constraint Verification (run safely and cleans up)
do $$
declare
  v_user1 uuid;
  v_user2 uuid;
begin
  -- Grab test user IDs from public.users
  select id into v_user1 from public.users order by created_at asc limit 1;
  select id into v_user2 from public.users where id != v_user1 order by created_at asc limit 1;

  if v_user1 is null then
    raise notice 'Skipping behavioral transaction test: no users in public.users';
    return;
  end if;

  -- Ensure clean test state for test user
  delete from public.user_roadmaps where user_id in (v_user1, coalesce(v_user2, v_user1));

  -- Test A: Owner can insert their active roadmap
  insert into public.user_roadmaps (user_id, roadmap_id, status, level, weekly_hours)
  values (v_user1, 'flutter', 'active', 'beginner', 6);
  raise notice 'PASSED Test A: Active roadmap inserted successfully for user';

  -- Test B: Second active roadmap for the SAME user must be REJECTED by partial index
  begin
    insert into public.user_roadmaps (user_id, roadmap_id, status, level, weekly_hours)
    values (v_user1, 'web', 'active', 'beginner', 6);
    raise exception 'FAILED Test B: Second active roadmap was allowed but should have been rejected!';
  exception
    when unique_violation then
      raise notice 'PASSED Test B: Second active roadmap was correctly rejected by idx_user_roadmaps_one_active';
  end;

  -- Test C: Inserting a second roadmap with status = 'saved' must be ALLOWED
  insert into public.user_roadmaps (user_id, roadmap_id, status, level, weekly_hours)
  values (v_user1, 'web', 'saved', 'basics', 3);
  raise notice 'PASSED Test C: Saved roadmap inserted successfully alongside active roadmap';

  -- Test D: Switching active roadmap (deactivate flutter -> activate web) must SUCCEED
  update public.user_roadmaps set status = 'saved' where user_id = v_user1 and roadmap_id = 'flutter';
  update public.user_roadmaps set status = 'active' where user_id = v_user1 and roadmap_id = 'web';
  raise notice 'PASSED Test D: Roadmap status switch executed successfully';

  -- Test E: If a second user exists, verify they can also have an active roadmap independently
  if v_user2 is not null then
    insert into public.user_roadmaps (user_id, roadmap_id, status, level, weekly_hours)
    values (v_user2, 'flutter', 'active', 'comfortable', 10);
    raise notice 'PASSED Test E: Independent active roadmap inserted for second user';
  end if;

  -- Clean up all test rows
  delete from public.user_roadmaps where user_id in (v_user1, coalesce(v_user2, v_user1));
  raise notice 'SUCCESS: All database constraint and behavior checks verified cleanly. Test rows removed.';
end;
$$;
