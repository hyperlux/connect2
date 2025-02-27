#!/bin/bash

# Deployment script for Auroville Connect to auroville.social
# This script should be run on the target server

# Exit on error
set -e

# Log file
LOG_FILE="/root/auroville-deploy.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create log file if it doesn't exist
touch "$LOG_FILE"

log_message "Starting deployment to auroville.social..."

# Check if we're running as root
if [ "$(id -u)" -ne 0 ]; then
    log_message "This script must be run as root. Exiting."
    exit 1
fi

# Create deployment directory
DEPLOY_DIR="/var/www/html/AurovilleConnect"
mkdir -p "$DEPLOY_DIR"

# Copy files from current directory to deployment directory
log_message "Copying files to deployment directory..."
cp -r /root/connect2/* "$DEPLOY_DIR/"

# Navigate to deployment directory
log_message "Navigating to deployment directory..."
cd "$DEPLOY_DIR"

# Install dependencies
log_message "Installing frontend dependencies..."
npm install

log_message "Installing backend dependencies..."
cd server
npm install
cd ..

# Create environment variables
log_message "Setting up environment variables..."
cat > .env << EOL
VITE_API_URL=https://api.auroville.social
VITE_APP_URL=https://auroville.social
EOL

log_message "Setting up server environment variables..."
cat > server/.env << EOL
NODE_ENV=production
PORT=5000
HOST=0.0.0.0
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/auroville
JWT_SECRET=y5S6M1Fr0kFoCJTSsEQoTUYVrjskG4f8FwtDl92GbXQ=
FRONTEND_URL=https://auroville.social
API_URL=https://api.auroville.social
SMTP_SERVER=smtp.ionos.com
SMTP_PORT=587
SMTP_USERNAME=notifications@aurovillenetwork.us
SMTP_PASSWORD=lucky8magic7aurOville*Q
EOL

# Set up database
log_message "Setting up database..."
# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    log_message "Installing PostgreSQL..."
    apt update
    apt install -y postgresql postgresql-contrib
fi

# Start PostgreSQL if not running
systemctl is-active --quiet postgresql || systemctl start postgresql

# Create database and user if they don't exist
sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname = 'auroville'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE auroville;"

sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname = 'postgres'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER postgres;"

# Set password for postgres user
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE auroville TO postgres;"

# Run database migrations
log_message "Running database migrations..."
cd server
npx prisma migrate deploy
cd ..

# Build the application
log_message "Building the application..."
npm run build

# Set up Nginx
log_message "Setting up Nginx..."
# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    log_message "Installing Nginx..."
    apt update
    apt install -y nginx
fi

# Copy Nginx configuration
cp nginx.conf /etc/nginx/sites-available/auroville-connect
ln -sf /etc/nginx/sites-available/auroville-connect /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Set up SSL certificates
log_message "Setting up SSL certificates..."
# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    log_message "Installing certbot..."
    apt update
    apt install -y certbot python3-certbot-nginx
fi

# Get SSL certificates
certbot certonly --nginx -d auroville.social --non-interactive --agree-tos --email polletkiro@gmail.com
certbot certonly --nginx -d api.auroville.social --non-interactive --agree-tos --email polletkiro@gmail.com

# Set up systemd service
log_message "Setting up systemd service..."
cp auroville-connect.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable auroville-connect

# Create uploads directory
mkdir -p "$DEPLOY_DIR/server/uploads"
chmod 755 "$DEPLOY_DIR/server/uploads"

# Restart services
log_message "Restarting services..."
systemctl restart nginx
systemctl restart auroville-connect

# Check service status
log_message "Checking service status..."
systemctl status nginx --no-pager
systemctl status auroville-connect --no-pager

log_message "Deployment completed successfully!"
log_message "The application should now be accessible at https://auroville.social"
