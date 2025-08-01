# 🚀 Quick Digital Ocean Deployment Commands

Follow these steps to deploy PharmaCopilot on your Digital Ocean droplet at 165.22.211.17

## Step 1: Upload Files to Droplet

From your local Windows machine:
```powershell
# Option 1: Using SCP (if you have SSH client)
scp -r "c:\Users\grant\Desktop\Report Generation\" root@165.22.211.17:/tmp/pharmacopilot

# Option 2: Using Git (recommended)
# First, push your code to GitHub, then on the droplet:
ssh root@165.22.211.17
cd /opt
git clone https://github.com/granthgg/Report-Generation.git pharmacopilot
```

## Step 2: Run Deployment on Droplet

SSH into your droplet and run these commands:

```bash
# Connect to droplet
ssh root@165.22.211.17

# Navigate to application directory
cd /opt/pharmacopilot

# Make deployment script executable
chmod +x deploy_complete.sh

# Run complete deployment
./deploy_complete.sh
```

## Step 3: Configure Environment

Edit the environment file with your GROQ API key:
```bash
nano /opt/pharmacopilot/.env

# Change this line:
GROQ_API_KEY=your_groq_api_key_here
# To your actual key:
GROQ_API_KEY=gsk_your_actual_key_here
```

## Step 4: Restart Service

After setting the API key:
```bash
cd /opt/pharmacopilot
docker-compose restart
```

## Step 5: Test Deployment

Test the service endpoints:
```bash
# Health check
curl http://localhost:8001/api/reports/health

# External access
curl http://165.22.211.17:8001/api/reports/health

# Via nginx proxy (if configured)
curl http://165.22.211.17/reports/health
```

## 🌐 Service URLs

After successful deployment:

- **Direct API Access**: http://165.22.211.17:8001
- **API Documentation**: http://165.22.211.17:8001/docs
- **Health Check**: http://165.22.211.17:8001/api/reports/health
- **Via Nginx Proxy**: http://165.22.211.17/reports/

## 📱 Test Endpoints

Generate a sample report:
```bash
curl -X POST "http://165.22.211.17:8001/api/reports/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "report_type": "quality_control",
    "batch_id": "TEST001",
    "equipment_id": "EQ001"
  }'
```

## 🔧 Management Commands

```bash
# View logs
cd /opt/pharmacopilot
docker-compose logs -f

# Restart service
docker-compose restart

# Stop service
docker-compose down

# Update application
./update.sh

# Check service status
docker-compose ps
```

## ⚠️ Troubleshooting

If the service doesn't start:

1. Check logs:
   ```bash
   docker-compose logs
   ```

2. Verify environment variables:
   ```bash
   cat .env
   ```

3. Check port availability:
   ```bash
   netstat -tlnp | grep :8001
   ```

4. Restart Docker:
   ```bash
   sudo systemctl restart docker
   docker-compose up -d
   ```

## 🔒 Security Notes

- Service runs on port 8001 (different from your existing FastAPI on 8000)
- Nginx proxy provides clean URLs
- CORS configured for your droplet IP
- Firewall rules added for necessary ports

## 📊 Service Architecture

```
Internet → Nginx (Port 80) → {
  /api/v1/*     → Existing FastAPI (Port 8000)
  /reports/*    → PharmaCopilot (Port 8001)
  /pharmacopilot/* → PharmaCopilot UI (Port 8001)
}
```

Your existing FastAPI service remains unchanged and accessible!
