#!/bin/bash

# Deployment package creator for BetWinner Agent Portal
# This script creates a deployment package for shared hosting environments

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
CLEAR='\033[0m'

echo -e "${CYAN}====================================================${CLEAR}"
echo -e "${CYAN}  Creating BetWinner Agent Portal Deployment Package${CLEAR}"
echo -e "${CYAN}====================================================${CLEAR}"

# Define directories
BASE_DIR="$(pwd)"
BUILD_DIR="$BASE_DIR/build"
TMP_DIR="$BASE_DIR/tmp"
DIST_DIR="$BASE_DIR/dist"
DEPLOY_DIR="$BASE_DIR/deploy"

# Create required directories
echo -e "${YELLOW}Creating deployment directories...${CLEAR}"
mkdir -p "$TMP_DIR"
mkdir -p "$DEPLOY_DIR"

# Build the frontend
echo -e "${YELLOW}Building frontend assets...${CLEAR}"
npm run build

if [ $? -ne 0 ]; then
  echo -e "${RED}Frontend build failed. Aborting.${CLEAR}"
  exit 1
fi

# Create server directory structure
echo -e "${YELLOW}Creating server deployment structure...${CLEAR}"
rm -rf "$TMP_DIR"/*

# Copy necessary files
mkdir -p "$TMP_DIR/server"
mkdir -p "$TMP_DIR/shared"
mkdir -p "$TMP_DIR/public"

# Copy server files
cp -r server/*.js "$TMP_DIR/server/" 2>/dev/null || true
cp -r server/*.ts "$TMP_DIR/server/" 2>/dev/null || true

# Copy shared files
cp -r shared/*.js "$TMP_DIR/shared/" 2>/dev/null || true
cp -r shared/*.ts "$TMP_DIR/shared/" 2>/dev/null || true

# Copy built frontend
cp -r "$DIST_DIR"/* "$TMP_DIR/public/"

# Copy configuration files
cp package.json "$TMP_DIR/"
cp package-lock.json "$TMP_DIR/"
cp tsconfig.json "$TMP_DIR/"
cp drizzle.config.ts "$TMP_DIR/"

# Copy installation scripts
cp shared_hosting_installer.php "$TMP_DIR/"
cp SHARED_HOSTING_GUIDE.md "$TMP_DIR/INSTALL.md"

# Remove previous zip file if exists
echo -e "${YELLOW}Preparing deployment package...${CLEAR}"
rm -f "$DEPLOY_DIR/betwinner_deploy.zip" 2>/dev/null || true

# Create deployment package
cd "$TMP_DIR"
zip -r "$DEPLOY_DIR/betwinner_deploy.zip" . -x "*.git*" -x "*node_modules*" > /dev/null

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to create deployment package. Aborting.${CLEAR}"
  exit 1
fi

# Clean up
cd "$BASE_DIR"
rm -rf "$TMP_DIR"

echo -e "${GREEN}Deployment package created successfully!${CLEAR}"
echo -e "${BLUE}Location: $DEPLOY_DIR/betwinner_deploy.zip${CLEAR}"
echo -e "${YELLOW}File size: $(du -h "$DEPLOY_DIR/betwinner_deploy.zip" | cut -f1)${CLEAR}"
echo -e "\n${MAGENTA}Instructions:${CLEAR}"
echo -e "1. Upload the deployment package to your shared hosting server"
echo -e "2. Extract the package to your web directory"
echo -e "3. Navigate to your domain/installer.php to run the installer"
echo -e "4. Follow the on-screen instructions to complete the installation"
echo -e "\n${CYAN}====================================================${CLEAR}"
