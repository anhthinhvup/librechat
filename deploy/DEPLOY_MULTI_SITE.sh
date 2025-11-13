#!/bin/bash
# Multi-Site Deployment Script
# Deploy LibreChat (chat.daydemy.com) alongside langhit.com
# Server: 88.99.26.236

set -e

echo "=========================================="
echo "Multi-Site Deployment Script"
echo "Deploying LibreChat alongside langhit.com"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Variables
LIBRECHAT_DIR="/opt/librechat"
DOMAIN="chat.daydemy.com"
LANGHIT_DOMAIN="langhit.com"
NGINX_MULTI_SITE="/etc/nginx/sites-available/multi-site"

# Step 1: Check current langhit.com port
echo -e "${YELLOW}Step 1: Checking langhit.com port...${NC}"
echo -e "${BLUE}Checking which port langhit.com is using...${NC}"
LANGHIT_PORT=$(netstat -tlnp | grep LISTEN | grep -E ':(3000|8000|8080|5000)' | head -1 | awk '{print $4}' | cut -d: -f2 || echo "3000")
echo -e "${GREEN}Detected langhit.com port: ${LANGHIT_PORT}${NC}"
read -p "Press Enter to use port $LANGHIT_PORT, or enter a different port: " USER_PORT
if [ ! -z "$USER_PORT" ]; then
    LANGHIT_PORT=$USER_PORT
fi
echo -e "${GREEN}Using port ${LANGHIT_PORT} for langhit.com${NC}"

# Step 2: Create directory
echo -e "${YELLOW}Step 2: Creating directory...${NC}"
mkdir -p $LIBRECHAT_DIR
cd $LIBRECHAT_DIR

# Step 3: Check if code exists
if [ ! -f "$LIBRECHAT_DIR/package.json" ]; then
    echo -e "${RED}LibreChat code not found in $LIBRECHAT_DIR${NC}"
    echo "Please upload the code first or clone from GitHub"
    exit 1
fi

# Step 4: Check if .env exists
echo -e "${YELLOW}Step 3: Checking .env file...${NC}"
if [ ! -f "$LIBRECHAT_DIR/.env" ]; then
    echo -e "${YELLOW}Creating .env from env.production...${NC}"
    if [ -f "$LIBRECHAT_DIR/deploy/env.production" ]; then
        cp deploy/env.production .env
        echo -e "${RED}IMPORTANT: You need to edit .env file and set:${NC}"
        echo "  - JWT_SECRET (generate: openssl rand -base64 32)"
        echo "  - JWT_REFRESH_SECRET (generate: openssl rand -base64 32)"
        echo "  - MEILI_MASTER_KEY (generate: openssl rand -base64 32)"
        read -p "Press Enter after you've updated .env file..."
    else
        echo -e "${RED}env.production not found!${NC}"
        exit 1
    fi
fi

# Step 5: Create necessary directories
echo -e "${YELLOW}Step 4: Creating necessary directories...${NC}"
mkdir -p images uploads logs data-node meili_data_v1.12
chown -R 1000:1000 images uploads logs data-node meili_data_v1.12

# Step 6: Setup Docker Compose
echo -e "${YELLOW}Step 5: Setting up Docker Compose...${NC}"
if [ ! -f "$LIBRECHAT_DIR/deploy/docker-compose.production.yml" ]; then
    echo -e "${RED}docker-compose.production.yml not found!${NC}"
    exit 1
fi

# Copy docker-compose file
cp deploy/docker-compose.production.yml docker-compose.yml

# Step 7: Update nginx-reverse-proxy.conf with correct port
echo -e "${YELLOW}Step 6: Updating Nginx configuration...${NC}"
if [ ! -f "$LIBRECHAT_DIR/deploy/nginx-reverse-proxy.conf" ]; then
    echo -e "${RED}nginx-reverse-proxy.conf not found!${NC}"
    exit 1
fi

# Backup existing nginx config
if [ -f "$NGINX_MULTI_SITE" ]; then
    cp $NGINX_MULTI_SITE ${NGINX_MULTI_SITE}.backup.$(date +%Y%m%d_%H%M%S)
fi

