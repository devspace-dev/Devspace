-- ==============================================================================
-- DEVSPACE VERIFICATION CHECK 04: NOTIFICATION TRIGGERS DEFINITIONS
-- File: supabase/checks/04_fcm_triggers_definition.sql
-- Run this in Supabase SQL Editor (read-only query).
-- ==============================================================================

SELECT
  t.tgname AS trigger_name,
  pg_get_triggerdef(t.oid, true) AS trigger_definition,
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS function_definition
FROM pg_trigger t
JOIN pg_proc p ON p.oid = t.tgfoid
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'notifications'
  AND NOT t.tgisinternal;
