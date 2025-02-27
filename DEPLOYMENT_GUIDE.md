# Auroville Connect Deployment Guide

This guide provides step-by-step instructions for deploying the Auroville Connect application to auroville.social.

## Prerequisites

- SSH access to the server
- Root or sudo privileges on the server
- Domain names (auroville.social and api.auroville.social) pointing to your server
- Basic knowledge of Linux, Nginx, and PostgreSQL

## Deployment Steps

### 1. Prepare the Server

Ensure your server has the following software installed:
- Node.js 18+ and npm
- Git
- PostgreSQL
- Nginx
- Certbot (for SSL certificates)

You can install these dependencies with:

```bash
sudo apt update
sudo apt install -y nodejs npm git postgresql postgresql-contrib nginx certbot python3-certbot-nginx
```

### 2. Transfer the Deployment Script

Transfer the `deploy-to-auroville.sh` script to your server:

```bash
scp deploy-to-auroville.sh user@auroville.social:/tmp/
```

### 3. Customize the Deployment Script

Before running the script, you need to customize it with your specific details:

1. SSH into your server:
   ```bash
   ssh user@auroville.social
   ```

2. Edit the deployment script:
   ```bash
   sudo nano /tmp/deploy-to-auroville.sh
   ```

3. Update the following values:
   - Replace `https://github.com/yourusername/AurovilleConnect.git` with your actual repository URL
   - Replace `your_secure_password` with a strong password for PostgreSQL
   - Replace `your_secure_jwt_secret` with a secure random string for JWT authentication
   - Replace `your-email@example.com` with your actual email for SSL certificate notifications

### 4. Run the Deployment Script

Make the script executable and run it:

```bash
sudo chmod +x /tmp/deploy-to-auroville.sh
sudo /tmp/deploy-to-auroville.sh
```

The script will:
- Clone the repository to `/var/www/html/AurovilleConnect`
- Install dependencies
- Set up environment variables
- Configure PostgreSQL database
- Run database migrations
- Build the application
- Configure Nginx
- Set up SSL certificates
- Configure and start the systemd service

### 5. Verify the Deployment

After the script completes, verify that the application is running:

1. Check the service status:
   ```bash
   sudo systemctl status auroville-connect
   sudo systemctl status nginx
   ```

2. Check that the application is accessible:
   - Open https://auroville.social in your browser
   - Test the API at https://api.auroville.social/health

### 6. Troubleshooting

If you encounter issues during deployment:

1. Check the logs:
   ```bash
   # Deployment logs
   cat /root/auroville-deploy.log
   
   # Application logs
   sudo journalctl -u auroville-connect -f
   
   # Nginx logs
   sudo tail -f /var/log/nginx/access.log
   sudo tail -f /var/log/nginx/error.log
   ```

2. Common issues:
   - **Database connection errors**: Check PostgreSQL is running and the connection string is correct
   - **Nginx configuration errors**: Run `sudo nginx -t` to test the configuration
   - **SSL certificate issues**: Check certbot logs and ensure domains point to your server
   - **Permission issues**: Ensure proper file permissions in the deployment directory

### 7. Post-Deployment Tasks

After successful deployment:

1. Create an admin user:
   ```bash
   cd /var/www/html/AurovilleConnect/server
   node scripts/create-admin.js
   ```

2. Set up regular database backups:
   ```bash
   # Create a backup script
   sudo nano /root/backup-auroville-db.sh
   ```
   
   Add the following content:
   ```bash
   #!/bin/bash
   BACKUP_DIR="/root/db_backups"
   mkdir -p $BACKUP_DIR
   TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
   sudo -u postgres pg_dump auroville > $BACKUP_DIR/auroville_$TIMESTAMP.sql
   ```
   
   Make it executable and add to crontab:
   ```bash
   sudo chmod +x /root/backup-auroville-db.sh
   sudo crontab -e
   ```
   
   Add this line to run daily at 2 AM:
   ```
   0 2 * * * /root/backup-auroville-db.sh
   ```

3. Set up log rotation:
   ```bash
   sudo nano /etc/logrotate.d/auroville-connect
   ```
   
   Add the following content:
   ```
   /root/auroville-deploy.log {
       weekly
       rotate 4
       compress
       delaycompress
       missingok
       notifempty
       create 0640 root root
   }
   ```

## Updating the Application

To update the application after making changes to the repository:

1. SSH into your server:
   ```bash
   ssh user@auroville.social
   ```

2. Navigate to the application directory:
   ```bash
   cd /var/www/html/AurovilleConnect
   ```

3. Pull the latest changes:
   ```bash
   git pull origin main
   ```

4. Install dependencies (if needed):
   ```bash
   npm install
   cd server && npm install && cd ..
   ```

5. Run database migrations (if needed):
   ```bash
   cd server
   npx prisma migrate deploy
   cd ..
   ```

6. Rebuild the application:
   ```bash
   npm run build
   ```

7. Restart the service:
   ```bash
   sudo systemctl restart auroville-connect
   ```

## Monitoring and Maintenance

### Monitoring

1. Check service status:
   ```bash
   sudo systemctl status auroville-connect
   sudo systemctl status nginx
   sudo systemctl status postgresql
   ```

2. Monitor logs:
   ```bash
   sudo journalctl -u auroville-connect -f
   sudo tail -f /var/log/nginx/access.log
   sudo tail -f /var/log/nginx/error.log
   ```

3. Check database status:
   ```bash
   sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity WHERE datname = 'auroville';"
   ```

### Maintenance

1. Renew SSL certificates (automatic with certbot, but can be tested):
   ```bash
   sudo certbot renew --dry-run
   ```

2. Check disk space:
   ```bash
   df -h
   ```

3. Clean up old logs and backups:
   ```bash
   find /root/db_backups -name "auroville_*.sql" -mtime +30 -delete
   ```

## Security Considerations

1. Keep the server updated:
   ```bash
   sudo apt update
   sudo apt upgrade
   ```

2. Set up a firewall:
   ```bash
   sudo ufw allow ssh
   sudo ufw allow http
   sudo ufw allow https
   sudo ufw enable
   ```

3. Regularly rotate JWT secrets:
   ```bash
   # Generate a new JWT secret
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   
   # Update the secret in the environment file
   sudo nano /var/www/html/AurovilleConnect/server/.env
   
   # Restart the service
   sudo systemctl restart auroville-connect
   ```

4. Set up fail2ban to protect against brute force attacks:
   ```bash
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```

## Conclusion

Your Auroville Connect application should now be successfully deployed to auroville.social. If you encounter any issues or need further assistance, refer to the troubleshooting section or consult the application documentation.
