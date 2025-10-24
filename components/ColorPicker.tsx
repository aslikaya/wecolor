"use client";
import { useState, useEffect } from "react";
import { HexColorPicker } from "react-colorful";
import styles from "./ColorPicker.module.css";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001";

export default function ColorPicker() {
  const [color, setColor] = useState("#0052FF");
  const [userId, setUserId] = useState<string>("");
  const [walletAddress, setWalletAddress] = useState<string>("");
  const [hasSelected, setHasSelected] = useState(false);
  const [selectedColor, setSelectedColor] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  useEffect(() => {
    // Get or create user ID
    let id = localStorage.getItem("wecolor_user_id");
    if (!id) {
      id = `user_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;
      localStorage.setItem("wecolor_user_id", id);
    }
    setUserId(id);

    // Check if user already selected today
    checkTodaySelection(id);
  }, []);

  const checkTodaySelection = async (uid: string) => {
    try {
      const res = await fetch(`${API_URL}/api/colors/my-color?userId=${uid}`);
      const data = await res.json();
      if (data.selected) {
        setHasSelected(true);
        setSelectedColor(data.color);
      }
    } catch (error) {
      console.error("Error checking selection:", error);
    }
  };

  const handleSubmit = async () => {
    if (!userId) return;

    setLoading(true);
    setMessage(null);

    try {
      const res = await fetch(`${API_URL}/api/colors/select`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId,
          color,
          walletAddress: walletAddress || undefined,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setMessage({ type: "error", text: data.error || "Failed to save color" });
      } else {
        setMessage({ type: "success", text: "Color saved successfully! 🎨" });
        setHasSelected(true);
        setSelectedColor(color);
      }
    } catch (error) {
      setMessage({ type: "error", text: "Network error. Please try again." });
    } finally {
      setLoading(false);
    }
  };

  if (hasSelected) {
    return (
      <div className={styles.container}>
        <div className={`${styles.card} ${styles.selectedCard}`}>
          <div className={styles.checkmark}>✓</div>
          <h3 className={styles.title}>You've Selected Your Color Today!</h3>
          <div className={styles.colorDisplay}>
            <div
              className={styles.colorPreview}
              style={{ backgroundColor: selectedColor }}
            />
            <span className={styles.colorHex}>{selectedColor}</span>
          </div>
          <p className={styles.note}>
            Come back tomorrow to select a new color!
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <h3 className={styles.title}>Select Your Daily Color</h3>
        <p className={styles.description}>
          Choose a color that represents your mood today
        </p>

        <div className={styles.pickerWrapper}>
          <HexColorPicker color={color} onChange={setColor} />
        </div>

        <div className={styles.colorInfo}>
          <div
            className={styles.colorPreview}
            style={{ backgroundColor: color }}
          />
          <input
            type="text"
            value={color}
            onChange={(e) => setColor(e.target.value)}
            className={styles.colorInput}
            placeholder="#000000"
            maxLength={7}
          />
        </div>

        <div className={styles.walletInput}>
          <label htmlFor="wallet" className={styles.label}>
            Wallet Address (optional)
          </label>
          <input
            id="wallet"
            type="text"
            value={walletAddress}
            onChange={(e) => setWalletAddress(e.target.value)}
            placeholder="0x..."
            className={styles.input}
          />
          <span className={styles.hint}>
            Required to receive rewards if this color is purchased as NFT
          </span>
        </div>

        {message && (
          <div className={`${styles.message} ${styles[message.type]}`}>
            {message.text}
          </div>
        )}

        <button
          onClick={handleSubmit}
          disabled={loading || !color}
          className="btn btn-primary"
          style={{ width: "100%" }}
        >
          {loading ? "Submitting..." : "Submit My Color"}
        </button>
      </div>
    </div>
  );
}
