-- Location: supabase/migrations/20250822103112_p2p_payment_system.sql
-- Schema Analysis: Fresh project - no existing schema
-- Integration Type: Complete P2P Payment System
-- Dependencies: None (fresh start)

-- 1. Extensions & Types
CREATE TYPE public.user_role AS ENUM ('standard', 'premium', 'admin');
CREATE TYPE public.transaction_type AS ENUM ('sent', 'received', 'request');
CREATE TYPE public.transaction_status AS ENUM ('pending', 'completed', 'failed', 'cancelled');
CREATE TYPE public.wallet_type AS ENUM ('standard', 'savings', 'business');

-- 2. Core user profiles table (PostgREST compatibility)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT,
    role public.user_role DEFAULT 'standard'::public.user_role,
    is_active BOOLEAN DEFAULT true,
    profile_image_url TEXT,
    qr_code TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Wallet accounts
CREATE TABLE public.wallet_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    account_number TEXT UNIQUE NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00,
    wallet_type public.wallet_type DEFAULT 'standard'::public.wallet_type,
    is_active BOOLEAN DEFAULT true,
    daily_limit DECIMAL(10,2) DEFAULT 5000.00,
    monthly_limit DECIMAL(12,2) DEFAULT 50000.00,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Transaction records
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_number TEXT UNIQUE NOT NULL,
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    receiver_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    sender_wallet_id UUID REFERENCES public.wallet_accounts(id) ON DELETE SET NULL,
    receiver_wallet_id UUID REFERENCES public.wallet_accounts(id) ON DELETE SET NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    transaction_type public.transaction_type NOT NULL,
    transaction_status public.transaction_status DEFAULT 'pending'::public.transaction_status,
    note TEXT,
    reference_code TEXT,
    failure_reason TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. QR payment requests
CREATE TABLE public.payment_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    note TEXT,
    qr_code TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMPTZ,
    used_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Transaction history for offline sync
CREATE TABLE public.offline_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    transaction_data JSONB NOT NULL,
    sync_status TEXT DEFAULT 'pending',
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMPTZ
);

-- 7. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_qr_code ON public.user_profiles(qr_code);
CREATE INDEX idx_wallet_accounts_user_id ON public.wallet_accounts(user_id);
CREATE INDEX idx_wallet_accounts_account_number ON public.wallet_accounts(account_number);
CREATE INDEX idx_transactions_sender_id ON public.transactions(sender_id);
CREATE INDEX idx_transactions_receiver_id ON public.transactions(receiver_id);
CREATE INDEX idx_transactions_status ON public.transactions(transaction_status);
CREATE INDEX idx_transactions_created_at ON public.transactions(created_at DESC);
CREATE INDEX idx_payment_requests_qr_code ON public.payment_requests(qr_code);
CREATE INDEX idx_payment_requests_requester_id ON public.payment_requests(requester_id);
CREATE INDEX idx_offline_transactions_user_id ON public.offline_transactions(user_id);
CREATE INDEX idx_offline_transactions_sync_status ON public.offline_transactions(sync_status);

-- 8. Functions BEFORE RLS Policies
CREATE OR REPLACE FUNCTION public.generate_account_number()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_number TEXT;
    counter INTEGER := 0;
BEGIN
    LOOP
        new_number := 'OPP' || LPAD((EXTRACT(EPOCH FROM NOW())::BIGINT % 10000000)::TEXT, 7, '0');
        
        IF NOT EXISTS (SELECT 1 FROM public.wallet_accounts WHERE account_number = new_number) THEN
            RETURN new_number;
        END IF;
        
        counter := counter + 1;
        IF counter > 100 THEN
            RAISE EXCEPTION 'Unable to generate unique account number after 100 attempts';
        END IF;
        
        PERFORM pg_sleep(0.001);
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_transaction_number()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_number TEXT;
    counter INTEGER := 0;
BEGIN
    LOOP
        new_number := 'TXN' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD((EXTRACT(EPOCH FROM NOW())::BIGINT % 100000)::TEXT, 5, '0');
        
        IF NOT EXISTS (SELECT 1 FROM public.transactions WHERE transaction_number = new_number) THEN
            RETURN new_number;
        END IF;
        
        counter := counter + 1;
        IF counter > 100 THEN
            RAISE EXCEPTION 'Unable to generate unique transaction number after 100 attempts';
        END IF;
        
        PERFORM pg_sleep(0.001);
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_qr_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_code TEXT;
    counter INTEGER := 0;
