## WeColor Architecture

### What It Does
Users pick a color each day. At midnight, all colors blend into one collective color. That color becomes a purchasable NFT. When someone buys it, 90% of the payment goes to the people who contributed colors, 10% to the project treasury.

### Three Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     FRONTEND (Vercel)                       │
│              Next.js 15 + React 19 + TypeScript             │
│                                                             │
│  OnchainKit (wallet)    ethers.js (contract calls)          │
│  Farcaster Mini App SDK    react-colorful (color picker)    │
└──────────────┬──────────────────────────┬───────────────────┘
               │ REST API                 │ RPC (read/write)
               ▼                          ▼
┌──────────────────────────┐  ┌───────────────────────────────┐
│    BACKEND (Railway)     │  │   SMART CONTRACT (Base Sepolia)│
│    Express.js + TypeScript│  │   Solidity + OpenZeppelin     │
│                          │  │                               │
│  Supabase client         │  │   WeColor.sol (ERC-721)       │
│  ethers.js (signing)     │  │   ECDSA signature verification│
│  node-cron (daily job)   │  │   Payment splitting           │
└──────────┬───────────────┘  └───────────────────────────────┘
           │ SQL
           ▼
┌──────────────────────────┐
│   DATABASE (Supabase)    │
│   PostgreSQL             │
│                          │
│   color_selections       │
│   daily_snapshots        │
└──────────────────────────┘
```

### Data Flow — Complete Lifecycle

**Step 1: User picks a color**
```
Browser → POST /api/colors/select → Supabase (color_selections table)
```
The frontend sends the user's wallet address + chosen hex color. The backend validates the format, checks they haven't already picked today (unique constraint on `user_id + date`), and inserts into Supabase. No blockchain interaction at all.

**Step 2: Live preview**
```
Browser → GET /api/colors/today → Supabase → all today's colors
Browser locally blends them (RGB average) → shows preview
```
The `CollectiveColor` component polls every 10 seconds and blends all submitted colors client-side to show a live preview of what today's collective color looks like so far.

**Step 3: Daily snapshot (cron at 23:59)**
```
Cron fires → reads all today's colors from Supabase
           → blends them (RGB average)
           → collects unique contributor wallet addresses
           → signs hash(date, color, contributors) with owner wallet
           → stores (color + contributors + signature) in Supabase (daily_snapshots table)
```
This is the key architectural decision — **nothing touches the blockchain here**. The owner's private key signs the data locally (a free cryptographic operation), and the signed package sits in the database waiting for a buyer.

**Step 4: Someone buys the NFT**
```
Browser → GET /api/snapshot/buy-data/:date → gets color, contributors, signature from Supabase
Browser → calls buyNftWithSignature(date, color, contributors, signature) on contract
                    │
                    ├─ Contract verifies signature (ECDSA.recover == owner)
                    ├─ Records the snapshot on-chain
                    ├─ Mints ERC-721 to buyer
                    ├─ Splits payment: 90% to contributors' pendingRewards, 10% to treasury
                    └─ Emits events
Browser → POST /api/snapshot/mark-minted → updates Supabase flag
```
The buyer pays all gas. The contract's signature check ensures only data approved by the owner wallet gets recorded — nobody can fake contributors or colors.

**Step 5: Contributors claim rewards**
```
Browser → reads pendingRewards(address) from contract
Browser → calls claimReward() on contract → ETH sent to wallet
```
This is a direct user-to-contract interaction. No backend involvement.

### The Smart Contract

```
WeColor.sol (ERC-721 + ReentrancyGuard)
├── State
│   ├── dateToDailyColor    mapping(uint256 => DailyColor)   date → snapshot data
│   ├── tokenIdToDate       mapping(uint256 => uint256)      NFT → date
│   ├── pendingRewards      mapping(address => uint256)      contributor → claimable ETH
│   ├── treasuryBalance     uint256                          accumulated 10% cuts
│   ├── basePrice           0.01 ETH
│   └── pricePerContributor 0.001 ETH
│
├── Write Functions
│   ├── buyNftWithSignature()   buyer submits signed data, records + mints + pays (new)
│   ├── buyNft()                buys an already-recorded snapshot (legacy)
│   ├── claimReward()           contributor withdraws accumulated ETH
│   ├── recordDailySnapshot()   owner records directly (legacy, kept for compat)
│   └── admin functions         setBasePrice, setTreasuryPercentage, withdrawTreasury, etc.
│
├── Read Functions
│   ├── getDailyColor()         returns full DailyColor struct for a date
│   ├── tokenURI()              on-chain SVG generation, returns base64 data URI
│   └── pendingRewards()        how much a contributor can claim
│
└── Internal
    ├── allocatePayment()       splits msg.value: 10% treasury, 90% ÷ contributors
    └── generateSvg()           builds SVG with color rect + metadata text
