# PharmaCopilot Report Generation - Deployment Guide

This guide covers deploying the PharmaCopilot Report Generation system to various platforms including Digital Ocean droplets and Heroku.

## Digital Ocean Droplet Deployment

### Overview
Deploy alongside your existing FastAPI service running on port 8000. PharmaCopilot will run on port 8001.

### Prerequisites
- Digital Ocean droplet with Docker and Docker Compose
- Existing FastAPI service on port 8000
- GROQ API key
- SSH access to droplet

## Files Created for Deployment

The following files have been created for deployment:

- `requirements.txt` - Python dependencies
- `.gitignore` - Files to exclude from version control
- `Procfile` - Heroku process configuration
- `runtime.txt` - Python version specification

## Deployment Steps

### 1. Initialize Git Repository

```bash
cd "Report Generation"
git init
git add .
git commit -m "Initial commit - PharmaCopilot Report Generation System"
```

### 2. Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Name it something like `pharmacopilot-report-generation`
3. Don't initialize with README (we already have files)

### 3. Connect Local Repository to GitHub

```bash
git remote add origin https://github.com/YOUR_USERNAME/pharmacopilot-report-generation.git
git branch -M main
git push -u origin main
```

### 4. Deploy to Heroku

#### Option A: Heroku CLI (Recommended)

```bash
# Install Heroku CLI if not already installed
# Download from: https://devcenter.heroku.com/articles/heroku-cli

# Login to Heroku
heroku login

# Create Heroku app
heroku create your-app-name

# Set environment variables (optional)
heroku config:set GROQ_API_KEY=your_groq_api_key_here

# Deploy
git push heroku main
```

#### Option B: Heroku Dashboard

1. Go to [Heroku Dashboard](https://dashboard.heroku.com)
2. Click "New" → "Create new app"
3. Enter app name and region
4. In "Deploy" tab, connect to GitHub
5. Select your repository
6. Enable automatic deploys (optional)
7. Click "Deploy Branch"

### 5. Configure Environment Variables

In Heroku Dashboard → Settings → Config Vars, add:

- `GROQ_API_KEY` - Your Groq API key (optional, system has fallback)
- `PORT` - Automatically set by Heroku
- `PYTHONPATH` - Set to `/app` if needed

### 6. Verify Deployment

After deployment, visit:
- `https://your-app-name.herokuapp.com/api/reports/health` - Health check
- `https://your-app-name.herokuapp.com/docs` - API documentation

## Local Testing Before Deployment

```bash
# Install dependencies
pip install -r requirements.txt

# Test locally
python simple_run.py --port 8001

# Test in production mode (using Heroku's environment)
PORT=8001 python simple_run.py
```

## Troubleshooting

### Common Issues

1. **Build Failed - Missing Dependencies**
   - Check `requirements.txt` has all needed packages
   - Ensure Python version in `runtime.txt` is supported

2. **Application Error on Startup**
   - Check Heroku logs: `heroku logs --tail`
   - Verify `Procfile` format is correct

3. **Port Binding Issues**
   - Heroku automatically sets `PORT` environment variable
   - App should bind to `0.0.0.0:$PORT`

4. **Large Slug Size Warning**
   - Add unnecessary files to `.gitignore`
   - Remove unused dependencies from `requirements.txt`

### Heroku Logs

```bash
# View real-time logs
heroku logs --tail

# View recent logs
heroku logs --num 100
```

### Scaling and Performance

```bash
# Scale web dynos
heroku ps:scale web=1

# View dyno status
heroku ps

# Restart application
heroku restart
```

## System Requirements

- **Memory**: ~512MB (suitable for Heroku free tier)
- **Storage**: Vector database will use ephemeral storage
- **Python**: 3.11.5 (specified in runtime.txt)

## Production Considerations

### Environment Variables
- Set `GROQ_API_KEY` for LLM functionality
- System gracefully degrades without API keys

### Database Storage
- ChromaDB uses local storage (ephemeral on Heroku)
- Consider external vector database for persistence

### API Limits
- Groq API has rate limits
- System includes fallback templates

### Monitoring
- Use Heroku metrics for basic monitoring
- Health check endpoint: `/api/reports/health`

## Security Notes

- Never commit API keys to git
- Use environment variables for secrets
- The generated `.gitignore` protects sensitive files
- HTTPS is enforced by Heroku for custom domains

## Support

For deployment issues:
1. Check Heroku logs
2. Verify all files are committed to git
3. Test locally first
4. Review Heroku documentation

---

**Your PharmaCopilot Report Generation system is now ready for cloud deployment!** 🚀
