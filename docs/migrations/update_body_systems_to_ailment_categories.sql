-- ============================================================================
-- Migration: Upgrade Body Systems to 17 Ailment Categories
-- Purpose:
--   1. Create the new PostgreSQL enum 'ailment_category' with all 17 categories.
--   2. Map existing condition data from legacy body systems to the new categories:
--        circulatory       -> heart_blood
--        respiratory       -> respiratory
--        digestive         -> digestive
--        nervous           -> nervous_system
--        musculoskeletal   -> pain_joints
--        immune_endocrine  -> immunity_hormones
--   3. Rename the column in 'conditions' from 'body_system' to 'ailment_category'.
-- ============================================================================

-- Step 1: Create the new ailment_category enum type if it does not already exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ailment_category') THEN
        CREATE TYPE public.ailment_category AS ENUM (
            'heart_blood',
            'respiratory',
            'digestive',
            'nervous_system',
            'pain_joints',
            'immunity_hormones',
            'reproductive_health',
            'sexual_health',
            'skin_wounds',
            'eyes_ears',
            'dental',
            'parasites',
            'fever',
            'child_health',
            'infections',
            'snakebite',
            'other_uses'
        );
    END IF;
END $$;

-- Step 2: Ensure column exists and migrate data safely
DO $$
BEGIN
    -- Check if legacy column 'body_system' exists
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'conditions'
          AND column_name = 'body_system'
    ) THEN
        -- A. Convert column to TEXT first to allow value replacements
        ALTER TABLE public.conditions
          ALTER COLUMN body_system TYPE TEXT USING body_system::TEXT;

        -- B. Map old values to the new enum string representations
        UPDATE public.conditions
        SET body_system = CASE LOWER(TRIM(body_system))
            WHEN 'circulatory' THEN 'heart_blood'
            WHEN 'respiratory' THEN 'respiratory'
            WHEN 'digestive' THEN 'digestive'
            WHEN 'nervous' THEN 'nervous_system'
            WHEN 'musculoskeletal' THEN 'pain_joints'
            WHEN 'immune_endocrine' THEN 'immunity_hormones'
            ELSE COALESCE(body_system, 'heart_blood')
        END;

        -- C. Rename the column from body_system to ailment_category
        ALTER TABLE public.conditions
          RENAME COLUMN body_system TO ailment_category;

        -- D. Cast the column to the new enum type
        ALTER TABLE public.conditions
          ALTER COLUMN ailment_category TYPE public.ailment_category
          USING ailment_category::public.ailment_category;

        -- E. Set a safe default for new rows
        ALTER TABLE public.conditions
          ALTER COLUMN ailment_category SET DEFAULT 'heart_blood'::public.ailment_category;
    ELSIF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'conditions'
          AND column_name = 'ailment_category'
    ) THEN
        -- If neither column exists, create ailment_category column directly
        ALTER TABLE public.conditions
          ADD COLUMN ailment_category public.ailment_category NOT NULL DEFAULT 'heart_blood';
    END IF;
END $$;

-- Step 3: Create an index for performance on ailment_category queries
CREATE INDEX IF NOT EXISTS idx_conditions_ailment_category
  ON public.conditions(ailment_category);
