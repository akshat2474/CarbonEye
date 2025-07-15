from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import numpy as np
from datetime import datetime
import logging

from app.ml.satellite_fetcher import SatelliteDataFetcher
from app.ml.ndvi_processor import NDVIProcessor
from app.ml.change_detector import ChangeDetector
from app.core.config import settings

logger = logging.getLogger(__name__)

router = APIRouter()

# Dependency to get ML components
def get_satellite_fetcher():
    return SatelliteDataFetcher(
        settings.SENTINELHUB_CLIENT_ID,
        settings.SENTINELHUB_CLIENT_SECRET
    )

def get_ndvi_processor():
    return NDVIProcessor()

def get_change_detector():
    return ChangeDetector(
        change_threshold=settings.NDVI_CHANGE_THRESHOLD,
        min_area=settings.MIN_DEFORESTATION_AREA,
        confidence_threshold=settings.CONFIDENCE_THRESHOLD
    )

def ensure_json_serializable(data):
    """
    Recursively convert NumPy types to Python native types for JSON serialization
    """
    if isinstance(data, dict):
        return {key: ensure_json_serializable(value) for key, value in data.items()}
    elif isinstance(data, list):
        return [ensure_json_serializable(item) for item in data]
    elif isinstance(data, np.integer):
        return int(data)
    elif isinstance(data, np.floating):
        return float(data)
    elif isinstance(data, np.bool_):
        return bool(data)
    elif isinstance(data, np.ndarray):
        return data.tolist()
    else:
        return data


# Pydantic models for API
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

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    python_version: str
    mock_mode: bool
    sentinelhub_configured: bool

@router.post("/analyze", response_model=AnalysisResponse)
async def analyze_deforestation(
    request: AnalysisRequest,
    satellite_fetcher: SatelliteDataFetcher = Depends(get_satellite_fetcher),
    ndvi_processor: NDVIProcessor = Depends(get_ndvi_processor),
    change_detector: ChangeDetector = Depends(get_change_detector)
):
    """
    Analyze deforestation in the specified area using NDVI change detection
    """
    try:
        logger.info(f"Starting analysis for bbox: {request.bbox_coordinates}")
        
        # Validate bounding box
        min_lon, min_lat, max_lon, max_lat = request.bbox_coordinates
        if min_lon >= max_lon or min_lat >= max_lat:
            raise HTTPException(
                status_code=400,
                detail="Invalid bounding box coordinates: min values must be less than max values"
            )
        
        # Check coordinate ranges
        if not (-180 <= min_lon <= 180 and -180 <= max_lon <= 180):
            raise HTTPException(
                status_code=400,
                detail="Longitude values must be between -180 and 180"
            )
        
        if not (-90 <= min_lat <= 90 and -90 <= max_lat <= 90):
            raise HTTPException(
                status_code=400,
                detail="Latitude values must be between -90 and 90"
            )
        
        # Fetch satellite data
        try:
            t0_data, t1_data = satellite_fetcher.get_time_series_data(
                request.bbox_coordinates,
                request.days_back
            )
        except Exception as e:
            logger.error(f"Satellite data fetch error: {str(e)}")
            raise HTTPException(
                status_code=503,
                detail=f"Unable to fetch satellite data: {str(e)}"
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
                'min_area': settings.MIN_DEFORESTATION_AREA,
                'confidence_threshold': settings.CONFIDENCE_THRESHOLD
            },
            detections=detections,
            summary={
                'total_detections': len(detections),
                'total_changed_pixels': change_results['total_changed_pixels'],
                'change_percentage': round(change_results['change_percentage'], 2),
                'high_confidence_detections': len([d for d in detections if d['confidence'] > 0.8]),
                'critical_detections': len([d for d in detections if d['severity'] == 'Critical']),
                'area_analyzed_km2': round(
                    abs((max_lon - min_lon) * (max_lat - min_lat)) * 111.32 * 111.32, 2
                )
            },
            message=f"Analysis completed successfully. Found {len(detections)} deforestation areas."
        )
        
        logger.info(f"Analysis completed: {len(detections)} detections found")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected analysis error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Analysis failed due to internal error: {str(e)}"
        )

@router.get("/health", response_model=HealthResponse)
async def health_check(
    satellite_fetcher: SatelliteDataFetcher = Depends(get_satellite_fetcher)
):
    """
    Health check endpoint to verify system status
    """
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat(),
        python_version="3.13",
        mock_mode=satellite_fetcher.mock_mode,
        sentinelhub_configured=not satellite_fetcher.mock_mode
    )

@router.get("/config")
async def get_configuration():
    """
    Get current system configuration (without sensitive data)
    """
    return {
        "ndvi_change_threshold": settings.NDVI_CHANGE_THRESHOLD,
        "min_deforestation_area": settings.MIN_DEFORESTATION_AREA,
        "confidence_threshold": settings.CONFIDENCE_THRESHOLD,
        "api_version": settings.VERSION,
        "project_name": settings.PROJECT_NAME
    }

