#!/bin/bash
# Quick Deployment Script for LibreChat on Hetzner
# Domain: chat.daydemy.com
# Server: 88.99.26.236

set -e

echo "=========================================="
echo "LibreChat Deployment Script"
echo "Domain: chat.daydemy.com"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Variables
LIBRECHAT_DIR="/opt/librechat"
DOMAIN="chat.daydemy.com"
NGINX_SITE="/etc/nginx/sites-available/librechat"

# Step 1: Create directory
echo -e "${YELLOW}Step 1: Creating directory...${NC}"
mkdir -p $LIBRECHAT_DIR
cd $LIBRECHAT_DIR

# Step 2: Check if .env exists
echo -e "${YELLOW}Step 2: Checking .env file...${NC}"
if [ ! -f "$LIBRECHAT_DIR/.env" ]; then
    echo -e "${RED}.env file not found!${NC}"
    echo "Please create .env file from env.production"
    echo "Don't forget to:"
    echo "  - Generate JWT_SECRET: openssl rand -base64 32"
    echo "  - Generate JWT_REFRESH_SECRET: openssl rand -base64 32"
    echo "  - Generate MEILI_MASTER_KEY: openssl rand -base64 32"
    exit 1
fi

# Step 3: Create necessary directories
echo -e "${YELLOW}Step 3: Creating necessary directories...${NC}"
mkdir -p images uploads logs data-node meili_data_v1.12
chown -R 1000:1000 images uploads logs data-node meili_data_v1.12

# Step 4: Check if docker-compose.production.yml exists
echo -e "${YELLOW}Step 4: Checking docker-compose file...${NC}"
if [ ! -f "$LIBRECHAT_DIR/deploy/docker-compose.production.yml" ]; then
    echo -e "${RED}docker-compose.production.yml not found!${NC}"
    exit 1
fi

# Copy docker-compose file
cp deploy/docker-compose.production.yml docker-compose.yml

# Step 5: Check if librechat.yaml exists
echo -e "${YELLOW}Step 5: Checking librechat.yaml...${NC}"
if [ ! -f "$LIBRECHAT_DIR/librechat.yaml" ]; then
    echo -e "${RED}librechat.yaml not found!${NC}"
    exit 1
fi

# Step 6: Setup Nginx
echo -e "${YELLOW}Step 6: Setting up Nginx...${NC}"
if [ ! -f "$LIBRECHAT_DIR/deploy/nginx-librechat.conf" ]; then
    echo -e "${RED}nginx-librechat.conf not found!${NC}"
    exit 1
fi

# Copy nginx config
cp deploy/nginx-librechat.conf $NGINX_SITE

# Check if SSL certificate exists
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo -e "${YELLOW}SSL certificate not found. Creating...${NC}"
    echo "Make sure domain $DOMAIN is pointing to this server!"
    read -p "Press Enter to continue with certbot..."
    certbot certonly --nginx -d $DOMAIN
fi

# Enable site
if [ ! -L "/etc/nginx/sites-enabled/librechat" ]; then
    ln -s $NGINX_SITE /etc/nginx/sites-enabled/
fi

# Test nginx config
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
nginx -t

# Reload nginx
echo -e "${YELLOW}Reloading Nginx...${NC}"
systemctl reload nginx

# Step 7: Start Docker Compose
echo -e "${YELLOW}Step 7: Starting Docker Compose...${NC}"
cd $LIBRECHAT_DIR
docker-compose up -d

# Step 8: Check status
echo -e "${YELLOW}Step 8: Checking status...${NC}"
sleep 5
docker-compose ps

# Step 9: Check logs
echo -e "${YELLOW}Step 9: Checking logs...${NC}"
echo "View logs with: docker-compose logs -f api"

# Step 10: Final instructions
echo -e "${GREEN}=========================================="
echo "Deployment completed!"
echo "=========================================="
echo "Domain: https://$DOMAIN"
echo "Next steps:"
echo "1. Update Google OAuth redirect URI:"
echo "   https://$DOMAIN/oauth/google/callback"
echo "2. Check logs: docker-compose logs -f api"
echo "3. Test: curl http://localhost:3080/api/health"
echo "==========================================${NC}"












