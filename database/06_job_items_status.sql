-- =========================================================
-- PHASE 6: JOB ITEM STATUS
-- =========================================================

CREATE OR REPLACE FUNCTION public.mover_update_item_status(p_item_id BIGINT, p_status job_item_status) RETURNS VOID AS $$
BEGIN
  UPDATE public.job_items SET status = p_status
  WHERE id = p_item_id
  AND EXISTS (SELECT 1 FROM public.assignments a WHERE a.job_id = job_items.job_id AND a.mover_id = auth.uid() AND a.status = 'ACCEPTED')
  AND ((status = 'PENDING' AND p_status = 'COLLECTED') OR (status = 'COLLECTED' AND p_status = 'DELIVERED'));

  IF NOT FOUND THEN RAISE EXCEPTION 'Invalid transition or unauthorized.'; END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.mover_update_item_status TO authenticated;
