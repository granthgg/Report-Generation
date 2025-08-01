#!/bin/bash

# Quick update and restart script for PharmaCopilot Report Generation
# Run this script to pull latest changes and restart the service

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_DIR="/opt/pharmacopilot-reports"

echo -e "${BLUE}🔄 Quick Update - PharmaCopilot Report Generation${NC}"
echo "================================================="

# Navigate to app directory
cd $APP_DIR

# Pull latest changes
echo -e "${GREEN}[1/4]${NC} Pulling latest changes from GitHub..."
git pull origin main

# Rebuild and restart containers
echo -e "${GREEN}[2/4]${NC} Rebuilding Docker images..."
docker-compose -f docker-compose.production.yml build --no-cache

echo -e "${GREEN}[3/4]${NC} Restarting containers..."
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml up -d

# Wait and verify
echo -e "${GREEN}[4/4]${NC} Verifying service..."
sleep 20

if curl -f http://localhost:8001/api/reports/health &> /dev/null; then
    echo -e "${GREEN}✅ Update completed successfully!${NC}"
    echo
    echo "📊 Service: http://165.22.211.17:8001"
    echo "📚 Docs: http://165.22.211.17:8001/docs"
    echo "🔍 Health: http://165.22.211.17:8001/api/reports/health"
else
    echo "❌ Service may not be running properly"
    echo "Check logs: docker-compose -f docker-compose.production.yml logs"
fi
