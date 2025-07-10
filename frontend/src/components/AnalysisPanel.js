import React from 'react';

const AnalysisPanel = ({ results, loading, error, onDetectionSelect }) => {
  if (loading) {
    return (
      <div className="analysis-panel">
        <div className="loading-state">
          <div className="spinner"></div>
          <p>Analyzing satellite imagery...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="analysis-panel">
        <div className="error-state">
          <h3>❌ Analysis Error</h3>
          <p>{error}</p>
        </div>
      </div>
    );
  }

  if (!results) {
    return (
      <div className="analysis-panel">
        <div className="empty-state">
          <h3>🌱 Carbon Eye</h3>
          <p>Select an area on the map to analyze deforestation</p>
          <div className="instructions">
            <ol>
              <li>Click "Select Area" button</li>
              <li>Click and drag on the map</li>
              <li>Right-click to confirm selection</li>
              <li>Wait for analysis results</li>
            </ol>
          </div>
        </div>
      </div>
    );
  }

  const { detections, summary } = results;

  return (
    <div className="analysis-panel">
      <div className="panel-header">
        <h3>📊 Analysis Results</h3>
        <div className="timestamp">
          {new Date(results.timestamp).toLocaleString()}
        </div>
      </div>

      <div className="summary-section">
        <div className="summary-card">
          <div className="summary-item">
            <span className="label">Total Detections:</span>
            <span className="value">{summary.total_detections}</span>
          </div>
          <div className="summary-item">
            <span className="label">Change Percentage:</span>
            <span className="value">{summary.change_percentage}%</span>
          </div>
          <div className="summary-item">
            <span className="label">High Confidence:</span>
            <span className="value">{summary.high_confidence_detections}</span>
          </div>
        </div>
      </div>

      {detections.length > 0 ? (
        <div className="detections-section">
          <h4>🚨 Deforestation Alerts</h4>
          <div className="detections-list">
            {detections.map((detection) => (
              <div
                key={detection.id}
                className={`detection-item severity-${detection.severity.toLowerCase()}`}
                onClick={() => onDetectionSelect(detection)}
              >
                <div className="detection-header">
                  <span className="detection-id">#{detection.id}</span>
                  <span className={`severity-badge ${detection.severity.toLowerCase()}`}>
                    {detection.severity}
                  </span>
                </div>
                
                <div className="detection-details">
                  <div className="detail-row">
                    <span>Confidence:</span>
                    <span>{(detection.confidence * 100).toFixed(1)}%</span>
                  </div>
                  <div className="detail-row">
                    <span>Area:</span>
                    <span>{detection.area_pixels} pixels</span>
                  </div>
                  <div className="detail-row">
                    <span>NDVI Change:</span>
                    <span>{detection.avg_ndvi_change.toFixed(3)}</span>
                  </div>
                </div>
                
                <div className="coordinates">
                  📍 {detection.center_coordinates.latitude.toFixed(4)}, 
                  {detection.center_coordinates.longitude.toFixed(4)}
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="no-detections">
          <h4>✅ No Deforestation Detected</h4>
          <p>The analyzed area shows no significant vegetation loss in the specified time period.</p>
        </div>
      )}
    </div>
  );
};

export default AnalysisPanel;
