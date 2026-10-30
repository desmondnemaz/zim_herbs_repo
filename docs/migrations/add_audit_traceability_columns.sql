-- ============================================================================
-- Migration: Add User Actions CRUD Audit Attribution & Traceability
-- Purpose: Track authorship (created_by), modifications (updated_by),
--          and moderation (verified_by, verified_at, moderation_notes).
-- Safety: All statements use IF NOT EXISTS and ON DELETE SET NULL.
-- ============================================================================

-- 1. Add audit columns to 'herbs' table
ALTER TABLE public.herbs
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS moderation_notes TEXT;

-- 2. Add creator and modifier attribution to 'remedies' table
ALTER TABLE public.remedies
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- 3. Add reviewer attribution to 'herbalist_profiles' table
ALTER TABLE public.herbalist_profiles
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS moderation_notes TEXT;

-- 4. Create performance indexes for audit lookups
CREATE INDEX IF NOT EXISTS idx_herbs_created_by ON public.herbs(created_by);
CREATE INDEX IF NOT EXISTS idx_herbs_verified_by ON public.herbs(verified_by);
CREATE INDEX IF NOT EXISTS idx_remedies_created_by ON public.remedies(created_by);
CREATE INDEX IF NOT EXISTS idx_remedies_approved_by ON public.remedies(approved_by);
CREATE INDEX IF NOT EXISTS idx_herbalist_profiles_verified_by ON public.herbalist_profiles(verified_by);

-- 5. Backfill historical records (Optional, safe defaults)
-- For existing rows that are already approved, stamp verified_at with their updated_at/created_at
UPDATE public.herbs
SET verified_at = COALESCE(updated_at, created_at, NOW())
WHERE is_approved = true AND verified_at IS NULL;
