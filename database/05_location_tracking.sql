-- Phase 5: Location Tracking & Realtime Setup

-- 1. Create Table
CREATE TABLE IF NOT EXISTS public.mover_locations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  assignment_id UUID NOT NULL REFERENCES public.assignments(id) ON DELETE CASCADE,
  mover_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy DOUBLE PRECISION,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Enable Realtime
-- This enables the live map stream in Flutter
ALTER PUBLICATION supabase_realtime ADD TABLE mover_locations;

-- 3. Enable RLS
ALTER TABLE public.mover_locations ENABLE ROW LEVEL SECURITY;

-- 4. Policies
DROP POLICY IF EXISTS "Movers can insert own locations" ON public.mover_locations;
DROP POLICY IF EXISTS "Involved users can view locations" ON public.mover_locations;

CREATE POLICY "Movers can insert own locations"
ON public.mover_locations
FOR INSERT
WITH CHECK (auth.uid() = mover_id);

CREATE POLICY "Involved users can view locations"
ON public.mover_locations
FOR SELECT
USING (
  auth.uid() = mover_id
  OR
  EXISTS (
    SELECT 1 FROM public.assignments a
    JOIN public.jobs j ON a.job_id = j.id
    WHERE a.id = mover_locations.assignment_id
    AND j.customer_id = auth.uid()
  )
);

-- 5. Performance Indexes
CREATE INDEX IF NOT EXISTS mover_locations_assignment_id_idx ON public.mover_locations (assignment_id);
CREATE INDEX IF NOT EXISTS mover_locations_recorded_at_idx ON public.mover_locations (recorded_at DESC);
