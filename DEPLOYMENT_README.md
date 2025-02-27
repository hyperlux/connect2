# Auroville Connect Deployment Documentation

This directory contains all the necessary documentation and scripts for deploying the Auroville Connect application to auroville.social.

## Files Overview

1. **deploy-to-auroville.sh**
   - Automated deployment script that handles the entire deployment process
   - Must be customized with your specific details before running
   - Requires root or sudo privileges on the target server

2. **DEPLOYMENT_GUIDE.md**
   - Comprehensive step-by-step guide for deploying the application
   - Includes detailed explanations for each deployment step
   - Covers pre-deployment preparation, deployment execution, and post-deployment tasks

3. **DEPLOYMENT_CHECKLIST.md**
   - Concise checklist to track deployment progress
   - Helps ensure no critical steps are missed
   - Can be used alongside the detailed guide

4. **MAINTENANCE_QUICK_REFERENCE.md**
   - Quick reference for common maintenance tasks
   - Includes commands for service management, updates, backups, and troubleshooting
   - Useful for ongoing maintenance after successful deployment

## Deployment Workflow

The recommended workflow for deploying the Auroville Connect application is:

1. **Preparation**
   - Review the DEPLOYMENT_GUIDE.md to understand the full deployment process
   - Ensure all prerequisites are met (server access, domain configuration, etc.)
   - Customize the deploy-to-auroville.sh script with your specific details

2. **Deployment**
   - Transfer the deployment script to your server
   - Execute the script and monitor the deployment process
   - Use the DEPLOYMENT_CHECKLIST.md to track progress

3. **Verification**
   - Verify the application is running correctly
   - Test key functionality
   - Complete post-deployment tasks

4. **Maintenance**
   - Refer to MAINTENANCE_QUICK_REFERENCE.md for ongoing maintenance tasks
   - Set up regular backups and updates
   - Monitor application performance and security

## Important Notes

- **Security**: The deployment script contains placeholders for sensitive information like database passwords and JWT secrets. Be sure to replace these with secure values.
- **Customization**: You may need to modify the deployment process based on your specific server environment or requirements.
- **Backup**: Always ensure you have backups before making significant changes to a production environment.
- **Support**: If you encounter issues during deployment, refer to the troubleshooting sections in the documentation.

## Getting Started

To begin the deployment process, start by reviewing the DEPLOYMENT_GUIDE.md file for a comprehensive understanding of the deployment steps.

```bash
# View the deployment guide
cat DEPLOYMENT_GUIDE.md
```

Then, customize the deployment script with your specific details:

```bash
# Edit the deployment script
nano deploy-to-auroville.sh
```

Follow the instructions in the deployment guide to complete the deployment process.
