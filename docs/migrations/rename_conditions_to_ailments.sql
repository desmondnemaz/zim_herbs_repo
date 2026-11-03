-- ============================================================================
-- Migration: Full Nomenclature Rename 'conditions' -> 'ailments'
-- Purpose:
--   1. Rename table 'conditions' to 'ailments'.
--   2. Rename junction table 'condition_body_parts' to 'ailment_body_parts'.
--   3. Rename foreign key columns:
--        ailment_body_parts.condition_id -> ailment_id
--        remedies.condition_id           -> ailment_id
--   4. Update indexes and foreign key constraints for integrity.
--   5. Enable Row Level Security (RLS) and recreate public access policies on 'ailments'.
-- ============================================================================

-- Step 1: Rename the main 'conditions' table to 'ailments'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'conditions'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'ailments'
    ) THEN
        ALTER TABLE public.conditions RENAME TO ailments;
    END IF;
END $$;

-- Step 2: Rename the junction table 'condition_body_parts' to 'ailment_body_parts'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'condition_body_parts'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'ailment_body_parts'
    ) THEN
        ALTER TABLE public.condition_body_parts RENAME TO ailment_body_parts;
    END IF;
END $$;

-- Step 3: Rename condition_id column to ailment_id in 'ailment_body_parts'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'ailment_body_parts' 
          AND column_name = 'condition_id'
    ) THEN
        ALTER TABLE public.ailment_body_parts RENAME COLUMN condition_id TO ailment_id;
    END IF;
END $$;

-- Step 4: Rename condition_id column to ailment_id in 'remedies'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'remedies' 
          AND column_name = 'condition_id'
    ) THEN
        ALTER TABLE public.remedies RENAME COLUMN condition_id TO ailment_id;
    END IF;
END $$;

-- Step 5: Update indexes
CREATE INDEX IF NOT EXISTS idx_ailments_name ON public.ailments(name);
CREATE INDEX IF NOT EXISTS idx_ailments_category ON public.ailments(ailment_category);
CREATE INDEX IF NOT EXISTS idx_ailment_body_parts_ailment_id ON public.ailment_body_parts(ailment_id);
CREATE INDEX IF NOT EXISTS idx_ailment_body_parts_body_part_id ON public.ailment_body_parts(body_part_id);
CREATE INDEX IF NOT EXISTS idx_remedies_ailment_id ON public.remedies(ailment_id);

-- Step 6: Configure Row Level Security (RLS) on 'ailments' & 'ailment_body_parts'
ALTER TABLE public.ailments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ailment_body_parts ENABLE ROW LEVEL SECURITY;

-- Allow public read access to ailments
DROP POLICY IF EXISTS "Public can view ailments" ON public.ailments;
CREATE POLICY "Public can view ailments" 
  ON public.ailments FOR SELECT 
  USING (true);

-- Allow authenticated users / moderators to insert and update ailments
DROP POLICY IF EXISTS "Authenticated users can manage ailments" ON public.ailments;
CREATE POLICY "Authenticated users can manage ailments" 
  ON public.ailments FOR ALL 
  TO authenticated 
  USING (true)
  WITH CHECK (true);

-- Allow public read access to ailment body parts
DROP POLICY IF EXISTS "Public can view ailment body parts" ON public.ailment_body_parts;
CREATE POLICY "Public can view ailment body parts" 
  ON public.ailment_body_parts FOR SELECT 
  USING (true);

-- Allow authenticated users to manage ailment body parts
DROP POLICY IF EXISTS "Authenticated users can manage ailment body parts" ON public.ailment_body_parts;
CREATE POLICY "Authenticated users can manage ailment body parts" 
  ON public.ailment_body_parts FOR ALL 
  TO authenticated 
  USING (true)
  WITH CHECK (true);
