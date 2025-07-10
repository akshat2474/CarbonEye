import numpy as np
import cv2
from scipy import ndimage
from sklearn.cluster import DBSCAN

class ChangeDetector:
    def __init__(self, change_threshold=-0.3, min_area=100, confidence_threshold=0.6):
        self.change_threshold = change_threshold
        self.min_area = min_area
        self.confidence_threshold = confidence_threshold
    
    def detect_changes(self, ndvi_t0, ndvi_t1):
        """
        Detect changes between two NDVI images
        
        Args:
            ndvi_t0: NDVI at time T0 (past)
            ndvi_t1: NDVI at time T1 (current)
        
        Returns:
            dict: Change detection results
        """
        # Calculate NDVI difference
        ndvi_diff = ndvi_t1 - ndvi_t0
        
        # Create binary change mask
        change_mask = (ndvi_diff < self.change_threshold).astype(np.uint8)
        
        # Apply morphological operations to clean up the mask
        kernel = np.ones((3, 3), np.uint8)
        change_mask = cv2.morphologyEx(change_mask, cv2.MORPH_CLOSE, kernel)
        change_mask = cv2.morphologyEx(change_mask, cv2.MORPH_OPEN, kernel)
        
        # Find connected components (potential deforestation areas)
        labeled_mask, num_features = ndimage.label(change_mask)
        
        # Extract bounding boxes and calculate confidence
        detections = self._extract_detections(
            labeled_mask, ndvi_diff, num_features
        )
        
        return {
            'change_mask': change_mask,
            'ndvi_difference': ndvi_diff,
            'detections': detections,
            'total_changed_pixels': np.sum(change_mask),
            'change_percentage': (np.sum(change_mask) / change_mask.size) * 100
        }
    
    def _extract_detections(self, labeled_mask, ndvi_diff, num_features):
        """
        Extract individual deforestation detections with bounding boxes
        
        Args:
            labeled_mask: Labeled connected components
            ndvi_diff: NDVI difference array
            num_features: Number of connected components
        
        Returns:
            list: List of detection dictionaries
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
            min_row, max_row = np.min(rows), np.max(rows)
            min_col, max_col = np.min(cols), np.max(cols)
            
            # Calculate confidence based on NDVI change magnitude
            component_ndvi_changes = ndvi_diff[component_mask]
            avg_change = np.mean(component_ndvi_changes)
            confidence = min(abs(avg_change) / abs(self.change_threshold), 1.0)
            
            # Only include high-confidence detections
            if confidence >= self.confidence_threshold:
                detection = {
                    'id': i,
                    'bounding_box': {
                        'min_row': int(min_row),
                        'max_row': int(max_row),
                        'min_col': int(min_col),
                        'max_col': int(max_col)
                    },
                    'area_pixels': int(component_size),
                    'confidence': float(confidence),
                    'avg_ndvi_change': float(avg_change),
                    'severity': self._calculate_severity(avg_change)
                }
                detections.append(detection)
        
        # Sort by confidence (highest first)
        detections.sort(key=lambda x: x['confidence'], reverse=True)
        
        return detections
    
    def _calculate_severity(self, avg_change):
        """
        Calculate severity level based on NDVI change
        
        Args:
            avg_change: Average NDVI change in the area
        
        Returns:
            str: Severity level
        """
        if avg_change <= -0.5:
            return "Critical"
        elif avg_change <= -0.4:
            return "High"
        elif avg_change <= -0.3:
            return "Medium"
        else:
            return "Low"
    
    def convert_pixel_to_coordinates(self, detections, bbox_coords, image_shape):
        """
        Convert pixel coordinates to geographic coordinates
        
        Args:
            detections: List of detections with pixel coordinates
            bbox_coords: [min_lon, min_lat, max_lon, max_lat]
            image_shape: (height, width) of the image
        
        Returns:
            list: Detections with geographic coordinates
        """
        min_lon, min_lat, max_lon, max_lat = bbox_coords
        height, width = image_shape
        
        # Calculate pixel to coordinate conversion factors
        lon_per_pixel = (max_lon - min_lon) / width
        lat_per_pixel = (max_lat - min_lat) / height
        
        for detection in detections:
            bbox = detection['bounding_box']
            
            # Convert pixel coordinates to geographic coordinates
            detection['geographic_bbox'] = {
                'min_lon': min_lon + bbox['min_col'] * lon_per_pixel,
                'max_lon': min_lon + bbox['max_col'] * lon_per_pixel,
                'min_lat': max_lat - bbox['max_row'] * lat_per_pixel,  # Note: Y is flipped
                'max_lat': max_lat - bbox['min_row'] * lat_per_pixel
            }
            
            # Calculate center coordinates
            detection['center_coordinates'] = {
                'latitude': (detection['geographic_bbox']['min_lat'] + 
                           detection['geographic_bbox']['max_lat']) / 2,
                'longitude': (detection['geographic_bbox']['min_lon'] + 
                            detection['geographic_bbox']['max_lon']) / 2
            }
        
        return detections
