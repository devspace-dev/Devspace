-- ==============================================================================
-- DEVSPACE LAUNCH INDEXES VERIFICATION CHECK (Read-Only)
-- Purpose: Verify that all launch critical performance indexes are present.
-- ==============================================================================

SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname IN (
    'idx_posts_created_at_desc',
    'idx_posts_user_created_at',
    'idx_messages_conversation_created',
    'idx_users_aura_created',
    'idx_notifications_to_uid_created',
    'idx_comments_post_created',
    'idx_follows_following_follower',
    'idx_follows_follower_created'
  )
ORDER BY tablename, indexname;
