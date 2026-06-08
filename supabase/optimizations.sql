-- Optimization migration to stabilize database under load
-- 1. Add missing indices for critical queries and streams
create index if not exists idx_aura_ledger_user_id_created_at on public.aura_ledger(user_id, created_at desc);
create index if not exists idx_notifications_to_uid_read_created_at on public.notifications(to_uid, read, created_at desc);
create index if not exists idx_user_missions_user_id_date on public.user_missions(user_id, assigned_date desc);

-- 2. Ensure Realtime is only used for necessary tables and with proper indices
-- Conversations and messages already have indices.

-- 3. Increase statement timeout slightly to prevent premature failures on cold starts, 
-- but not so much that it holds connections forever.
-- alter role authenticator set statement_timeout = '15s'; 
-- (Note: Only superusers can do this, so we skip for now)

-- 4. Clean up any orphaned conversations (optional, but helps performance)
delete from public.conversations 
where array_length(participants, 1) < 2;
