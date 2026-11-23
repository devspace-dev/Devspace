-- supabase/patches/avatars-01-cleanup.sql
-- Migration: Clean up non-URL values (initials like 'AK', 'HR') stored in users.avatar.
-- DevSpace now handles initials fallback locally on the client side.
-- Setting invalid non-URL avatar strings to NULL prevents image load failures.

BEGIN;

UPDATE users
SET avatar = NULL
WHERE avatar IS NOT NULL
  AND trim(avatar) != ''
  AND avatar !~* '^https?://';

COMMIT;