# Update port in nginx-reverse-proxy.conf
sed -i "s/server 127.0.0.1:3000;/server 127.0.0.1:${LANGHIT_PORT};/" deploy/nginx-reverse-proxy.conf

# Copy nginx config
cp deploy/nginx-reverse-proxy.conf $NGINX_MULTI_SITE

# Step 8: Setup SSL certificates
echo -e "${YELLOW}Step 7: Setting up SSL certificates...${NC}"

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo -e "${YELLOW}Installing certbot...${NC}"
    apt update
    apt install certbot python3-certbot-nginx -y
fi

# Check if SSL certificate exists for chat.daydemy.com
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo -e "${YELLOW}SSL certificate for $DOMAIN not found.${NC}"
    echo -e "${BLUE}Make sure DNS for $DOMAIN is pointing to this server!${NC}"
    read -p "Press Enter to create SSL certificate..."
    certbot certonly --nginx -d $DOMAIN
fi

# Check if SSL certificate exists for langhit.com
if [ ! -d "/etc/letsencrypt/live/$LANGHIT_DOMAIN" ]; then
    echo -e "${YELLOW}SSL certificate for $LANGHIT_DOMAIN not found.${NC}"
    echo -e "${BLUE}Make sure DNS for $LANGHIT_DOMAIN is pointing to this server!${NC}"
    read -p "Press Enter to create SSL certificate..."
    certbot certonly --nginx -d $LANGHIT_DOMAIN
fi

# Step 9: Enable Nginx site
echo -e "${YELLOW}Step 8: Enabling Nginx site...${NC}"

# Backup existing langhit nginx config if exists
if [ -f "/etc/nginx/sites-available/langhit" ]; then
    cp /etc/nginx/sites-available/langhit /etc/nginx/sites-available/langhit.backup.$(date +%Y%m%d_%H%M%S)
fi

# Enable multi-site config
if [ ! -L "/etc/nginx/sites-enabled/multi-site" ]; then
    ln -s $NGINX_MULTI_SITE /etc/nginx/sites-enabled/
fi

# Disable old langhit config if exists (optional, comment out if you want to keep both)
# if [ -L "/etc/nginx/sites-enabled/langhit" ]; then
#     rm /etc/nginx/sites-enabled/langhit
# fi

# Test nginx config
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}Nginx configuration is valid${NC}"
else
    echo -e "${RED}Nginx configuration has errors!${NC}"
    exit 1
fi

# Reload nginx
echo -e "${YELLOW}Reloading Nginx...${NC}"
systemctl reload nginx

# Step 10: Start Docker Compose
echo -e "${YELLOW}Step 9: Starting Docker Compose...${NC}"
cd $LIBRECHAT_DIR
docker-compose up -d

# Step 11: Check status
echo -e "${YELLOW}Step 10: Checking status...${NC}"
sleep 5
echo -e "${BLUE}Docker containers status:${NC}"
docker-compose ps

# Step 12: Check if LibreChat is running
echo -e "${YELLOW}Step 11: Checking LibreChat health...${NC}"
sleep 10
if curl -f http://localhost:3080/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}LibreChat is running!${NC}"
else
    echo -e "${YELLOW}LibreChat might still be starting. Check logs with: docker-compose logs -f api${NC}"
fi

# Step 13: Final instructions
echo -e "${GREEN}=========================================="
echo "Deployment completed!"
echo "=========================================="
echo "Domains:"
echo "  - Langhit: https://$LANGHIT_DOMAIN (port $LANGHIT_PORT)"
echo "  - LibreChat: https://$DOMAIN (port 3080)"
echo ""
echo "Next steps:"
echo "1. Update Google OAuth redirect URI:"
echo "   https://$DOMAIN/oauth/google/callback"
echo "2. Check LibreChat logs:"
echo "   cd $LIBRECHAT_DIR && docker-compose logs -f api"
echo "3. Test LibreChat:"
echo "   curl http://localhost:3080/api/health"
echo "4. Test from browser:"
echo "   https://$DOMAIN"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Restart: docker-compose restart"
echo "  - Stop: docker-compose down"
echo "  - Nginx logs: tail -f /var/log/nginx/error.log"
echo "==========================================${NC}"





