# PharmaCopilot Report Generation - Production Deployment

This guide provides step-by-step instructions for deploying the PharmaCopilot Report Generation system on a Digital Ocean Ubuntu droplet.

## 🎯 Prerequisites

- Ubuntu 20.04+ Digital Ocean Droplet
- SSH access to the droplet
- Prediction API running on `http://165.22.211.17:8000`
- GROQ API key for LLM integration

## 🚀 Quick Deployment

### Step 1: Connect to Your Droplet

```bash
ssh root@165.22.211.17
# or
ssh your-username@165.22.211.17
```

### Step 2: Run the Deployment Script

```bash
# Download and run the deployment script
curl -fsSL https://raw.githubusercontent.com/granthgg/Report-Generation/main/deploy.sh -o deploy.sh
chmod +x deploy.sh
./deploy.sh
```

### Step 3: Configure Environment

```bash
# Edit the environment file to add your GROQ API key
cd /opt/pharmacopilot-reports
nano .env

# Add your GROQ API key:
GROQ_API_KEY=gsk_your_actual_groq_api_key_here
```

### Step 4: Restart the Service

```bash
cd /opt/pharmacopilot-reports
docker-compose -f docker-compose.production.yml restart
```

## 📋 Manual Deployment Steps

If you prefer to deploy manually, follow these steps:

### 1. System Updates

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y curl wget git unzip software-properties-common
```

### 2. Install Docker

```bash
# Remove old versions
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
```

### 3. Install Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 4. Clone Repository

```bash
sudo mkdir -p /opt/pharmacopilot-reports
sudo chown $USER:$USER /opt/pharmacopilot-reports
git clone https://github.com/granthgg/Report-Generation.git /opt/pharmacopilot-reports
cd /opt/pharmacopilot-reports
```

### 5. Configure Environment

```bash
# Create environment file
cat > .env << EOF
GROQ_API_KEY=your_groq_api_key_here
PORT=8001
HOST=0.0.0.0
API_BASE_URL=http://localhost:8000
ANONYMIZED_TELEMETRY=False
CHROMA_TELEMETRY=False
PYTHONPATH=/app
EOF

# Edit and add your actual GROQ API key
nano .env
```

### 6. Deploy Application

```bash
# Build and start
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d

# Check status
docker-compose -f docker-compose.production.yml ps
```

### 7. Setup Auto-Start Service

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

# Enable service
sudo systemctl daemon-reload
sudo systemctl enable pharmacopilot-reports.service
```

## 🔧 Management Commands

### Service Management

```bash
# Start service
sudo systemctl start pharmacopilot-reports

# Stop service
sudo systemctl stop pharmacopilot-reports

# Restart service
sudo systemctl restart pharmacopilot-reports

# Check service status
sudo systemctl status pharmacopilot-reports
```

### Docker Management

```bash
cd /opt/pharmacopilot-reports

# View running containers
docker-compose -f docker-compose.production.yml ps

# View logs
docker-compose -f docker-compose.production.yml logs -f

# Restart containers
docker-compose -f docker-compose.production.yml restart

# Stop containers
docker-compose -f docker-compose.production.yml down

# Start containers
docker-compose -f docker-compose.production.yml up -d

# Rebuild containers
docker-compose -f docker-compose.production.yml build --no-cache
```

### Quick Update

```bash
cd /opt/pharmacopilot-reports
./update.sh
```

### System Status Check

```bash
cd /opt/pharmacopilot-reports
./status.sh
```

## 🌐 Access Points

After successful deployment, the service will be available at:

- **Main API**: http://165.22.211.17:8001
- **API Documentation**: http://165.22.211.17:8001/docs
- **Health Check**: http://165.22.211.17:8001/api/reports/health
- **Prediction API**: http://165.22.211.17:8000

## 🔍 Testing the Deployment

### 1. Health Check

```bash
curl http://165.22.211.17:8001/api/reports/health
```

### 2. Generate Test Report

```bash
curl -X POST "http://165.22.211.17:8001/api/reports/quality" \
     -H "Content-Type: application/json" \
     -d '{
       "report_type": "comprehensive",
       "include_predictions": true,
       "include_recommendations": true
     }'
```

### 3. Check API Documentation

Visit: http://165.22.211.17:8001/docs

## 🛠️ Troubleshooting

### Common Issues

1. **Container not starting**
   ```bash
   docker-compose -f docker-compose.production.yml logs
   ```

2. **Permission denied errors**
   ```bash
   sudo chown -R $USER:$USER /opt/pharmacopilot-reports
   ```

3. **Port conflicts**
   ```bash
   # Check what's using port 8001
   sudo netstat -tlnp | grep :8001
   ```

4. **Prediction API not accessible**
   ```bash
   # Test prediction API connectivity
   curl http://localhost:8000/health
   curl http://165.22.211.17:8000/health
   ```

### Log Locations

- Application logs: `docker-compose -f docker-compose.production.yml logs`
- System logs: `journalctl -u pharmacopilot-reports`
- Docker logs: `docker logs pharmacopilot-reports`

## 🔄 Updating the Application

To update the application with latest changes:

```bash
cd /opt/pharmacopilot-reports
./update.sh
```

Or manually:

```bash
cd /opt/pharmacopilot-reports
git pull origin main
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d
```

## 🔐 Security Considerations

1. **Firewall Configuration**
   ```bash
   sudo ufw allow 8001/tcp
   sudo ufw allow 22/tcp
   sudo ufw enable
   ```

2. **SSL/TLS Setup** (Optional)
   - Use nginx or traefik as reverse proxy
   - Configure Let's Encrypt certificates

3. **Environment Variables**
   - Keep `.env` file secure
   - Use Docker secrets for production

## 📊 Monitoring

### Basic Monitoring

```bash
# Check system resources
docker stats

# Check application health
watch -n 30 'curl -s http://localhost:8001/api/reports/health'
```

### Advanced Monitoring (Optional)

Consider setting up:
- Prometheus + Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Application monitoring (New Relic, DataDog)

## 🆘 Support

If you encounter issues:

1. Check the logs: `docker-compose -f docker-compose.production.yml logs`
2. Verify system status: `./status.sh`
3. Check GitHub issues: https://github.com/granthgg/Report-Generation/issues
4. Contact system administrator

---

**Note**: Make sure to replace `your_groq_api_key_here` with your actual GROQ API key in the `.env` file for the system to work properly.
