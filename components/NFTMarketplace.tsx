"use client";
import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { ethers } from "ethers";
import styles from "./NFTMarketplace.module.css";

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS || "0xbe9c142865748C7ea4699d6E2Dc0f4bc438977Ee";
const RPC_URL = process.env.NEXT_PUBLIC_RPC_URL || "https://sepolia.base.org";
const REQUIRED_CHAIN_ID = 84532; // Base Sepolia

const WECOLOR_ABI = [
  "function getDailyColor(uint256 date) external view returns (tuple(uint256 day, string colorHex, address[] contributors, bool minted, uint256 price, address buyer, uint256 tokenId, bool recorded))",
  "function buyNft(uint256 date) external payable",
];

interface NFTData {
  date: string;
  colorHex: string;
  contributorCount: number;
  minted: boolean;
  price: string;
  recorded: boolean;
}

export default function NFTMarketplace() {
  const { address, isConnected } = useAccount();
  const [nfts, setNfts] = useState<NFTData[]>([]);
  const [loading, setLoading] = useState(true);
  const [buying, setBuying] = useState<string | null>(null);

  useEffect(() => {
    loadNFTs();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadNFTs = async () => {
    try {
      const provider = new ethers.JsonRpcProvider(RPC_URL);
      const contract = new ethers.Contract(CONTRACT_ADDRESS, WECOLOR_ABI, provider);

      const today = new Date();
      const nftList: NFTData[] = [];

      // Load last 7 days (including today)
      for (let i = 0; i < 7; i++) {
        const date = new Date(today);
        date.setDate(date.getDate() - i);
        const dateKey = formatDate(date);

        try {
          // First check if this date is likely to exist (don't query too far back)
          const dateNum = parseInt(dateKey);

          const dailyColor = await contract.getDailyColor(dateNum);

          // Only add if it's actually recorded (not empty)
          if (dailyColor.recorded && dailyColor.contributors.length > 0) {
            nftList.push({
              date: dateKey,
              colorHex: dailyColor.colorHex,
              contributorCount: dailyColor.contributors.length,
              minted: dailyColor.minted,
              price: ethers.formatEther(dailyColor.price),
              recorded: dailyColor.recorded,
            });
          }
        } catch {
          // Date not recorded yet or contract call failed, skip silently
          console.log(`Skipping date ${dateKey}: not recorded`);
        }
      }

      setNfts(nftList);
    } catch (error) {
      console.error("Error loading NFTs:", error);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (date: Date): string => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}${month}${day}`;
  };

  const formatDateDisplay = (dateStr: string): string => {
    const year = dateStr.substring(0, 4);
    const month = dateStr.substring(4, 6);
    const day = dateStr.substring(6, 8);
    return `${day}/${month}/${year}`;
  };

  const buyNFT = async (dateKey: string, price: string) => {
    if (!isConnected || !address) {
      alert("Please connect your wallet first");
      return;
    }

    setBuying(dateKey);

    try {
      // Check if on correct network
      const provider = new ethers.BrowserProvider(window.ethereum);
      const network = await provider.getNetwork();

      if (Number(network.chainId) !== REQUIRED_CHAIN_ID) {
        alert("Please switch to Base Sepolia network");
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x14a34' }], // 84532 in hex
          });
        } catch (switchError) {
          // This error code indicates that the chain has not been added to MetaMask
          const error = switchError as { code?: number };
          if (error.code === 4902) {
            try {
              await window.ethereum.request({
                method: 'wallet_addEthereumChain',
                params: [{
                  chainId: '0x14a34',
                  chainName: 'Base Sepolia',
                  nativeCurrency: {
                    name: 'ETH',
                    symbol: 'ETH',
                    decimals: 18
                  },
                  rpcUrls: ['https://sepolia.base.org'],
                  blockExplorerUrls: ['https://sepolia.basescan.org']
                }]
              });
            } catch (addError) {
              console.error("Error adding network:", addError);
              setBuying(null);
              return;
            }
          } else {
            console.error("Error switching network:", switchError);
            setBuying(null);
            return;
          }
        }
      }

      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDRESS, WECOLOR_ABI, signer);

      const priceWei = ethers.parseEther(price);
      const tx = await contract.buyNft(parseInt(dateKey), { value: priceWei });

      await tx.wait();

      alert("NFT purchased successfully! 🎉");
      loadNFTs(); // Refresh list
    } catch (error) {
      console.error("Error buying NFT:", error);
      const err = error as { message?: string };
      alert(err.message || "Failed to purchase NFT");
    } finally {
      setBuying(null);
    }
  };

  if (loading) {
    return (
      <div className={styles.container}>
        <div className={styles.grid}>
          {[1, 2, 3].map((i) => (
            <div key={i} className={`${styles.card} ${styles.loading}`}>
              <div className={styles.shimmer}></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (nfts.length === 0) {
    return (
      <div className={styles.container}>
        <div className={styles.emptyState}>
          <div className={styles.emptyIcon}>🎨</div>
          <h3>No NFTs Available Yet</h3>
          <p>Check back tomorrow for the first collective color NFT!</p>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.container}>
      <div className={styles.grid}>
        {nfts.map((nft) => (
          <div key={nft.date} className={styles.card}>
            <div
              className={styles.colorPreview}
              style={{ backgroundColor: nft.colorHex }}
            >
              <div className={styles.colorOverlay}>
                <span className={styles.colorHex}>{nft.colorHex}</span>
              </div>
            </div>

            <div className={styles.cardContent}>
              <div className={styles.cardHeader}>
                <h4 className={styles.date}>{formatDateDisplay(nft.date)}</h4>
                {nft.minted && (
                  <span className={styles.soldBadge}>SOLD</span>
                )}
              </div>

              <div className={styles.stats}>
                <div className={styles.stat}>
                  <span className={styles.statIcon}>👥</span>
                  <span className={styles.statValue}>{nft.contributorCount}</span>
                  <span className={styles.statLabel}>contributors</span>
                </div>
                <div className={styles.stat}>
                  <span className={styles.statIcon}>💎</span>
                  <span className={styles.statValue}>{parseFloat(nft.price).toFixed(4)}</span>
                  <span className={styles.statLabel}>ETH</span>
                </div>
              </div>

              {nft.minted ? (
                <button className="btn btn-secondary" disabled style={{ width: "100%" }}>
                  Sold Out
                </button>
              ) : (
                <button
                  className="btn btn-primary"
                  onClick={() => buyNFT(nft.date, nft.price)}
                  disabled={buying === nft.date || !isConnected}
                  style={{ width: "100%" }}
                >
                  {buying === nft.date ? "Buying..." : isConnected ? "Buy NFT" : "Connect Wallet"}
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
