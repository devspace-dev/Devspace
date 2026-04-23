-- 1. Create Storage Bucket for images if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
SELECT 'images', 'images', true
WHERE NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'images'
);

-- 2. Allow public access to images (SELECT)
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access" ON storage.objects
  FOR SELECT USING (bucket_id = 'images');

-- 3. Allow authenticated users to upload images
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;
CREATE POLICY "Authenticated Upload" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'images');

-- 4. Allow users to update/delete their own uploads
DROP POLICY IF EXISTS "User Update Own" ON storage.objects;
CREATE POLICY "User Update Own" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'images' AND auth.uid() = owner);

DROP POLICY IF EXISTS "User Delete Own" ON storage.objects;
CREATE POLICY "User Delete Own" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'images' AND auth.uid() = owner);

-- 5. Messaging RPC hardening
-- This function ensures message insertion and conversation updates happen atomically.
DROP FUNCTION IF EXISTS public.send_direct_message(uuid, text);

CREATE OR REPLACE FUNCTION public.send_direct_message(
  p_conversation_id uuid,
  p_content text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sender_id uuid;
  v_recipient_id uuid;
BEGIN
  v_sender_id := auth.uid();
  
  IF v_sender_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Identify the recipient (the other person in the participants array)
  SELECT CASE 
    WHEN participants[1] = v_sender_id THEN participants[2]
    ELSE participants[1]
  END INTO v_recipient_id
  FROM public.conversations
  WHERE id = p_conversation_id;

  IF v_recipient_id IS NULL THEN
    RAISE EXCEPTION 'Conversation not found or recipient missing';
  END IF;

  -- Insert message
  INSERT INTO public.messages (
    conversation_id,
    sender_id,
    recipient_id,
    content
  ) VALUES (
    p_conversation_id,
    v_sender_id,
    v_recipient_id,
    p_content
  );

  -- Update conversation metadata
  UPDATE public.conversations
  SET 
    last_message = CASE 
      WHEN p_content LIKE '[IMAGE]%' THEN 'Sent an image'
      ELSE p_content
    END,
    last_message_at = now()
  WHERE id = p_conversation_id;

  -- Create notification for recipient
  INSERT INTO public.notifications (
    to_uid,
    from_uid,
    type,
    message,
    payload
  ) VALUES (
    v_recipient_id,
    v_sender_id,
    'message',
    'sent you a message',
    jsonb_build_object('conversation_id', p_conversation_id)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_direct_message(uuid, text) TO authenticated;