```

**Price formula**: `basePrice + (contributorCount × pricePerContributor)` — more contributors means a higher price, reflecting a more "collaborative" piece.

### The Database

Two tables:

```
color_selections                     daily_snapshots
┌──────────────────────┐             ┌──────────────────────────┐
│ id          UUID     │             │ id               UUID    │
│ user_id     TEXT     │             │ date             TEXT    │  ← YYYYMMDD, unique
│ date        TEXT     │             │ collective_color TEXT    │  ← blended hex
│ color       TEXT     │             │ contributors     JSONB   │  ← wallet addresses
│ wallet_address TEXT  │             │ signature        TEXT    │  ← owner's ECDSA sig
│ created_at  TIMESTAMP│             │ minted           BOOLEAN │
│                      │             │ created_at       TIMESTAMP│
│ UNIQUE(user_id,date) │             └──────────────────────────┘
└──────────────────────┘
```

`color_selections` is the staging area — raw user inputs during the day. `daily_snapshots` is the finalized output — what the cron produces and what buyers consume.

### The Frontend

```
app/
├── layout.tsx          RootProvider wraps everything in OnchainKit
├── rootProvider.tsx     OnchainKit config (wallet modal, Base chain)
├── page.tsx            Main page, calls sdk.actions.ready() for Farcaster
└── .well-known/        Farcaster Mini App manifest

components/
├── ColorPicker.tsx      Color selection (react-colorful → backend API)
├── CollectiveColor.tsx  Live preview (polls backend → client-side RGB blend)
├── NFTMarketplace.tsx   Browse + buy NFTs (backend API + on-chain reads/writes)
└── ClaimRewards.tsx     Check + withdraw rewards (direct contract interaction)
```

The wallet layer uses **Coinbase OnchainKit** which handles wallet connection, account state, and provides the `useAccount()` hook via wagmi. For contract writes (buying NFTs, claiming rewards), the components use `ethers.BrowserProvider` + `window.ethereum` directly with chain-switching logic for Base Sepolia.

### How Signing Works

This is the trust mechanism that makes lazy minting safe:

```
Backend (cron)                              Contract (on-chain)
─────────────                               ──────────────────
data = (date, colorHex, contributors)
messageHash = keccak256(                    messageHash = keccak256(
  solidityPacked(                             abi.encodePacked(
    ['uint256','string','address[]'],           date, colorHex, contributors
    [date, colorHex, contributors]            )
  )                                         )
)
signature = wallet.signMessage(             ethSignedHash = toEthSignedMessageHash(
  getBytes(messageHash)                       messageHash
)                                           )
                                            signer = ECDSA.recover(ethSignedHash, sig)
  ← stored in Supabase ──→                 require(signer == owner)
    buyer carries it
```

The encoding must match exactly between ethers.js (`solidityPackedKeccak256`) and Solidity (`keccak256(abi.encodePacked(...))`). The `signMessage` / `toEthSignedMessageHash` pair handles the EIP-191 prefix automatically on both sides.

### Deployment Topology

| Component | Platform | URL |
|---|---|---|
| Frontend | Vercel | wecolor.vercel.app |
| Backend | Railway | port 3001 |
| Database | Supabase | hosted PostgreSQL |
| Contract | Base Sepolia | `0xbe9c...77Ee` |
| CI | GitHub Actions | forge fmt + build + test |

### Key Design Tradeoffs

**Why Supabase instead of on-chain storage for daily selections?** Storing individual color picks on-chain would cost gas per user per day. Supabase is free and handles the high-write, low-value data. Only the final blended result needs chain permanence.

**Why signature-based lazy minting instead of recording daily?** The owner never pays gas. If nobody buys a day's NFT, it costs zero. The buyer absorbs the recording cost as part of their purchase transaction.

**Why duplicate the color blending logic (frontend + backend)?** The frontend needs it for live preview without an API call every time a new color comes in. The backend needs it for the authoritative blend that gets signed. Same simple RGB averaging algorithm in both places.

**Why keep the old `recordDailySnapshot` + `buyNft`?** Any snapshots already recorded on the current contract deployment still work through the legacy path. The frontend checks both sources and uses the right function for each.
