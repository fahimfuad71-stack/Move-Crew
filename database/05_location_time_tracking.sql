-- =========================================================
-- PHASE 5: LOCATION + TIME TRACKING
-- =========================================================

CREATE TABLE IF NOT EXISTS public.mover_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES public.assignments(id) ON DELETE CASCADE,
  mover_id UUID NOT NULL REFERENCES public.movers(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy DOUBLE PRECISION,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.time_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES public.assignments(id) ON DELETE CASCADE,
  mover_id UUID NOT NULL REFERENCES public.movers(id) ON DELETE CASCADE,
  clock_in_at TIMESTAMPTZ,
  clock_out_at TIMESTAMPTZ,
  status TEXT DEFAULT 'ACTIVE' -- ACTIVE/COMPLETED
);

-- Realtime Setup
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'mover_locations') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE mover_locations;
    END IF;
END $$;

ALTER TABLE public.mover_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_logs ENABLE ROW LEVEL SECURITY;

-- Location RLS
CREATE POLICY "Movers insert locations" ON public.mover_locations FOR INSERT WITH CHECK (auth.uid() = mover_id);
CREATE POLICY "Involved view locations" ON public.mover_locations FOR SELECT USING (auth.uid() = mover_id OR EXISTS (SELECT 1 FROM public.assignments a JOIN public.jobs j ON a.job_id = j.id WHERE a.id = mover_locations.assignment_id AND j.customer_id = auth.uid()));

-- Time Log RLS
CREATE POLICY "Movers manage time logs" ON public.time_logs FOR ALL USING (auth.uid() = mover_id);

-- Start/Stop Job RPCs
CREATE OR REPLACE FUNCTION public.mover_start_job(p_assignment_id UUID) RETURNS VOID AS $$
BEGIN
  INSERT INTO public.time_logs (assignment_id, mover_id, clock_in_at, status)
  SELECT id, mover_id, NOW(), 'ACTIVE' FROM public.assignments WHERE id = p_assignment_id AND mover_id = auth.uid();
  UPDATE public.jobs SET status = 'IN_PROGRESS' WHERE id = (SELECT job_id FROM public.assignments WHERE id = p_assignment_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.mover_stop_job(p_assignment_id UUID) RETURNS VOID AS $$
BEGIN
  UPDATE public.time_logs SET clock_out_at = NOW(), status = 'COMPLETED' WHERE assignment_id = p_assignment_id AND mover_id = auth.uid() AND status = 'ACTIVE';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
