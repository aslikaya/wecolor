import express from 'express';
import {
  saveColorSelection,
  getUserColorForToday,
  getColorSelectionsForDate,
} from '../services/colorService';
import { getCurrentDateKey } from '../utils/colorBlending';

const router = express.Router();

/**
 * POST /api/colors/select
 * User selects their daily color
 */
router.post('/select', async (req, res) => {
  try {
    const { userId, color, walletAddress } = req.body;

    if (!userId || !color) {
      return res.status(400).json({
        error: 'Missing required fields: userId and color',
      });
    }

    const result = await saveColorSelection(userId, color, walletAddress);

    if (!result.success) {
      return res.status(400).json({ error: result.error });
    }

    res.json({
      success: true,
      message: 'Color selection saved successfully',
      date: getCurrentDateKey(),
    });
  } catch (error) {
    console.error('Error in /select:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/colors/my-color
 * Get user's color selection for today
 */
router.get('/my-color', async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({ error: 'Missing userId parameter' });
    }

    const selection = await getUserColorForToday(userId as string);

    if (!selection) {
      return res.json({ selected: false });
    }

    res.json({
      selected: true,
      color: selection.color,
      date: selection.date,
    });
  } catch (error) {
    console.error('Error in /my-color:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/colors/date/:date
 * Get all color selections for a specific date
 */
router.get('/date/:date', async (req, res) => {
  try {
    const { date } = req.params;

    const selections = await getColorSelectionsForDate(date);

    res.json({
      date,
      count: selections.length,
      selections: selections.map((s) => ({
        color: s.color,
        timestamp: s.created_at,
      })),
    });
  } catch (error) {
    console.error('Error in /date/:date:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/colors/today
 * Get all color selections for today
 */
router.get('/today', async (req, res) => {
  try {
    const dateKey = getCurrentDateKey();
    const selections = await getColorSelectionsForDate(dateKey);

    res.json({
      date: dateKey,
      count: selections.length,
      selections: selections.map((s) => ({
        color: s.color,
        timestamp: s.created_at,
      })),
    });
  } catch (error) {
    console.error('Error in /today:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
