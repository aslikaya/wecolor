-- WeColor Database Schema for Supabase

-- Create color_selections table
CREATE TABLE IF NOT EXISTS color_selections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  date TEXT NOT NULL,
  color TEXT NOT NULL,
  wallet_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_color_format CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),
  CONSTRAINT valid_date_format CHECK (date ~ '^\d{8}$'),

  -- Unique constraint: one color per user per day
  UNIQUE(user_id, date)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_color_selections_date ON color_selections(date);
CREATE INDEX IF NOT EXISTS idx_color_selections_user_date ON color_selections(user_id, date);
CREATE INDEX IF NOT EXISTS idx_color_selections_wallet ON color_selections(wallet_address) WHERE wallet_address IS NOT NULL;

-- Enable Row Level Security (RLS)
ALTER TABLE color_selections ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can insert their own color selections
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'color_selections'
    AND policyname = 'Users can insert their own color selections'
  ) THEN
    CREATE POLICY "Users can insert their own color selections"
      ON color_selections
      FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

-- RLS Policy: Anyone can read color selections (public data)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'color_selections'
    AND policyname = 'Anyone can read color selections'
  ) THEN
    CREATE POLICY "Anyone can read color selections"
      ON color_selections
      FOR SELECT
      USING (true);
  END IF;
END $$;

-- Optional: Create a view for daily statistics
CREATE OR REPLACE VIEW daily_stats
WITH (security_invoker = true) AS
SELECT
  date,
  COUNT(*) as selection_count,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(DISTINCT wallet_address) as wallet_count,
  MIN(created_at) as first_selection,
  MAX(created_at) as last_selection
FROM color_selections
GROUP BY date
ORDER BY date DESC;

-- Grant permissions
GRANT SELECT ON daily_stats TO anon, authenticated;

COMMENT ON TABLE color_selections IS 'Stores user color selections for each day';
COMMENT ON COLUMN color_selections.user_id IS 'User identifier (can be Farcaster FID, wallet address, etc)';
COMMENT ON COLUMN color_selections.date IS 'Date in YYYYMMDD format';
COMMENT ON COLUMN color_selections.color IS 'Hex color code (e.g., #FF5733)';
COMMENT ON COLUMN color_selections.wallet_address IS 'Optional: User wallet address for on-chain rewards';

-- ============================================================
-- Daily Snapshots table (for lazy minting with signatures)
-- Stores signed snapshot data off-chain until an NFT is purchased
-- ============================================================

CREATE TABLE IF NOT EXISTS daily_snapshots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date TEXT NOT NULL UNIQUE,
  collective_color TEXT NOT NULL,
  contributors JSONB NOT NULL,       -- array of wallet addresses
  signature TEXT NOT NULL,           -- hex-encoded owner signature
  minted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_snapshot_date_format CHECK (date ~ '^\d{8}$'),
  CONSTRAINT valid_snapshot_color_format CHECK (collective_color ~ '^#[0-9A-Fa-f]{6}$')
);

CREATE INDEX IF NOT EXISTS idx_daily_snapshots_date ON daily_snapshots(date);
CREATE INDEX IF NOT EXISTS idx_daily_snapshots_minted ON daily_snapshots(minted);

ALTER TABLE daily_snapshots ENABLE ROW LEVEL SECURITY;

-- Anyone can read snapshots (frontend needs this for marketplace)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'daily_snapshots'
    AND policyname = 'Anyone can read daily snapshots'
  ) THEN
    CREATE POLICY "Anyone can read daily snapshots"
      ON daily_snapshots
      FOR SELECT
      USING (true);
  END IF;
END $$;

-- Backend can insert snapshots
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'daily_snapshots'
    AND policyname = 'Service can insert daily snapshots'
  ) THEN
    CREATE POLICY "Service can insert daily snapshots"
      ON daily_snapshots
      FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

-- Backend can update snapshots (mark as minted)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'daily_snapshots'
    AND policyname = 'Service can update daily snapshots'
  ) THEN
    CREATE POLICY "Service can update daily snapshots"
      ON daily_snapshots
      FOR UPDATE
      USING (true);
  END IF;
END $$;

COMMENT ON TABLE daily_snapshots IS 'Stores signed daily color snapshots for lazy NFT minting';
COMMENT ON COLUMN daily_snapshots.date IS 'Date in YYYYMMDD format';
COMMENT ON COLUMN daily_snapshots.collective_color IS 'Blended hex color from all contributors';
COMMENT ON COLUMN daily_snapshots.contributors IS 'JSON array of contributor wallet addresses';
COMMENT ON COLUMN daily_snapshots.signature IS 'Owner wallet signature for on-chain verification';
COMMENT ON COLUMN daily_snapshots.minted IS 'Whether this snapshot has been purchased as an NFT';
