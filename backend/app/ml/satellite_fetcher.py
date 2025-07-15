import requests
import numpy as np
from datetime import datetime, timedelta
from typing import Tuple, Optional, List
import warnings
warnings.filterwarnings('ignore')
import base64
from io import BytesIO
from PIL import Image


try:
    from sentinelhub import SHConfig, BBox, CRS, MimeType, DataCollection
    from sentinelhub import SentinelHubRequest, bbox_to_dimensions
    SENTINELHUB_AVAILABLE = True
except ImportError:
    SENTINELHUB_AVAILABLE = False
    print("Warning: SentinelHub not available. Using mock data for development.")

class SatelliteDataFetcher:
    def __init__(self, client_id: Optional[str], client_secret: Optional[str]):
        if SENTINELHUB_AVAILABLE and all([client_id, client_secret]):
            self.config = SHConfig()
            self.config.sh_client_id = client_id
            self.config.sh_client_secret = client_secret
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

    def get_rgb_evalscript(self) -> str:
        """
        Evalscript for RGB visualization (True Color)
        """
        return """
        //VERSION=3
        function setup() {
            return {
                input: ["B04", "B03", "B02"],
                output: { bands: 3 }
            };
        }
        
        function evaluatePixel(sample) {
            return [sample.B04, sample.B03, sample.B02];
        }
        """

    def fetch_rgb_image(self, bbox_coords: List[float], start_date: datetime, 
                    end_date: datetime, resolution: int = 60) -> np.ndarray:
        """
        Fetch RGB satellite image for visualization
        """
        if self.mock_mode:
            return self._generate_mock_rgb_image()

        bbox = BBox(bbox=bbox_coords, crs=CRS.WGS84)
        size = bbox_to_dimensions(bbox, resolution=resolution)
        
        # Limit size for performance
        if size[0] > 2048 or size[1] > 2048:
            size = (min(size[0], 2048), min(size[1], 2048))

        request = SentinelHubRequest(
            evalscript=self.get_rgb_evalscript(),
            input_data=[
                SentinelHubRequest.input_data(
                    data_collection=DataCollection.SENTINEL2_L2A,
                    time_interval=(start_date, end_date),
                    mosaicking_order='leastCC'
                )
            ],
            responses=[
                SentinelHubRequest.output_response('default', MimeType.PNG)
            ],
            bbox=bbox,
            size=size,
            config=self.config
        )

        response = request.get_data()
        if response and len(response) > 0:
            return response[0]
        else:
            raise Exception("No RGB image data available")

    def get_comparison_images(self, bbox_coords: List[float], days_back: int = 10) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        """
        Get both NDVI data and RGB images for T0 and T1
        
        Returns:
            tuple: (t0_ndvi_data, t1_ndvi_data, t0_rgb_image, t1_rgb_image)
        """
        end_date = datetime.now()
        start_date_t1 = end_date - timedelta(days=3)
        start_date_t0 = end_date - timedelta(days=days_back + 3)
        end_date_t0 = end_date - timedelta(days=days_back)

        try:
            # Fetch NDVI data (using your existing method)
            t1_ndvi_data = self.fetch_satellite_data(bbox_coords, start_date_t1, end_date)
            t0_ndvi_data = self.fetch_satellite_data(bbox_coords, start_date_t0, end_date_t0)
            
            # Fetch RGB images for visualization
            t1_rgb_image = self.fetch_rgb_image(bbox_coords, start_date_t1, end_date)
            t0_rgb_image = self.fetch_rgb_image(bbox_coords, start_date_t0, end_date_t0)
            
            return t0_ndvi_data, t1_ndvi_data, t0_rgb_image, t1_rgb_image
            
        except Exception as e:
            raise Exception(f"Error fetching comparison data: {str(e)}")

    def _generate_mock_rgb_image(self, width: int = 256, height: int = 256) -> np.ndarray:
        """Generate mock RGB image for testing"""
        np.random.seed(42)
        
        # Create realistic RGB satellite image
        rgb_image = np.random.randint(0, 255, (height, width, 3), dtype=np.uint8)
        
        # Add some forest-like patterns (green areas)
        forest_mask = np.random.random((height, width)) > 0.7
        rgb_image[forest_mask, 1] = np.random.randint(100, 200, np.sum(forest_mask))  # Green
        rgb_image[forest_mask, 0] = np.random.randint(50, 120, np.sum(forest_mask))   # Red
        rgb_image[forest_mask, 2] = np.random.randint(30, 100, np.sum(forest_mask))   # Blue
        
        return rgb_image

    def convert_image_to_base64(self, image_array: np.ndarray) -> str:
        """
        Convert numpy image array to base64 string for web transfer
        """
        if image_array.dtype != np.uint8:
            # Normalize to 0-255 range
            image_array = ((image_array - image_array.min()) / 
                        (image_array.max() - image_array.min()) * 255).astype(np.uint8)
        
        # Convert to PIL Image
        from PIL import Image
        import base64
        from io import BytesIO
        
        pil_image = Image.fromarray(image_array)
        
        # Convert to base64
        buffer = BytesIO()
        pil_image.save(buffer, format='PNG')
        img_str = base64.b64encode(buffer.getvalue()).decode()
        
        return f"data:image/png;base64,{img_str}"

    def get_cloud_filtered_evalscript(self) -> str:
        """
        Enhanced evalscript with cloud masking capabilities
        """
        return """
        //VERSION=3
        function setup() {
            return {
                input: [{
                    bands: ["B04", "B08", "B02", "B03", "B09", "B11", "SCL"],
                    units: "DN"
                }],
                output: { 
                    bands: 5,
                    sampleType: "FLOAT32"
                }
            };
        }
        
        function evaluatePixel(sample) {
            // Use Scene Classification Layer (SCL) for cloud masking
            // SCL values: 4=vegetation, 5=not-vegetated, 6=water, 7=unclassified
            // 8=cloud medium probability, 9=cloud high probability, 10=thin cirrus, 11=snow
            
            let validPixel = (sample.SCL == 4 || sample.SCL == 5 || sample.SCL == 6 || sample.SCL == 11);
            
            if (!validPixel) {
                return [0, 0, 0, 0, 0]; // Return null values for cloudy pixels
            }
            
            return [sample.B04, sample.B08, sample.B02, sample.B03, 1]; // Last band indicates valid pixel
        }
        """

    def fetch_cloud_free_data(self, bbox_coords: List[float], start_date: datetime, 
                            end_date: datetime, resolution: int = 60, max_cloud_cover: int = 20) -> np.ndarray:
        """
        Fetch cloud-filtered satellite data with multiple attempts
        """
        if self.mock_mode:
            return self._generate_mock_data()

        bbox = BBox(bbox=bbox_coords, crs=CRS.WGS84)
        size = bbox_to_dimensions(bbox, resolution=resolution)
        
        # Limit size for performance
        if size[0] > 2048 or size[1] > 2048:
            size = (min(size[0], 2048), min(size[1], 2048))

        # Try multiple time windows to find cloud-free data
        attempts = 0
        max_attempts = 5
        current_start = start_date
        current_end = end_date
        
        while attempts < max_attempts:
            try:
                request = SentinelHubRequest(
                    evalscript=self.get_cloud_filtered_evalscript(),
                    input_data=[
                        SentinelHubRequest.input_data(
                            data_collection=DataCollection.SENTINEL2_L2A,
                            time_interval=(current_start, current_end),
                            mosaicking_order='leastCC',
                            maxcc=max_cloud_cover/100.0  # Maximum cloud coverage
                        )
                    ],
                    responses=[
                        SentinelHubRequest.output_response('default', MimeType.TIFF)
                    ],
                    bbox=bbox,
                    size=size,
                    config=self.config
                )
                
                response = request.get_data()
                
                if response and len(response) > 0:
                    data = response[0].astype(np.float32)
                    
                    # Check if we have enough valid pixels (non-zero in last band)
                    valid_pixel_ratio = np.sum(data[:, :, 4] > 0) / (data.shape[0] * data.shape[1])
                    
                    if valid_pixel_ratio > 0.3:  # At least 30% valid pixels
                        return data[:, :, :4]  # Return only the spectral bands
                    
                # If not enough valid pixels, try expanding the time window
                attempts += 1
                window_expansion = timedelta(days=3 * attempts)
                current_start = start_date - window_expansion
                current_end = end_date + window_expansion
                
            except Exception as e:
                attempts += 1
                if attempts >= max_attempts:
                    raise Exception(f"Failed to fetch cloud-free data after {max_attempts} attempts: {str(e)}")
        
        raise Exception("No cloud-free data available for the specified parameters")

    def get_cloud_aware_time_series(self, bbox_coords: List[float], days_back: int = 10) -> Tuple[np.ndarray, np.ndarray]:
        """
        Get cloud-aware time series data with multiple fallback options
        """
        end_date = datetime.now()
        
        # Try multiple time windows to find cloud-free images
        time_windows = [
            (days_back, 3),      # Original window
            (days_back + 5, 3),  # Extended past window
            (days_back, 7),      # Extended recent window
            (days_back + 10, 7), # Both extended
            (days_back + 15, 10) # Maximum extension
        ]
        
        for past_days, recent_days in time_windows:
            try:
                start_date_t1 = end_date - timedelta(days=recent_days)
                start_date_t0 = end_date - timedelta(days=past_days + recent_days)
                end_date_t0 = end_date - timedelta(days=past_days)
                
                print(f"Trying time window: T0({start_date_t0.strftime('%Y-%m-%d')} to {end_date_t0.strftime('%Y-%m-%d')}) vs T1({start_date_t1.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')})")
                
                # Fetch with cloud filtering
                t1_data = self.fetch_cloud_free_data(bbox_coords, start_date_t1, end_date, max_cloud_cover=30)
                t0_data = self.fetch_cloud_free_data(bbox_coords, start_date_t0, end_date_t0, max_cloud_cover=30)
                
                print(f"✅ Successfully found cloud-free data for time window")
                return t0_data, t1_data
                
            except Exception as e:
                print(f"❌ Failed for time window: {str(e)}")
                continue
        
        # If all attempts fail, try with higher cloud tolerance
        print("⚠️ Attempting with higher cloud tolerance...")
        try:
            start_date_t1 = end_date - timedelta(days=7)
            start_date_t0 = end_date - timedelta(days=days_back + 7)
            end_date_t0 = end_date - timedelta(days=days_back)
            
            t1_data = self.fetch_cloud_free_data(bbox_coords, start_date_t1, end_date, max_cloud_cover=60)
            t0_data = self.fetch_cloud_free_data(bbox_coords, start_date_t0, end_date_t0, max_cloud_cover=60)
            
            return t0_data, t1_data
            
        except Exception as e:
            raise Exception(f"No suitable cloud-free data available: {str(e)}")
