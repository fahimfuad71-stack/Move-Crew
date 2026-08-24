-- Phase 9: Rating & Review System

-- 1. Create Reviews Table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) UNIQUE,
    customer_id UUID NOT NULL REFERENCES public.users(id),
    mover_id UUID NOT NULL REFERENCES public.users(id),
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- 3. Policies
DROP POLICY IF EXISTS "Customers can insert own reviews" ON public.reviews;
DROP POLICY IF EXISTS "Anyone can view reviews" ON public.reviews;

CREATE POLICY "Customers can insert own reviews"
ON public.reviews
FOR INSERT
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Anyone can view reviews"
ON public.reviews
FOR SELECT
USING (true);

-- 4. View for Mover Average Rating
CREATE OR REPLACE VIEW public.mover_ratings AS
SELECT
    mover_id,
    AVG(rating)::NUMERIC(3,2) as avg_rating,
    COUNT(*) as total_reviews
FROM public.reviews
GROUP BY mover_id;
