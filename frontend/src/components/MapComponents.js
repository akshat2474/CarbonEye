import React, { useState, useRef } from 'react';
import { MapContainer, TileLayer, Rectangle, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix for default markers
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
});

const MapComponent = ({ onAnalysis, analysisResults, onDetectionClick, loading }) => {
  const [selectedArea, setSelectedArea] = useState(null);
  const [isSelecting, setIsSelecting] = useState(false);
  const mapRef = useRef();

  // Component for handling map clicks
  const MapClickHandler = () => {
    useMapEvents({
      click: (e) => {
        if (isSelecting) {
          // Start area selection
          setSelectedArea({
            start: [e.latlng.lat, e.latlng.lng],
            end: null
          });
        }
      },
      mousemove: (e) => {
        if (isSelecting && selectedArea && selectedArea.start && !selectedArea.end) {
          // Update selection rectangle
          setSelectedArea({
            ...selectedArea,
            current: [e.latlng.lat, e.latlng.lng]
          });
        }
      },
      contextmenu: (e) => {
        if (isSelecting && selectedArea && selectedArea.start) {
          // Finish area selection
          const bbox = [
            Math.min(selectedArea.start[1], e.latlng.lng), // min_lon
            Math.min(selectedArea.start[0], e.latlng.lat),  // min_lat
            Math.max(selectedArea.start[1], e.latlng.lng), // max_lon
            Math.max(selectedArea.start[0], e.latlng.lat)   // max_lat
          ];
          
          setSelectedArea({
            start: selectedArea.start,
            end: [e.latlng.lat, e.latlng.lng]
          });
          
          setIsSelecting(false);
          onAnalysis(bbox);
        }
      }
    });
    return null;
  };

  // Render detection rectangles
  const renderDetections = () => {
    if (!analysisResults || !analysisResults.detections) return null;

    return analysisResults.detections.map((detection) => {
      const bounds = [
        [detection.geographic_bbox.min_lat, detection.geographic_bbox.min_lon],
        [detection.geographic_bbox.max_lat, detection.geographic_bbox.max_lon]
      ];

      const color = detection.severity === 'Critical' ? '#ff0000' :
                   detection.severity === 'High' ? '#ff6600' :
                   detection.severity === 'Medium' ? '#ffaa00' : '#ffdd00';

      return (
        <Rectangle
          key={detection.id}
          bounds={bounds}
          pathOptions={{
            color: color,
            fillColor: color,
            fillOpacity: 0.3,
            weight: 2
          }}
          eventHandlers={{
            click: () => onDetectionClick(detection)
          }}
        />
      );
    });
  };

  return (
    <div className="map-component">
      <div className="map-controls">
        <button
          onClick={() => setIsSelecting(!isSelecting)}
          className={`control-btn ${isSelecting ? 'active' : ''}`}
          disabled={loading}
        >
          {isSelecting ? 'Cancel Selection' : 'Select Area'}
        </button>
        
        {loading && <div className="loading-indicator">Analyzing...</div>}
      </div>

      <MapContainer
        center={[-3.4653, -62.2159]} // Amazon rainforest center
        zoom={10}
        style={{ height: '100%', width: '100%' }}
        ref={mapRef}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        />
        
        {/* Satellite imagery overlay */}
        <TileLayer
          url="https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
          attribution='&copy; <a href="https://www.esri.com/">Esri</a>'
          opacity={0.7}
        />

        <MapClickHandler />

        {/* Selection rectangle */}
        {selectedArea && selectedArea.start && selectedArea.current && (
          <Rectangle
            bounds={[selectedArea.start, selectedArea.current]}
            pathOptions={{ color: 'blue', fillOpacity: 0.1 }}
          />
        )}

        {/* Detection rectangles */}
        {renderDetections()}
      </MapContainer>
    </div>
  );
};

export default MapComponent;
