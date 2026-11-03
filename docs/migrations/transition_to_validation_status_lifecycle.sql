-- ==============================================================================
-- Migration: Transition from binary is_approved to RecordValidationStatus Lifecycle
-- Purpose:
--   1. Replace binary is_approved with a multi-stage validation lifecycle:
--      'draft', 'submitted', 'under_review', 'validated', 'published', 'rejected', 'archived'
--   2. Add unpublish audit attribution (unpublished_by, unpublished_at, unpublish_reason)
--   3. Enforce strict Row-Level Security (RLS) so public clients only view 'published' records
-- ==============================================================================

-- 1. Ensure Validation Lifecycle Columns on 'herbs'
ALTER TABLE public.herbs
  ADD COLUMN IF NOT EXISTS validation_status VARCHAR(32) NOT NULL DEFAULT 'submitted',
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
  ADD COLUMN IF NOT EXISTS unpublish_reason TEXT,
  ADD COLUMN IF NOT EXISTS submitted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS published_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS unpublished_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS unpublished_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ;

-- Constraint check for allowed validation status states
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'herbs_validation_status_check'
  ) THEN
    ALTER TABLE public.herbs
      ADD CONSTRAINT herbs_validation_status_check
      CHECK (validation_status IN ('draft', 'submitted', 'under_review', 'validated', 'published', 'rejected', 'archived'));
  END IF;
END $$;

-- Migrate existing data on 'herbs'
UPDATE public.herbs
SET validation_status = 'published',
    published_at = COALESCE(verified_at, updated_at, created_at)
WHERE is_approved IS TRUE AND validation_status != 'published';

UPDATE public.herbs
SET validation_status = 'submitted'
WHERE (is_approved IS FALSE OR is_approved IS NULL) AND validation_status IS NULL;

-- 2. Ensure Validation Lifecycle Columns on 'remedies'
ALTER TABLE public.remedies
  ADD COLUMN IF NOT EXISTS validation_status VARCHAR(32) NOT NULL DEFAULT 'submitted',
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
  ADD COLUMN IF NOT EXISTS unpublish_reason TEXT,
  ADD COLUMN IF NOT EXISTS submitted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS published_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS unpublished_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS unpublished_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'remedies_validation_status_check'
  ) THEN
    ALTER TABLE public.remedies
      ADD CONSTRAINT remedies_validation_status_check
      CHECK (validation_status IN ('draft', 'submitted', 'under_review', 'validated', 'published', 'rejected', 'archived'));
  END IF;
END $$;

-- Migrate existing data on 'remedies'
UPDATE public.remedies
SET validation_status = 'published',
    published_at = COALESCE(approved_at, updated_at, created_at)
WHERE is_approved IS TRUE AND validation_status != 'published';

UPDATE public.remedies
SET validation_status = 'submitted'
WHERE (is_approved IS FALSE OR is_approved IS NULL) AND validation_status IS NULL;

-- 3. Fast Performance Indexes
CREATE INDEX IF NOT EXISTS idx_herbs_validation_status ON public.herbs(validation_status);
CREATE INDEX IF NOT EXISTS idx_remedies_validation_status ON public.remedies(validation_status);

-- 4. Row Level Security: Public Anon Access (Only Published Records Live)
DROP POLICY IF EXISTS "Public users view published herbs only" ON public.herbs;
CREATE POLICY "Public users view published herbs only"
  ON public.herbs
  FOR SELECT
  TO public
  USING (validation_status = 'published');

DROP POLICY IF EXISTS "Public users view published remedies only" ON public.remedies;
CREATE POLICY "Public users view published remedies only"
  ON public.remedies
  FOR SELECT
  TO public
  USING (validation_status = 'published');

