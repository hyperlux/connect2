# Auroville Connect Deployment Checklist

Use this checklist to track your progress when deploying the Auroville Connect application to auroville.social.

## Pre-Deployment Preparation

- [x] Ensure you have SSH access to the server
- [x] Verify domain names (auroville.social and api.auroville.social) are pointing to your server
- [x] Check server specifications (recommended: 2+ CPU cores, 4+ GB RAM, 20+ GB storage)
- [x] Backup any existing data on the server if applicable

## Server Setup

- [x] Install required software:
  - [x] Node.js 18+ and npm
  - [x] Git
  - [x] PostgreSQL
  - [x] Nginx
  - [x] Certbot

## Deployment Script Preparation

- [x] Transfer the deployment script to the server
- [x] Customize the script with your specific details:
  - [x] Repository URL
  - [x] PostgreSQL password
  - [x] JWT secret
  - [x] Email for SSL certificates

## Deployment Execution

- [x] Make the deployment script executable
- [x] Run the deployment script
- [x] Monitor the deployment process for any errors

## Verification

- [x] Check service status:
  - [x] auroville-connect service
  - [x] Nginx service
  - [x] PostgreSQL service
- [x] Verify application accessibility:
  - [x] Frontend at https://auroville.social
  - [x] API at https://api.auroville.social/health
- [ ] Test basic functionality:
  - [ ] User registration/login
  - [ ] Forum posts
  - [ ] Events calendar

## Post-Deployment Tasks

- [x] Create an admin user
- [x] Set up database backups
- [x] Configure log rotation
- [ ] Set up monitoring (optional)
- [ ] Configure firewall
- [ ] Install and configure fail2ban (optional)

## Documentation

- [x] Document any custom configurations made during deployment
- [x] Save important credentials securely
- [x] Update team members on deployment status

## Maintenance Plan

- [x] Schedule regular updates
- [x] Plan for SSL certificate renewals (automatic with certbot)
- [ ] Set up regular security audits
- [x] Create a backup and recovery plan

## Notes

Use this space to document any issues encountered during deployment and their solutions:

```
[2025-02-26] [403 Forbidden Error] [Updated Nginx configuration to point to the correct directory (dist instead of public)]
[2025-02-26] [Admin User Creation Error] [Created a wrapper script with dotenv to properly load environment variables]
```

---

Refer to the detailed DEPLOYMENT_GUIDE.md for step-by-step instructions on each of these tasks.
