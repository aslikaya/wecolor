import { ethers } from 'ethers';
import dotenv from 'dotenv';

dotenv.config();

// WeColor Contract ABI (only functions we need)
export const WECOLOR_ABI = [
  'function recordDailySnapshot(uint256 date, string calldata colorHex, address[] calldata contributors) external',
  'function getDailyColor(uint256 date) external view returns (tuple(uint256 day, string colorHex, address[] contributors, bool minted, uint256 price, address buyer, uint256 tokenId, bool recorded))',
  'function owner() external view returns (address)',
];

const rpcUrl = process.env.BASE_SEPOLIA_RPC_URL!;
const contractAddress = process.env.WECOLOR_CONTRACT_ADDRESS!;
const privateKey = process.env.DEPLOYER_PRIVATE_KEY!;

if (!rpcUrl || !contractAddress || !privateKey) {
  throw new Error('Missing contract configuration in environment variables');
}

// Create provider and wallet
export const provider = new ethers.JsonRpcProvider(rpcUrl);
export const wallet = new ethers.Wallet(privateKey, provider);

// Create contract instance
export const wecolorContract = new ethers.Contract(
  contractAddress,
  WECOLOR_ABI,
  wallet
);

export { contractAddress };
