-- ============================================================
-- PHASE 1: AUTHENTICATION + ROLES
-- ============================================================

DO $$ BEGIN
    CREATE TYPE public.user_role AS ENUM ('customer', 'admin', 'mover');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT,
  role public.user_role NOT NULL DEFAULT 'customer',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.movers (
  id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  employee_code TEXT UNIQUE NOT NULL
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "Customers can view own customer record" ON public.customers;
CREATE POLICY "Customers can view own customer record" ON public.customers FOR SELECT TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "Movers can view own mover record" ON public.movers;
CREATE POLICY "Movers can view own mover record" ON public.movers FOR SELECT TO authenticated USING (auth.uid() = id);

-- Automatic User Creation Trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, full_name, phone, role)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''), NEW.raw_user_meta_data ->> 'phone', 'customer');

  INSERT INTO public.customers (id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
