import express, { Application } from 'express';
import { createServer } from 'http';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

import { connectDatabase } from './config/database';
import { API_PREFIX } from './config/constants';
import { initializeSocket } from './config/socket';
import routes from './routes';
import { notFoundHandler, errorHandler } from './middleware/errorHandler';
import logger from './utils/logger';
import { startAutoConfirmScheduler } from './jobs/autoConfirmScheduler';

// Load environment variables
dotenv.config();

// Create Express app
const app: Application = express();

// Create HTTP server for Socket.io
const httpServer = createServer(app);

// Middleware
app.use(helmet());
app.use(
  cors({
    origin: process.env.CORS_ORIGIN?.split(',') || '*',
    credentials: true,
  })
);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging
if (process.env.NODE_ENV !== 'test') {
  app.use(
    morgan('combined', {
      stream: {
        write: (message) => logger.info(message.trim()),
      },
    })
  );
}

// Static files (uploads)
app.use('/uploads', express.static('uploads'));

// API routes
app.use(API_PREFIX, routes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: "Sina'a API",
    version: '1.0.0',
    status: 'running',
    documentation: `${API_PREFIX}/docs`,
  });
});

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Start server
const PORT = parseInt(process.env.PORT || '3000', 10);
const HOST = '0.0.0.0'; // Listen on all network interfaces

const startServer = async (): Promise<void> => {
  try {
    // Connect to database
    await connectDatabase();

    // Initialize Socket.io
    const io = initializeSocket(httpServer);

    // Start listening on all interfaces (important for mobile device testing)
    httpServer.listen(PORT, HOST, () => {
      logger.info('═══════════════════════════════════════════════════════════');
      logger.info(`🚀 Server running on port ${PORT}`);
      logger.info(`📚 API available at:`);
      logger.info(`   - Local:   http://localhost:${PORT}${API_PREFIX}`);
      logger.info(`   - Network: http://<YOUR_IP>:${PORT}${API_PREFIX}`);
      logger.info(`🔌 WebSocket ready for connections`);
      logger.info(`🔧 Environment: ${process.env.NODE_ENV || 'development'}`);
      logger.info('═══════════════════════════════════════════════════════════');
      logger.info('💡 For mobile device testing:');
      logger.info('   1. Find your IP: ipconfig (Windows) or ifconfig (Mac)');
      logger.info('   2. Make sure phone is on same WiFi');
      logger.info('   3. Allow port 3000 through firewall');
      logger.info('═══════════════════════════════════════════════════════════');

      // Start background jobs
      startAutoConfirmScheduler();
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Handle unhandled rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', { promise, reason });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

// Start the server only if not in test mode
if (process.env.NODE_ENV !== 'test') {
  startServer();
}

export default app;
