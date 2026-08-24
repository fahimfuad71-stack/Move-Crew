-- FIX: Missing completed_at column and admin_job_stats view

-- 1. Add completed_at column to jobs table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'jobs' AND column_name = 'completed_at') THEN
        ALTER TABLE public.jobs ADD COLUMN completed_at TIMESTAMPTZ;
    END IF;
END $$;

-- 2. Create or Update admin_job_stats view
-- This provides aggregated stats for the Admin Dashboard
CREATE OR REPLACE VIEW public.admin_job_stats AS
SELECT
    COUNT(*) FILTER (WHERE status = 'REQUESTED') as requested_count,
    COUNT(*) FILTER (WHERE status = 'APPROVED') as approved_count,
    COUNT(*) FILTER (WHERE status = 'ASSIGNED') as assigned_count,
    COUNT(*) FILTER (WHERE status = 'IN_PROGRESS') as in_progress_count,
    COUNT(*) FILTER (WHERE status = 'COMPLETED') as completed_count,
    COUNT(*) as total_jobs
FROM public.jobs;

-- 3. Ensure complete_job function is correctly defined
CREATE OR REPLACE FUNCTION public.complete_job(p_job_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.jobs
    SET
        status = 'COMPLETED',
        completed_at = NOW()
    WHERE id = p_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Fix Ambiguous job_code in create_move_request
CREATE OR REPLACE FUNCTION public.create_move_request(
    p_pickup_address TEXT,
    p_destination_address TEXT,
    p_move_date DATE,
    p_start_time TIME,
    p_instructions TEXT,
    p_items JSONB
) RETURNS TABLE (job_id UUID, job_code TEXT) AS $$
DECLARE
    v_job_id UUID;
    v_job_code TEXT;
BEGIN
    INSERT INTO public.jobs (customer_id, pickup_address, destination_address, move_date, start_time, instructions, status)
    VALUES (auth.uid(), trim(p_pickup_address), trim(p_destination_address), p_move_date, p_start_time, p_instructions, 'REQUESTED')
    RETURNING id, jobs.job_code INTO v_job_id, v_job_code;

    INSERT INTO public.job_items (job_id, name, quantity)
    SELECT v_job_id, trim(item.name), item.quantity FROM jsonb_to_recordset(p_items) AS item(name TEXT, quantity INTEGER);

    RETURN QUERY SELECT v_job_id, v_job_code;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- 6. Fix Assignment RLS Policy (Allow Customers to view assignments for their jobs)
DROP POLICY IF EXISTS "Assignment view" ON public.assignments;
CREATE POLICY "Assignment view" ON public.assignments FOR SELECT
USING (
    mover_id = auth.uid()
    OR public.is_admin()
    OR EXISTS (
        SELECT 1 FROM public.jobs
        WHERE id = assignments.job_id AND customer_id = auth.uid()
    )
);

-- 4. Grant access to the view (if using specific roles)
GRANT SELECT ON public.admin_job_stats TO authenticated;
GRANT SELECT ON public.admin_job_stats TO service_role;
