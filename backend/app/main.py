from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import numpy as np
from datetime import datetime

from app.ml.satellite_fetcher import SatelliteDataFetcher
from app.ml.ndvi_processor import NDVIProcessor
from app.ml.change_detector import ChangeDetector
from app.core.config import settings

app = FastAPI(title="Carbon Eye API", version="1.0.0")

# CORS middleware for frontend access
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

# Request/Response models
class AnalysisRequest(BaseModel):
    bbox_coordinates: List[float]  # [min_lon, min_lat, max_lon, max_lat]
    days_back: Optional[int] = 10
    resolution: Optional[int] = 60

class Detection(BaseModel):
    id: int
    bounding_box: dict
    geographic_bbox: dict
    center_coordinates: dict
    area_pixels: int
    confidence: float
    avg_ndvi_change: float
    severity: str

class AnalysisResponse(BaseModel):
    success: bool
    timestamp: str
    analysis_parameters: dict
    detections: List[Detection]
    summary: dict
    message: str

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_deforestation(request: AnalysisRequest):
    """
    Analyze deforestation in the specified area
    """
    try:
        # Validate bounding box
        if len(request.bbox_coordinates) != 4:
            raise HTTPException(
                status_code=400, 
                detail="Bounding box must contain exactly 4 coordinates"
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
                'total_changed_pixels': int(change_results['total_changed_pixels']),
                'change_percentage': round(change_results['change_percentage'], 2),
                'high_confidence_detections': len([d for d in detections if d['confidence'] > 0.8])
            },
            message=f"Analysis completed. Found {len(detections)} deforestation areas."
        )
        
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
