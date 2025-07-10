import React, { useState } from 'react';
import MapComponent from './components/MapComponent';
import AnalysisPanel from './components/AnalysisPanel';
import AlertModal from './components/AlertModal';
import './App.css';

function App() {
  const [analysisResults, setAnalysisResults] = useState(null);
  const [selectedDetection, setSelectedDetection] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleAnalysis = async (bbox, daysBack = 10) => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch('http://localhost:8000/analyze', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          bbox_coordinates: bbox,
          days_back: daysBack,
          resolution: 60
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setAnalysisResults(data);
      
    } catch (err) {
      setError(err.message);
      console.error('Analysis error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="app-header">
        <h1>🌱 Carbon Eye</h1>
        <p>Real-time deforestation detection</p>
      </header>
      
      <div className="app-content">
        <div className="map-container">
          <MapComponent
            onAnalysis={handleAnalysis}
            analysisResults={analysisResults}
            onDetectionClick={setSelectedDetection}
            loading={loading}
          />
        </div>
        
        <div className="panel-container">
          <AnalysisPanel
            results={analysisResults}
            loading={loading}
            error={error}
            onDetectionSelect={setSelectedDetection}
          />
        </div>
      </div>

      {selectedDetection && (
        <AlertModal
          detection={selectedDetection}
          onClose={() => setSelectedDetection(null)}
        />
      )}
    </div>
  );
}

export default App;
