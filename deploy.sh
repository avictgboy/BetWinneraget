#!/bin/bash

# BetWinner Agent Portal - One-Click Deployment Script
# This script handles the entire deployment process in a single command

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo -e "${BOLD}${GREEN}BetWinner Agent Portal - One-Click Deployment Script${NC}\n"

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}This script must be run as root or with sudo privileges${NC}" 1>&2
   exit 1
fi

# Configuration variables (can be overridden with command line arguments)
INSTALL_DIR="/var/www/betwinner"
DB_NAME="betwinner"
DB_USER="betwinneruser"
DB_PASS=$(openssl rand -base64 12) # Generate a random password
WEB_PORT=3000
DOMAIN="" # Will be prompted if not provided

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-dir=*)
            INSTALL_DIR="${1#*=}"
            shift
            ;;
        --db-name=*)
            DB_NAME="${1#*=}"
            shift
            ;;
        --db-user=*)
            DB_USER="${1#*=}"
            shift
            ;;
        --db-pass=*)
            DB_PASS="${1#*=}"
            shift
            ;;
        --web-port=*)
            WEB_PORT="${1#*=}"
            shift
            ;;
        --domain=*)
            DOMAIN="${1#*=}"
            shift
            ;;
        --help|-h)
            echo -e "${BOLD}BetWinner Agent Portal - Deployment Options${NC}\n"
            echo -e "Usage: $0 [options]\n"
            echo -e "Options:"
            echo "  --install-dir=PATH   Installation directory (default: /var/www/betwinner)"
            echo "  --db-name=NAME       Database name (default: betwinner)"
            echo "  --db-user=USER       Database username (default: betwinneruser)"
            echo "  --db-pass=PASS       Database password (default: auto-generated)"
            echo "  --web-port=PORT      Web application port (default: 3000)"
            echo "  --domain=DOMAIN      Domain name (default: prompt during install)"
            echo "  --help, -h           Show this help message"
            echo -e "\nExample: $0 --install-dir=/opt/betwinner --domain=betwinner.example.com"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
done

# Function to check command success
check_command() {
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}Error: $1 failed. Installation aborted.${NC}"
        exit 1
    fi
}

# Prompt for domain if not provided
if [ -z "$DOMAIN" ]; then
    read -p "Enter domain name for your application (e.g., betwinner.example.com): " DOMAIN
    if [ -z "$DOMAIN" ]; then
        echo -e "${YELLOW}No domain provided. Will use server IP address instead.${NC}"
    fi
fi

# Function to log progress
log_progress() {
    echo -e "\n${BOLD}${GREEN}[$1]${NC} $2"
}

# Function to log a task
log_task() {
    echo -e "  ${BLUE}→${NC} $1"
}

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    log_progress "SYSTEM" "Detected operating system: $OS $VER"
else
    echo -e "${RED}Cannot detect operating system. This script supports Ubuntu and Debian.${NC}"
    exit 1
fi

# 1. Update system
log_progress "SYSTEM" "Updating system packages"
apt-get update
check_command "System update"
apt-get upgrade -y
check_command "System upgrade"

# 2. Install required packages
log_progress "DEPENDENCIES" "Installing required packages"
log_task "Installing system dependencies"
apt-get install -y curl wget zip unzip git build-essential nginx
check_command "Installing system dependencies"

# 3. Install PostgreSQL
log_progress "DATABASE" "Setting up PostgreSQL"
if ! command -v psql &> /dev/null; then
    log_task "Installing PostgreSQL"
    apt-get install -y postgresql postgresql-contrib
    check_command "PostgreSQL installation"
    systemctl enable postgresql
    systemctl start postgresql
    log_task "PostgreSQL installed successfully"
else
    log_task "PostgreSQL is already installed"
fi

# 4. Install Node.js
log_progress "RUNTIME" "Setting up Node.js"
if ! command -v node &> /dev/null; then
    log_task "Installing Node.js"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    check_command "Node.js repository setup"
    apt-get install -y nodejs
    check_command "Node.js installation"
    log_task "Node.js installed: $(node -v)"
else
    NODE_VER=$(node -v)
    log_task "Node.js is already installed: $NODE_VER"
