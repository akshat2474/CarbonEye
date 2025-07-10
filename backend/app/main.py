from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import numpy as np
from datetime import datetime
import traceback
import logging

from app.ml.satellite_fetcher import SatelliteDataFetcher
from app.ml.ndvi_processor import NDVIProcessor
from app.ml.change_detector import ChangeDetector
from app.core.config import settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Real-time deforestation detection using satellite imagery and NDVI analysis"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize components
satellite_fetcher = SatelliteDataFetcher(
    settings.SENTINELHUB_CLIENT_ID,
    settings.SENTINELHUB_CLIENT_SECRET,
    settings.SENTINELHUB_INSTANCE_ID
)
ndvi_processor = NDVIProcessor()
change_detector = ChangeDetector(
    change_threshold=settings.NDVI_CHANGE_THRESHOLD,
    min_area=settings.MIN_DEFORESTATION_AREA,
    confidence_threshold=settings.CONFIDENCE_THRESHOLD
)

# Pydantic models
class AnalysisRequest(BaseModel):
    bbox_coordinates: List[float] = Field(..., min_length=4, max_length=4)
    days_back: Optional[int] = Field(default=10, ge=1, le=30)
    resolution: Optional[int] = Field(default=60, ge=10, le=100)

class Detection(BaseModel):
    id: int
    bounding_box: Dict[str, int]
    geographic_bbox: Dict[str, float]
    center_coordinates: Dict[str, float]
    area_pixels: int
    confidence: float
    avg_ndvi_change: float
    severity: str

class AnalysisResponse(BaseModel):
    success: bool
    timestamp: str
    analysis_parameters: Dict[str, Any]
    detections: List[Detection]
    summary: Dict[str, Any]
    message: str

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Global exception: {str(exc)}\n{traceback.format_exc()}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error occurred"}
    )

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_deforestation(request: AnalysisRequest):
    """
    Analyze deforestation in the specified area
    """
    try:
        logger.info(f"Starting analysis for bbox: {request.bbox_coordinates}")
        
        # Validate bounding box
        min_lon, min_lat, max_lon, max_lat = request.bbox_coordinates
        if min_lon >= max_lon or min_lat >= max_lat:
            raise HTTPException(
                status_code=400,
                detail="Invalid bounding box coordinates"
            )
        
        # Fetch satellite data
        t0_data, t1_data = satellite_fetcher.get_time_series_data(
            request.bbox_coordinates,
            request.days_back
        )
        
        # Preprocess images
        t0_processed = ndvi_processor.preprocess_image(t0_data)
        t1_processed = ndvi_processor.preprocess_image(t1_data)
        
        # Calculate NDVI
        ndvi_t0 = ndvi_processor.calculate_ndvi(t0_processed)
        ndvi_t1 = ndvi_processor.calculate_ndvi(t1_processed)
        
        # Detect changes
        change_results = change_detector.detect_changes(ndvi_t0, ndvi_t1)
        
        # Convert to geographic coordinates
        detections = change_detector.convert_pixel_to_coordinates(
            change_results['detections'],
            request.bbox_coordinates,
            ndvi_t0.shape
        )
        
        # Prepare response
        response = AnalysisResponse(
            success=True,
            timestamp=datetime.now().isoformat(),
            analysis_parameters={
                'bbox_coordinates': request.bbox_coordinates,
                'days_back': request.days_back,
                'resolution': request.resolution,
                'change_threshold': settings.NDVI_CHANGE_THRESHOLD,
                'min_area': settings.MIN_DEFORESTATION_AREA
            },
            detections=detections,
            summary={
                'total_detections': len(detections),
                'total_changed_pixels': change_results['total_changed_pixels'],
                'change_percentage': round(change_results['change_percentage'], 2),
                'high_confidence_detections': len([d for d in detections if d['confidence'] > 0.8])
            },
            message=f"Analysis completed successfully. Found {len(detections)} deforestation areas."
        )
        
        logger.info(f"Analysis completed: {len(detections)} detections found")
        return response
        
    except Exception as e:
        logger.error(f"Analysis error: {str(e)}\n{traceback.format_exc()}")
        raise HTTPException(
            status_code=500,
            detail=f"Analysis failed: {str(e)}"
        )

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "python_version": "3.13",
        "mock_mode": satellite_fetcher.mock_mode
    }

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Carbon Eye API - Real-time Deforestation Detection",
        "version": settings.VERSION,
        "docs": "/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
