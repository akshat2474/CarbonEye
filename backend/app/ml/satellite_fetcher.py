import requests
import numpy as np
from datetime import datetime, timedelta
from typing import Tuple, Optional, List
import warnings
warnings.filterwarnings('ignore')

try:
    from sentinelhub import SHConfig, BBox, CRS, MimeType, DataCollection
    from sentinelhub import SentinelHubRequest, bbox_to_dimensions
    SENTINELHUB_AVAILABLE = True
except ImportError:
    SENTINELHUB_AVAILABLE = False
    print("Warning: SentinelHub not available. Using mock data for development.")

class SatelliteDataFetcher:
    def __init__(self, client_id: Optional[str], client_secret: Optional[str], instance_id: Optional[str]):
        if SENTINELHUB_AVAILABLE and all([client_id, client_secret, instance_id]):
            self.config = SHConfig()
            self.config.sh_client_id = client_id
            self.config.sh_client_secret = client_secret
            self.config.instance_id = instance_id
            self.mock_mode = False
        else:
            self.mock_mode = True
            print("Running in mock mode - using synthetic data")
    
    def get_evalscript(self) -> str:
        """
        Evalscript to fetch Red, NIR, and RGB bands from Sentinel-2
        """
        return """
        //VERSION=3
        function setup() {
            return {
                input: ["B04", "B08", "B02", "B03"],  // Red, NIR, Blue, Green
                output: { bands: 4, sampleType: "FLOAT32" }
            };
        }
        
        function evaluatePixel(sample) {
            return [sample.B04, sample.B08, sample.B02, sample.B03];
        }
        """
    
    def _generate_mock_data(self, width: int = 256, height: int = 256) -> np.ndarray:
        """Generate mock satellite data for testing"""
        np.random.seed(42)  # For reproducible results
        
        # Create realistic satellite data
        red = np.random.uniform(0.1, 0.3, (height, width))
        nir = np.random.uniform(0.4, 0.8, (height, width))
        blue = np.random.uniform(0.05, 0.2, (height, width))
        green = np.random.uniform(0.1, 0.4, (height, width))
        
        # Add some forest areas (high NIR, low Red)
        forest_mask = np.random.random((height, width)) > 0.7
        red[forest_mask] *= 0.5
        nir[forest_mask] *= 1.5
        
        return np.stack([red, nir, blue, green], axis=2).astype(np.float32)
    
    def fetch_satellite_data(self, bbox_coords: List[float], start_date: datetime, 
                           end_date: datetime, resolution: int = 60) -> np.ndarray:
        """
        Fetch satellite data for given bounding box and time range
        """
        if self.mock_mode:
            return self._generate_mock_data()
        
        # Create bounding box
        bbox = BBox(bbox=bbox_coords, crs=CRS.WGS84)
        size = bbox_to_dimensions(bbox, resolution=resolution)
        
        # Ensure reasonable size limits
        if size[0] > 2048 or size[1] > 2048:
            size = (min(size[0], 2048), min(size[1], 2048))
        
        # Create request
        request = SentinelHubRequest(
            evalscript=self.get_evalscript(),
            input_data=[
                SentinelHubRequest.input_data(
                    data_collection=DataCollection.SENTINEL2_L2A,
                    time_interval=(start_date, end_date),
                    mosaicking_order='leastCC'
                )
            ],
            responses=[
                SentinelHubRequest.output_response('default', MimeType.TIFF)
            ],
            bbox=bbox,
            size=size,
            config=self.config
        )
        
        # Get data
        response = request.get_data()
        
        if response and len(response) > 0:
            return response[0].astype(np.float32)
        else:
            raise Exception("No satellite data available for the specified parameters")
    
    def get_time_series_data(self, bbox_coords: List[float], days_back: int = 10) -> Tuple[np.ndarray, np.ndarray]:
        """
        Get T0 (past) and T1 (current) satellite images
        """
        if self.mock_mode:
            t0_data = self._generate_mock_data()
            t1_data = self._generate_mock_data()
            
            # Simulate some deforestation in t1
            deforestation_mask = np.random.random(t1_data.shape[:2]) > 0.95
            t1_data[deforestation_mask, 0] *= 1.5  # Increase red
            t1_data[deforestation_mask, 1] *= 0.3  # Decrease NIR
            
            return t0_data, t1_data
        
        end_date = datetime.now()
        start_date_t1 = end_date - timedelta(days=3)
        
        start_date_t0 = end_date - timedelta(days=days_back + 3)
        end_date_t0 = end_date - timedelta(days=days_back)
        
        try:
            t1_data = self.fetch_satellite_data(bbox_coords, start_date_t1, end_date)
            t0_data = self.fetch_satellite_data(bbox_coords, start_date_t0, end_date_t0)
            
            return t0_data, t1_data
            
        except Exception as e:
            raise Exception(f"Error fetching time series data: {str(e)}")
