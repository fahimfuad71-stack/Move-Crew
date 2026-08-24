-- ============================================================
-- ROLE SETUP UTILITIES
-- Use these in the Supabase SQL Editor to manually set roles.
-- ============================================================

-- 1. PROMOTE TO ADMIN
-- Usage: Replace 'admin@example.com' with the user's email.
/*
DELETE FROM public.customers WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@example.com');
UPDATE public.users SET role = 'admin' WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@example.com');
*/

-- 2. PROMOTE TO MOVER
-- Usage: Replace 'mover@example.com' and 'MOV-001'.
/*
DELETE FROM public.customers WHERE id = (SELECT id FROM auth.users WHERE email = 'mover@example.com');
UPDATE public.users SET role = 'mover' WHERE id = (SELECT id FROM auth.users WHERE email = 'mover@example.com');
INSERT INTO public.movers (id, employee_code) VALUES ((SELECT id FROM auth.users WHERE email = 'mover@example.com'), 'MOV-001');
*/
