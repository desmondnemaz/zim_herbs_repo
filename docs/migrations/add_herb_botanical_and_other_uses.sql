-- Migration: Add Botanical Fields to Herbs and Create herb_other_uses Table
-- Description:
--   1. Adds botanical metadata columns to public.herbs (scientific_name, family, growth_habit, parts_used, places_found, exotic_status).
--   2. Creates public.herb_other_uses table for non-medicinal uses (food, construction, firewood, cultural, ritual, etc.).
--   3. Establishes audit traceability (created_by, created_at, updated_by, updated_at).
--   4. Creates performance indexes for fast filtering and searching.
--   5. Configures Row-Level Security (RLS) policies for public reading and authenticated management.

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Extend public.herbs table with botanical and ecological fields
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.herbs 
  ADD COLUMN IF NOT EXISTS scientific_name TEXT,
  ADD COLUMN IF NOT EXISTS family TEXT,
  ADD COLUMN IF NOT EXISTS growth_habit TEXT,
  ADD COLUMN IF NOT EXISTS parts_used TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS places_found TEXT,
  ADD COLUMN IF NOT EXISTS exotic_status TEXT DEFAULT 'Indigenous';

-- Indexes for botanical queries & search
CREATE INDEX IF NOT EXISTS idx_herbs_scientific_name ON public.herbs(scientific_name);
CREATE INDEX IF NOT EXISTS idx_herbs_family ON public.herbs(family);
CREATE INDEX IF NOT EXISTS idx_herbs_growth_habit ON public.herbs(growth_habit);
CREATE INDEX IF NOT EXISTS idx_herbs_exotic_status ON public.herbs(exotic_status);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Create public.herb_other_uses table
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.herb_other_uses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    herb_id UUID NOT NULL REFERENCES public.herbs(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN (
        'food_nutrition',
        'construction_fencing',
        'firewood',
        'cultural_spiritual',
        'ritual',
        'crafts_tools',
        'veterinary',
        'other'
    )),
    title TEXT,
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_by UUID REFERENCES auth.users(id)
);

-- Foreign key & category indexes for rapid joins
CREATE INDEX IF NOT EXISTS idx_herb_other_uses_herb_id ON public.herb_other_uses(herb_id);
CREATE INDEX IF NOT EXISTS idx_herb_other_uses_category ON public.herb_other_uses(category);

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: Configure Row-Level Security (RLS) on public.herb_other_uses
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.herb_other_uses ENABLE ROW LEVEL SECURITY;

-- Allow public read access to other uses
DROP POLICY IF EXISTS "Public can view herb other uses" ON public.herb_other_uses;
CREATE POLICY "Public can view herb other uses" 
  ON public.herb_other_uses FOR SELECT 
  USING (true);

-- Allow authenticated users / moderators to manage other uses
DROP POLICY IF EXISTS "Authenticated users can manage herb other uses" ON public.herb_other_uses;
CREATE POLICY "Authenticated users can manage herb other uses" 
  ON public.herb_other_uses FOR ALL 
  TO authenticated 
  USING (true) 
  WITH CHECK (true);
