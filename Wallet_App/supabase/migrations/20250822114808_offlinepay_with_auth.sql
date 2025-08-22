-- Location: supabase/migrations/20250822114808_offlinepay_with_auth.sql
-- Schema Analysis: Fresh project with no existing schema
-- Integration Type: Complete new schema for payment management system
-- Dependencies: None (fresh project)

-- 1. Types and Core Tables
CREATE TYPE public.user_role AS ENUM ('admin', 'user');
CREATE TYPE public.transaction_type AS ENUM ('sent', 'received');
CREATE TYPE public.transaction_status AS ENUM ('pending', 'completed', 'failed', 'cancelled');

-- Critical intermediary table
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT,
    balance DECIMAL(12, 2) DEFAULT 0.00,
    role public.user_role DEFAULT 'user'::public.user_role,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Contacts/Recipients table
CREATE TABLE public.contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    contact_name TEXT NOT NULL,
    contact_email TEXT,
    contact_phone TEXT,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Transactions table
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    recipient_name TEXT NOT NULL,
    recipient_email TEXT,
    amount DECIMAL(12, 2) NOT NULL,
    description TEXT,
    transaction_type public.transaction_type NOT NULL,
    status public.transaction_status DEFAULT 'pending'::public.transaction_status,
    fee_amount DECIMAL(12, 2) DEFAULT 0.00,
    reference_number TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Essential Indexes
CREATE INDEX idx_user_profiles_user_id ON public.user_profiles(id);
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_contacts_user_id ON public.contacts(user_id);
CREATE INDEX idx_transactions_sender_id ON public.transactions(sender_id);
CREATE INDEX idx_transactions_recipient_id ON public.transactions(recipient_id);
CREATE INDEX idx_transactions_status ON public.transactions(status);
CREATE INDEX idx_transactions_created_at ON public.transactions(created_at);
CREATE INDEX idx_transactions_reference ON public.transactions(reference_number);

-- 3. Functions for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')::public.user_role
  );  
  RETURN NEW;
END;
$$;

-- Function to generate reference numbers
CREATE OR REPLACE FUNCTION public.generate_reference_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    ref_number TEXT;
BEGIN
    ref_number := 'TXN' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8));
    RETURN ref_number;
END;
$$;

-- Function to update user balance
CREATE OR REPLACE FUNCTION public.update_user_balance(user_uuid UUID, amount_change DECIMAL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.user_profiles 
    SET balance = balance + amount_change,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = user_uuid;
END;
$$;

-- 4. Triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger to set reference number
CREATE OR REPLACE FUNCTION public.set_transaction_reference()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.reference_number IS NULL OR NEW.reference_number = '' THEN
        NEW.reference_number := public.generate_reference_number();
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER set_reference_before_insert
    BEFORE INSERT ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION public.set_transaction_reference();

-- 5. RLS Setup
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies using correct patterns

-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for contacts
CREATE POLICY "users_manage_own_contacts"
ON public.contacts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 3: Operation-specific policies for transactions
CREATE POLICY "users_can_view_related_transactions"
ON public.transactions
FOR SELECT
TO authenticated
USING (sender_id = auth.uid() OR recipient_id = auth.uid());

CREATE POLICY "users_can_create_transactions"
ON public.transactions
FOR INSERT
TO authenticated
WITH CHECK (sender_id = auth.uid());

CREATE POLICY "users_can_update_own_transactions"
ON public.transactions
FOR UPDATE
TO authenticated
USING (sender_id = auth.uid())
WITH CHECK (sender_id = auth.uid());

-- 7. Mock Data for Development
DO $$
DECLARE
    user1_uuid UUID := gen_random_uuid();
    user2_uuid UUID := gen_random_uuid();
    user3_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users with required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (user1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'john.doe@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Doe"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sarah.johnson@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Johnson"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user3_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'michael.chen@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Michael Chen"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Update user balances
    UPDATE public.user_profiles SET balance = 2847.50 WHERE id = user1_uuid;
    UPDATE public.user_profiles SET balance = 1520.75 WHERE id = user2_uuid;
    UPDATE public.user_profiles SET balance = 890.25 WHERE id = user3_uuid;

    -- Create contacts
    INSERT INTO public.contacts (user_id, contact_name, contact_email, is_favorite) VALUES
        (user1_uuid, 'Sarah Johnson', 'sarah.johnson@example.com', true),
        (user1_uuid, 'Michael Chen', 'michael.chen@example.com', true),
        (user1_uuid, 'Emma Wilson', 'emma.wilson@example.com', false),
        (user1_uuid, 'David Rodriguez', 'david.rodriguez@example.com', false);

    -- Create sample transactions
    INSERT INTO public.transactions (sender_id, recipient_id, recipient_name, recipient_email, amount, description, transaction_type, status, created_at) VALUES
        (user1_uuid, user2_uuid, 'Sarah Johnson', 'sarah.johnson@example.com', 125.00, 'Coffee meetup payment', 'sent', 'completed', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
        (user3_uuid, user1_uuid, 'John Doe', 'john.doe@example.com', 75.50, 'Lunch split payment', 'received', 'completed', CURRENT_TIMESTAMP - INTERVAL '5 hours'),
        (user1_uuid, null, 'Emma Wilson', 'emma.wilson@example.com', 200.00, 'Rent contribution', 'sent', 'pending', CURRENT_TIMESTAMP - INTERVAL '1 day'),
        (user2_uuid, user1_uuid, 'John Doe', 'john.doe@example.com', 50.00, 'Movie ticket reimbursement', 'received', 'completed', CURRENT_TIMESTAMP - INTERVAL '1 day 3 hours'),
        (user1_uuid, null, 'Lisa Thompson', 'lisa.thompson@example.com', 300.00, 'Utility bill payment', 'sent', 'failed', CURRENT_TIMESTAMP - INTERVAL '2 days');

END $$;