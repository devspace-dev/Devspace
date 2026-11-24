-- ==============================================================================
-- DEVSPACE LAUNCH INDEXES PATCH (Stage 7 - Role 2 Backend & Database)
-- Purpose: Optimize p95 query latency under high load for one-college launch.
-- Targets:
--   1. Feed ordering & user profile post queries
--   2. Realtime conversation & message thread retrieval
--   3. Leaderboard & Aura board rank lookups
--   4. User notifications inbox
--   5. Post comments retrieval
-- ==============================================================================

-- 1. Posts index for chronological feed pagination & filtering
CREATE INDEX IF NOT EXISTS idx_posts_created_at_desc
  ON public.posts (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_posts_user_created_at
  ON public.posts (user_id, created_at DESC);

-- 2. Messages index for conversation thread queries
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
  ON public.messages (conversation_id, created_at DESC);

-- 3. Leaderboard / Aura ranking index
CREATE INDEX IF NOT EXISTS idx_users_aura_created
  ON public.users (aura DESC, created_at ASC);

-- 4. User notifications index (queries filter by recipient to_uid)
CREATE INDEX IF NOT EXISTS idx_notifications_to_uid_created
  ON public.notifications (to_uid, created_at DESC);

-- 5. Comments per post index
CREATE INDEX IF NOT EXISTS idx_comments_post_created
  ON public.comments (post_id, created_at ASC);

-- 6. Follows lookup index
CREATE INDEX IF NOT EXISTS idx_follows_following_follower
  ON public.follows (following_id, follower_id);

CREATE INDEX IF NOT EXISTS idx_follows_follower_created
  ON public.follows (follower_id, created_at DESC);
