# WeColor Backend

Backend API and cron jobs for WeColor - Daily collective color NFT project on Base blockchain.

## Features

- 🎨 **Color Selection API** - Users select their daily color
- 🤖 **Automated Snapshots** - Cron job records daily collective color on-chain
- 🎭 **Color Blending** - Averages all user colors into collective color
- 💎 **Smart Contract Integration** - Interacts with WeColor contract on Base Sepolia
- 🗄️ **Supabase Database** - Stores daily color selections

## Tech Stack

- **Runtime:** Node.js + TypeScript
- **Framework:** Express.js
- **Database:** Supabase (PostgreSQL)
- **Blockchain:** ethers.js (Base Sepolia)
- **Cron:** node-cron
- **Contract:** WeColor NFT

## Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Supabase

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Open your project: `wecolor`
3. Go to **SQL Editor**
4. Copy and paste the contents of `supabase-schema.sql`
5. Run the SQL to create the `color_selections` table

### 3. Environment Variables

Copy `.env.example` to `.env` and fill in the values:

```bash
cp .env.example .env
```

Edit `.env`:

```env
# Supabase
SUPABASE_URL=https://ujwxrlvxwqhwpkxpqsjd.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Base Sepolia
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
WECOLOR_CONTRACT_ADDRESS=0xbe9c142865748C7ea4699d6E2Dc0f4bc438977Ee
DEPLOYER_PRIVATE_KEY=your_private_key

# Server
PORT=3001
NODE_ENV=development

# Cron (23:59 every day)
SNAPSHOT_CRON_SCHEDULE=59 23 * * *
```

### 4. Run Development Server

```bash
npm run dev
```

Server will start on `http://localhost:3001`

## API Endpoints

### Color Selection

#### `POST /api/colors/select`
User selects their daily color.

**Request:**
```json
{
  "userId": "user123",
  "color": "#FF5733",
  "walletAddress": "0x..." // optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "Color selection saved successfully",
  "date": "20241024"
}
```

#### `GET /api/colors/my-color?userId=user123`
Get user's color selection for today.

**Response:**
```json
{
  "selected": true,
  "color": "#FF5733",
  "date": "20241024"
}
```

#### `GET /api/colors/today`
Get all color selections for today.

**Response:**
```json
{
  "date": "20241024",
  "count": 150,
  "selections": [
    { "color": "#FF5733", "timestamp": "2024-10-24T10:30:00Z" },
    { "color": "#00FF00", "timestamp": "2024-10-24T11:15:00Z" }
  ]
}
```

#### `GET /api/colors/date/:date`
Get all color selections for a specific date.

### Snapshot Management

#### `POST /api/snapshot/record`
Manually trigger snapshot recording (also runs automatically via cron).

**Request:**
```json
{
  "date": "20241024" // optional, defaults to today
}
```

**Response:**
```json
{
  "success": true,
  "message": "Snapshot recorded successfully",
  "txHash": "0x...",
  "date": "20241024"
}
```

#### `GET /api/snapshot/status`
Get snapshot status for today.

**Response:**
```json
{
  "date": "20241024",
  "recorded": true,
  "collectiveColor": "#FF8833",
  "contributorCount": 150,
  "price": "160000000000000000"
}
```

#### `GET /api/snapshot/status/:date`
Get snapshot status for a specific date.

## Cron Jobs

### Daily Snapshot
- **Schedule:** 23:59 every day (configurable via `SNAPSHOT_CRON_SCHEDULE`)
- **Action:** Records daily collective color on blockchain
- **Process:**
  1. Fetches all color selections for the day
  2. Blends colors into collective color
  3. Gets unique contributor wallet addresses
  4. Calls `recordDailySnapshot()` on WeColor contract

## Color Blending Algorithm

The backend uses RGB averaging to blend colors:

1. Convert all hex colors to RGB
2. Calculate average R, G, B values
3. Convert back to hex color

Example:
```
#FF0000 (red) + #00FF00 (green) = #7F7F00 (yellow-ish)
```

## Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration (Supabase, Contract)
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   ├── cron/            # Cron jobs
│   ├── utils/           # Utilities (color blending)
│   └── index.ts         # Entry point
├── supabase-schema.sql  # Database schema
├── package.json
├── tsconfig.json
└── .env
```

## Deployment

### Option 1: Railway
1. Push to GitHub
2. Connect Railway to your repo
3. Add environment variables
4. Deploy!

### Option 2: Heroku
```bash
heroku create wecolor-backend
heroku addons:create heroku-postgresql:mini
git push heroku main
```

### Option 3: VPS (Ubuntu)
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone and setup
git clone <repo>
cd backend
npm install
npm run build

# Use PM2 for process management
npm install -g pm2
pm2 start dist/index.js --name wecolor-backend
pm2 save
pm2 startup
```

## Testing

### Test Color Selection
```bash
curl -X POST http://localhost:3001/api/colors/select \
  -H "Content-Type: application/json" \
  -d '{"userId":"test123","color":"#FF5733","walletAddress":"0xYourWallet"}'
```

### Test Snapshot Recording
```bash
curl -X POST http://localhost:3001/api/snapshot/record \
  -H "Content-Type: application/json" \
  -d '{"date":"20241024"}'
```

## Troubleshooting

### Database Connection Failed
- Check Supabase URL and API keys in `.env`
- Verify table `color_selections` exists in Supabase

### Contract Call Failed
- Check RPC URL is working
- Verify private key has ETH for gas
- Check contract address is correct
- Ensure wallet is the contract owner (for `recordDailySnapshot`)

### Cron Job Not Running
- Check cron schedule format in `.env`
- View logs for cron execution
- Test manually via `/api/snapshot/record`

## License

MIT
