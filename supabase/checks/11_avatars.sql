-- ============================================================================
-- 11_avatars.sql
-- READ-ONLY CHECK FOR LEADERBOARD RPC AVATARS
-- ============================================================================

-- Check what get_aura_leaderboard returns for the avatar column for 5 users
select
  id,
  name,
  handle,
  avatar,
  aura
from public.get_aura_leaderboard(null, 5, 'all_time');
