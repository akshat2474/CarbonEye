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