BEGIN
    LOOP
        new_code := 'QR' || ENCODE(gen_random_bytes(8), 'base64');
        new_code := REPLACE(new_code, '/', '');
        new_code := REPLACE(new_code, '+', '');
        new_code := REPLACE(new_code, '=', '');
        
        IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE qr_code = new_code) 
           AND NOT EXISTS (SELECT 1 FROM public.payment_requests WHERE qr_code = new_code) THEN
            RETURN new_code;
        END IF;
        
        counter := counter + 1;
        IF counter > 100 THEN
            RAISE EXCEPTION 'Unable to generate unique QR code after 100 attempts';
        END IF;
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_wallet_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.transaction_status = 'completed' AND OLD.transaction_status != 'completed' THEN
        -- Debit sender wallet
        IF NEW.sender_wallet_id IS NOT NULL THEN
            UPDATE public.wallet_accounts 
            SET balance = balance - NEW.amount,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.sender_wallet_id;
        END IF;
        
        -- Credit receiver wallet
        IF NEW.receiver_wallet_id IS NOT NULL THEN
            UPDATE public.wallet_accounts 
            SET balance = balance + NEW.amount,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.receiver_wallet_id;
        END IF;
        
        NEW.completed_at = CURRENT_TIMESTAMP;
    END IF;
    
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    user_qr_code TEXT;
    wallet_id UUID;
BEGIN
    -- Generate QR code for user
    user_qr_code := public.generate_qr_code();
    
    -- Insert user profile
    INSERT INTO public.user_profiles (id, email, full_name, role, qr_code)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'standard')::public.user_role,
        user_qr_code
    );
    
    -- Create default wallet account
    INSERT INTO public.wallet_accounts (user_id, account_number, balance)
    VALUES (NEW.id, public.generate_account_number(), 1000.00)
    RETURNING id INTO wallet_id;
    
    RETURN NEW;
END;
$$;

-- 9. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offline_transactions ENABLE ROW LEVEL SECURITY;

-- 10. RLS Policies (Using Pattern 1 & 2)
-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
CREATE POLICY "users_manage_own_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for other tables
CREATE POLICY "users_manage_own_wallets"
ON public.wallet_accounts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_view_own_transactions"
ON public.transactions
FOR SELECT
TO authenticated
USING (sender_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "users_create_transactions"
ON public.transactions
FOR INSERT
TO authenticated
WITH CHECK (sender_id = auth.uid());

CREATE POLICY "users_update_own_sent_transactions"
ON public.transactions
FOR UPDATE
TO authenticated
USING (sender_id = auth.uid())
WITH CHECK (sender_id = auth.uid());

CREATE POLICY "users_manage_payment_requests"
ON public.payment_requests
FOR ALL
TO authenticated
USING (requester_id = auth.uid())
WITH CHECK (requester_id = auth.uid());

CREATE POLICY "users_manage_offline_transactions"
ON public.offline_transactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 11. Triggers
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_transaction_status_change
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW EXECUTE FUNCTION public.update_wallet_balance();

-- 12. Mock Data
DO $$
DECLARE
    user1_id UUID := gen_random_uuid();
    user2_id UUID := gen_random_uuid();
    user3_id UUID := gen_random_uuid();
    wallet1_id UUID := gen_random_uuid();
    wallet2_id UUID := gen_random_uuid();
    wallet3_id UUID := gen_random_uuid();
    txn1_id UUID := gen_random_uuid();
    txn2_id UUID := gen_random_uuid();
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
        (user1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'alice@example.com', crypt('alice123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Alice Johnson"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'bob@example.com', crypt('bob123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Bob Smith"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'charlie@example.com', crypt('charlie123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Charlie Brown"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create wallet accounts with specific IDs
    INSERT INTO public.wallet_accounts (id, user_id, account_number, balance) VALUES
        (wallet1_id, user1_id, 'OPP1001001', 2547.85),
        (wallet2_id, user2_id, 'OPP1001002', 1250.00),
        (wallet3_id, user3_id, 'OPP1001003', 850.50);

    -- Create some transactions
    INSERT INTO public.transactions (
        id, transaction_number, sender_id, receiver_id, sender_wallet_id, receiver_wallet_id,
        amount, transaction_type, transaction_status, note, completed_at, created_at
    ) VALUES
        (txn1_id, 'TXN20250822001', user2_id, user1_id, wallet2_id, wallet1_id,
         125.50, 'sent', 'completed', 'Payment for lunch', 
         CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
        (txn2_id, 'TXN20250822002', user1_id, user2_id, wallet1_id, wallet2_id,
         75.00, 'sent', 'pending', 'Shared taxi fare', 
         null, CURRENT_TIMESTAMP - INTERVAL '4 hours');

    -- Create payment requests
    INSERT INTO public.payment_requests (requester_id, amount, note, qr_code, expires_at) VALUES
        (user1_id, 50.00, 'Coffee money', 'QRCoffee001', CURRENT_TIMESTAMP + INTERVAL '1 day'),
        (user3_id, 200.00, 'Event ticket', 'QRTicket002', CURRENT_TIMESTAMP + INTERVAL '3 days');

EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Some mock data already exists, skipping duplicates';
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint error in mock data: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error in mock data generation: %', SQLERRM;
END $$;