-- ============================================================================
-- Migration: Add is_active column to 'user_profiles'
-- Purpose: Enable administrative deactivation/reactivation of user accounts
-- Safety: Defaults to true so existing accounts remain active with zero downtime.
-- ============================================================================

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON public.user_profiles(is_active);
