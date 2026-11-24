-- ==============================================================================
-- DEVSPACE VERIFICATION CHECK 03: PART C NOTIFICATIONS TRACE
-- File: supabase/checks/03_part_c_notifications_trace.sql
-- Run this in Supabase SQL Editor (read-only queries).
-- ==============================================================================

-- 1. Recent notification rows (last 20 rows, including message_id if present)
SELECT
  id,
  to_uid,
  from_uid,
  type,
  title,
  message,
  message_id,
  created_at
FROM public.notifications
ORDER BY created_at DESC
LIMIT 20;

-- 2. Check for duplicate notifications for the same recipient in the last 2 hours
SELECT
  to_uid,
  type,
  title,
  message,
  COUNT(*) AS count_of_duplicate_rows,
  ARRAY_AGG(id) AS notification_ids,
  MIN(created_at) AS first_created_at,
  MAX(created_at) AS last_created_at
FROM public.notifications
WHERE created_at >= NOW() - INTERVAL '2 hours'
GROUP BY to_uid, type, title, message
HAVING COUNT(*) > 1
ORDER BY count_of_duplicate_rows DESC;

-- 3. Check for notifications referencing the same message_id
SELECT
  message_id,
  COUNT(*) AS notification_count,
  ARRAY_AGG(id) AS notification_ids,
  ARRAY_AGG(created_at) AS timestamps
FROM public.notifications
WHERE message_id IS NOT NULL
GROUP BY message_id
HAVING COUNT(*) > 1;

-- 4. Check for direct message notifications where message_id IS NULL
SELECT
  COUNT(*) AS dm_notifications_without_message_id
FROM public.notifications
WHERE type = 'message' AND message_id IS NULL;

-- 5. Check active triggers and webhook hooks on public.notifications and public.messages
SELECT
  tgname AS trigger_name,
  relname AS table_name,
  tgenabled AS is_enabled
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('notifications', 'messages')
  AND NOT tgisinternal;