fi

# 5. Set up Database
log_progress "DATABASE" "Creating PostgreSQL database"
log_task "Setting up database: $DB_NAME"

# Check if database already exists
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    log_task "Database $DB_NAME already exists"
else
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
    check_command "Database creation"
    log_task "Database created: $DB_NAME"
    
    # Create database user
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
        log_task "User $DB_USER already exists"
    else
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
        check_command "Database user creation"
        log_task "Database user created: $DB_USER"
    fi
    
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    check_command "Database privileges"
    log_task "Database privileges granted to $DB_USER"
fi

# 6. Create installation directory
log_progress "APPLICATION" "Setting up application"
log_task "Creating installation directory: $INSTALL_DIR"
mkdir -p $INSTALL_DIR
check_command "Creating installation directory"

# 7. Extract or clone application files
log_task "Installing application files"
if [ -f "betwinner_project.zip" ]; then
    unzip betwinner_project.zip -d $INSTALL_DIR
    check_command "Extracting application files"
    log_task "Application files extracted from ZIP"
elif [ -f "./create_deployment_package.sh" ]; then
    # Run the deployment package creator
    log_task "Creating deployment package"
    ./create_deployment_package.sh
    check_command "Creating deployment package"
    unzip betwinner_project.zip -d $INSTALL_DIR
    check_command "Extracting application files"
    log_task "Application files extracted from generated ZIP"
