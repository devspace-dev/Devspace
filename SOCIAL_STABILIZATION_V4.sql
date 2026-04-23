-- 1. DROP OLD FUNCTIONS PROGRAMMATICALLY (to resolve "not unique" conflicts)
DO $$ 
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN (
        SELECT 'DROP FUNCTION ' || n.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ');' as cmd
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE p.proname IN ('award_aura', 'add_comment_with_aura')
          AND n.nspname = 'public'
    ) LOOP
        EXECUTE func_record.cmd;
    END LOOP;
END $$;


-- 3. HARDEN ADD_COMMENT_WITH_AURA
-- This function adds a comment and awards aura to the author.
CREATE OR REPLACE FUNCTION public.add_comment_with_aura(
  p_post_id uuid,
  p_content text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_post_owner_id uuid;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Get post owner for notification
  SELECT user_id INTO v_post_owner_id
  FROM public.posts
  WHERE id = p_post_id;

  IF v_post_owner_id IS NULL THEN
    RAISE EXCEPTION 'Post not found';
  END IF;

  -- Insert the comment
  INSERT INTO public.comments (
    post_id,
    user_id,
    content
  ) VALUES (
    p_post_id,
    v_user_id,
    p_content
  );

  -- Award aura to commenter (2 points)
  PERFORM public.award_aura(
    v_user_id::uuid,
    'add_comment'::text,
    2::integer,
    'comment'::text,
    p_post_id::text,
    NULL::uuid
  );

  -- Create notification for post owner (if not the same person)
  IF v_post_owner_id != v_user_id THEN
    INSERT INTO public.notifications (
      to_uid,
      from_uid,
      type,
      post_id,
      message
    ) VALUES (
      v_post_owner_id,
      v_user_id,
      'comment',
      p_post_id,
      'commented on your post'
    );
  END IF;
  
  -- Update post comment count
  UPDATE public.posts
  SET comments_count = comments_count + 1
  WHERE id = p_post_id;
END;
$$;


-- 5. ENSURE LEDGER TABLE EXISTS AND HAS CORRECT COLUMNS
CREATE TABLE IF NOT EXISTS public.aura_ledger (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  action text NOT NULL,
  points integer NOT NULL,
  reference_type text,
  reference_id text,
  actor_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Ensure missing columns are added if the table already existed
ALTER TABLE public.aura_ledger ADD COLUMN IF NOT EXISTS actor_id uuid REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.aura_ledger ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

-- 2. HARDEN AWARD_AURA (Updated to handle metadata)
-- This function handles aura awarding and logging safely.
CREATE OR REPLACE FUNCTION public.award_aura(
  p_user_id uuid,
  p_action text,
  p_points integer,
  p_reference_type text DEFAULT NULL,
  p_reference_id text DEFAULT NULL,
  p_actor_id uuid DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update user aura (handles both aura and aura_points columns if they exist)
  UPDATE public.users
  SET aura = aura + p_points,
      aura_points = coalesce(aura_points, 0) + p_points
  WHERE id = p_user_id;

  -- Log to aura_ledger
  INSERT INTO public.aura_ledger (
    user_id,
    action,
    points,
    reference_type,
    reference_id,
    actor_id,
    metadata
  ) VALUES (
    p_user_id,
    p_action,
    p_points,
    p_reference_type,
    p_reference_id,
    p_actor_id,
    coalesce(p_metadata, '{}'::jsonb)
  );
END;
$$;

-- 4. GRANT PERMISSIONS (Updated)
GRANT EXECUTE ON FUNCTION public.add_comment_with_aura(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.award_aura(uuid, text, integer, text, text, uuid, jsonb) TO authenticated;

ALTER TABLE public.aura_ledger ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own aura ledger" ON public.aura_ledger;
CREATE POLICY "Users can view own aura ledger" ON public.aura_ledger
  FOR SELECT TO authenticated USING (auth.uid() = user_id);