@router.post("/validate-coordinates")
async def validate_coordinates(coordinates: List[float]):
    """
    Validate bounding box coordinates
    """
    if len(coordinates) != 4:
        raise HTTPException(
            status_code=400,
            detail="Coordinates must contain exactly 4 values: [min_lon, min_lat, max_lon, max_lat]"
        )
    
    min_lon, min_lat, max_lon, max_lat = coordinates
    
    errors = []
    
    if min_lon >= max_lon:
        errors.append("min_longitude must be less than max_longitude")
    
    if min_lat >= max_lat:
        errors.append("min_latitude must be less than max_latitude")
    
    if not (-180 <= min_lon <= 180 and -180 <= max_lon <= 180):
        errors.append("Longitude values must be between -180 and 180")
    
    if not (-90 <= min_lat <= 90 and -90 <= max_lat <= 90):
        errors.append("Latitude values must be between -90 and 90")
    
    # Calculate area
    area_km2 = abs((max_lon - min_lon) * (max_lat - min_lat)) * 111.32 * 111.32
    
    if area_km2 > 10000:  # Limit to ~100km x 100km
        errors.append(f"Area too large ({area_km2:.1f} km²). Maximum recommended area is 10,000 km²")
    
    if errors:
        raise HTTPException(status_code=400, detail={"errors": errors})
    
    return {
        "valid": True,
        "area_km2": round(area_km2, 2),
        "message": "Coordinates are valid"
    }

from typing import Dict, Any
from pydantic import BaseModel

class ImageComparisonRequest(BaseModel):
    bbox_coordinates: List[float] = Field(..., min_length=4, max_length=4)
    days_back: Optional[int] = Field(default=10, ge=1, le=30)
    resolution: Optional[int] = Field(default=60, ge=10, le=100)

class ImageComparisonResponse(BaseModel):
    success: bool
    timestamp: str
    t0_image: str  # Base64 encoded image
    t1_image: str  # Base64 encoded image
    t0_date_range: Dict[str, str]
    t1_date_range: Dict[str, str]
    image_metadata: Dict[str, Any]
    message: str

@router.post("/extract-images", response_model=ImageComparisonResponse)
async def extract_comparison_images(
    request: ImageComparisonRequest,
    satellite_fetcher: SatelliteDataFetcher = Depends(get_satellite_fetcher)
):
    """
    Extract T0 and T1 satellite images for visual comparison
    """
    try:
        logger.info(f"Extracting images for bbox: {request.bbox_coordinates}")
        
        # Validate bounding box
        min_lon, min_lat, max_lon, max_lat = request.bbox_coordinates
        if min_lon >= max_lon or min_lat >= max_lat:
            raise HTTPException(
                status_code=400,
                detail="Invalid bounding box coordinates"
            )
        
        # Calculate date ranges
        from datetime import datetime, timedelta
        end_date = datetime.now()
        start_date_t1 = end_date - timedelta(days=3)
        start_date_t0 = end_date - timedelta(days=request.days_back + 3)
        end_date_t0 = end_date - timedelta(days=request.days_back)
        
        # Fetch comparison data
        t0_ndvi_data, t1_ndvi_data, t0_rgb_image, t1_rgb_image = satellite_fetcher.get_comparison_images(
            request.bbox_coordinates,
            request.days_back
        )
        
        # Convert images to base64 for web transfer
        t0_image_b64 = satellite_fetcher.convert_image_to_base64(t0_rgb_image)
        t1_image_b64 = satellite_fetcher.convert_image_to_base64(t1_rgb_image)
        
        # Prepare response
        response = ImageComparisonResponse(
            success=True,
            timestamp=datetime.now().isoformat(),
            t0_image=t0_image_b64,
            t1_image=t1_image_b64,
            t0_date_range={
                "start": start_date_t0.strftime('%Y-%m-%d'),
                "end": end_date_t0.strftime('%Y-%m-%d')
            },
            t1_date_range={
                "start": start_date_t1.strftime('%Y-%m-%d'),
                "end": end_date.strftime('%Y-%m-%d')
            },
            image_metadata={
                "resolution": request.resolution,
                "image_size": f"{t0_rgb_image.shape[1]}x{t0_rgb_image.shape[0]}",
                "bands": "RGB (True Color)",
                "source": "Sentinel-2 L2A"
            },
            message=f"Successfully extracted comparison images for {request.days_back}-day analysis"
        )
        
        logger.info("Image extraction completed successfully")
        return response
        
    except Exception as e:
        logger.error(f"Image extraction error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Image extraction failed: {str(e)}"
        )

