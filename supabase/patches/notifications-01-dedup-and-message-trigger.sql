-- ==============================================================================
-- DEVSPACE NOTIFICATION REBUILD: MIGRATION 01
-- File: supabase/patches/notifications-01-dedup-and-message-trigger.sql
-- 
-- 1. Adds message_id to public.notifications with foreign key to public.messages
-- 2. Creates a partial unique index on message_id (type='message' dedup)
-- 3. Updates push_direct_message_notification() to:
--    - Set title = sender_name
--    - Set message = content snippet (up to 100 chars)
--    - Store message_id = new.id
--    - Use ON CONFLICT (message_id) DO NOTHING
-- 4. Re-binds trg_push_direct_message_notification on public.messages
-- 5. Optional historical cleanup queries (commented out)
-- ==============================================================================

-- 1. ADD message_id COLUMN
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS message_id uuid REFERENCES public.messages(id) ON DELETE CASCADE;

-- 2. CREATE PARTIAL UNIQUE INDEX (strictly one notification row per message_id)
CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_message_id_unique
  ON public.notifications(message_id)
  WHERE message_id IS NOT NULL;

-- 3. UPDATED TRIGGER FUNCTION (Option A: Sender name as title, message snippet as body)
CREATE OR REPLACE FUNCTION public.push_direct_message_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  recipient_id uuid;
  sender_name text;
  snippet text;
BEGIN
  -- Determine recipient: the other participant in the conversation
  SELECT participant
  INTO recipient_id
  FROM public.conversations c
  CROSS JOIN LATERAL unnest(c.participants) AS participant
  WHERE c.id = NEW.conversation_id
    AND participant <> NEW.sender_id
  LIMIT 1;

  IF recipient_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Resolve sender display name
  SELECT COALESCE(NULLIF(TRIM(name), ''), 'Someone')
  INTO sender_name
  FROM public.users
  WHERE id = NEW.sender_id;

  -- Create clean snippet of message content (max 100 characters)
  snippet := TRIM(COALESCE(NEW.content, ''));
  IF LENGTH(snippet) > 100 THEN
    snippet := LEFT(snippet, 97) || '...';
  END IF;

  -- Insert notification with sender name as title and content snippet as body
  -- Enforced unique per message_id via idx_notifications_message_id_unique
  INSERT INTO public.notifications(to_uid, from_uid, type, title, message, message_id)
  VALUES (
    recipient_id,
    NEW.sender_id,
    'message',
    sender_name,
    snippet,
    NEW.id
  )
  ON CONFLICT (message_id) WHERE message_id IS NOT NULL DO NOTHING;

  RETURN NEW;
END;
$$;

-- 4. RE-BIND TRIGGER TO public.messages
DROP TRIGGER IF EXISTS trg_push_direct_message_notification ON public.messages;
CREATE TRIGGER trg_push_direct_message_notification
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.push_direct_message_notification();

GRANT EXECUTE ON FUNCTION public.push_direct_message_notification() TO authenticated, service_role;


-- ==============================================================================
-- OPTIONAL SECTION: CLEANUP OF HISTORICAL DUPLICATE MESSAGE NOTIFICATIONS
-- (Run the queries below ONLY if you want to deduplicate past notifications)
-- ==============================================================================

-- Step A (Preview): Run this SELECT to see how many duplicate pairs exist in history
/*
SELECT to_uid, from_uid, date_trunc('minute', created_at) AS time_window, count(*) AS duplicate_count
FROM public.notifications
WHERE type = 'message'
GROUP BY to_uid, from_uid, date_trunc('minute', created_at)
HAVING count(*) > 1
ORDER BY time_window DESC;
*/

-- Step B (Execute Cleanup): Deletes older duplicates, keeping the most recent row per minute window
/*
WITH ranked_dups AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY to_uid, from_uid, type, date_trunc('minute', created_at)
           ORDER BY created_at DESC, id DESC
         ) AS rank
  FROM public.notifications
  WHERE type = 'message'
)
DELETE FROM public.notifications
WHERE id IN (
  SELECT id FROM ranked_dups WHERE rank > 1
);
*/
