#!/bin/bash

# Load environment variables
# Load environment variables from .env file
if [ -f .env ]; then
  source .env
fi

# Log file for deployment (in user's home directory instead of /var/log)
LOG_FILE="$HOME/auroville-deploy.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create log file if it doesn0't exist
touch "$LOG_FILE"

log_message "Starting deployment process..."

# Pull latest code from main branch
log_message "Pulling latest code from main branch..."
git pull origin main

# Function to check service status
check_service() {
    if brew services list | grep "$1" | grep "started" >/dev/null; then
        log_message "$1 is running"
        return 0
    else
        log_message "ERROR: $1 is not running"
        return 1
    fi
}

# Function to check if port is in use
check_port() {
    if lsof -i:$1 >/dev/null; then
        log_message "Port $1 is already in use"
        return 1
    fi
    return 0
}

# Check required port
log_message "Checking ports..."
check_port 5000
if [ $? -eq 0 ]; then
    log_message "Port 5000 is available"
else
    log_message "Port 5000 is in use. Will attempt to free it."
    pm2 delete all
    pm2 kill
fi

# Check PostgreSQL service
log_message "Checking PostgreSQL service..."
check_service postgresql
if [ $? -ne 0 ]; then
    log_message "PostgreSQL service is not running. Exiting."
    exit 1
fi

# Check Nginx service
log_message "Checking Nginx service..."
check_service nginx
if [ $? -ne 0 ]; then
    log_message "Nginx service is not running. Exiting."
    exit 1
fi

# Install/update dependencies
log_message "Installing dependencies..."
export NODE_OPTIONS="--max-old-space-size=4096"
npm install
if [ $? -ne 0 ]; then
    log_message "Failed to install frontend dependencies. Exiting."
    exit 1
fi

cd server
npm install
if [ $? -ne 0 ]; then
    log_message "Failed to install backend dependencies. Exiting."
    exit 1
fi
cd ..

# Run database migrations
log_message "Running database migrations..."
export DATABASE_URL="postgresql://postgres:${DB_PASSWORD}@localhost:5432/auroville?schema=public"
cd server
npx prisma migrate deploy
if [ $? -ne 0 ]; then
    log_message "Failed to run database migrations. Exiting."
    exit 1
fi
cd ..

# Build frontend
log_message "Building frontend..."
export VITE_API_URL="http://localhost:5000/api"
NODE_ENV=production npm run build
if [ $? -ne 0 ]; then
    log_message "Frontend build failed. Exiting."
    exit 1
fi

# Start backend with PM2
log_message "Starting or restarting backend service with PM2..."
pm2 startOrRestart ecosystem.config.js --only auroville-connect-server
if [ $? -ne 0 ]; then
    log_message "Failed to start or restart backend service with PM2. Exiting."
    exit 1
fi
cd ..

# Verify services are running
log_message "Verifying services..."

# Check if API is responding
sleep 5  # Give the API a moment to start
curl -f http://localhost:5000/health >/dev/null 2>&1
if [ $? -eq 0 ]; then
    log_message "API is responding"
else
    log_message "API is not responding. Deployment may have failed."
    exit 1
fi

log_message "Deployment completed successfully!"

# Display status
pm2 status
exit 0

cd server && touch .env
