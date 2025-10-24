import express from 'express';
import {
  recordDailySnapshot,
  getSnapshotStatus,
} from '../services/snapshotService';
import { getCurrentDateKey } from '../utils/colorBlending';

const router = express.Router();

/**
 * POST /api/snapshot/record
 * Manually trigger snapshot recording
 * (Also runs automatically via cron job)
 */
router.post('/record', async (req, res) => {
  try {
    const { date } = req.body;
    const dateKey = date || getCurrentDateKey();

    console.log(`Manual snapshot trigger for date: ${dateKey}`);

    const result = await recordDailySnapshot(dateKey);

    if (!result.success) {
      return res.status(400).json({ error: result.error });
    }

    res.json({
      success: true,
      message: 'Snapshot recorded successfully',
      txHash: result.txHash,
      date: dateKey,
    });
  } catch (error) {
    console.error('Error in /record:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/snapshot/status/:date
 * Get snapshot status for a specific date
 */
router.get('/status/:date', async (req, res) => {
  try {
    const { date } = req.params;

    const status = await getSnapshotStatus(date);

    res.json(status);
  } catch (error) {
    console.error('Error in /status/:date:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/snapshot/status
 * Get snapshot status for today
 */
router.get('/status', async (req, res) => {
  try {
    const dateKey = getCurrentDateKey();
    const status = await getSnapshotStatus(dateKey);

    res.json({
      date: dateKey,
      ...status,
    });
  } catch (error) {
    console.error('Error in /status:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
