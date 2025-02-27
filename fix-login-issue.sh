#!/bin/bash

# Script to fix the login issue by rebuilding the frontend with correct API URL
# and restarting the services

# Exit on error
set -e

# Log file
LOG_FILE="/root/auroville-fix.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create log file if it doesn't exist
touch "$LOG_FILE"

log_message "Starting fix for login issue..."

# Check if we're running as root
if [ "$(id -u)" -ne 0 ]; then
    log_message "This script must be run as root. Exiting."
    exit 1
fi

# Navigate to deployment directory
DEPLOY_DIR="/var/www/html/AurovilleConnect"
log_message "Navigating to deployment directory..."
cd "$DEPLOY_DIR"

# Verify environment variables
log_message "Verifying environment variables..."
if [ ! -f .env ]; then
    log_message "Creating .env file..."
    cat > .env << EOL
VITE_API_URL=https://api.auroville.social
VITE_APP_URL=https://auroville.social
EOL
else
    log_message ".env file exists, ensuring correct values..."
    grep -q "VITE_API_URL=https://api.auroville.social" .env || echo "VITE_API_URL=https://api.auroville.social" >> .env
    grep -q "VITE_APP_URL=https://auroville.social" .env || echo "VITE_APP_URL=https://auroville.social" >> .env
fi

# Fix service worker
log_message "Fixing service worker..."
sed -i 's|const apiURL = "http://localhost:5000/api"|const apiURL = "https://api.auroville.social"|g' public/service-worker.js
sed -i "s|const apiURL = 'http://localhost:5000/api'|const apiURL = 'https://api.auroville.social'|g" public/service-worker.js

# Clean and rebuild the frontend
log_message "Cleaning previous build..."
rm -rf dist

log_message "Rebuilding the frontend with correct API URL..."
NODE_ENV=production VITE_API_URL=https://api.auroville.social VITE_APP_URL=https://auroville.social npm run build
if [ $? -ne 0 ]; then
    log_message "Frontend build failed. Exiting."
    exit 1
fi

# Restart the server
log_message "Restarting the server..."
systemctl restart auroville-connect
if [ $? -ne 0 ]; then
    log_message "Failed to restart server. Exiting."
    exit 1
fi

# Restart Nginx
log_message "Restarting Nginx..."
systemctl restart nginx
if [ $? -ne 0 ]; then
    log_message "Failed to restart Nginx. Exiting."
    exit 1
fi

# Check service status
log_message "Checking service status..."
systemctl status auroville-connect --no-pager
systemctl status nginx --no-pager

log_message "Fix completed successfully!"
log_message "The application should now be accessible at https://auroville.social"
log_message "Try logging in with admin@auroville.social / SecurePassword123"