@router.post("/analyze-with-images", response_model=Dict[str, Any])
async def analyze_with_images(
    request: AnalysisRequest,
    satellite_fetcher: SatelliteDataFetcher = Depends(get_satellite_fetcher),
    ndvi_processor: NDVIProcessor = Depends(get_ndvi_processor),
    change_detector: ChangeDetector = Depends(get_change_detector)
):
    """
    Complete analysis with both deforestation detection and image comparison
    """
    try:
        # Get both NDVI data and RGB images
        t0_ndvi_data, t1_ndvi_data, t0_rgb_image, t1_rgb_image = satellite_fetcher.get_comparison_images(
            request.bbox_coordinates,
            request.days_back
        )
        
        # Process NDVI analysis (existing logic)
        t0_processed = ndvi_processor.preprocess_image(t0_ndvi_data)
        t1_processed = ndvi_processor.preprocess_image(t1_ndvi_data)
        
        ndvi_t0 = ndvi_processor.calculate_ndvi(t0_processed)
        ndvi_t1 = ndvi_processor.calculate_ndvi(t1_processed)
        
        change_results = change_detector.detect_changes(ndvi_t0, ndvi_t1)
        detections = change_detector.convert_pixel_to_coordinates(
            change_results['detections'],
            request.bbox_coordinates,
            ndvi_t0.shape
        )
        
        # Convert images to base64
        t0_image_b64 = satellite_fetcher.convert_image_to_base64(t0_rgb_image)
        t1_image_b64 = satellite_fetcher.convert_image_to_base64(t1_rgb_image)
        
        # Combined response
        response = {
            "analysis": {
                "success": True,
                "timestamp": datetime.now().isoformat(),
                "detections": detections,
                "summary": {
                    "total_detections": len(detections),
                    "total_changed_pixels": change_results['total_changed_pixels'],
                    "change_percentage": round(change_results['change_percentage'], 2),
                    "high_confidence_detections": len([d for d in detections if d['confidence'] > 0.8])
                }
            },
            "images": {
                "t0_image": t0_image_b64,
                "t1_image": t1_image_b64,
                "metadata": {
                    "resolution": request.resolution,
                    "image_size": f"{t0_rgb_image.shape[1]}x{t0_rgb_image.shape[0]}",
                    "bands": "RGB (True Color)"
                }
            }
        }
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Combined analysis failed: {str(e)}"
        )

@router.post("/analyze-with-cloud-info", response_model=Dict[str, Any])
async def analyze_with_cloud_awareness(
    request: AnalysisRequest,
    satellite_fetcher: SatelliteDataFetcher = Depends(get_satellite_fetcher),
    ndvi_processor: NDVIProcessor = Depends(get_ndvi_processor),
    change_detector: ChangeDetector = Depends(get_change_detector)
):
    """
    Enhanced analysis with cloud awareness and quality assessment
    """
    try:
        # Fetch cloud-aware time series data
        t0_data, t1_data = satellite_fetcher.get_cloud_aware_time_series(
            request.bbox_coordinates,
            request.days_back
        )
        
        # Preprocess with cloud masking
        t0_processed = ndvi_processor.preprocess_image(t0_data)
        t1_processed = ndvi_processor.preprocess_image(t1_data)
        
        # Calculate NDVI with cloud masks
        ndvi_t0, cloud_mask_t0 = ndvi_processor.calculate_ndvi_with_cloud_mask(t0_processed)
        ndvi_t1, cloud_mask_t1 = ndvi_processor.calculate_ndvi_with_cloud_mask(t1_processed)
        
        # Assess image quality
        quality_t0 = ndvi_processor.assess_image_quality(t0_processed, cloud_mask_t0)
        quality_t1 = ndvi_processor.assess_image_quality(t1_processed, cloud_mask_t1)
        
        # Detect changes with cloud awareness
        change_results = change_detector.detect_changes_with_cloud_mask(
            ndvi_t0, ndvi_t1, cloud_mask_t0, cloud_mask_t1
        )
        
        # Convert to geographic coordinates
        detections = change_detector.convert_pixel_to_coordinates(
            change_results['detections'],
            request.bbox_coordinates,
            ndvi_t0.shape
        )
        
        # Enhanced response with cloud information
        response = {
            "analysis": {
                "success": True,
                "timestamp": datetime.now().isoformat(),
                "detections": detections,
                "summary": {
                    "total_detections": len(detections),
                    "total_changed_pixels": change_results['total_changed_pixels'],
                    "total_valid_pixels": change_results['total_valid_pixels'],
                    "change_percentage": round(change_results['change_percentage'], 2),
                    "high_confidence_detections": len([d for d in detections if d['confidence'] > 0.8])
                }
            },
            "cloud_info": {
                "t0_cloud_coverage": round(change_results['cloud_coverage_t0'], 2),
                "t1_cloud_coverage": round(change_results['cloud_coverage_t1'], 2),
                "t0_quality": quality_t0,
                "t1_quality": quality_t1,
                "analysis_reliability": "High" if (quality_t0['overall_quality_score'] > 70 and 
                                                 quality_t1['overall_quality_score'] > 70) else "Medium"
            }
        }
        
        # ✅ Ensure all data is JSON serializable
        response = ensure_json_serializable(response)
        
        return response
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Cloud-aware analysis failed: {str(e)}"
        )
