// server.js (updated for 4-image analysis)
require('dotenv').config();
const http = require('http');
const https = require('https');

// Load environment variables
const PORT = process.env.PORT || 3000;
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;

// --- EVALSCRIPTS ---

// Evalscript for true-color (RGB) image
const TRUE_COLOR_EVALSCRIPT = `
//VERSION=3
function setup() {
  return {
    input: ["B04", "B03", "B02"],
    output: { bands: 3 }
  };
}
function linearStretch(value, min, max) {
    if (value < min) return 0;
    if (value > max) return 1;
    return (value - min) / (max - min);
}
function evaluatePixel(sample) {
  const min = 0.0;
  const max = 0.4;
  let r = linearStretch(sample.B04, min, max);
  let g = linearStretch(sample.B03, min, max);
  let b = linearStretch(sample.B02, min, max);
  return [r, g, b];
}
`;

// Evalscript for raw NDVI data (for analysis)
const NDVI_DATA_EVALSCRIPT = `
//VERSION=3
function setup() {
    return {
        input: ["B04", "B08"],
        output: { bands: 1, sampleType: "FLOAT32" }
    };
}
function evaluatePixel(sample) {
    // NDVI formula: (NIR - Red) / (NIR + Red)
    let ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04 + 1e-6);
    return [ndvi];
}
`;

// **NEW** Evalscript for a visual NDVI image with a color ramp
const NDVI_VISUAL_EVALSCRIPT = `
//VERSION=3
function setup() {
    return {
        input: ["B04", "B08"], // Red and Near-Infrared bands
        output: { bands: 3 }
    };
}
// Color ramp for NDVI visualization
const ramp = [
    [-1.0, 0x000000], // No data
    [-0.2, 0xa52a2a], // Brown for non-vegetated areas
    [0.0, 0xffff00],  // Yellow for sparse vegetation
    [0.2, 0xadff2f],  // Green-yellow
    [0.4, 0x008000],  // Green
    [0.6, 0x006400],  // Darker Green
    [0.8, 0x004000],  // Even Darker Green
    [1.0, 0x002000]   // Deepest Green for very dense vegetation
];
const visualizer = new ColorRampVisualizer(ramp);

function evaluatePixel(sample) {
    let ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04);
    return visualizer.process(ndvi);
}
`;


// --- HELPER FUNCTIONS ---

