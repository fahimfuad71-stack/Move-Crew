-- Phase 10: Admin Dashboard Views

-- 1. Admin Job Summary View
CREATE OR REPLACE VIEW public.admin_job_summary AS
SELECT
    status,
    COUNT(*) as total_count
FROM public.jobs
GROUP BY status;

-- 2. Admin Mover Performance View
CREATE OR REPLACE VIEW public.admin_mover_performance AS
SELECT
    u.full_name,
    m.employee_code,
    mr.avg_rating,
    mr.total_reviews,
    (SELECT COUNT(*) FROM public.assignments a WHERE a.mover_id = m.id AND a.status = 'ACCEPTED') as total_jobs
FROM public.movers m
JOIN public.users u ON m.id = u.id
LEFT JOIN public.mover_ratings mr ON m.id = mr.mover_id;
