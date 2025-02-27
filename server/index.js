import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import rateLimit from 'express-rate-limit';
import { dirname } from 'path';
import cors from 'cors';
import dotenv from 'dotenv';
import { errorHandler } from './middleware/errorHandler.js';
import { authRouter } from './routes/auth.mjs';
import { forumsRouter } from './routes/forums.js';
import { usersRouter } from './routes/users.js';
import winston from 'winston';
import fs from 'fs';

// Load environment variables based on environment
console.log('Loading environment variables...');
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment-specific .env file if it exists, otherwise fall back to parent directory's .env
const envFile = process.env.NODE_ENV === 'development' 
  ? path.join(__dirname, '.env.development')
  : path.join(__dirname, '..', '.env');

console.log(`Loading environment variables from: ${envFile}`);
dotenv.config({ path: envFile });

const app = express();

// Ensure logs directory exists
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir);
}

// Winston logger configuration
console.log('Configuring Winston logger...');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ 
      filename: path.join(logsDir, 'error.log'), 
      level: 'error' 
    }),
    new winston.transports.File({ 
      filename: path.join(logsDir, 'combined.log')
    }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ],
});

// Load configuration based on environment
console.log('Loading configuration...');
let config;
try {
  const configPath = process.env.NODE_ENV === 'production'
    ? './config/production.cjs'
    : './config/development.cjs';
  const { default: loadedConfig } = await import(configPath);
  config = loadedConfig;
  logger.info('Loaded configuration:', {
    env: process.env.NODE_ENV,
    port: config.port,
    cors: config.cors.origin
  });
} catch (error) {
  logger.error('Failed to load configuration:', error);
  process.exit(1);
}

// CORS configuration
console.log('Setting up CORS...');
app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Check if the origin is allowed
    if (config.cors.origin.indexOf(origin) !== -1) {
      return callback(null, true);
    } else {
      return callback(null, false);
    }
  },
  credentials: config.cors.credentials,
  methods: config.cors.methods,
  allowedHeaders: config.cors.allowedHeaders
}));

// Rate limiting in production
if (process.env.NODE_ENV === 'production') {
  console.log('Setting up rate limiting...');
  app.use(rateLimit({
    windowMs: config.security.timeWindow,
    max: config.security.maxRequests,
    // Configure rate limiter for proxy setup
    trustProxy: process.env.NODE_ENV === 'production',
    handler: (req, res) => {
      logger.warn('Rate limit exceeded:', {
        ip: req.ip,
        path: req.path
      });
      res.status(429).json({
        error: 'Too many requests, please try again later'
      });
    }
  }));
}

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
console.log('Setting up health check endpoint...');
app.get('/health', (req, res) => {
  try {
    res.status(200).json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      env: process.env.NODE_ENV,
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message
    });
  }
});

// Debug logging for file requests
console.log('Setting up file request logging...');
app.use('/api/uploads', (req, res, next) => {
  logger.info('File request:', req.path);
  logger.info('Full URL:', req.url);
  logger.info('Absolute path:', path.join(__dirname, 'uploads', req.path));
  next();
});

// Serve static files from uploads directory with absolute path
const uploadsPath = path.join(__dirname, 'uploads');
logger.info('Uploads directory path:', uploadsPath);
app.use('/api/uploads', express.static(uploadsPath, {
  setHeaders: (res) => {
    res.set('Cache-Control', 'public, max-age=31536000');
  }
}));

// Routes with /api prefix
console.log('Setting up routes...');
app.use('/api/auth', authRouter);
app.use('/api/users', usersRouter);
app.use('/api/forums', forumsRouter);

// Import and use other routes
const { eventsRouter } = await import('./routes/events.js');
const { servicesRouter } = await import('./routes/services.js');
const { notificationsRouter } = await import('./routes/notifications.js');

app.use('/api/events', eventsRouter);
app.use('/api/services', servicesRouter);
app.use('/api/notifications', notificationsRouter);

// Add a route for the root URL
console.log('Setting up root URL route...');
app.get('/', (req, res) => {
  res.send('Hello, World!');
});

// Error handling
console.log('Setting up error handling...');
app.use(errorHandler);

const PORT = process.env.PORT || 5000;
console.log('Starting server...');
const server = app.listen(PORT, '0.0.0.0', () => {
    logger.info(`
      🚀 Server is running in ${process.env.NODE_ENV || 'undefined'} mode
      🔊 Listening on 0.0.0.0:${PORT}
      📱 API URL: ${process.env.API_URL}
      🌐 Frontend URL: ${process.env.FRONTEND_URL}
      `);
    logger.info('NODE_ENV:', process.env.NODE_ENV);
});

// Graceful shutdown
console.log('Setting up graceful shutdown...');
process.on('SIGTERM', () => {
  server.close(() => {
    logger.info('Server closed gracefully');
  });
});

process.on('SIGINT', () => {
  server.close(() => {
    logger.info('Server closed gracefully');
  });
});

process.on('uncaughtException', (err) => {
  logger.error('Uncaught exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled rejection:', reason);
  process.exit(1);
});
