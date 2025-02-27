#!/bin/bash

# Script to fix the CORS issue by updating server configuration and restarting services
# Exit on error
set -e

# Log file
LOG_FILE="/root/auroville-cors-fix.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create log file if it doesn't exist
touch "$LOG_FILE"

log_message "Starting fix for CORS issue..."

# Check if we're running as root
if [ "$(id -u)" -ne 0 ]; then
    log_message "This script must be run as root. Exiting."
    exit 1
fi

# Navigate to deployment directory
DEPLOY_DIR="/var/www/html/AurovilleConnect"
log_message "Navigating to deployment directory..."
cd "$DEPLOY_DIR" || {
    log_message "Error: Could not navigate to $DEPLOY_DIR. Directory may not exist."
    log_message "Please check the deployment directory path and try again."
    exit 1
}

# Backup current files
log_message "Creating backups of configuration files..."
cp server/index.js server/index.js.bak || log_message "Warning: Could not backup server/index.js"
cp public/service-worker.js public/service-worker.js.bak || log_message "Warning: Could not backup service-worker.js"

# Find Nginx configuration file
if [ -f "/etc/nginx/sites-available/auroville.conf" ]; then
    NGINX_CONF="/etc/nginx/sites-available/auroville.conf"
    cp $NGINX_CONF ${NGINX_CONF}.bak || log_message "Warning: Could not backup Nginx configuration"
elif [ -f "/etc/nginx/conf.d/auroville.conf" ]; then
    NGINX_CONF="/etc/nginx/conf.d/auroville.conf"
    cp $NGINX_CONF ${NGINX_CONF}.bak || log_message "Warning: Could not backup Nginx configuration"
else
    # Create a new configuration file in the appropriate location
    if [ -d "/etc/nginx/sites-available" ]; then
        NGINX_CONF="/etc/nginx/sites-available/auroville.conf"
        log_message "Creating new Nginx configuration in sites-available"
        
        # If using sites-available, we need to create a symlink to sites-enabled
        if [ -d "/etc/nginx/sites-enabled" ]; then
            log_message "Will create symlink in sites-enabled"
            NGINX_ENABLED="/etc/nginx/sites-enabled/auroville.conf"
        fi
    elif [ -d "/etc/nginx/conf.d" ]; then
        NGINX_CONF="/etc/nginx/conf.d/auroville.conf"
        log_message "Creating new Nginx configuration in conf.d"
    else
        log_message "Error: Could not find appropriate Nginx configuration directory"
        exit 1
    fi
fi

log_message "Using Nginx configuration file: $NGINX_CONF"

# Update server/index.js to fix CORS configuration
log_message "Updating server/index.js with correct CORS configuration..."
cat > server/index.js << 'EOL'
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
EOL

# Update Nginx configuration
log_message "Updating Nginx configuration..."
cat > $NGINX_CONF << 'EOL'
server {
    listen 80;
    listen [::]:80;
    server_name auroville.social api.auroville.social;
    
    # Redirect all HTTP traffic to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
    
    # Allow ACME challenge for certificate renewal
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root /var/www/html/AurovilleConnect/dist;
    }
}

# Main application server
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name auroville.social;

    ssl_certificate /etc/letsencrypt/live/auroville.social/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/auroville.social/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    
    root /var/www/html/AurovilleConnect/dist;
    index index.html;

    # Handle SPA routing
    location / {
        try_files $uri $uri/ /index.html =404;
        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
    }
    
    location /service-worker.js {
        root /var/www/html/AurovilleConnect/dist;
        try_files $uri =404;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, no-transform";
    }

    # Proxy API requests to the backend
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;

        # Let the backend handle CORS
        proxy_pass_request_headers on;
    }
}

# API server
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name api.auroville.social;

    ssl_certificate /etc/letsencrypt/live/auroville.social/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/auroville.social/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;

        # Let the backend handle CORS
        proxy_pass_request_headers on;
    }
}
EOL

# Update service worker
log_message "Updating service worker..."
cat > public/service-worker.js << 'EOL'
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open('vite').then(function(cache) {
      return cache.addAll([
        '/',
        '/index.html',
        '/manifest.json',
        '/service-worker.js',
        // Add more files as needed
      ]);
    })
  );
});

self.addEventListener('fetch', function(event) {
  const apiURL = 'https://api.auroville.social';
  
  // Check if this is an API request
  if (event.request.url.includes('/api/')) {
    // Don't cache API requests, always fetch from network
    event.respondWith(fetch(event.request));
    return;
  }
  
  // For non-API requests, try the cache first, then network
  event.respondWith(
    caches.match(event.request).then(function(response) {
      return response || fetch(event.request);
    })
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(self.registration.unregister());
});
EOL

# Rebuild the frontend
log_message "Rebuilding the frontend..."
NODE_ENV=production VITE_API_URL=https://api.auroville.social VITE_APP_URL=https://auroville.social npm run build || {
    log_message "Frontend build failed. Exiting."
    exit 1
}

# Create symlink if needed
if [ -n "$NGINX_ENABLED" ] && [ ! -f "$NGINX_ENABLED" ]; then
    log_message "Creating symlink from $NGINX_CONF to $NGINX_ENABLED"
    ln -sf "$NGINX_CONF" "$NGINX_ENABLED"
fi

# Test Nginx configuration
log_message "Testing Nginx configuration..."
nginx -t || {
    log_message "Nginx configuration test failed. Reverting changes..."
    if [ -f "${NGINX_CONF}.bak" ]; then
        cp "${NGINX_CONF}.bak" "$NGINX_CONF"
    fi
    if [ -n "$NGINX_ENABLED" ] && [ -L "$NGINX_ENABLED" ]; then
        log_message "Removing symlink $NGINX_ENABLED"
        rm -f "$NGINX_ENABLED"
    fi
    exit 1
}

# Restart services
log_message "Restarting services..."
systemctl restart auroville-connect || {
    log_message "Failed to restart application server. Exiting."
    exit 1
}

systemctl restart nginx || {
    log_message "Failed to restart Nginx. Exiting."
    exit 1
}

# Check service status
log_message "Checking service status..."
systemctl status auroville-connect --no-pager
systemctl status nginx --no-pager

log_message "Fix completed successfully!"
log_message "The application should now be accessible at https://auroville.social"
log_message "Try logging in with admin@auroville.social / SecurePassword123"
