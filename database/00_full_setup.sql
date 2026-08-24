-- COMBINED SQL SETUP FOR PHASES 5-10
-- Run this if you want to apply all recent changes at once.

-- [PHASE 5: LOCATION]
CREATE TABLE IF NOT EXISTS public.mover_locations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  assignment_id UUID NOT NULL REFERENCES public.assignments(id) ON DELETE CASCADE,
  mover_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy DOUBLE PRECISION,
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'mover_locations') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE mover_locations;
    END IF;
END $$;
ALTER TABLE public.mover_locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Movers can insert own locations" ON public.mover_locations;
DROP POLICY IF EXISTS "Involved users can view locations" ON public.mover_locations;
CREATE POLICY "Movers can insert own locations" ON public.mover_locations FOR INSERT WITH CHECK (auth.uid() = mover_id);
CREATE POLICY "Involved users can view locations" ON public.mover_locations FOR SELECT USING (auth.uid() = mover_id OR EXISTS (SELECT 1 FROM public.assignments a JOIN public.jobs j ON a.job_id = j.id WHERE a.id = mover_locations.assignment_id AND j.customer_id = auth.uid()));

-- [PHASE 8: COMPLETION]
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
CREATE OR REPLACE FUNCTION public.complete_job(p_job_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.jobs SET status = 'COMPLETED', completed_at = NOW() WHERE id = p_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- [PHASE 9: REVIEWS]
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) UNIQUE,
    customer_id UUID NOT NULL REFERENCES public.users(id),
    mover_id UUID NOT NULL REFERENCES public.users(id),
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Customers can insert own reviews" ON public.reviews;
DROP POLICY IF EXISTS "Anyone can view reviews" ON public.reviews;
CREATE POLICY "Customers can insert own reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Anyone can view reviews" ON public.reviews FOR SELECT USING (true);
CREATE OR REPLACE VIEW public.mover_ratings AS SELECT mover_id, AVG(rating)::NUMERIC(3,2) as avg_rating, COUNT(*) as total_reviews FROM public.reviews GROUP BY mover_id;

-- [PHASE 10: DASHBOARD]
CREATE OR REPLACE VIEW public.admin_job_summary AS SELECT status, COUNT(*) as total_count FROM public.jobs GROUP BY status;
CREATE OR REPLACE VIEW public.admin_mover_performance AS SELECT u.full_name, m.employee_code, mr.avg_rating, mr.total_reviews, (SELECT COUNT(*) FROM public.assignments a WHERE a.mover_id = m.id AND a.status = 'ACCEPTED') as total_jobs FROM public.movers m JOIN public.users u ON m.id = u.id LEFT JOIN public.mover_ratings mr ON m.id = mr.mover_id;