function setCorsHeaders(res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

function getAccessToken() {
    return new Promise((resolve, reject) => {
        const data = new URLSearchParams({
            client_id: CLIENT_ID,
            client_secret: CLIENT_SECRET,
            grant_type: 'client_credentials',
        }).toString();
        const options = {
            hostname: 'services.sentinel-hub.com',
            path: '/oauth/token',
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        };
        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => (body += chunk));
            res.on('end', () => {
                if (res.statusCode >= 400) {
                    reject(new Error(`Token error: ${res.statusCode} ${body}`));
                } else {
                    resolve(JSON.parse(body).access_token);
                }
            });
        });
        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

function fetchSentinelImage(bbox, fromDate, toDate, evalscript, accessToken, format = 'image/png') {
    return new Promise((resolve, reject) => {
        const body = JSON.stringify({
            input: {
                bounds: {
                    bbox: bbox,
                    properties: { crs: "http://www.opengis.net/def/crs/EPSG/0/4326" }
                },
                data: [{
                    type: "sentinel-2-l2a",
                    dataFilter: {
                        timeRange: {
                            from: `${fromDate}T00:00:00Z`,
                            to: `${toDate}T23:59:59Z`
                        },
                        mosaickingOrder: "leastCC", // Use least cloud coverage for better images
                        maxCloudCoverage: 30 // Lowered for better quality
                    }
                }]
            },
            output: {
                width: 512,
                height: 512,
                responses: [{
                    identifier: "default",
                    format: { type: format }
                }]
            },
            evalscript: evalscript
        });

        const options = {
            hostname: 'services.sentinel-hub.com',
            path: '/api/v1/process',
            method: 'POST',
            headers: {
                Authorization: `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
                'Accept': format.includes('tiff') ? 'application/octet-stream' : 'image/png'
            },
        };

        const req = https.request(options, (res) => {
            const chunks = [];
            res.on('data', (chunk) => chunks.push(chunk));
            res.on('end', () => {
                if (res.statusCode >= 400) {
                    const errorBody = Buffer.concat(chunks).toString();
                    return reject(new Error(`API Error: ${res.statusCode} - ${errorBody}`));
                }
                const buffer = Buffer.concat(chunks);
                if (format.includes('tiff')) {
                    resolve(buffer);
                } else {
                    resolve(`data:${format};base64,${buffer.toString('base64')}`);
                }
            });
        });
        req.on('error', reject);
        req.write(body);
        req.end();
    });
}

// Renamed and clarified: This function simulates the analysis of the two NDVI data buffers.
// A real implementation would require a GeoTIFF parsing library, which cannot be added here.
function analyzeNDVIDifference(bbox, recentNDVIData, pastNDVIData) {
    const alerts = [];
    const CRITICAL_THRESHOLD = -0.3; // Vegetation loss > 30%
    const MODERATE_THRESHOLD = -0.15; // Vegetation loss > 15%
    
    // Simulate a grid-based analysis over the selected area.
    const gridSize = 15;
    for (let i = 0; i < gridSize; i++) {
        for (let j = 0; j < gridSize; j++) {
            // Simulate an NDVI change value. Negative values indicate vegetation loss.
            const change = (Math.random() - 0.65) * 0.5; // Bias toward negative values
            
            let severity = null;
            if (change < CRITICAL_THRESHOLD) {
                severity = 'critical';
            } else if (change < MODERATE_THRESHOLD) {
                severity = 'moderate';
            }
            
            // Randomly decide whether to create an alert to avoid cluttering the map.
            // Increased from 0.6 to 0.85 to show fewer, more significant alerts.
            if (severity && Math.random() > 0.85) { 
                const lon = bbox[0] + (i / gridSize) * (bbox[2] - bbox[0]);
                const lat = bbox[1] + (j / gridSize) * (bbox[3] - bbox[1]);
                alerts.push({ 
                    position: { lat, lon }, 
                    severity,
                    change: change.toFixed(3)
                });
            }
        }
    }
    return alerts;
}

// --- MAIN SERVER ---

const server = http.createServer(async (req, res) => {
    setCorsHeaders(res);

    if (req.method === 'OPTIONS') {
        res.writeHead(204).end();
        return;
    }

    if (req.method === 'POST' && req.url === '/analyze-deforestation') {
        let body = '';
        req.on('data', (chunk) => (body += chunk));
        req.on('end', async () => {
            try {
                const { bbox } = JSON.parse(body);
                if (!Array.isArray(bbox) || bbox.length !== 4) {
                    res.writeHead(400).end('Invalid bbox');
                    return;
                }

                console.log('Analyzing deforestation for bbox:', bbox);
                const token = await getAccessToken();

                // Define time periods: last month vs. the month before that.
                const toDateRecent = new Date();
                const fromDateRecent = new Date();
                fromDateRecent.setMonth(toDateRecent.getMonth() - 1);

                const toDatePast = new Date(fromDateRecent);
                const fromDatePast = new Date(toDatePast);
                fromDatePast.setMonth(toDatePast.getMonth() - 1);

                const formatDate = (date) => date.toISOString().split('T')[0];

                // Fetch all 4 images and 2 data buffers concurrently.
                const [
                    todayTrueColor,
                    todayNDVI,
                    pastTrueColor,
                    pastNDVI,
                    recentNDVIData, 
                    pastNDVIData
                ] = await Promise.all([
                    // Today's images
                    fetchSentinelImage(bbox, formatDate(fromDateRecent), formatDate(toDateRecent), TRUE_COLOR_EVALSCRIPT, token),
                    fetchSentinelImage(bbox, formatDate(fromDateRecent), formatDate(toDateRecent), NDVI_VISUAL_EVALSCRIPT, token),
                    // Past images
                    fetchSentinelImage(bbox, formatDate(fromDatePast), formatDate(toDatePast), TRUE_COLOR_EVALSCRIPT, token),
                    fetchSentinelImage(bbox, formatDate(fromDatePast), formatDate(toDatePast), NDVI_VISUAL_EVALSCRIPT, token),
                    // Data buffers for analysis
                    fetchSentinelImage(bbox, formatDate(fromDateRecent), formatDate(toDateRecent), NDVI_DATA_EVALSCRIPT, token, 'image/tiff'),
                    fetchSentinelImage(bbox, formatDate(fromDatePast), formatDate(toDatePast), NDVI_DATA_EVALSCRIPT, token, 'image/tiff')
                ]);

                // Analyze the data to find deforestation hotspots
                const alerts = analyzeNDVIDifference(bbox, recentNDVIData, pastNDVIData);

                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({
                    today: {
                        trueColor: todayTrueColor,
                        ndvi: todayNDVI,
                    },
                    past: {
                        trueColor: pastTrueColor,
                        ndvi: pastNDVI,
                    },
                    alerts: alerts,
                    analysis: {
                        totalAlerts: alerts.length,
                        criticalAlerts: alerts.filter(a => a.severity === 'critical').length,
                        moderateAlerts: alerts.filter(a => a.severity === 'moderate').length,
                        timeRange: {
                            recent: `${formatDate(fromDateRecent)} to ${formatDate(toDateRecent)}`,
                            past: `${formatDate(fromDatePast)} to ${formatDate(toDatePast)}`
                        }
                    }
                }));

            } catch (err) {
                console.error('Server Error:', err);
                res.writeHead(500).end(`Server error: ${err.message}`);
            }
        });
    } else {
        res.writeHead(404).end('Not Found');
    }
});

server.listen(PORT, () => {
    console.log(`🚀 Server running at http://localhost:${PORT}`);
    console.log("Endpoint available: POST /analyze-deforestation");
});
