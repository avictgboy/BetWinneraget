#!/bin/bash

# BetWinner Agent Portal - Installation Script
# This script automates the installation of the BetWinner Agent Portal application

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${BOLD}${GREEN}BetWinner Agent Portal - Installation Script${NC}\n"

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}This script must be run as root or with sudo privileges${NC}" 1>&2
   exit 1
fi

# Function to check command success
check_command() {
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}Error: $1 failed. Installation aborted.${NC}"
        exit 1
    fi
}

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo -e "${RED}Cannot detect operating system. This script supports Ubuntu and Debian.${NC}"
    exit 1
fi

echo -e "${YELLOW}Detected operating system: $OS $VER${NC}\n"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}PostgreSQL is not installed. Installing...${NC}"
    apt-get update
    check_command "apt-get update"
    apt-get install -y postgresql postgresql-contrib
    check_command "PostgreSQL installation"
    systemctl enable postgresql
    systemctl start postgresql
    echo -e "${GREEN}PostgreSQL installed successfully${NC}\n"
else
    echo -e "${GREEN}PostgreSQL is already installed${NC}\n"
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Node.js is not installed. Installing Node.js 18.x...${NC}"
    apt-get update
    check_command "apt-get update"
    apt-get install -y ca-certificates curl gnupg
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install -y nodejs
    check_command "Node.js installation"
    echo -e "${GREEN}Node.js installed successfully: $(node -v)${NC}\n"
else
    NODE_VER=$(node -v)
    echo -e "${GREEN}Node.js is already installed: $NODE_VER${NC}\n"
fi

# Install PM2 globally
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}Installing PM2...${NC}"
    npm install -g pm2
    check_command "PM2 installation"
    echo -e "${GREEN}PM2 installed successfully${NC}\n"
else
    echo -e "${GREEN}PM2 is already installed${NC}\n"
fi

# Install Nginx if not already installed
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}Installing Nginx...${NC}"
    apt-get update
    apt-get install -y nginx
    check_command "Nginx installation"
    systemctl enable nginx
    systemctl start nginx
    echo -e "${GREEN}Nginx installed successfully${NC}\n"
else
    echo -e "${GREEN}Nginx is already installed${NC}\n"
fi

# Configure PostgreSQL database
echo -e "${YELLOW}Setting up PostgreSQL database...${NC}"
DB_NAME="betwinner"
DB_USER="betwinneruser"

# Generate a random password
DB_PASS=$(openssl rand -base64 12)

# Check if database already exists
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    echo -e "${GREEN}Database $DB_NAME already exists${NC}"
else
    # Create database and user
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
    check_command "Database creation"
    
    # Check if user already exists
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
        echo -e "${GREEN}User $DB_USER already exists${NC}"
    else
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
        check_command "Database user creation"
    fi
    
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    check_command "Database privileges"
    echo -e "${GREEN}PostgreSQL database setup completed${NC}\n"
fi

# Installation directory
INSTALL_DIR="/opt/betwinner"
echo -e "${YELLOW}Installing BetWinner Agent Portal to $INSTALL_DIR...${NC}"

# Create installation directory if it doesn't exist
mkdir -p $INSTALL_DIR
check_command "Creating installation directory"

# Unzip application or copy files
if [ -f "betwinner_project.zip" ]; then
    unzip betwinner_project.zip -d $INSTALL_DIR
    check_command "Extracting application files"
else
    # If not running from a zip file, copy all current files
    cp -r ./* $INSTALL_DIR/
    check_command "Copying application files"
fi

# Give proper permissions
chown -R www-data:www-data $INSTALL_DIR
chmod -R 755 $INSTALL_DIR

# Navigate to installation directory
cd $INSTALL_DIR

# Create .env file
echo -e "${YELLOW}Creating environment configuration...${NC}"
if [ ! -f ".env" ]; then
    cat > .env << EOF
DATABASE_URL="postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME"
NODE_ENV=production
PORT=3000
EOF
    check_command "Creating .env file"
    echo -e "${GREEN}.env file created successfully${NC}\n"
else
    echo -e "${GREEN}.env file already exists${NC}\n"
fi

# Install dependencies
echo -e "${YELLOW}Installing Node.js dependencies...${NC}"
npm install --production
check_command "Installing dependencies"
echo -e "${GREEN}Dependencies installed successfully${NC}\n"

# Build the application
echo -e "${YELLOW}Building the application...${NC}"
npm run build
check_command "Building application"
echo -e "${GREEN}Application built successfully${NC}\n"

# Initialize database
echo -e "${YELLOW}Initializing database...${NC}"
npm run db:push
check_command "Database initialization"

# Create admin user and seed data
echo -e "${YELLOW}Creating initial data...${NC}"
npm run create-admin-user
npm run create-exchange-rate
npm run add-payment-methods
npm run create-remittance-fees
echo -e "${GREEN}Initial data created successfully${NC}\n"

# Configure PM2
echo -e "${YELLOW}Configuring PM2...${NC}"
pm2 start npm --name "betwinner" -- run start
check_command "Starting application with PM2"
pm2 save
echo -e "${GREEN}PM2 configuration completed${NC}\n"

# Set up PM2 to start on system boot
pm2 startup
check_command "PM2 startup configuration"

# Configure Nginx
echo -e "${YELLOW}Configuring Nginx...${NC}"

# Get server IP address for default configuration
SERVER_IP=$(hostname -I | awk '{print $1}')

cat > /etc/nginx/sites-available/betwinner << EOF
server {
    listen 80;
    server_name $SERVER_IP;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
check_command "Creating Nginx configuration"

# Enable the site
ln -sf /etc/nginx/sites-available/betwinner /etc/nginx/sites-enabled/
check_command "Enabling Nginx site"

# Test Nginx configuration
nginx -t
check_command "Testing Nginx configuration"

# Restart Nginx
systemctl restart nginx
check_command "Restarting Nginx"

echo -e "${GREEN}Nginx configuration completed${NC}\n"

# Installation complete
echo -e "\n${BOLD}${GREEN}BetWinner Agent Portal Installation Complete!${NC}\n"
echo -e "${YELLOW}Database Information:${NC}"
echo -e "   Database Name: ${BOLD}$DB_NAME${NC}"
echo -e "   Database User: ${BOLD}$DB_USER${NC}"
echo -e "   Database Password: ${BOLD}$DB_PASS${NC}"
echo -e "   Save this information in a secure location!"

echo -e "\n${YELLOW}Access Information:${NC}"
echo -e "   URL: ${BOLD}http://$SERVER_IP${NC}"
echo -e "   Admin Username: ${BOLD}admin${NC}"
echo -e "   Admin Password: ${BOLD}admin123${NC}"
echo -e "   ${RED}IMPORTANT: Change the admin password immediately after your first login!${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Configure a domain name for your site"
echo -e "2. Set up SSL with Let's Encrypt using: ${BOLD}sudo certbot --nginx -d yourdomain.com${NC}"
echo -e "3. Update your password after first login"
echo -e "4. Configure your payment methods in the admin panel"

echo -e "\nThank you for installing BetWinner Agent Portal!\n"