else
    # If we're already in the application directory
    log_task "Copying application files"
    cp -r ./* $INSTALL_DIR/
    check_command "Copying application files"
fi

# 8. Set proper permissions
log_task "Setting file permissions"
chown -R www-data:www-data $INSTALL_DIR
chmod -R 755 $INSTALL_DIR

# 9. Create environment configuration
log_progress "CONFIGURATION" "Creating application configuration"
if [ ! -f "$INSTALL_DIR/.env" ]; then
    log_task "Creating .env file"
    cat > "$INSTALL_DIR/.env" << EOL
DATABASE_URL="postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME"
NODE_ENV=production
PORT=$WEB_PORT
EOL
    check_command "Creating .env file"
else
    log_task ".env file already exists"
fi

# 10. Install application dependencies
log_progress "DEPENDENCIES" "Installing Node.js dependencies"
log_task "Running npm install"
cd $INSTALL_DIR
npm install --production
check_command "Installing dependencies"

# 11. Build the application
log_progress "BUILD" "Building the application"
log_task "Running build process"
npm run build
check_command "Building application"

# 12. Initialize database
log_progress "DATABASE" "Initializing database schema"
log_task "Running database migrations"
npm run db:push
check_command "Database initialization"

# 13. Create initial data
log_progress "DATA" "Creating initial application data"
log_task "Creating admin user"
npm run create-admin-user
log_task "Creating exchange rates"
npm run create-exchange-rate
log_task "Adding payment methods"
npm run add-payment-methods
log_task "Creating remittance fees"
npm run create-remittance-fees

# 14. Set up PM2 for process management
log_progress "PROCESS" "Setting up process management"
log_task "Installing PM2"
npm install -g pm2
check_command "PM2 installation"

log_task "Configuring PM2 process"
pm2 start npm --name "betwinner" -- run start
check_command "Starting application with PM2"
pm2 save
log_task "Configuring PM2 startup"
pm2 startup | tail -n 1 > pm2_startup_command.sh
chmod +x pm2_startup_command.sh
./pm2_startup_command.sh
rm pm2_startup_command.sh

# 15. Configure Nginx
log_progress "WEBSERVER" "Configuring Nginx"

# Get server IP if no domain provided
if [ -z "$DOMAIN" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
    DOMAIN=$SERVER_IP
fi

log_task "Creating Nginx site configuration"
cat > /etc/nginx/sites-available/betwinner << EOL
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$WEB_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL
check_command "Creating Nginx configuration"

# Enable the site
log_task "Enabling Nginx site"
ln -sf /etc/nginx/sites-available/betwinner /etc/nginx/sites-enabled/
check_command "Enabling Nginx site"

# Test and restart Nginx
log_task "Testing Nginx configuration"
nginx -t
check_command "Testing Nginx configuration"

log_task "Restarting Nginx"
systemctl restart nginx
check_command "Restarting Nginx"

# 16. Set up SSL with Let's Encrypt (if domain is provided and not an IP)
if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_progress "SSL" "Skipping SSL setup as domain is an IP address: $DOMAIN"
else
    log_progress "SSL" "Setting up SSL with Let's Encrypt"
    
    log_task "Installing Certbot"
    apt-get install -y certbot python3-certbot-nginx
    check_command "Installing Certbot"
    
    log_task "Obtaining SSL certificate"
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
    # Don't check command here as it might fail if DNS isn't set up yet
    if [ $? -ne 0 ]; then
        log_task "${YELLOW}Warning: Could not obtain SSL certificate. You can run certbot manually later.${NC}"
    else
        log_task "SSL certificate installed successfully"
    fi
fi

# 17. Setup Firewall
log_progress "SECURITY" "Configuring firewall"
if command -v ufw &> /dev/null; then
    log_task "Enabling UFW firewall"
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw --force enable
    check_command "Enabling firewall"
fi

# 18. Generate documentation
log_progress "DOCUMENTATION" "Creating server documentation"

DOCS_DIR="$INSTALL_DIR/docs"
mkdir -p $DOCS_DIR

log_task "Generating server information document"
cat > "$DOCS_DIR/server_info.md" << EOL
# BetWinner Agent Portal - Server Information

## Server Details

- **Deployment Date:** $(date)
- **Server OS:** $OS $VER
- **IP Address:** $(hostname -I | awk '{print $1}')
- **Domain:** $DOMAIN

## Database Information

- **Database Type:** PostgreSQL
- **Database Name:** $DB_NAME
- **Database User:** $DB_USER
- **Database Password:** $DB_PASS

## Application Details

- **Installation Directory:** $INSTALL_DIR
- **Web Port:** $WEB_PORT
- **Process Manager:** PM2
- **Web Server:** Nginx

## Access Information

- **URL:** http://$DOMAIN (or https://$DOMAIN if SSL is enabled)
- **Admin Username:** admin
- **Admin Password:** admin123 (IMPORTANT: Change immediately after first login)

## Maintenance Commands

**View application logs:**
\`\`\`
pm2 logs betwinner
\`\`\`

**Restart the application:**
\`\`\`
pm2 restart betwinner
\`\`\`

**Check application status:**
\`\`\`
pm2 status
\`\`\`

## Backup Instructions

**Database backup:**
\`\`\`
pg_dump -U $DB_USER -d $DB_NAME > backup_\$(date +%Y%m%d).sql
\`\`\`

**Application backup:**
\`\`\`
cp -r $INSTALL_DIR /backup/betwinner_\$(date +%Y%m%d)
\`\`\`
EOL

# 19. Final steps
log_progress "SUMMARY" "Installation complete!"

echo -e "\n${BOLD}${GREEN}BetWinner Agent Portal has been successfully deployed!${NC}\n"

echo -e "${YELLOW}Database Information:${NC}"
echo -e "   Database Name: ${BOLD}$DB_NAME${NC}"
echo -e "   Database User: ${BOLD}$DB_USER${NC}"
echo -e "   Database Password: ${BOLD}$DB_PASS${NC}"
echo -e "   Save this information in a secure location!"

echo -e "\n${YELLOW}Access Information:${NC}"
echo -e "   URL: ${BOLD}http://$DOMAIN${NC}"
echo -e "   Admin Username: ${BOLD}admin${NC}"
echo -e "   Admin Password: ${BOLD}admin123${NC}"
echo -e "   ${RED}IMPORTANT: Change the admin password immediately after your first login!${NC}"

echo -e "\n${YELLOW}Documentation:${NC}"
echo -e "   Server information has been saved to: ${BOLD}$DOCS_DIR/server_info.md${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Update your DNS to point to this server (if using a domain)"
echo -e "2. Change the admin password in the application"
echo -e "3. Configure payment methods in the admin panel"
echo -e "4. Set up a regular backup schedule"

echo -e "\nThank you for installing BetWinner Agent Portal!\n"