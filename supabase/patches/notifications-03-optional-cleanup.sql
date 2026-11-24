-- ==============================================================================
-- DEVSPACE NOTIFICATION CLEANUP: MIGRATION 03 (OPTIONAL)
-- File: supabase/patches/notifications-03-optional-cleanup.sql
-- 
-- Description:
-- Cleans up historical duplicate message notifications created by the client.
-- Before Stage 2, when a message was sent:
--   1. The database trigger created a notification row (with message_id set, title = sender_name).
--   2. The client also called pushNotification() creating a duplicate row (with message_id NULL, title NULL).
--
-- This script:
--   Step 1: SELECT preview of duplicate client-created message notifications that have
--           a sibling row for the same recipient and sender within 5 seconds.
--   Step 2: DELETE query to remove only the redundant client-created rows.
--
-- NOTE: Review Step 1 output first before running Step 2. Do not run without review.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- STEP 1: PREVIEW (Run this query first to inspect duplicate rows)
-- ------------------------------------------------------------------------------
WITH client_rows AS (
  SELECT
    n.id AS duplicate_id,
    n.to_uid,
    n.from_uid,
    n.type,
    n.title AS duplicate_title,
    n.message AS duplicate_message,
    n.created_at AS duplicate_created_at
  FROM public.notifications n
  WHERE n.type = 'message'
    AND n.message_id IS NULL
),
matched_pairs AS (
  SELECT
    c.duplicate_id,
    c.to_uid,
    c.from_uid,
    c.duplicate_title,
    c.duplicate_message,
    c.duplicate_created_at,
    s.id AS sibling_id,
    s.title AS sibling_title,
    s.message AS sibling_message,
    s.message_id AS sibling_message_id,
    s.created_at AS sibling_created_at,
    ROUND(ABS(EXTRACT(EPOCH FROM (c.duplicate_created_at - s.created_at)))::numeric, 3) AS diff_seconds
  FROM client_rows c
  JOIN public.notifications s
    ON s.to_uid = c.to_uid
   AND s.from_uid = c.from_uid
   AND s.type = 'message'
   AND s.id <> c.duplicate_id
   AND s.message_id IS NOT NULL
   AND ABS(EXTRACT(EPOCH FROM (c.duplicate_created_at - s.created_at))) <= 5
)
SELECT *
FROM matched_pairs
ORDER BY duplicate_created_at DESC;


-- ------------------------------------------------------------------------------
-- STEP 2: DELETE (Removes the redundant client-created message notifications)
-- ------------------------------------------------------------------------------
-- Uncomment and run the query below in Supabase SQL editor after verifying Step 1 preview:

/*
DELETE FROM public.notifications n
WHERE n.type = 'message'
  AND n.message_id IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.notifications s
    WHERE s.to_uid = n.to_uid
      AND s.from_uid = n.from_uid
      AND s.type = 'message'
      AND s.id <> n.id
      AND s.message_id IS NOT NULL
      AND ABS(EXTRACT(EPOCH FROM (n.created_at - s.created_at))) <= 5
  );
*/
