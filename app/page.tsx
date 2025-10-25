"use client";
import { Wallet } from "@coinbase/onchainkit/wallet";
import styles from "./page.module.css";
import ColorPicker from "@/components/ColorPicker";
import CollectiveColor from "@/components/CollectiveColor";
import NFTMarketplace from "@/components/NFTMarketplace";
import ClaimRewards from "@/components/ClaimRewards";

export default function Home() {
  return (
    <div className={styles.container}>
      <header className={styles.header}>
        <div className={styles.headerContent}>
          <div className={styles.logo}>
            <span className={styles.logoIcon}>🎨</span>
            <div>
              <h1 className={styles.logoTitle}>WeColor</h1>
              <p className={styles.logoTagline}>Daily Collective Color NFT</p>
            </div>
          </div>
          <Wallet />
        </div>
      </header>

      <main className={styles.main}>
        <section className={styles.hero}>
          <h2 className={styles.heroTitle}>
            Express Your Daily Mood Through Color
          </h2>
          <p className={styles.heroDescription}>
            Select a color each day. At 23:59, all colors blend into a unique collective NFT.
            Purchase NFTs to support contributors and earn rewards.
          </p>
        </section>

        <section className={styles.section}>
          <ColorPicker />
        </section>

        <section className={styles.section}>
          <CollectiveColor />
        </section>

        <section className={styles.section}>
          <ClaimRewards />
        </section>

        <section className={styles.section}>
          <div className={styles.sectionHeader}>
            <h2 className={styles.sectionTitle}>NFT Marketplace</h2>
            <p className={styles.sectionDescription}>
              Purchase past collective colors as NFTs. Revenue is shared with all contributors.
            </p>
          </div>
          <NFTMarketplace />
        </section>
      </main>

      <footer className={styles.footer}>
        <p>Built on Base • Powered by OnchainKit • Open Source</p>
      </footer>
    </div>
  );
}
