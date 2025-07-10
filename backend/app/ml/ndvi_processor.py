import numpy as np
import cv2
from typing import Tuple, Optional
import warnings
warnings.filterwarnings('ignore')

class NDVIProcessor:
    def __init__(self):
        self.epsilon = 1e-8  # Small value to prevent division by zero
    
    def calculate_ndvi(self, satellite_data: np.ndarray) -> np.ndarray:
        """
        Calculate NDVI from satellite data
        
        Args:
            satellite_data: numpy array with shape (height, width, 4)
                           Bands: [Red, NIR, Blue, Green]
        
        Returns:
            numpy array with NDVI values (-1 to 1)
        """
        # Extract Red (Band 4) and NIR (Band 8) - indices 0 and 1
        red = satellite_data[:, :, 0].astype(np.float64)
        nir = satellite_data[:, :, 1].astype(np.float64)
        
        # Avoid division by zero
        denominator = nir + red + self.epsilon
        
        # Calculate NDVI
        ndvi = (nir - red) / denominator
        
        # Clip values to valid NDVI range
        ndvi = np.clip(ndvi, -1, 1)
        
        return ndvi.astype(np.float32)
    
    def preprocess_image(self, image_data: np.ndarray) -> np.ndarray:
        """
        Preprocess satellite image data
        """
        # Ensure float32 type
        image_data = image_data.astype(np.float32)
        
        # Normalize values to 0-1 range if needed
        if image_data.max() > 1:
            image_data = image_data / 10000.0
        
        # Apply median filter to reduce noise
        processed_data = np.zeros_like(image_data)
        for i in range(image_data.shape[2]):
            processed_data[:, :, i] = cv2.medianBlur(
                image_data[:, :, i], 3
            )
        
        return processed_data
    
    def create_rgb_image(self, satellite_data: np.ndarray) -> np.ndarray:
        """
        Create RGB image for visualization
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
    
    def enhance_ndvi_visualization(self, ndvi: np.ndarray) -> np.ndarray:
        """
        Create color-coded NDVI visualization
        """
        # Normalize NDVI to 0-255 range
        ndvi_normalized = ((ndvi + 1) * 127.5).astype(np.uint8)
        
        # Apply colormap
        ndvi_colored = cv2.applyColorMap(ndvi_normalized, cv2.COLORMAP_RdYlGn)
        
        return ndvi_colored
