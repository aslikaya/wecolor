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
CREATE POLICY "Users can insert their own color selections"
  ON color_selections
  FOR INSERT
  WITH CHECK (true);

-- RLS Policy: Anyone can read color selections (public data)
CREATE POLICY "Anyone can read color selections"
  ON color_selections
  FOR SELECT
  USING (true);

-- Optional: Create a view for daily statistics
CREATE OR REPLACE VIEW daily_stats AS
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
