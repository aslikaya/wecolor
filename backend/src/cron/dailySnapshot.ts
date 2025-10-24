import cron from 'node-cron';
import { recordDailySnapshot } from '../services/snapshotService';
import { getCurrentDateKey } from '../utils/colorBlending';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Setup cron job to record daily snapshot
 * Runs every day at 23:59 (configurable via env)
 */
export function setupDailySnapshotCron() {
  const schedule = process.env.SNAPSHOT_CRON_SCHEDULE || '59 23 * * *';

  console.log(`Setting up daily snapshot cron job: ${schedule}`);

  cron.schedule(schedule, async () => {
    const dateKey = getCurrentDateKey();
    console.log(`\n=== Cron Job Triggered at ${new Date().toISOString()} ===`);
    console.log(`Recording snapshot for date: ${dateKey}`);

    try {
      const result = await recordDailySnapshot(dateKey);

      if (result.success) {
        console.log(`✅ Snapshot recorded successfully!`);
        console.log(`Transaction hash: ${result.txHash}`);
      } else {
        console.error(`❌ Failed to record snapshot: ${result.error}`);
      }
    } catch (error) {
      console.error('❌ Cron job error:', error);
    }

    console.log('=== Cron Job Completed ===\n');
  });

  console.log('✅ Daily snapshot cron job is active');

  // Optional: Test mode - run immediately for testing
  if (process.env.NODE_ENV === 'development' && process.env.TEST_CRON === 'true') {
    console.log('🧪 Test mode: Running snapshot immediately...');
    setTimeout(async () => {
      const dateKey = getCurrentDateKey();
      console.log(`Testing snapshot for date: ${dateKey}`);
      const result = await recordDailySnapshot(dateKey);
      console.log('Test result:', result);
    }, 5000); // Run after 5 seconds
  }
}
