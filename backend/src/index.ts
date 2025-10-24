import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import colorRoutes from './routes/colorRoutes';
import snapshotRoutes from './routes/snapshotRoutes';
import { setupDailySnapshotCron } from './cron/dailySnapshot';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'wecolor-backend',
  });
});

// API Routes
app.use('/api/colors', colorRoutes);
app.use('/api/snapshot', snapshotRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  console.log('\n🚀 WeColor Backend Server Started');
  console.log(`📡 Server running on http://localhost:${PORT}`);
  console.log(`🏥 Health check: http://localhost:${PORT}/health`);
  console.log(`🎨 API Endpoints:`);
  console.log(`   - POST /api/colors/select`);
  console.log(`   - GET  /api/colors/my-color?userId=xxx`);
  console.log(`   - GET  /api/colors/today`);
  console.log(`   - GET  /api/colors/date/:date`);
  console.log(`   - POST /api/snapshot/record`);
  console.log(`   - GET  /api/snapshot/status`);
  console.log(`   - GET  /api/snapshot/status/:date`);
  console.log(`\n⏰ Cron Jobs:`);

  // Setup cron jobs
  setupDailySnapshotCron();

  console.log('\n✅ Backend ready!\n');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('\nSIGINT received, shutting down gracefully...');
  process.exit(0);
});
