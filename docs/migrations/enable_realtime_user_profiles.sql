-- ============================================================================
-- Migration: Enable Supabase Realtime on 'user_profiles'
-- Purpose: Push profile/role changes (is_admin, is_moderator, is_active, ...)
--          to every open app session so privilege changes apply without a
--          restart or re-login. See .agents/rules/realtime_sync_rules.md.
-- Security: Realtime respects existing RLS SELECT policies — subscribers only
--           receive rows they are already allowed to read.
-- Status: Applied manually in the Supabase SQL editor on 2026-11-02.
-- ============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.user_profiles;

-- Rollback:
-- ALTER PUBLICATION supabase_realtime DROP TABLE public.user_profiles;
