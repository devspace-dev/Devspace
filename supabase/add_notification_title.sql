-- Add title column to notifications table for FCM push notifications support
alter table public.notifications add column if not exists title text;
