#!/bin/bash

# Simple deployment package creator for BetWinner Agent Portal
# This script creates a deployment package for shared hosting environments

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CLEAR='\033[0m'

echo -e "${YELLOW}====================================================${CLEAR}"
echo -e "${YELLOW}  Creating BetWinner Shared Hosting Package${CLEAR}"
echo -e "${YELLOW}====================================================${CLEAR}"

# Define directories
BASE_DIR="$(pwd)"
PACKAGE_DIR="$BASE_DIR/hosting-package"
ZIP_FILE="$BASE_DIR/betwinner_shared_hosting.zip"

# Clean up any previous package
rm -rf "$PACKAGE_DIR" 2>/dev/null
rm -f "$ZIP_FILE" 2>/dev/null

# Create package directory
mkdir -p "$PACKAGE_DIR"

# Copy essential files
echo -e "${YELLOW}Copying essential files...${CLEAR}"

# Server and shared files
mkdir -p "$PACKAGE_DIR/server"
mkdir -p "$PACKAGE_DIR/shared"
cp -r server/*.ts "$PACKAGE_DIR/server/"
cp -r shared/*.ts "$PACKAGE_DIR/shared/"

# Configuration files
cp package.json "$PACKAGE_DIR/"
cp tsconfig.json "$PACKAGE_DIR/"
cp drizzle.config.ts "$PACKAGE_DIR/"

# PWA files
mkdir -p "$PACKAGE_DIR/public/icons"
cp -r public/icons/* "$PACKAGE_DIR/public/icons/"
cp public/manifest.json "$PACKAGE_DIR/public/"
cp public/service-worker.js "$PACKAGE_DIR/public/"

# Scripts
cp create-admin-user.ts "$PACKAGE_DIR/"
cp create-exchange-rate.ts "$PACKAGE_DIR/"
cp add-payment-methods.ts "$PACKAGE_DIR/"
cp create-remittance-fees.ts "$PACKAGE_DIR/"

# Docs
cp README.md "$PACKAGE_DIR/"
cp SHARED_HOSTING_GUIDE.md "$PACKAGE_DIR/"
cp MOBILE_INSTALLATION_GUIDE.md "$PACKAGE_DIR/"

# Installers
cp shared_hosting_installer.php "$PACKAGE_DIR/installer.php"
cp cpanel_setup.php "$PACKAGE_DIR/cpanel_setup.php"

# Create a basic .env.example file
cat > "$PACKAGE_DIR/.env.example" << EOL
# Database Configuration
DATABASE_URL=postgres://username:password@localhost:5432/database_name

# Node Environment
NODE_ENV=production

# Application Port
PORT=5000
EOL

# Create a basic install script
cat > "$PACKAGE_DIR/install.sh" << EOL
#!/bin/bash

# BetWinner Shared Hosting Setup

# Install dependencies
npm install --production

# Create database schema
npm run db:push

# Initialize basic data
npm run create-admin-user
npm run create-exchange-rate
npm run add-payment-methods
npm run create-remittance-fees

echo "Installation complete! Please set up your web server to point to this directory."
EOL
chmod +x "$PACKAGE_DIR/install.sh"

# Create zip file
echo -e "${YELLOW}Creating zip archive...${CLEAR}"
cd "$BASE_DIR"
zip -r "$ZIP_FILE" "hosting-package" > /dev/null

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Package created successfully: $ZIP_FILE${CLEAR}"
  echo -e "${YELLOW}Package size: $(du -h "$ZIP_FILE" | cut -f1)${CLEAR}"
  
  # Clean up package directory
  rm -rf "$PACKAGE_DIR"
  
  echo -e "\n${YELLOW}Instructions:${CLEAR}"
  echo -e "1. Upload and extract the ZIP file to your shared hosting account"
  echo -e "2. Navigate to your domain/installer.php to complete the installation"
  echo -e "3. Follow the on-screen prompts to configure your application"
else
  echo -e "${RED}Failed to create package.${CLEAR}"
  exit 1
fi
