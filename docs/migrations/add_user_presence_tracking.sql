-- ==============================================================================
-- Migration: Add last_seen_at column for Online User Tracking & Presence
-- Purpose:
--   1. Stores persistent timestamp of when each user was last active in the app.
--   2. Combined with Supabase Realtime Presence, this enables both:
--      a) Instant zero-write live connection tracking (via WebSockets).
--      b) Persistent activity history ("Last seen 15 minutes ago") in Postgres.
-- Security:
--   Row-Level Security (RLS) on 'user_profiles' allows authenticated users to
--   update their own rows (id = auth.uid()), so client heartbeats work cleanly.
-- Maintenance:
--   To query active users in SQL:
--     SELECT count(*) FROM public.user_profiles
--     WHERE last_seen_at > now() - INTERVAL '5 minutes';
-- ==============================================================================

-- 1. Add last_seen_at column with default of now()
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ DEFAULT now();

-- 2. Create index on last_seen_at descending for fast queries and admin filtering
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_seen_at
  ON public.user_profiles(last_seen_at DESC);

