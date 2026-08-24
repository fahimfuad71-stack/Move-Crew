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
    (SELECT COUNT(DISTINCT job_id) FROM public.assignments WHERE status = 'REJECTED' AND job_id IN (SELECT id FROM public.jobs WHERE status = 'ASSIGNED')) as rejected_count,
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

-- 7. Add Admin Policies for Jobs and Items
DROP POLICY IF EXISTS "Admins view all jobs" ON public.jobs;
CREATE POLICY "Admins view all jobs" ON public.jobs FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "Admins view all items" ON public.job_items;
CREATE POLICY "Admins view all items" ON public.job_items FOR ALL USING (public.is_admin());

-- 8. Add Admin Policy for Time Logs
DROP POLICY IF EXISTS "Admins view all time logs" ON public.time_logs;
CREATE POLICY "Admins view all time logs" ON public.time_logs FOR SELECT USING (public.is_admin());

-- 9. Add Admin Policy for Users Table
DROP POLICY IF EXISTS "Admins view all users" ON public.users;
CREATE POLICY "Admins view all users" ON public.users FOR SELECT USING (public.is_admin());

-- 10. Ensure Mover/Customer consistency when roles change
CREATE OR REPLACE FUNCTION public.sync_user_role_tables()
RETURNS TRIGGER AS $$
DECLARE
    v_employee_code TEXT;
BEGIN
    -- 1. Handle MOVER role
    IF NEW.role = 'mover' THEN
        -- Delete from customers if they were one
        DELETE FROM public.customers WHERE id = NEW.id;

        -- Insert into movers if not exists
        IF NOT EXISTS (SELECT 1 FROM public.movers WHERE id = NEW.id) THEN
            -- Generate a code like MOV-001
            SELECT 'MOV-' || LPAD((COALESCE(MAX(SUBSTRING(employee_code FROM 5)::INT), 0) + 1)::TEXT, 3, '0')
            INTO v_employee_code FROM public.movers;

            INSERT INTO public.movers (id, employee_code) VALUES (NEW.id, v_employee_code);
        END IF;

    -- 2. Handle CUSTOMER role
    ELSIF NEW.role = 'customer' THEN
        -- Delete from movers if they were one
        DELETE FROM public.movers WHERE id = NEW.id;

        -- Insert into customers if not exists
        IF NOT EXISTS (SELECT 1 FROM public.customers WHERE id = NEW.id) THEN
            INSERT INTO public.customers (id) VALUES (NEW.id);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_sync_user_role_tables ON public.users;
CREATE TRIGGER tr_sync_user_role_tables AFTER INSERT OR UPDATE OF role ON public.users
FOR EACH ROW EXECUTE PROCEDURE public.sync_user_role_tables();

-- 11. Migration: Fix existing users who have 'mover' role but no entry in movers table
DO $$
DECLARE
    r RECORD;
    v_employee_code TEXT;
BEGIN
    FOR r IN SELECT id FROM public.users WHERE role = 'mover' AND id NOT IN (SELECT id FROM public.movers) LOOP
        SELECT 'MOV-' || LPAD((COALESCE(MAX(SUBSTRING(employee_code FROM 5)::INT), 0) + 1)::TEXT, 3, '0')
        INTO v_employee_code FROM public.movers;

        INSERT INTO public.movers (id, employee_code) VALUES (r.id, v_employee_code);
    END LOOP;
END $$;

-- 4. Grant access to the view (if using specific roles)
GRANT SELECT ON public.admin_job_stats TO authenticated;
GRANT SELECT ON public.admin_job_stats TO service_role;
