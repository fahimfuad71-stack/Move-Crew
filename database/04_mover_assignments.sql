-- =========================================================
-- PHASE 4: MOVER ASSIGNMENTS
-- =========================================================

DO $$ BEGIN
    CREATE TYPE public.assignment_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED');
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE TABLE IF NOT EXISTS public.assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  mover_id UUID NOT NULL REFERENCES public.movers(id) ON DELETE CASCADE,
  status public.assignment_status NOT NULL DEFAULT 'PENDING',
  responded_at TIMESTAMPTZ,
  CONSTRAINT assignments_job_mover_unique UNIQUE (job_id, mover_id)
);

ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins view all assignments" ON public.assignments FOR SELECT USING (public.is_admin());
CREATE POLICY "Movers view own assignments" ON public.assignments FOR SELECT USING (mover_id = auth.uid());
CREATE POLICY "Admins view movers" ON public.movers FOR SELECT USING (public.is_admin());

-- Mover Job Visibility Helper
CREATE OR REPLACE FUNCTION public.is_mover_assigned(p_job_id UUID) RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM public.assignments WHERE job_id = p_job_id AND mover_id = auth.uid());
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE POLICY "Movers view assigned jobs" ON public.jobs FOR SELECT USING (public.is_mover_assigned(id));
CREATE POLICY "Movers view assigned items" ON public.job_items FOR SELECT USING (public.is_mover_assigned(job_id));

-- Admin Assign RPC
CREATE OR REPLACE FUNCTION public.admin_assign_movers(p_job_id UUID, p_mover_ids JSONB)
RETURNS TABLE (job_id UUID, job_code TEXT, assigned_count INTEGER, new_status public.job_status) AS $$
DECLARE v_mover_ids UUID[];
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'Admin access required.'; END IF;
  SELECT ARRAY_AGG(DISTINCT value::UUID) INTO v_mover_ids FROM jsonb_array_elements_text(p_mover_ids);

  INSERT INTO public.assignments (job_id, mover_id, status)
  SELECT p_job_id, m_id, 'PENDING' FROM unnest(v_mover_ids) AS m_id
  ON CONFLICT ON CONSTRAINT assignments_job_mover_unique DO UPDATE SET status = 'PENDING', responded_at = NULL WHERE assignments.status = 'REJECTED';

  UPDATE public.jobs SET status = 'ASSIGNED' WHERE id = p_job_id;
  RETURN QUERY SELECT id, jobs.job_code, cardinality(v_mover_ids), status FROM public.jobs WHERE id = p_job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mover Response RPC
CREATE OR REPLACE FUNCTION public.mover_respond_assignment(p_assignment_id UUID, p_decision TEXT)
RETURNS TABLE (assignment_id UUID, job_id UUID, new_status public.assignment_status, responded_at TIMESTAMPTZ) AS $$
BEGIN
  RETURN QUERY UPDATE public.assignments SET status = upper(trim(p_decision))::public.assignment_status, responded_at = NOW()
  WHERE id = p_assignment_id AND mover_id = auth.uid() AND status = 'PENDING'
  RETURNING id, public.assignments.job_id, status, public.assignments.responded_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
