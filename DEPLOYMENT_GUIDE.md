# BetWinner Agent Portal - Deployment Guide

This guide provides instructions for deploying the BetWinner Agent Portal on a dedicated server or VPS. For shared hosting deployment, please refer to [SHARED_HOSTING_GUIDE.md](SHARED_HOSTING_GUIDE.md).

## Server Requirements

- Ubuntu 20.04 LTS or later (recommended)
- Node.js 16.x or later
- PostgreSQL 12 or later
- Nginx web server
- At least 2GB RAM
- 20GB disk space

## Deployment Steps

### Automated Deployment

For most users, the automated deployment script is the easiest way to deploy:

1. Upload the `deploy.sh` script to your server
2. Make it executable: `chmod +x deploy.sh`
3. Run the script: `sudo ./deploy.sh`
4. Follow the on-screen prompts

The automated deployment handles:
- System dependencies installation
- PostgreSQL database setup
- Node.js installation
- Application installation
- Nginx configuration
- SSL certificate (Let's Encrypt)
- Process management (PM2)
- Firewall configuration

### Manual Deployment

If you prefer to deploy manually, follow these steps:

#### 1. Install System Dependencies

```bash
apt update
apt install -y curl git build-essential postgresql postgresql-contrib nginx
```

#### 2. Install Node.js

```bash
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
apt install -y nodejs
```

#### 3. Set Up PostgreSQL

```bash
sudo -i -u postgres psql
```

In PostgreSQL prompt:
```sql
CREATE DATABASE betwinner;
CREATE USER betwinneruser WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE betwinner TO betwinneruser;
\q
```

#### 4. Clone Repository & Install Dependencies

```bash
git clone https://github.com/yourusername/betwinner-agent-portal.git /var/www/betwinner
cd /var/www/betwinner
npm install --production
```

#### 5. Configure Environment Variables

```bash
cat > /var/www/betwinner/.env << EOL
DATABASE_URL=postgres://betwinneruser:your_secure_password@localhost:5432/betwinner
NODE_ENV=production
PORT=5000
EOL
```

#### 6. Initialize Database

```bash
cd /var/www/betwinner
npm run db:push
npm run create-admin-user
npm run create-exchange-rate
npm run add-payment-methods
npm run create-remittance-fees
```

#### 7. Set Up Process Management (PM2)

```bash
npm install -g pm2
pm2 start npm --name "betwinner" -- run start
pm2 save
pm2 startup
```

#### 8. Configure Nginx

```bash
cat > /etc/nginx/sites-available/betwinner << EOL
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

ln -s /etc/nginx/sites-available/betwinner /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

#### 9. Set Up SSL (Optional but Recommended)

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d your-domain.com
```

#### 10. Configure Firewall

```bash
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable
```

## Post-Deployment

### Monitoring

Monitor your application with PM2:

```bash
pm2 status
pm2 logs betwinner
```

### Backups

Set up regular database backups:

```bash
# Add to crontab:
crontal -e

# Add this line for daily backups at 2 AM:
0 2 * * * pg_dump -U betwinneruser -d betwinner > /var/backups/betwinner_$(date +\%Y\%m\%d).sql
```

### Updates

To update your application:

```bash
cd /var/www/betwinner
git pull
npm install --production
npm run db:push
pm2 restart betwinner
```

## Troubleshooting

### Common Issues

- **Application Cannot Connect to Database**:
  - Check the DATABASE_URL environment variable
  - Verify PostgreSQL is running: `systemctl status postgresql`
  - Check database permissions

- **Nginx Configuration Issues**:
  - Test Nginx config: `nginx -t`
  - Check Nginx logs: `tail -f /var/log/nginx/error.log`

- **Node.js Application Won't Start**:
  - Check PM2 logs: `pm2 logs betwinner`
  - Verify Node.js version: `node -v`
  - Check disk space: `df -h`

## Security Considerations

- Change default admin password immediately after deployment
- Keep your server updated with security patches
- Consider implementing IP restrictions for admin access
- Set up fail2ban to prevent brute force attacks
- Regularly review PM2 and Nginx logs for suspicious activity
