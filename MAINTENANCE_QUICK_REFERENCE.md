# Auroville Connect Maintenance Quick Reference

This document provides quick reference commands for common maintenance tasks for the Auroville Connect application deployed at auroville.social.

## Service Management

### Check Service Status
```bash
# Application service
sudo systemctl status auroville-connect

# Web server
sudo systemctl status nginx

# Database
sudo systemctl status postgresql
```

### Restart Services
```bash
# Restart application
sudo systemctl restart auroville-connect

# Restart web server
sudo systemctl restart nginx

# Restart database
sudo systemctl restart postgresql
```

### View Logs
```bash
# Application logs
sudo journalctl -u auroville-connect -f

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Deployment logs
cat /root/auroville-deploy.log
```

## Application Updates

### Update Application Code
```bash
cd /var/www/html/AurovilleConnect
git pull origin main
npm install
cd server && npm install && cd ..
npm run build
sudo systemctl restart auroville-connect
```

### Apply Database Migrations
```bash
cd /var/www/html/AurovilleConnect/server
npx prisma migrate deploy
sudo systemctl restart auroville-connect
```

## Database Management

### Create Database Backup
```bash
sudo -u postgres pg_dump auroville > /root/db_backups/auroville_$(date +"%Y%m%d_%H%M%S").sql
```

### Restore Database from Backup
```bash
sudo -u postgres psql auroville < /path/to/backup.sql
```

### Check Database Size
```bash
sudo -u postgres psql -c "SELECT pg_size_pretty(pg_database_size('auroville'));"
```

### Check Active Connections
```bash
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity WHERE datname = 'auroville';"
```

## User Management

### Create Admin User
```bash
cd /var/www/html/AurovilleConnect/server
node scripts/create-admin.js
```

### Make Existing User an Admin
```bash
cd /var/www/html/AurovilleConnect/server
node scripts/make-admin.js
```

### Check User Details
```bash
cd /var/www/html/AurovilleConnect/server
node scripts/check-user.js
```

## SSL Certificate Management

### Check Certificate Status
```bash
sudo certbot certificates
```

### Renew Certificates (Manual)
```bash
sudo certbot renew
```

### Test Certificate Renewal
```bash
sudo certbot renew --dry-run
```

## Security Maintenance

### Update Server Packages
```bash
sudo apt update
sudo apt upgrade
```

### Check Disk Space
```bash
df -h
```

### Check Memory Usage
```bash
free -h
```

### Check Running Processes
```bash
top
# or
htop  # if installed
```

### Rotate JWT Secret
```bash
# Generate new secret
NEW_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
echo $NEW_SECRET

# Update in environment file
sudo sed -i "s/JWT_SECRET=.*/JWT_SECRET=$NEW_SECRET/" /var/www/html/AurovilleConnect/server/.env

# Restart service
sudo systemctl restart auroville-connect
```

## Backup Management

### Clean Old Backups
```bash
# Remove backups older than 30 days
find /root/db_backups -name "auroville_*.sql" -mtime +30 -delete
```

### Check Backup Size
```bash
du -sh /root/db_backups
```

## Troubleshooting

### Check for Port Conflicts
```bash
sudo lsof -i :5000
sudo lsof -i :80
sudo lsof -i :443
```

### Test Nginx Configuration
```bash
sudo nginx -t
```

### Check for Errors in Application
```bash
sudo journalctl -u auroville-connect -p err
```

### Restart Everything
```bash
sudo systemctl restart postgresql
sudo systemctl restart auroville-connect
sudo systemctl restart nginx
```

## Performance Monitoring

### Check CPU Usage
```bash
mpstat 1 5
```

### Check Memory Usage
```bash
vmstat 1 5
```

### Check Disk I/O
```bash
iostat -x 1 5
```

### Check Network Usage
```bash
iftop  # if installed
# or
netstat -tulpn
```

## Common Issues and Solutions

### Application Not Starting
1. Check logs: `sudo journalctl -u auroville-connect -f`
2. Verify environment variables: `cat /var/www/html/AurovilleConnect/server/.env`
3. Check if database is running: `sudo systemctl status postgresql`
4. Ensure correct Node.js version: `node --version`

### Database Connection Issues
1. Check PostgreSQL is running: `sudo systemctl status postgresql`
2. Verify connection string in .env file
3. Check PostgreSQL logs: `sudo tail -f /var/log/postgresql/postgresql-*.log`
4. Ensure database exists: `sudo -u postgres psql -c "\l" | grep auroville`

### Nginx/SSL Issues
1. Test Nginx config: `sudo nginx -t`
2. Check SSL certificates: `sudo certbot certificates`
3. Verify domain DNS settings: `dig auroville.social`
4. Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`

### Performance Issues
1. Check server load: `uptime`
2. Monitor resource usage: `top` or `htop`
3. Check disk space: `df -h`
4. Consider increasing server resources if consistently high usage
