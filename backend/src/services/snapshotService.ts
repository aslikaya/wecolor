import { ethers } from 'ethers';
import { wallet, wecolorContract } from '../config/contract';
import { supabase } from '../config/supabase';
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
 * Sign and store daily snapshot off-chain (no gas cost)
 * Called by cron job at end of each day
 */
export async function recordDailySnapshot(
  dateKey?: string
): Promise<{ success: boolean; error?: string; signature?: string }> {
  try {
    const date = dateKey || getCurrentDateKey();
    console.log(`Starting snapshot for date: ${date}`);

    // Check if already signed
    const { data: existing } = await supabase
      .from('daily_snapshots')
      .select('date')
      .eq('date', date)
      .single();

    if (existing) {
      console.log(`Snapshot already signed for date ${date}`);
      return { success: false, error: 'Snapshot already signed for this date' };
    }

    // Get all color selections for the date
    const selections = await getColorSelectionsForDate(date);

    if (selections.length === 0) {
      console.log(`No color selections for date ${date}`);
      return { success: false, error: 'No color selections for this date' };
    }

    // Extract colors and blend
    const colors = selections.map((s) => s.color);
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

    // Convert date to uint256 format (same as contract)
    const dateUint = dateKeyToTimestamp(date);

    // Sign the snapshot data with the owner wallet
    // Must match: keccak256(abi.encodePacked(date, colorHex, contributors)) in Solidity
    const messageHash = ethers.solidityPackedKeccak256(
      ['uint256', 'string', 'address[]'],
      [dateUint, collectiveColor, contributors]
    );
    const signature = await wallet.signMessage(ethers.getBytes(messageHash));

    console.log(`Snapshot signed: ${signature.substring(0, 20)}...`);

    // Store in Supabase
    const { error: insertError } = await supabase
      .from('daily_snapshots')
      .insert({
        date,
        collective_color: collectiveColor,
        contributors: contributors,
        signature,
        minted: false,
      });

    if (insertError) {
      console.error('Supabase insert error:', insertError);
      return { success: false, error: 'Failed to store snapshot' };
    }

    console.log(`Snapshot signed and stored for date ${date}`);

    return {
      success: true,
      signature,
    };
  } catch (error: any) {
    console.error('Error in recordDailySnapshot:', error);
    return {
      success: false,
      error: error.message || 'Failed to sign snapshot',
    };
  }
}

/**
 * Get signed snapshot data for a specific date (used by frontend to buy NFT)
 */
export async function getSignedSnapshot(dateKey: string): Promise<{
  date: number;
  colorHex: string;
  contributors: string[];
  signature: string;
  price: string;
  minted: boolean;
} | null> {
  try {
    const { data, error } = await supabase
      .from('daily_snapshots')
      .select('*')
      .eq('date', dateKey)
      .single();

    if (error || !data) {
      return null;
    }

    // Calculate price using contract parameters
    const basePrice = await wecolorContract.basePrice();
    const pricePerContrib = await wecolorContract.pricePerContributor();
    const contributors: string[] = data.contributors;
    const price = basePrice + BigInt(contributors.length) * pricePerContrib;

    return {
      date: dateKeyToTimestamp(dateKey),
      colorHex: data.collective_color,
      contributors,
      signature: data.signature,
      price: price.toString(),
      minted: data.minted,
    };
  } catch (error) {
    console.error('Error in getSignedSnapshot:', error);
    return null;
  }
}

/**
 * Get all available (signed but unminted) snapshots
 */
export async function getAvailableSnapshots(): Promise<
  Array<{
    date: string;
    colorHex: string;
    contributorCount: number;
    price: string;
    minted: boolean;
  }>
> {
  try {
    const { data, error } = await supabase
      .from('daily_snapshots')
      .select('*')
      .order('date', { ascending: false });

    if (error || !data) {
      return [];
    }

    // Read price parameters once
    const basePrice = await wecolorContract.basePrice();
    const pricePerContrib = await wecolorContract.pricePerContributor();

    return data.map((snapshot) => {
      const contributors: string[] = snapshot.contributors;
      const price = basePrice + BigInt(contributors.length) * pricePerContrib;

      return {
        date: snapshot.date,
        colorHex: snapshot.collective_color,
        contributorCount: contributors.length,
        price: ethers.formatEther(price),
        minted: snapshot.minted,
      };
    });
  } catch (error) {
    console.error('Error in getAvailableSnapshots:', error);
    return [];
  }
}

/**
 * Mark a snapshot as minted in Supabase
 */
export async function markSnapshotMinted(dateKey: string): Promise<void> {
  try {
    const { error } = await supabase
      .from('daily_snapshots')
      .update({ minted: true })
      .eq('date', dateKey);

    if (error) {
      console.error('Error marking snapshot as minted:', error);
    }
  } catch (error) {
    console.error('Error in markSnapshotMinted:', error);
  }
}

/**
 * Get snapshot status for a date
 * Checks Supabase first (for signed snapshots), falls back to on-chain
 */
export async function getSnapshotStatus(dateKey: string): Promise<{
  recorded: boolean;
  signed: boolean;
  collectiveColor?: string;
  contributorCount?: number;
  price?: string;
  minted?: boolean;
}> {
  try {
    // Check Supabase first
    const { data } = await supabase
      .from('daily_snapshots')
      .select('*')
      .eq('date', dateKey)
      .single();

    if (data) {
      const contributors: string[] = data.contributors;
      const basePrice = await wecolorContract.basePrice();
      const pricePerContrib = await wecolorContract.pricePerContributor();
      const price = basePrice + BigInt(contributors.length) * pricePerContrib;

      return {
        recorded: true,
        signed: true,
        collectiveColor: data.collective_color,
        contributorCount: contributors.length,
        price: ethers.formatEther(price),
        minted: data.minted,
      };
    }

    // Fall back to on-chain check (for legacy recorded snapshots)
    const dateUint = dateKeyToTimestamp(dateKey);
    const dailyColor = await wecolorContract.getDailyColor(dateUint);

    if (dailyColor.recorded) {
      return {
        recorded: true,
        signed: false,
        collectiveColor: dailyColor.colorHex,
        contributorCount: dailyColor.contributors.length,
        price: ethers.formatEther(dailyColor.price),
        minted: dailyColor.minted,
      };
    }

    return { recorded: false, signed: false };
  } catch (error) {
    console.error('Error in getSnapshotStatus:', error);
    return { recorded: false, signed: false };
  }
}
