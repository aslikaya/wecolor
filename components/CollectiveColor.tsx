"use client";
import { useState, useEffect } from "react";
import styles from "./CollectiveColor.module.css";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001";

interface TodayData {
  date: string;
  count: number;
  selections: Array<{ color: string; timestamp: string }>;
}

export default function CollectiveColor() {
  const [todayData, setTodayData] = useState<TodayData | null>(null);
  const [loading, setLoading] = useState(true);
  const [countdown, setCountdown] = useState("");

  useEffect(() => {
    fetchTodayData();
    const interval = setInterval(fetchTodayData, 10000); // Refresh every 10 seconds
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const timer = setInterval(() => {
      const now = new Date();
      const midnight = new Date();
      midnight.setHours(23, 59, 59, 999);

      const diff = midnight.getTime() - now.getTime();
      if (diff > 0) {
        const hours = Math.floor(diff / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((diff % (1000 * 60)) / 1000);
        setCountdown(`${hours}h ${minutes}m ${seconds}s`);
      } else {
        setCountdown("Snapshot in progress...");
      }
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  const fetchTodayData = async () => {
    try {
      const res = await fetch(`${API_URL}/api/colors/today`);
      const data = await res.json();
      setTodayData(data);
    } catch (error) {
      console.error("Error fetching today's data:", error);
    } finally {
      setLoading(false);
    }
  };

  const blendColors = (colors: string[]): string => {
    if (colors.length === 0) return "#808080";

    let r = 0, g = 0, b = 0;
    colors.forEach(color => {
      const hex = color.replace("#", "");
      r += parseInt(hex.substring(0, 2), 16);
      g += parseInt(hex.substring(2, 4), 16);
      b += parseInt(hex.substring(4, 6), 16);
    });

    r = Math.round(r / colors.length);
    g = Math.round(g / colors.length);
    b = Math.round(b / colors.length);

    return `#${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")}`;
  };

  if (loading) {
    return (
      <div className={styles.container}>
        <div className={`${styles.card} ${styles.loading}`}>
          <div className={styles.shimmer}></div>
        </div>
      </div>
    );
  }

  const colors = todayData?.selections.map(s => s.color) || [];
  const collectiveColor = blendColors(colors);

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <div className={styles.header}>
          <h3 className={styles.title}>Today&apos;s Collective Color</h3>
          <div className={styles.badge}>
            <span className={styles.count}>{todayData?.count || 0}</span>
            <span className={styles.label}>contributors</span>
          </div>
        </div>

        <div className={styles.colorDisplay}>
          <div
            className={styles.collectiveColor}
            style={{ backgroundColor: collectiveColor }}
          >
            <div className={styles.colorOverlay}>
              <span className={styles.colorHex}>{collectiveColor}</span>
            </div>
          </div>
        </div>

        {colors.length > 0 && (
          <div className={styles.colorsGrid}>
            {colors.slice(0, 12).map((color, i) => (
              <div
                key={i}
                className={styles.miniColor}
                style={{ backgroundColor: color }}
                title={color}
              />
            ))}
            {colors.length > 12 && (
              <div className={styles.moreColors}>
                +{colors.length - 12}
              </div>
            )}
          </div>
        )}

        <div className={styles.info}>
          <div className={styles.infoItem}>
            <span className={styles.infoIcon}>⏰</span>
            <div>
              <div className={styles.infoLabel}>Snapshot in</div>
              <div className={styles.infoValue}>{countdown}</div>
            </div>
          </div>
          <div className={styles.infoItem}>
            <span className={styles.infoIcon}>🎨</span>
            <div>
              <div className={styles.infoLabel}>Status</div>
              <div className={styles.infoValue}>
                {colors.length === 0 ? "Waiting..." : "Active"}
              </div>
            </div>
          </div>
        </div>

        {colors.length === 0 && (
          <p className={styles.emptyState}>
            No colors selected yet. Be the first to contribute!
          </p>
        )}
      </div>
    </div>
  );
}
