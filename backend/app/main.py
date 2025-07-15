from fastapi import FastAPI, HTTPException
from fastapi import status  # Import status separately

from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
import traceback

from app.api import endpoints
from app.core.config import settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Real-time deforestation detection using satellite imagery and NDVI analysis",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Global exception: {str(exc)}\n{traceback.format_exc()}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error occurred"}
    )

# Include API routes from endpoints.py
app.include_router(endpoints.router, prefix="/api/v1", tags=["analysis"])

# Root endpoint
@app.get("/")
async def root():
    """
    Root endpoint providing API information
    """
    return {
        "message": "Carbon Eye API - Real-time Deforestation Detection",
        "tagline": "Eyes on the forest. Always.",
        "version": settings.VERSION,
        "python_version": "3.13",
        "endpoints": {
            "docs": "/docs",
            "health": "/api/v1/health",
            "analyze": "/api/v1/analyze",
            "config": "/api/v1/config",
            "validate": "/api/v1/validate-coordinates"
        },
        "features": [
            "NDVI-based change detection",
            "Real-time satellite imagery analysis",
            "Geographic coordinate mapping",
            "Confidence scoring",
            "Mock mode for development"
        ]
    }

@app.get("/status")
async def status():
    """
    Quick status check endpoint
    """
    return {
        "status": "online",
        "service": "Carbon Eye API",
        "version": settings.VERSION
    }

# Startup event
@app.on_event("startup")
async def startup_event():
    """
    Application startup event
    """
    logger.info(f"Starting {settings.PROJECT_NAME} v{settings.VERSION}")
    logger.info("Carbon Eye API is ready for deforestation detection")

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """
    Application shutdown event
    """
    logger.info("Shutting down Carbon Eye API")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8000,
        log_level="info",
        reload=True  # Set to False in production
    )
