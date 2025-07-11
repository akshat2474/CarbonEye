const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const config = require('./config');
const imageRoutes = require('./routes/imageRoutes');

const app = express();

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests',
    message: 'Please try again later'
  }
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

// API routes
app.use(`${config.api.prefix}/images`, imageRoutes);

// API documentation endpoint
app.get(`${config.api.prefix}/docs`, (req, res) => {
  res.json({
    title: 'Sentinel Hub Image API',
    version: '1.0.0',
    endpoints: {
      'GET /api/images/search': 'Search for available satellite images',
      'GET /api/images/process': 'Get processed satellite image',
      'GET /api/images/ndvi': 'Get NDVI processed image',
      'GET /api/images/wcs': 'Get image using WCS service'
    },
    examples: {
      search: '/api/images/search?bbox=13.0,45.0,14.0,46.0&dateFrom=2023-01-01&dateTo=2023-01-31',
      process: '/api/images/process?bbox=13.0,45.0,14.0,46.0&datetime=2023-01-15&width=512&height=512',
      ndvi: '/api/images/ndvi?bbox=13.0,45.0,14.0,46.0&datetime=2023-01-15',
      wcs: '/api/images/wcs?bbox=13.0,45.0,14.0,46.0&time=2023-01-15&layer=TRUE_COLOR'
    }
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error('Global error handler:', error);
  
  res.status(error.status || 500).json({
    error: error.name || 'Internal Server Error',
    message: error.message || 'Something went wrong',
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
  });
});

// Start server
const PORT = config.server.port;
const HOST = config.server.host;

app.listen(PORT, HOST, () => {
  console.log(`🚀 Server running on http://${HOST}:${PORT}`);
  console.log(`📚 API Documentation: http://${HOST}:${PORT}${config.api.prefix}/docs`);
  console.log(`🏥 Health Check: http://${HOST}:${PORT}/health`);
});

module.exports = app;
