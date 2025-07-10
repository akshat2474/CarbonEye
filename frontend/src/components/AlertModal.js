import React from 'react';

const AlertModal = ({ detection, onClose }) => {
  const exportData = () => {
    const exportObj = {
      alert_id: detection.id,
      timestamp: new Date().toISOString(),
      severity: detection.severity,
      confidence: detection.confidence,
      coordinates: detection.center_coordinates,
      bounding_box: detection.geographic_bbox,
      area_pixels: detection.area_pixels,
      ndvi_change: detection.avg_ndvi_change
    };

    const dataStr = JSON.stringify(exportObj, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    
    const link = document.createElement('a');
    link.href = url;
    link.download = `deforestation_alert_${detection.id}.json`;
    link.click();
    
    URL.revokeObjectURL(url);
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h3>🚨 Deforestation Alert #{detection.id}</h3>
          <button className="close-btn" onClick={onClose}>×</button>
        </div>

        <div className="modal-body">
          <div className="alert-summary">
            <div className={`severity-indicator ${detection.severity.toLowerCase()}`}>
              {detection.severity} Severity
            </div>
            <div className="confidence-score">
              {(detection.confidence * 100).toFixed(1)}% Confidence
            </div>
          </div>

          <div className="alert-details">
            <div className="detail-section">
              <h4>📍 Location</h4>
              <div className="coordinates-grid">
                <div>
                  <strong>Center:</strong><br />
                  {detection.center_coordinates.latitude.toFixed(6)}, 
                  {detection.center_coordinates.longitude.toFixed(6)}
                </div>
                <div>
                  <strong>Bounding Box:</strong><br />
                  N: {detection.geographic_bbox.max_lat.toFixed(6)}<br />
                  S: {detection.geographic_bbox.min_lat.toFixed(6)}<br />
                  E: {detection.geographic_bbox.max_lon.toFixed(6)}<br />
                  W: {detection.geographic_bbox.min_lon.toFixed(6)}
                </div>
              </div>
            </div>

            <div className="detail-section">
              <h4>📊 Analysis Data</h4>
              <div className="data-grid">
                <div className="data-item">
                  <span>Area Affected:</span>
                  <span>{detection.area_pixels} pixels</span>
                </div>
                <div className="data-item">
                  <span>NDVI Change:</span>
                  <span>{detection.avg_ndvi_change.toFixed(3)}</span>
                </div>
                <div className="data-item">
                  <span>Detection Time:</span>
                  <span>{new Date().toLocaleString()}</span>
                </div>
              </div>
            </div>

            <div className="detail-section">
              <h4>🎯 Recommended Actions</h4>
              <ul className="action-list">
                <li>Verify the area using high-resolution imagery</li>
                <li>Contact local authorities or conservation groups</li>
                <li>Monitor the area for continued changes</li>
                <li>Document evidence for reporting</li>
              </ul>
            </div>
          </div>
        </div>

        <div className="modal-footer">
          <button className="btn-secondary" onClick={exportData}>
            📥 Export Data
          </button>
          <button className="btn-primary" onClick={onClose}>
            Close
          </button>
        </div>
      </div>
    </div>
  );
};

export default AlertModal;
