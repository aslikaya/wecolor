import { supabase } from '../config/supabase';
import { isValidHexColor, getCurrentDateKey } from '../utils/colorBlending';

export interface ColorSelection {
  user_id: string;
  date: string;
  color: string;
  wallet_address?: string;
  created_at?: string;
}

/**
 * Save a user's color selection for today
 */
export async function saveColorSelection(
  userId: string,
  color: string,
  walletAddress?: string
): Promise<{ success: boolean; error?: string }> {
  try {
    // Validate color format
    if (!isValidHexColor(color)) {
      return { success: false, error: 'Invalid hex color format' };
    }

    const dateKey = getCurrentDateKey();

    // Check if user already selected a color today
    const { data: existing } = await supabase
      .from('color_selections')
      .select('*')
      .eq('user_id', userId)
      .eq('date', dateKey)
      .single();

    if (existing) {
      return { success: false, error: 'You have already selected a color for today' };
    }

    // Insert new color selection
    const { error } = await supabase.from('color_selections').insert({
      user_id: userId,
      date: dateKey,
      color: color,
      wallet_address: walletAddress,
    });

    if (error) {
      console.error('Supabase insert error:', error);
      return { success: false, error: 'Failed to save color selection' };
    }

    return { success: true };
  } catch (error) {
    console.error('Error in saveColorSelection:', error);
    return { success: false, error: 'Internal server error' };
  }
}

/**
 * Get all color selections for a specific date
 */
export async function getColorSelectionsForDate(
  dateKey: string
): Promise<ColorSelection[]> {
  try {
    const { data, error } = await supabase
      .from('color_selections')
      .select('*')
      .eq('date', dateKey);

    if (error) {
      console.error('Supabase query error:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('Error in getColorSelectionsForDate:', error);
    return [];
  }
}

/**
 * Get user's color selection for today
 */
export async function getUserColorForToday(
  userId: string
): Promise<ColorSelection | null> {
  try {
    const dateKey = getCurrentDateKey();

    const { data, error } = await supabase
      .from('color_selections')
      .select('*')
      .eq('user_id', userId)
      .eq('date', dateKey)
      .single();

    if (error) {
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in getUserColorForToday:', error);
    return null;
  }
}

/**
 * Get unique contributor wallet addresses for a date
 */
export async function getContributorAddressesForDate(
  dateKey: string
): Promise<string[]> {
  try {
    const { data, error } = await supabase
      .from('color_selections')
      .select('wallet_address')
      .eq('date', dateKey)
      .not('wallet_address', 'is', null);

    if (error) {
      console.error('Supabase query error:', error);
      return [];
    }

    // Remove duplicates and filter out nulls
    const addresses = data
      .map((item) => item.wallet_address)
      .filter((addr): addr is string => addr !== null && addr !== undefined);

    return [...new Set(addresses)];
  } catch (error) {
    console.error('Error in getContributorAddressesForDate:', error);
    return [];
  }
}
