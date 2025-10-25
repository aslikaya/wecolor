"use client";
import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { ethers } from "ethers";
import styles from "./ClaimRewards.module.css";

const CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS || "0xbe9c142865748C7ea4699d6E2Dc0f4bc438977Ee";
const REQUIRED_CHAIN_ID = 84532; // Base Sepolia

const WECOLOR_ABI = [
  "function pendingRewards(address) view returns (uint256)",
  "function claimReward() external",
  "event RewardClaimed(address indexed contributor, uint256 amount)"
];

export default function ClaimRewards() {
  const { address, isConnected } = useAccount();
  const [pendingReward, setPendingReward] = useState<string>("0");
  const [claiming, setClaiming] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (address && isConnected) {
      loadPendingReward();
    }
  }, [address, isConnected]);

  const loadPendingReward = async () => {
    if (!address) return;

    setLoading(true);
    try {
      const provider = new ethers.JsonRpcProvider(process.env.NEXT_PUBLIC_RPC_URL || "https://sepolia.base.org");
      const contract = new ethers.Contract(CONTRACT_ADDRESS, WECOLOR_ABI, provider);

      const reward = await contract.pendingRewards(address);
      setPendingReward(ethers.formatEther(reward));
    } catch (error) {
      console.error("Error loading pending reward:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleClaimReward = async () => {
    if (!address || !isConnected) {
      alert("Please connect your wallet first");
      return;
    }

    if (parseFloat(pendingReward) === 0) {
      alert("No rewards to claim");
      return;
    }

    setClaiming(true);

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
        } catch (switchError: any) {
          if (switchError.code === 4902) {
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
              setClaiming(false);
              return;
            }
          } else {
            console.error("Error switching network:", switchError);
            setClaiming(false);
            return;
          }
        }
      }

      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDRESS, WECOLOR_ABI, signer);

      const tx = await contract.claimReward();
      await tx.wait();

      alert(`Successfully claimed ${pendingReward} ETH! 🎉`);

      // Refresh pending reward
      await loadPendingReward();
    } catch (error: any) {
      console.error("Error claiming reward:", error);
      alert(error.message || "Failed to claim reward");
    } finally {
      setClaiming(false);
    }
  };

  if (!isConnected) {
    return (
      <div className={styles.container}>
        <div className={styles.card}>
          <h3 className={styles.title}>Claim Your Rewards</h3>
          <p className={styles.description}>
            Connect your wallet to check your pending rewards
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <h3 className={styles.title}>Claim Your Rewards</h3>
        <p className={styles.description}>
          Your contributions to daily colors earn you rewards when NFTs are purchased
        </p>

        {loading ? (
          <div className={styles.loading}>Loading...</div>
        ) : (
          <>
            <div className={styles.rewardAmount}>
              <div className={styles.amountLabel}>Pending Rewards</div>
              <div className={styles.amount}>
                {parseFloat(pendingReward).toFixed(6)} ETH
              </div>
              <div className={styles.amountUsd}>
                {parseFloat(pendingReward) > 0 ? "Ready to claim" : "No rewards yet"}
              </div>
            </div>

            <button
              onClick={handleClaimReward}
              disabled={claiming || parseFloat(pendingReward) === 0}
              className="btn btn-primary"
              style={{ width: "100%" }}
            >
              {claiming ? "Claiming..." : parseFloat(pendingReward) > 0 ? "Claim Rewards" : "No Rewards Available"}
            </button>

            <div className={styles.note}>
              <p>
                <strong>How it works:</strong> When someone purchases an NFT of a daily color,
                90% of the payment is distributed among contributors who selected colors that day.
                You can claim your share here.
              </p>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
