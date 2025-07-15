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

    def detect_and_mask_clouds(self, satellite_data: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Detect clouds using multiple spectral indices and create cloud mask
        """
        # Extract bands
        red = satellite_data[:, :, 0].astype(np.float64)
        nir = satellite_data[:, :, 1].astype(np.float64)
        blue = satellite_data[:, :, 2].astype(np.float64)
        green = satellite_data[:, :, 3].astype(np.float64)
        
        # Cloud detection using multiple indices
        
        # 1. Simple cloud detection (high reflectance in all bands)
        cloud_mask_simple = (red > 0.3) & (green > 0.3) & (blue > 0.3) & (nir > 0.3)
        
        # 2. Whiteness index (clouds are white)
        mean_reflectance = (red + green + blue + nir) / 4
        whiteness = np.abs(red - mean_reflectance) + np.abs(green - mean_reflectance) + \
                    np.abs(blue - mean_reflectance) + np.abs(nir - mean_reflectance)
        cloud_mask_white = (whiteness < 0.1) & (mean_reflectance > 0.25)
        
        # 3. Temperature-based detection (using thermal bands if available)
        # For Sentinel-2, we'll use a proxy based on spectral characteristics
        
        # Combine cloud masks
        cloud_mask = cloud_mask_simple | cloud_mask_white
        
        # Apply morphological operations to clean up the mask
        kernel = np.ones((3, 3), np.uint8)
        cloud_mask = cv2.morphologyEx(cloud_mask.astype(np.uint8), cv2.MORPH_CLOSE, kernel)
        cloud_mask = cv2.morphologyEx(cloud_mask, cv2.MORPH_OPEN, kernel)
        
        return satellite_data, cloud_mask.astype(bool)

    def calculate_ndvi_with_cloud_mask(self, satellite_data: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Calculate NDVI with cloud masking
        """
        # Detect clouds first
        clean_data, cloud_mask = self.detect_and_mask_clouds(satellite_data)
        
        # Extract bands
        red = clean_data[:, :, 0].astype(np.float64)
        nir = clean_data[:, :, 1].astype(np.float64)
        
        # Calculate NDVI
        denominator = nir + red + self.epsilon
        ndvi = (nir - red) / denominator
        
        # Apply cloud mask (set cloudy pixels to NaN)
        ndvi[cloud_mask] = np.nan
        
        # Clip values to valid NDVI range
        ndvi = np.clip(ndvi, -1, 1)
        
        return ndvi.astype(np.float32), cloud_mask

    def assess_image_quality(self, satellite_data: np.ndarray, cloud_mask: np.ndarray) -> dict[str, float]:
        """
        Assess the quality of satellite imagery for NDVI analysis
        """
        total_pixels = satellite_data.shape[0] * satellite_data.shape[1]
        cloud_pixels = np.sum(cloud_mask)
        
        # Calculate various quality metrics
        cloud_coverage = (cloud_pixels / total_pixels) * 100
        clear_pixels = total_pixels - cloud_pixels
        usable_ratio = (clear_pixels / total_pixels) * 100
        
        # Check for data saturation (overexposed pixels)
        saturated_pixels = np.sum(np.any(satellite_data > 0.9, axis=2))
        saturation_ratio = (saturated_pixels / total_pixels) * 100
        
        # Overall quality score
        quality_score = max(0, 100 - cloud_coverage - saturation_ratio)
        
        return {
            'cloud_coverage_percent': float(cloud_coverage),
            'usable_area_percent': float(usable_ratio),
            'saturation_percent': float(saturation_ratio),
            'overall_quality_score': float(quality_score),
            'suitable_for_analysis': bool(quality_score > 50)
        }
