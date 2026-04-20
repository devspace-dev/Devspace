-- DEVSPACE SOCIAL STABILIZATION V3
-- This script fixes the "invalid input syntax for type uuid: '19'" error
-- by hardening types and ensuring consistent function signatures.

-- 1. DROP OLD FUNCTIONS (to avoid signature conflicts)
DROP FUNCTION IF EXISTS public.add_comment_with_aura(uuid, text);
DROP FUNCTION IF EXISTS public.award_aura(uuid, text, integer, text, text, uuid);

-- 2. HARDEN AWARD_AURA
-- This function handles aura awarding and logging safely.
CREATE OR REPLACE FUNCTION public.award_aura(
  p_user_id uuid,
  p_action text,
  p_points integer,
  p_reference_type text DEFAULT NULL,
  p_reference_id text DEFAULT NULL,
  p_actor_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 1. Update user's aura
  UPDATE public.users
  SET aura = aura + p_points,
      aura_points = aura_points + p_points,
      updated_at = now()
  WHERE id = p_user_id;

  -- 2. Log the aura transaction (Safe against non-UUID reference IDs)
  -- We use TEXT for reference_id in aura_logs to be safe
  BEGIN
    INSERT INTO public.aura_logs(user_id, action, points, reference_type, reference_id, actor_id)
    VALUES (p_user_id, p_action, p_points, p_reference_type, p_reference_id, p_actor_id);
  EXCEPTION WHEN OTHERS THEN
    -- If aura_logs fails (e.g. table doesn't exist), don't crash the whole thing
    NULL;
  END;
END;
$$;

-- 3. HARDEN ADD_COMMENT_WITH_AURA
-- This function handles comment creation, aura awarding, and notifications.
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
  actor_id uuid;
  actor_name text;
  post_owner_id uuid;
  new_comment_id uuid;
BEGIN
  actor_id := auth.uid();
  
  -- Get actor info
  SELECT name INTO actor_name FROM public.users WHERE id = actor_id;
  actor_name := COALESCE(actor_name, 'A user');

  -- Get post owner
  SELECT user_id INTO post_owner_id FROM public.posts WHERE id = p_post_id;
  
  IF post_owner_id IS NULL THEN
    RAISE EXCEPTION 'Post not found or owner missing.';
  END IF;

  -- 1. Insert comment
  INSERT INTO public.comments(post_id, user_id, content)
  VALUES (p_post_id, actor_id, trim(p_content))
  RETURNING id INTO new_comment_id;

  -- 2. Update post comment count
  UPDATE public.posts 
  SET comments_count = (SELECT count(*) FROM public.comments WHERE post_id = p_post_id) 
  WHERE id = p_post_id;

  -- 3. Award aura to commenter (3 points)
  PERFORM public.award_aura(
    actor_id, 
    'create_comment', 
    3, 
    'comment', 
    new_comment_id::text, 
    actor_id
  );

  -- 4. Notify post owner (if not the same person)
  IF post_owner_id <> actor_id THEN
    INSERT INTO public.notifications(to_uid, from_uid, type, post_id, message)
    VALUES (
      post_owner_id, 
      actor_id, 
      'comment', 
      p_post_id, 
      actor_name || ' commented on your post'
    );
  END IF;
END;
$$;

-- 4. ENSURE RLS FOR LIKES & COMMENTS
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Likes are viewable by everyone" ON public.likes;
CREATE POLICY "Likes are viewable by everyone" ON public.likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can like posts" ON public.likes;
CREATE POLICY "Users can like posts" ON public.likes FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unlike posts" ON public.likes;
CREATE POLICY "Users can unlike posts" ON public.likes FOR DELETE TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Comments are viewable by everyone" ON public.comments;
CREATE POLICY "Comments are viewable by everyone" ON public.comments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can post comments" ON public.comments;
CREATE POLICY "Users can post comments" ON public.comments FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- 5. FINAL CHECK OF NOTIFICATIONS TABLE
-- Ensure the post_id column is correctly typed
ALTER TABLE public.notifications ALTER COLUMN post_id TYPE uuid USING post_id::uuid;
