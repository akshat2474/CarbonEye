import requests
import numpy as np
from datetime import datetime, timedelta
from sentinelhub import SHConfig, BBox, CRS, MimeType, DataCollection
from sentinelhub import SentinelHubRequest, bbox_to_dimensions

class SatelliteDataFetcher:
    def __init__(self, client_id, client_secret, instance_id):
        self.config = SHConfig()
        self.config.sh_client_id = client_id
        self.config.sh_client_secret = client_secret
        self.config.instance_id = instance_id
    
    def get_evalscript(self):
        """
        Evalscript to fetch Red, NIR, and RGB bands from Sentinel-2
        """
        return """
        //VERSION=3
        function setup() {
            return {
                input: ["B04", "B08", "B02", "B03"],  // Red, NIR, Blue, Green
                output: { bands: 4 }
            };
        }
        
        function evaluatePixel(sample) {
            return [sample.B04, sample.B08, sample.B02, sample.B03];
        }
        """
    
    def fetch_satellite_data(self, bbox_coords, start_date, end_date, resolution=60):
        """
        Fetch satellite data for given bounding box and time range
        
        Args:
            bbox_coords: [min_lon, min_lat, max_lon, max_lat]
            start_date: datetime object
            end_date: datetime object
            resolution: pixel resolution in meters
        
        Returns:
            numpy array with shape (height, width, 4) - [Red, NIR, Blue, Green]
        """
        # Create bounding box
        bbox = BBox(bbox=bbox_coords, crs=CRS.WGS84)
        size = bbox_to_dimensions(bbox, resolution=resolution)
        
        # Create request
        request = SentinelHubRequest(
            evalscript=self.get_evalscript(),
            input_data=[
                SentinelHubRequest.input_data(
                    data_collection=DataCollection.SENTINEL2_L2A,
                    time_interval=(start_date, end_date),
                    mosaicking_order='leastCC'  # Least cloud coverage
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
            return response[0]  # Return first (and only) response
        else:
            raise Exception("No satellite data available for the specified parameters")
    
    def get_time_series_data(self, bbox_coords, days_back=10):
        """
        Get T0 (past) and T1 (current) satellite images
        
        Args:
            bbox_coords: [min_lon, min_lat, max_lon, max_lat]
            days_back: Number of days to look back for T0
        
        Returns:
            tuple: (t0_data, t1_data) - Both are numpy arrays
        """
        end_date = datetime.now()
        start_date_t1 = end_date - timedelta(days=3)  # Recent data (T1)
        
        start_date_t0 = end_date - timedelta(days=days_back + 3)
        end_date_t0 = end_date - timedelta(days=days_back)  # Past data (T0)
        
        try:
            # Fetch T1 (current/recent)
            t1_data = self.fetch_satellite_data(
                bbox_coords, start_date_t1, end_date
            )
            
            # Fetch T0 (past)
            t0_data = self.fetch_satellite_data(
                bbox_coords, start_date_t0, end_date_t0
            )
            
            return t0_data, t1_data
            
        except Exception as e:
            raise Exception(f"Error fetching time series data: {str(e)}")
