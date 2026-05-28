import express from 'express';
import {
  recordDailySnapshot,
  getSnapshotStatus,
  getSignedSnapshot,
  getAvailableSnapshots,
  markSnapshotMinted,
} from '../services/snapshotService';
import { getCurrentDateKey } from '../utils/colorBlending';

const router = express.Router();

/**
 * POST /api/snapshot/record
 * Manually trigger snapshot signing (no longer writes to blockchain)
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
      message: 'Snapshot signed and stored successfully',
      date: dateKey,
    });
  } catch (error) {
    console.error('Error in /record:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/snapshot/buy-data/:date
 * Returns signed snapshot data for buying an NFT
 * Frontend uses this to call buyNftWithSignature on the contract
 */
router.get('/buy-data/:date', async (req, res) => {
  try {
    const { date } = req.params;

    const snapshot = await getSignedSnapshot(date);

    if (!snapshot) {
      return res.status(404).json({ error: 'No snapshot available for this date' });
    }

    if (snapshot.minted) {
      return res.status(400).json({ error: 'Already minted' });
    }

    res.json(snapshot);
  } catch (error) {
    console.error('Error in /buy-data/:date:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/snapshot/available
 * Returns all signed snapshots (available for purchase and already sold)
 * Frontend uses this for the NFT marketplace
 */
router.get('/available', async (req, res) => {
  try {
    const snapshots = await getAvailableSnapshots();

    res.json(snapshots);
  } catch (error) {
    console.error('Error in /available:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/snapshot/mark-minted
 * Mark a snapshot as minted after successful on-chain purchase
 */
router.post('/mark-minted', async (req, res) => {
  try {
    const { date } = req.body;

    if (!date) {
      return res.status(400).json({ error: 'Missing date parameter' });
    }

    await markSnapshotMinted(date);

    res.json({ success: true, message: 'Snapshot marked as minted' });
  } catch (error) {
    console.error('Error in /mark-minted:', error);
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
