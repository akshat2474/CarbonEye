import numpy as np
import cv2
from sklearn.preprocessing import MinMaxScaler

class NDVIProcessor:
    def __init__(self):
        self.scaler = MinMaxScaler()
    
    def calculate_ndvi(self, satellite_data):
        """
        Calculate NDVI from satellite data
        
        Args:
            satellite_data: numpy array with shape (height, width, 4)
                           Bands: [Red, NIR, Blue, Green]
        
        Returns:
            numpy array with NDVI values (-1 to 1)
        """
        # Extract Red (Band 4) and NIR (Band 8) - indices 0 and 1
        red = satellite_data[:, :, 0].astype(np.float32)
        nir = satellite_data[:, :, 1].astype(np.float32)
        
        # Avoid division by zero
        denominator = nir + red
        denominator = np.where(denominator == 0, 0.0001, denominator)
        
        # Calculate NDVI
        ndvi = (nir - red) / denominator
        
        # Clip values to valid NDVI range
        ndvi = np.clip(ndvi, -1, 1)
        
        return ndvi
    
    def preprocess_image(self, image_data):
        """
        Preprocess satellite image data
        
        Args:
            image_data: Raw satellite data
        
        Returns:
            Preprocessed image data
        """
        # Normalize values to 0-1 range
        if image_data.max() > 1:
            image_data = image_data / 10000.0  # Sentinel-2 scaling factor
        
        # Apply median filter to reduce noise
        for i in range(image_data.shape[2]):
            image_data[:, :, i] = cv2.medianBlur(
                image_data[:, :, i].astype(np.float32), 3
            )
        
        return image_data
    
    def create_rgb_image(self, satellite_data):
        """
        Create RGB image for visualization
        
        Args:
            satellite_data: numpy array with bands [Red, NIR, Blue, Green]
        
        Returns:
            RGB image array
        """
        # Extract RGB bands (Red=0, Green=3, Blue=2)
        rgb = np.stack([
            satellite_data[:, :, 0],  # Red
            satellite_data[:, :, 3],  # Green
            satellite_data[:, :, 2]   # Blue
        ], axis=2)
        
        # Normalize to 0-255 range
        rgb = np.clip(rgb * 255, 0, 255).astype(np.uint8)
        
        return rgb
    
    def enhance_ndvi_visualization(self, ndvi):
        """
        Create color-coded NDVI visualization
        
        Args:
            ndvi: NDVI array (-1 to 1)
        
        Returns:
            Color-coded NDVI image
        """
        # Normalize NDVI to 0-255 range
        ndvi_normalized = ((ndvi + 1) * 127.5).astype(np.uint8)
        
        # Apply colormap (green for high NDVI, red for low)
        ndvi_colored = cv2.applyColorMap(ndvi_normalized, cv2.COLORMAP_RdYlGn)
        
        return ndvi_colored
