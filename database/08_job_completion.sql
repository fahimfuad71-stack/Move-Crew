-- Phase 8: Job Completion Workflow

-- 1. Update Jobs Table
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- 2. Update Status Constraint
-- Note: You might need to drop the old constraint first if it has a specific name
-- ALTER TABLE public.jobs DROP CONSTRAINT jobs_status_check;
-- ALTER TABLE public.jobs ADD CONSTRAINT jobs_status_check CHECK (status IN ('REQUESTED', 'APPROVED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'));

-- 3. Completion RPC
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
