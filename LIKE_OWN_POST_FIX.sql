-- FIX: ALLOW USERS TO LIKE THEIR OWN POSTS
-- This script removes the restriction in the like_post_with_aura function

CREATE OR REPLACE FUNCTION public.like_post_with_aura(p_post_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  actor_id uuid;
  post_owner_id uuid;
BEGIN
  actor_id := auth.uid();
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT user_id
  INTO post_owner_id
  FROM public.posts
  WHERE id = p_post_id;

  -- 1. Rate limit the action
  PERFORM public.register_rate_limited_action('like_post', 120, 3600, p_post_id::text);

  -- 2. Insert the like (on conflict do nothing)
  INSERT INTO public.likes(post_id, user_id)
  VALUES (p_post_id, actor_id)
  ON CONFLICT (post_id, user_id) DO NOTHING;

  -- 3. Sync the count
  PERFORM public.sync_post_like_count(p_post_id);

  -- 4. Award aura ONLY if the actor is NOT the post owner
  -- (Always allow the like, but don't give "free" aura for liking your own post)
  IF post_owner_id != actor_id THEN
    PERFORM public.award_aura(
      post_owner_id,
      'receive_like',
      2,
      'post_like',
      p_post_id::text,
      actor_id,
      jsonb_build_object('postId', p_post_id)
    );
    
    -- Send notification
    INSERT INTO public.notifications (user_id, from_uid, type, message, post_id)
    VALUES (
      post_owner_id,
      actor_id,
      'like',
      'liked your post',
      p_post_id
    );
  END IF;

  RETURN jsonb_build_object('liked', true);
END;
$function$;
