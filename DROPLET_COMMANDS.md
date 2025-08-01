# 🚀 PharmaCopilot Report Generation - Digital Ocean Deployment Commands

## Complete Step-by-Step Commands for Ubuntu Droplet

### 1. Connect to Your Droplet
```bash
ssh root@165.22.211.17
# or if you have a non-root user:
# ssh your-username@165.22.211.17
```

### 2. One-Command Deployment (Recommended)
```bash
# Download and run the complete deployment script
curl -fsSL https://raw.githubusercontent.com/granthgg/Report-Generation/main/deploy.sh -o deploy.sh && chmod +x deploy.sh && ./deploy.sh
```

### 3. Configure Your GROQ API Key
```bash
# Navigate to the application directory
cd /opt/pharmacopilot-reports

# Edit the environment file
nano .env

# In the .env file, replace 'your_groq_api_key_here' with your actual GROQ API key:
# GROQ_API_KEY=gsk_your_actual_groq_api_key_here
```

### 4. Restart the Service
```bash
# After adding your API key, restart the service
cd /opt/pharmacopilot-reports
docker-compose -f docker-compose.production.yml restart
```

### 5. Verify Everything is Working
```bash
# Check if the service is running
curl http://localhost:8001/api/reports/health

# Check status of all services
./status.sh
```

---

## Alternative: Manual Step-by-Step Deployment

If the automated script doesn't work, follow these manual steps:

### Step 1: System Preparation
```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install essential packages
sudo apt-get install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
```

### Step 2: Install Docker
```bash
# Remove old Docker versions
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Add Docker's GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

### Step 3: Install Docker Compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Step 4: Clone and Setup Application
```bash
# Create application directory
sudo mkdir -p /opt/pharmacopilot-reports
sudo chown $USER:$USER /opt/pharmacopilot-reports

# Clone repository
git clone https://github.com/granthgg/Report-Generation.git /opt/pharmacopilot-reports
cd /opt/pharmacopilot-reports

# Create environment file
cat > .env << 'EOF'
GROQ_API_KEY=your_groq_api_key_here
PORT=8001
HOST=0.0.0.0
API_BASE_URL=http://localhost:8000
ANONYMIZED_TELEMETRY=False
CHROMA_TELEMETRY=False
PYTHONPATH=/app
EOF

# Edit the .env file to add your actual GROQ API key
nano .env
```

### Step 5: Deploy Application
```bash
# Build and start containers
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d

# Check if containers are running
docker-compose -f docker-compose.production.yml ps
```

### Step 6: Setup Auto-Start Service
```bash
# Create systemd service
sudo tee /etc/systemd/system/pharmacopilot-reports.service > /dev/null << EOF
[Unit]
Description=PharmaCopilot Report Generation Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/pharmacopilot-reports
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0
User=$USER
Group=$USER

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable pharmacopilot-reports.service
sudo systemctl start pharmacopilot-reports.service
```

---

## 🔍 Verification Commands

### Check Service Status
```bash
# Check if the report generation API is working
curl http://165.22.211.17:8001/api/reports/health

# Check if containers are running
cd /opt/pharmacopilot-reports
docker-compose -f docker-compose.production.yml ps

# Check system service status
sudo systemctl status pharmacopilot-reports
```

### Test Report Generation
```bash
# Generate a test report
curl -X POST "http://165.22.211.17:8001/api/reports/quality" \
     -H "Content-Type: application/json" \
     -d '{
       "report_type": "comprehensive",
       "include_predictions": true,
       "include_recommendations": true
     }'
```

### View Logs
```bash
# View application logs
cd /opt/pharmacopilot-reports
docker-compose -f docker-compose.production.yml logs -f

# View system service logs
journalctl -u pharmacopilot-reports -f
```

---

## 🔧 Management Commands

### Daily Operations
```bash
# Check status
cd /opt/pharmacopilot-reports && ./status.sh

# Update application
cd /opt/pharmacopilot-reports && ./update.sh

# Restart service
sudo systemctl restart pharmacopilot-reports

# View logs
cd /opt/pharmacopilot-reports && docker-compose -f docker-compose.production.yml logs -f
```

### Troubleshooting
```bash
# Stop all containers
cd /opt/pharmacopilot-reports
docker-compose -f docker-compose.production.yml down

# Remove old containers and rebuild
docker-compose -f docker-compose.production.yml down --volumes
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d

# Check Docker system info
docker system info
docker system df

# Check what's using port 8001
sudo netstat -tlnp | grep :8001
```

---

## 🌐 Access URLs After Deployment

- **Report Generation API**: http://165.22.211.17:8001
- **API Documentation**: http://165.22.211.17:8001/docs  
- **Health Check**: http://165.22.211.17:8001/api/reports/health
- **Prediction API**: http://165.22.211.17:8000 (already running)

---

## 🔐 Security Setup (Recommended)

```bash
# Configure firewall
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 8000/tcp  # Prediction API
sudo ufw allow 8001/tcp  # Report Generation API
sudo ufw enable

# Check firewall status
sudo ufw status
```

---

## ⚠️ Important Notes

1. **GROQ API Key**: Make sure to add your actual GROQ API key in the `.env` file
2. **Prediction API**: Ensure your prediction API at `http://165.22.211.17:8000` is running
3. **Ports**: Make sure ports 8000 and 8001 are open in your Digital Ocean firewall
4. **Memory**: Ensure your droplet has at least 2GB RAM for optimal performance
5. **Updates**: Use `./update.sh` to pull latest changes from GitHub

---

## 🆘 If Something Goes Wrong

1. **Check logs**: `cd /opt/pharmacopilot-reports && docker-compose -f docker-compose.production.yml logs`
2. **Restart everything**: `sudo systemctl restart pharmacopilot-reports`
3. **Check status**: `cd /opt/pharmacopilot-reports && ./status.sh`
4. **Rebuild from scratch**: Remove `/opt/pharmacopilot-reports` and run the deployment script again

---

**✅ After running these commands, your PharmaCopilot Report Generation system should be fully operational and accessible at http://165.22.211.17:8001**
