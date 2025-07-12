# Deploying Carbon Eye API to Render

## Prerequisites
- GitHub repository with your code
- Render account (free tier)

## Step-by-Step Deployment

### 1. Prepare Your Repository
Your repository should have this structure:
```
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── api/
│   │   ├── core/
│   │   └── ml/
│   ├── requirements.txt
│   └── Dockerfile
├── render.yaml
└── DEPLOYMENT.md
```

### 2. Deploy to Render

#### Option A: Using render.yaml (Recommended)
1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click "New +" → "Blueprint"
3. Connect your GitHub repository
4. Render will automatically detect the `render.yaml` file
5. Click "Apply" to deploy

#### Option B: Manual Deployment
1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository
4. Configure the service:
   - **Name**: `carbon-eye-api`
   - **Environment**: `Python`
   - **Build Command**: `pip install -r backend/requirements.txt`
   - **Start Command**: `cd backend && gunicorn app.main:app --bind 0.0.0.0:$PORT --workers 1 --worker-class uvicorn.workers.UvicornWorker`
   - **Plan**: Free

### 3. Environment Variables
Set these in Render dashboard:
- `SENTINELHUB_CLIENT_ID` (your Sentinel Hub client ID)
- `SENTINELHUB_CLIENT_SECRET` (your Sentinel Hub client secret)
- `NDVI_CHANGE_THRESHOLD` = -0.3
- `MIN_DEFORESTATION_AREA` = 100
- `CONFIDENCE_THRESHOLD` = 0.6

### 4. Free Tier Limitations
- **Sleep after 15 minutes** of inactivity
- **512 MB RAM** limit
- **Shared CPU** resources
- **Automatic sleep/wake** based on traffic

### 5. Testing Your Deployment
Once deployed, test these endpoints:
- `GET /` - API information
- `GET /status` - Health check
- `GET /docs` - Interactive API docs
- `GET /api/v1/health` - Detailed health check

### 6. Custom Domain (Optional)
- Go to your service settings
- Add custom domain in "Custom Domains" section
- Update DNS records as instructed

## Troubleshooting

### Common Issues:
1. **Build fails**: Check requirements.txt for missing dependencies
2. **Service won't start**: Verify start command and port configuration
3. **Environment variables**: Ensure all required env vars are set
4. **Memory issues**: Free tier has 512MB limit, optimize if needed

### Logs:
- Check build logs in Render dashboard
- Monitor runtime logs for errors
- Use `curl` to test endpoints

## API Endpoints
Your deployed API will have these endpoints:
- `https://your-app-name.onrender.com/` - Root
- `https://your-app-name.onrender.com/docs` - Swagger UI
- `https://your-app-name.onrender.com/api/v1/analyze` - Main analysis endpoint
- `https://your-app-name.onrender.com/api/v1/health` - Health check

## Cost Optimization
- Free tier sleeps after 15 minutes of inactivity
- First request after sleep takes 30-60 seconds to wake up
- Consider upgrading to paid plan for production use 