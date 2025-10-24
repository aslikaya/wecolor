import { wecolorContract } from '../config/contract';
import {
  getColorSelectionsForDate,
  getContributorAddressesForDate,
} from './colorService';
import {
  blendColors,
  getCurrentDateKey,
  dateKeyToTimestamp,
} from '../utils/colorBlending';

/**
 * Record daily snapshot to the blockchain
 * Called by cron job at end of each day
 */
export async function recordDailySnapshot(
  dateKey?: string
): Promise<{ success: boolean; error?: string; txHash?: string }> {
  try {
    const date = dateKey || getCurrentDateKey();
    console.log(`Starting snapshot for date: ${date}`);

    // Get all color selections for the date
    const selections = await getColorSelectionsForDate(date);

    if (selections.length === 0) {
      console.log(`No color selections for date ${date}`);
      return { success: false, error: 'No color selections for this date' };
    }

    // Extract colors
    const colors = selections.map((s) => s.color);

    // Blend all colors into collective color
    const collectiveColor = blendColors(colors);
    console.log(
      `Blended ${colors.length} colors into collective color: ${collectiveColor}`
    );

    // Get unique contributor wallet addresses
    const contributors = await getContributorAddressesForDate(date);

    if (contributors.length === 0) {
      console.log(`No contributors with wallet addresses for date ${date}`);
      return {
        success: false,
        error: 'No contributors with wallet addresses',
      };
    }

    console.log(`Found ${contributors.length} unique contributors`);

    // Convert date to contract format (uint256)
    const dateUint = dateKeyToTimestamp(date);

    // Check if already recorded
    try {
      const dailyColor = await wecolorContract.getDailyColor(dateUint);
      if (dailyColor.recorded) {
        console.log(`Snapshot already recorded for date ${date}`);
        return { success: false, error: 'Snapshot already recorded for this date' };
      }
    } catch (error) {
      // If getDailyColor fails, it means it's not recorded yet (expected)
      console.log('Daily color not yet recorded (expected)');
    }

    // Record snapshot on blockchain
    console.log('Sending transaction to blockchain...');
    const tx = await wecolorContract.recordDailySnapshot(
      dateUint,
      collectiveColor,
      contributors
    );

    console.log(`Transaction sent: ${tx.hash}`);
    console.log('Waiting for confirmation...');

    const receipt = await tx.wait();
    console.log(`Transaction confirmed in block ${receipt.blockNumber}`);

    return {
      success: true,
      txHash: tx.hash,
    };
  } catch (error: any) {
    console.error('Error in recordDailySnapshot:', error);
    return {
      success: false,
      error: error.message || 'Failed to record snapshot',
    };
  }
}

/**
 * Get snapshot status for a date
 */
export async function getSnapshotStatus(dateKey: string): Promise<{
  recorded: boolean;
  collectiveColor?: string;
  contributorCount?: number;
  price?: string;
}> {
  try {
    const dateUint = dateKeyToTimestamp(dateKey);
    const dailyColor = await wecolorContract.getDailyColor(dateUint);

    if (!dailyColor.recorded) {
      return { recorded: false };
    }

    return {
      recorded: true,
      collectiveColor: dailyColor.colorHex,
      contributorCount: dailyColor.contributors.length,
      price: dailyColor.price.toString(),
    };
  } catch (error) {
    console.error('Error in getSnapshotStatus:', error);
    return { recorded: false };
  }
}
