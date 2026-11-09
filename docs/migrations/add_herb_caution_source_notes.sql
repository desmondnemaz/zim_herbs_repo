-- Migration: Add Caution, Source, and Other Uses Notes to Herbs table
-- Description:
--   1. Adds optional caution, source, and other_uses_notes text columns to public.herbs.
--   2. Adds performance indexes for text search and filtering.
--   3. All columns are NULLABLE, ensuring existing rows remain valid.

ALTER TABLE public.herbs 
  ADD COLUMN IF NOT EXISTS caution TEXT,
  ADD COLUMN IF NOT EXISTS source TEXT,
  ADD COLUMN IF NOT EXISTS other_uses_notes TEXT;

-- Create indexes for fast filtering / searching
CREATE INDEX IF NOT EXISTS idx_herbs_caution ON public.herbs(caution);
CREATE INDEX IF NOT EXISTS idx_herbs_source ON public.herbs(source);

