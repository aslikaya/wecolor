/**
 * Blend multiple hex colors into a single collective color
 * Uses average RGB values with transparency blending
 */
export function blendColors(colors: string[]): string {
  if (colors.length === 0) {
    return '#000000'; // Default black
  }

  if (colors.length === 1) {
    return colors[0];
  }

  let totalR = 0;
  let totalG = 0;
  let totalB = 0;

  // Convert hex to RGB and accumulate
  for (const color of colors) {
    const rgb = hexToRgb(color);
    totalR += rgb.r;
    totalG += rgb.g;
    totalB += rgb.b;
  }

  // Calculate average
  const avgR = Math.round(totalR / colors.length);
  const avgG = Math.round(totalG / colors.length);
  const avgB = Math.round(totalB / colors.length);

  // Convert back to hex
  return rgbToHex(avgR, avgG, avgB);
}

/**
 * Convert hex color to RGB
 */
function hexToRgb(hex: string): { r: number; g: number; b: number } {
  // Remove # if present
  hex = hex.replace('#', '');

  // Parse hex values
  const r = parseInt(hex.substring(0, 2), 16);
  const g = parseInt(hex.substring(2, 4), 16);
  const b = parseInt(hex.substring(4, 6), 16);

  return { r, g, b };
}

/**
 * Convert RGB to hex color
 */
function rgbToHex(r: number, g: number, b: number): string {
  const toHex = (n: number) => {
    const hex = Math.max(0, Math.min(255, n)).toString(16);
    return hex.length === 1 ? '0' + hex : hex;
  };

  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

/**
 * Validate hex color format
 */
export function isValidHexColor(color: string): boolean {
  return /^#[0-9A-Fa-f]{6}$/.test(color);
}

/**
 * Get current date in YYYYMMDD format
 */
export function getCurrentDateKey(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}${month}${day}`;
}

/**
 * Convert date string (YYYYMMDD) to Unix timestamp (for contract)
 */
export function dateKeyToTimestamp(dateKey: string): number {
  return parseInt(dateKey, 10);
}
