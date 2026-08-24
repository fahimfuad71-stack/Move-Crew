-- =========================================================
-- PHASE 3: ADMIN AUTHORIZATION
-- =========================================================

CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin');
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Admin RLS Updates
CREATE POLICY "Admins can view all jobs" ON public.jobs FOR SELECT TO authenticated USING (public.is_admin());
CREATE POLICY "Admins can view all items" ON public.job_items FOR SELECT TO authenticated USING (public.is_admin());
CREATE POLICY "Admins can view all profiles" ON public.users FOR SELECT TO authenticated USING (public.is_admin());

-- Review RPC
CREATE OR REPLACE FUNCTION public.admin_review_request(p_job_id UUID, p_decision TEXT)
RETURNS TABLE (job_id UUID, job_code TEXT, new_status public.job_status) AS $$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'Admin access required.'; END IF;

  RETURN QUERY UPDATE public.jobs SET status = upper(trim(p_decision))::public.job_status
  WHERE id = p_job_id AND status = 'REQUESTED'
  RETURNING id, jobs.job_code, status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.admin_review_request TO authenticated;
