"use client";
import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { HexColorPicker } from "react-colorful";
import styles from "./ColorPicker.module.css";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001";

export default function ColorPicker() {
  const { address, isConnected } = useAccount();
  const [color, setColor] = useState("#0052FF");
  const [hasSelected, setHasSelected] = useState(false);
  const [selectedColor, setSelectedColor] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  useEffect(() => {
    // Reset state when wallet changes
    setHasSelected(false);
    setSelectedColor("");
    setMessage(null);

    if (address) {
      checkTodaySelection(address);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [address]);

  useEffect(() => {
    // Disable body scroll when color picker is active (prevents Mini App frame drag)
    if (!hasSelected && isConnected) {
      // Save original styles
      const originalOverflow = document.body.style.overflow;
      const originalPosition = document.body.style.position;
      const originalWidth = document.body.style.width;
      const originalHeight = document.body.style.height;
      const originalTouchAction = document.body.style.touchAction;

      // Lock body scroll - this prevents Mini App frame from being draggable
      document.body.style.overflow = 'hidden';
      document.body.style.position = 'fixed';
      document.body.style.width = '100%';
      document.body.style.height = '100%';
      document.body.style.touchAction = 'none';

      return () => {
        // Restore original styles when component unmounts or color is selected
        document.body.style.overflow = originalOverflow;
        document.body.style.position = originalPosition;
        document.body.style.width = originalWidth;
        document.body.style.height = originalHeight;
        document.body.style.touchAction = originalTouchAction;
      };
    }
  }, [hasSelected, isConnected]);

  const checkTodaySelection = async (walletAddr: string) => {
    try {
      const res = await fetch(`${API_URL}/api/colors/my-color?userId=${walletAddr}`);
      const data = await res.json();
      if (data.selected) {
        setHasSelected(true);
        setSelectedColor(data.color);
      } else {
        setHasSelected(false);
        setSelectedColor("");
      }
    } catch (error) {
      console.error("Error checking selection:", error);
      setHasSelected(false);
      setSelectedColor("");
    }
  };

  const handleSubmit = async () => {
    if (!address || !isConnected) {
      setMessage({ type: "error", text: "Please connect your wallet first" });
      return;
    }

    setLoading(true);
    setMessage(null);

    try {
      const res = await fetch(`${API_URL}/api/colors/select`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId: address,
          color,
          walletAddress: address,
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
    } catch {
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
          <h3 className={styles.title}>You&apos;ve Selected Your Color Today!</h3>
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

  if (!isConnected) {
    return (
      <div className={styles.container}>
        <div className={styles.card}>
          <h3 className={styles.title}>Select Your Daily Color</h3>
          <p className={styles.description}>
            Please connect your wallet to participate
          </p>
          <div className={styles.walletPrompt}>
            <p>Connect your wallet using the button in the header to start selecting colors!</p>
          </div>
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
