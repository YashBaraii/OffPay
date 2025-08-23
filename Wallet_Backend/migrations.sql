-- Users (basic, wallet + email)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  display_name text,
  balance numeric(18,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Incoming offline requests (send or receive)
CREATE TABLE IF NOT EXISTS offline_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  mode text NOT NULL CHECK (mode IN ('send','receive')),
  amount numeric(18,2) NOT NULL CHECK (amount >= 0),
  security_hash text NOT NULL,
  nonce text NOT NULL, -- unique nonce to prevent replays
  local_txn_id text, -- local transaction id from the mobile app
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paired','failed')),
  paired_txn_id uuid, -- references transaction_history id after pairing
  created_at timestamptz DEFAULT now(),
  UNIQUE (security_hash, nonce) -- optional but useful
);

-- Transaction history (finalized)
CREATE TABLE IF NOT EXISTS transaction_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid REFERENCES users(id),
  receiver_id uuid REFERENCES users(id),
  amount numeric(18,2) NOT NULL CHECK (amount >= 0),
  created_at timestamptz DEFAULT now(),
  metadata jsonb DEFAULT '{}'
);

-- Simple index to find pending requests quickly
CREATE INDEX IF NOT EXISTS idx_offreq_security_pending ON offline_requests (security_hash) WHERE status = 'pending';
