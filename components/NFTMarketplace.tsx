"use client";
import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { ethers } from "ethers";
import styles from "./NFTMarketplace.module.css";

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS || "0xbe9c142865748C7ea4699d6E2Dc0f4bc438977Ee";
const RPC_URL = process.env.NEXT_PUBLIC_RPC_URL || "https://sepolia.base.org";

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
  }, []);

  const loadNFTs = async () => {
    try {
      const provider = new ethers.JsonRpcProvider(RPC_URL);
      const contract = new ethers.Contract(CONTRACT_ADDRESS, WECOLOR_ABI, provider);

      const today = new Date();
      const nftList: NFTData[] = [];

      // Load last 7 days
      for (let i = 1; i <= 7; i++) {
        const date = new Date(today);
        date.setDate(date.getDate() - i);
        const dateKey = formatDate(date);

        try {
          const dailyColor = await contract.getDailyColor(parseInt(dateKey));
          if (dailyColor.recorded) {
            nftList.push({
              date: dateKey,
              colorHex: dailyColor.colorHex,
              contributorCount: dailyColor.contributors.length,
              minted: dailyColor.minted,
              price: ethers.formatEther(dailyColor.price),
              recorded: dailyColor.recorded,
            });
          }
        } catch (error) {
          // Date not recorded yet
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
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDRESS, WECOLOR_ABI, signer);

      const priceWei = ethers.parseEther(price);
      const tx = await contract.buyNft(parseInt(dateKey), { value: priceWei });

      await tx.wait();

      alert("NFT purchased successfully! 🎉");
      loadNFTs(); // Refresh list
    } catch (error: any) {
      console.error("Error buying NFT:", error);
      alert(error.message || "Failed to purchase NFT");
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
