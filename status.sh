#!/bin/bash

# Status check script for PharmaCopilot Report Generation

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 PharmaCopilot Report Generation - Status Check${NC}"
echo "================================================="

# Check Docker
echo -e "${BLUE}🐳 Docker Status:${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker installed${NC}"
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}✅ Docker service running${NC}"
    else
        echo -e "${RED}❌ Docker service not running${NC}"
    fi
else
    echo -e "${RED}❌ Docker not installed${NC}"
fi

echo

# Check Docker Compose
echo -e "${BLUE}🔧 Docker Compose Status:${NC}"
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✅ Docker Compose installed${NC}"
    docker-compose --version
else
    echo -e "${RED}❌ Docker Compose not installed${NC}"
fi

echo

# Check Application
echo -e "${BLUE}📱 Application Status:${NC}"
APP_DIR="/opt/pharmacopilot-reports"

if [ -d "$APP_DIR" ]; then
    echo -e "${GREEN}✅ Application directory exists${NC}"
    
    cd $APP_DIR
    
    # Check containers
    if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
        echo -e "${GREEN}✅ Containers running${NC}"
        docker-compose -f docker-compose.production.yml ps
    else
        echo -e "${RED}❌ Containers not running${NC}"
        docker-compose -f docker-compose.production.yml ps
    fi
    
    echo
    
    # Check API health
    echo -e "${BLUE}🔍 API Health Check:${NC}"
    if curl -s -f http://localhost:8001/api/reports/health > /dev/null; then
        echo -e "${GREEN}✅ Report Generation API responding${NC}"
        echo "   URL: http://165.22.211.17:8001"
    else
        echo -e "${RED}❌ Report Generation API not responding${NC}"
    fi
    
    # Check prediction API
    if curl -s -f http://localhost:8000/health > /dev/null; then
        echo -e "${GREEN}✅ Prediction API responding${NC}"
        echo "   URL: http://165.22.211.17:8000"
    else
        echo -e "${YELLOW}⚠️  Prediction API not responding (reports will use fallback data)${NC}"
    fi
    
else
    echo -e "${RED}❌ Application not installed${NC}"
fi

echo

# System resources
echo -e "${BLUE}💻 System Resources:${NC}"
echo "Memory usage:"
free -h
echo
echo "Disk usage:"
df -h /
echo
echo "Docker system info:"
docker system df

echo
echo -e "${BLUE}📋 Management Commands:${NC}"
echo "Start:    sudo systemctl start pharmacopilot-reports"
echo "Stop:     sudo systemctl stop pharmacopilot-reports"
echo "Restart:  sudo systemctl restart pharmacopilot-reports"
echo "Logs:     cd $APP_DIR && docker-compose -f docker-compose.production.yml logs -f"
echo "Update:   cd $APP_DIR && ./update.sh"
