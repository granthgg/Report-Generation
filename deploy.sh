#!/bin/bash

# PharmaCopilot Report Generation - Complete Deployment Script
# For Digital Ocean Ubuntu Droplet

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 PharmaCopilot Report Generation - Deployment Script${NC}"
echo -e "${BLUE}====================================================${NC}"

# Function to print colored output
print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root. Run as regular user with sudo privileges."
    exit 1
fi

# Verify we're on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    print_warning "This script is designed for Ubuntu. Proceeding anyway..."
fi

print_step "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

print_step "Installing essential packages..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    print_step "Installing Docker..."
    
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    print_step "Docker installed successfully!"
else
    print_step "Docker is already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    print_step "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_step "Docker Compose installed successfully!"
else
    print_step "Docker Compose is already installed"
fi

# Create application directory
APP_DIR="/opt/pharmacopilot-reports"
print_step "Creating application directory at $APP_DIR..."
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Clone or update repository
if [ -d "$APP_DIR/.git" ]; then
    print_step "Updating existing repository..."
    cd $APP_DIR
    git pull origin main
else
    print_step "Cloning repository..."
    git clone https://github.com/granthgg/Report-Generation.git $APP_DIR
    cd $APP_DIR
fi

# Check if prediction API is running
print_step "Checking prediction API status..."
if curl -f http://localhost:8000/health &> /dev/null || curl -f http://165.22.211.17:8000/health &> /dev/null; then
    print_step "Prediction API is accessible ✓"
else
    print_warning "Prediction API may not be accessible. The report generation will use fallback data."
fi

# Create environment file
print_step "Setting up environment variables..."
if [ ! -f .env ]; then
    cat > .env << EOF
# Environment Configuration
GROQ_API_KEY=your_groq_api_key_here
PORT=8001
HOST=0.0.0.0
API_BASE_URL=http://localhost:8000
ANONYMIZED_TELEMETRY=False
CHROMA_TELEMETRY=False
PYTHONPATH=/app

# Add your actual GROQ API key here
# GROQ_API_KEY=gsk_your_actual_key_here
EOF
    print_warning "Please edit .env file and add your GROQ_API_KEY"
    print_warning "Run: nano $APP_DIR/.env"
else
    print_step "Environment file already exists"
fi

# Stop existing containers
print_step "Stopping existing containers..."
docker-compose down || true

# Build and start the application
print_step "Building and starting the application..."
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d

# Wait for the application to start
print_step "Waiting for application to start..."
sleep 30

# Check if application is running
if curl -f http://localhost:8001/api/reports/health &> /dev/null; then
    print_step "✅ Application is running successfully!"
    echo
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo
    echo "📊 Report Generation API: http://165.22.211.17:8001"
    echo "📚 API Documentation: http://165.22.211.17:8001/docs"
    echo "🔍 Health Check: http://165.22.211.17:8001/api/reports/health"
    echo
    echo "📋 Next steps:"
    echo "1. Edit $APP_DIR/.env and add your GROQ_API_KEY"
    echo "2. Restart the service: cd $APP_DIR && docker-compose -f docker-compose.production.yml restart"
    echo "3. Monitor logs: docker-compose -f docker-compose.production.yml logs -f"
    echo
else
    print_error "Application failed to start properly"
    echo "Check logs with: docker-compose -f docker-compose.production.yml logs"
    exit 1
fi

# Setup systemd service for auto-restart
print_step "Setting up systemd service for auto-restart..."
sudo tee /etc/systemd/system/pharmacopilot-reports.service > /dev/null << EOF
[Unit]
Description=PharmaCopilot Report Generation Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pharmacopilot-reports.service

print_step "✅ Systemd service configured for auto-start on boot"

echo
echo -e "${BLUE}🔧 Management Commands:${NC}"
echo "Start:   sudo systemctl start pharmacopilot-reports"
echo "Stop:    sudo systemctl stop pharmacopilot-reports"
echo "Status:  sudo systemctl status pharmacopilot-reports"
echo "Logs:    cd $APP_DIR && docker-compose -f docker-compose.production.yml logs -f"
echo
echo -e "${GREEN}🎯 Deployment completed! Your report generation service is now running.${NC}"
