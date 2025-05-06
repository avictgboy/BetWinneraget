# BetWinner Agent Portal - Shared Hosting Installation Guide

This guide will help you install BetWinner Agent Portal on a shared hosting environment like HostGator, Namecheap, or similar services.

## Requirements

Before you begin, make sure your shared hosting environment meets the following requirements:

- PHP 8.0 or higher
- PostgreSQL database
- PHP extensions: pdo, pdo_pgsql, json, openssl, zip
- Node.js 16.x or higher support
- NPM support

## Installation Steps

### 1. Prepare Your Hosting Environment

1. Log in to your hosting control panel (cPanel, Plesk, etc.)
2. Create a new PostgreSQL database and database user
3. Note down the database credentials (host, port, database name, username, password)

### 2. Upload Files

1. Download the deployment package `betwinner_deploy.zip`
2. Extract the package on your local computer
3. Upload all files to your hosting account using FTP or the file manager in your control panel
4. Make sure to maintain the directory structure

### 3. Run the Installer

1. Navigate to `https://your-domain.com/installer.php` in your web browser
2. Follow the on-screen instructions to complete the installation:
   - System requirements check
   - Database configuration
   - Admin account setup
   - Installation process

### 4. Post-Installation

1. Delete the installer file (`installer.php`) for security
2. Log in with your admin credentials
3. Configure payment methods and other settings
4. Your BetWinner Agent Portal is now ready to use!

## Troubleshooting

### Common Issues

- **Database Connection Fails**: Double-check your database credentials and make sure the database user has proper permissions
- **Missing PHP Extensions**: Contact your hosting provider to enable required PHP extensions
- **Node.js Not Available**: Some shared hosting environments don't support Node.js. Consider upgrading to a hosting plan that supports Node.js or using a VPS

### For HostGator Users

1. You may need to use SSH access to run Node.js commands
2. For database connection, use:
   - Host: localhost
   - Port: 5432 (default)

### For Namecheap Users

1. Make sure you're using a Namecheap shared hosting plan that supports Node.js
2. You may need to configure Node.js version using `.node-version` file

## Support

If you encounter issues during installation, please contact your hosting provider for assistance with server configuration or contact BetWinner support for application-specific issues.

## Custom Installation

For more customized installations or deployment on VPS/dedicated servers, refer to the main `DEPLOYMENT_GUIDE.md` document.
