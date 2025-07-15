import numpy as np
import cv2
from scipy import ndimage
from typing import List, Dict, Any, Tuple
import warnings
warnings.filterwarnings('ignore')

class ChangeDetector:
    def __init__(self, change_threshold: float = -0.3, min_area: int = 100, 
                 confidence_threshold: float = 0.6):
        self.change_threshold = change_threshold
        self.min_area = min_area
        self.confidence_threshold = confidence_threshold
    
    def detect_changes(self, ndvi_t0: np.ndarray, ndvi_t1: np.ndarray) -> Dict[str, Any]:
        """
        Detect changes between two NDVI images
        """
        # Calculate NDVI difference
        ndvi_diff = ndvi_t1 - ndvi_t0
        
        # Create binary change mask
        change_mask = (ndvi_diff < self.change_threshold).astype(np.uint8)
        
        # Apply morphological operations
        kernel = np.ones((3, 3), np.uint8)
        change_mask = cv2.morphologyEx(change_mask, cv2.MORPH_CLOSE, kernel)
        change_mask = cv2.morphologyEx(change_mask, cv2.MORPH_OPEN, kernel)
        
        # Find connected components
        labeled_mask, num_features = ndimage.label(change_mask)
        
        # Extract detections
        detections = self._extract_detections(labeled_mask, ndvi_diff, num_features)
        
        return {
            'change_mask': change_mask,
            'ndvi_difference': ndvi_diff,
            'detections': detections,
            'total_changed_pixels': int(np.sum(change_mask)),
            'change_percentage': float((np.sum(change_mask) / change_mask.size) * 100)
        }
    
    def _extract_detections(self, labeled_mask: np.ndarray, ndvi_diff: np.ndarray, 
                          num_features: int) -> List[Dict[str, Any]]:
        """
        Extract individual deforestation detections
        """
        detections = []
        
        for i in range(1, num_features + 1):
            component_mask = (labeled_mask == i)
            component_size = np.sum(component_mask)
            
            if component_size < self.min_area:
                continue
            
            # Get bounding box
            rows, cols = np.where(component_mask)
            min_row, max_row = int(np.min(rows)), int(np.max(rows))
            min_col, max_col = int(np.min(cols)), int(np.max(cols))
            
            # Calculate confidence
            component_ndvi_changes = ndvi_diff[component_mask]
            avg_change = float(np.mean(component_ndvi_changes))
            confidence = min(abs(avg_change) / abs(self.change_threshold), 1.0)
            
            if confidence >= self.confidence_threshold:
                detection = {
                    'id': i,
                    'bounding_box': {
                        'min_row': min_row,
                        'max_row': max_row,
                        'min_col': min_col,
                        'max_col': max_col
                    },
                    'area_pixels': int(component_size),
                    'confidence': float(confidence),
                    'avg_ndvi_change': avg_change,
                    'severity': self._calculate_severity(avg_change)
                }
                detections.append(detection)
        
        # Sort by confidence
        detections.sort(key=lambda x: x['confidence'], reverse=True)
        
        return detections
    
    def _extract_detections_with_cloud_info(self, labeled_mask: np.ndarray, ndvi_diff: np.ndarray, 
                                        num_features: int, valid_mask: np.ndarray) -> List[Dict[str, Any]]:
        """
        Extract individual deforestation detections with cloud information
        
        Args:
            labeled_mask: Labeled connected components
            ndvi_diff: NDVI difference array
            num_features: Number of connected components
            valid_mask: Mask indicating valid (non-cloudy) pixels
        
        Returns:
            list: List of detection dictionaries with cloud info
        """
        detections = []
        
        for i in range(1, num_features + 1):
            # Get pixels for this component
            component_mask = (labeled_mask == i)
            component_size = np.sum(component_mask)
            
            # Filter by minimum area
            if component_size < self.min_area:
                continue
            
            # Get bounding box
            rows, cols = np.where(component_mask)
            min_row, max_row = int(np.min(rows)), int(np.max(rows))
            min_col, max_col = int(np.min(cols)), int(np.max(cols))
            
            # Calculate confidence based on NDVI change magnitude (only for valid pixels)
            valid_component_pixels = component_mask & valid_mask
            
            if np.sum(valid_component_pixels) == 0:
                continue  # Skip if no valid pixels in this component
            
            component_ndvi_changes = ndvi_diff[valid_component_pixels]
            avg_change = float(np.nanmean(component_ndvi_changes))
            confidence = min(abs(avg_change) / abs(self.change_threshold), 1.0)
            
            # Calculate cloud coverage within this detection area
            cloud_pixels_in_detection = np.sum(component_mask & ~valid_mask)
            cloud_coverage_in_detection = (cloud_pixels_in_detection / component_size) * 100
            
            # Only include high-confidence detections
            if confidence >= self.confidence_threshold:
                detection = {
                    'id': i,
                    'bounding_box': {
                        'min_row': min_row,
                        'max_row': max_row,
                        'min_col': min_col,
                        'max_col': max_col
                    },
                    'area_pixels': int(component_size),
                    'valid_pixels': int(np.sum(valid_component_pixels)),
                    'confidence': float(confidence),
                    'avg_ndvi_change': avg_change,
                    'severity': self._calculate_severity(avg_change),
                    'cloud_coverage_percent': float(cloud_coverage_in_detection),
                    'data_quality': 'High' if cloud_coverage_in_detection < 20 else 'Medium' if cloud_coverage_in_detection < 50 else 'Low'
                }
                detections.append(detection)
        
        # Sort by confidence (highest first)
        detections.sort(key=lambda x: x['confidence'], reverse=True)
        
        return detections

    def _calculate_severity(self, avg_change: float) -> str:
        """Calculate severity level"""
        if avg_change <= -0.5:
            return "Critical"
        elif avg_change <= -0.4:
            return "High"
        elif avg_change <= -0.3:
            return "Medium"
        else:
            return "Low"
    
    def convert_pixel_to_coordinates(self, detections: List[Dict[str, Any]], 
                                   bbox_coords: List[float], 
                                   image_shape: Tuple[int, int]) -> List[Dict[str, Any]]:
        """
        Convert pixel coordinates to geographic coordinates
        """
        min_lon, min_lat, max_lon, max_lat = bbox_coords
        height, width = image_shape
        
        lon_per_pixel = (max_lon - min_lon) / width
        lat_per_pixel = (max_lat - min_lat) / height
        
        for detection in detections:
            bbox = detection['bounding_box']
            
            detection['geographic_bbox'] = {
                'min_lon': min_lon + bbox['min_col'] * lon_per_pixel,
                'max_lon': min_lon + bbox['max_col'] * lon_per_pixel,
                'min_lat': max_lat - bbox['max_row'] * lat_per_pixel,
                'max_lat': max_lat - bbox['min_row'] * lat_per_pixel
            }
            
            detection['center_coordinates'] = {
                'latitude': (detection['geographic_bbox']['min_lat'] + 
                           detection['geographic_bbox']['max_lat']) / 2,
                'longitude': (detection['geographic_bbox']['min_lon'] + 
                            detection['geographic_bbox']['max_lon']) / 2
            }
        
        return detections

    def detect_changes_with_cloud_mask(self, ndvi_t0: np.ndarray, ndvi_t1: np.ndarray, 
                                    cloud_mask_t0: np.ndarray, cloud_mask_t1: np.ndarray) -> Dict[str, Any]:
        """
        Detect changes while accounting for cloud masks
        """
        # Create combined valid pixel mask
        valid_mask = ~(cloud_mask_t0 | cloud_mask_t1 | np.isnan(ndvi_t0) | np.isnan(ndvi_t1))
        
        # Only analyze pixels that are valid in both time periods
        ndvi_diff = np.full_like(ndvi_t0, np.nan)
        ndvi_diff[valid_mask] = ndvi_t1[valid_mask] - ndvi_t0[valid_mask]
        
        # Create binary change mask only for valid pixels
        change_mask = np.zeros_like(ndvi_t0, dtype=np.uint8)
        change_mask[valid_mask & (ndvi_diff < self.change_threshold)] = 1
        
        # Apply morphological operations
        kernel = np.ones((3, 3), np.uint8)
        change_mask = cv2.morphologyEx(change_mask, cv2.MORPH_CLOSE, kernel)
        change_mask = cv2.morphologyEx(change_mask, cv2.MORPH_OPEN, kernel)
        
        # Find connected components
        labeled_mask, num_features = ndimage.label(change_mask)
        
        # Extract detections
        detections = self._extract_detections_with_cloud_info(
            labeled_mask, ndvi_diff, num_features, valid_mask
        )
        
        # Calculate statistics only for valid pixels
        total_valid_pixels = np.sum(valid_mask)
        total_changed_pixels = np.sum(change_mask)
        
        return {
            'change_mask': change_mask,
            'ndvi_difference': ndvi_diff,
            'detections': detections,
            'total_changed_pixels': int(total_changed_pixels),
            'total_valid_pixels': int(total_valid_pixels),
            'change_percentage': float((total_changed_pixels / max(total_valid_pixels, 1)) * 100),
            'cloud_coverage_t0': float(np.sum(cloud_mask_t0) / cloud_mask_t0.size * 100),
            'cloud_coverage_t1': float(np.sum(cloud_mask_t1) / cloud_mask_t1.size * 100)
        }

    def assess_image_quality(self, satellite_data: np.ndarray, cloud_mask: np.ndarray) -> Dict[str, float]:
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
            'suitable_for_analysis': quality_score > 50
        }

