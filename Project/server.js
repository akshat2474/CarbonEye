// server.js (with improved evalscripts for better visualization)
require('dotenv').config();
const http = require('http');
const https = require('https'); // FIX: Corrected typo from 'httpss' to 'https'

// Load environment variables
const PORT = process.env.PORT || 3000;
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;

// --- EVALSCRIPTS ---

// **FIXED** Evalscript for true-color (RGB) image.
// Replaced the 'LinearStretch' class with a manual function to avoid ReferenceError.
const TRUE_COLOR_EVALSCRIPT = `
  //VERSION=3
  function setup() {
    return {
      input: ["B04", "B03", "B02"],
      output: { bands: 3 }
    };
  }

  // Self-contained linear stretch function
  function linearStretch(value, min, max) {
      if (value < min) return 0;
      if (value > max) return 1;
      return (value - min) / (max - min);
  }

  function evaluatePixel(sample) {
      // Define the stretch range for visualization
      const min = 0.0;
      const max = 0.4;
      
      // Apply the stretch to each band
      let r = linearStretch(sample.B04, min, max);
      let g = linearStretch(sample.B03, min, max);
      let b = linearStretch(sample.B02, min, max);
      
      return [r, g, b];
  }
`;

// **IMPROVED** Evalscript for a visual NDVI image with a better color ramp
const NDVI_EVALSCRIPT = `
  //VERSION=3
  function setup() {
    return {
      input: ["B04", "B08"], // Red and Near-Infrared bands
      output: { bands: 3 }
    };
  }
  
  // A more detailed color ramp for better NDVI visualization
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
    // NDVI formula: (NIR - Red) / (NIR + Red)
    let ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04);
    // The visualizer will turn the NDVI value into a color from the detailed ramp
    return visualizer.process(ndvi);
  }
`;

// Enable CORS for browser access
function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

// Get access token from Sentinel Hub
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

// Fetch a Sentinel image as base64 using a provided evalscript
function fetchSentinelImage(bbox, fromDate, toDate, accessToken, mosaickingOrder, evalscript) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      input: {
        bounds: { bbox },
        data: [{
          type: 'sentinel-2-l2a',
          dataFilter: {
            timeRange: { from: `${fromDate}T00:00:00Z`, to: `${toDate}T23:59:59Z` },
            maxCloudCoverage: 100,
            mosaickingOrder: mosaickingOrder,
          },
        }],
      },
      output: {
        width: 512,
        height: 512,
        responses: [{ identifier: 'default', format: { type: 'image/png' } }],
      },
      evalscript: evalscript, // Use the provided evalscript
    });
    const options = {
      hostname: 'services.sentinel-hub.com',
      path: '/api/v1/process',
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    };
    const req = https.request(options, (res) => {
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => {
        const buffer = Buffer.concat(chunks);
        if (res.headers['content-type'] === 'application/json') {
          return reject(new Error(`Image fetch error from Sentinel Hub: ${buffer.toString()}`));
        }
        const base64 = `data:image/png;base64,${buffer.toString('base64')}`;
        resolve(base64);
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// Main HTTP server
const server = http.createServer(async (req, res) => {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204).end();
    return;
  }

  if (req.method === 'POST' && req.url === '/stream-image') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', async () => {
      try {
        const { bbox } = JSON.parse(body);
        if (!Array.isArray(bbox) || bbox.length !== 4) {
          res.writeHead(400).end('Invalid bbox');
          return;
        }

        const token = await getAccessToken();

        const toDate = new Date();
        const fromDateRecent = new Date(toDate);
        fromDateRecent.setDate(toDate.getDate() - 2);
        const fromDatePast = new Date(toDate);
        fromDatePast.setDate(toDate.getDate() - 17);
        const toDatePast = new Date(toDate);
        toDatePast.setDate(toDate.getDate() - 14);

        const formatDate = (date) => date.toISOString().split('T')[0];

        // Fetch all four images concurrently
        const [
          todayTrueColor,
          todayNDVI,
          pastTrueColor,
          pastNDVI,
        ] = await Promise.all([
          // "Today" images
          fetchSentinelImage(bbox, formatDate(fromDateRecent), formatDate(toDate), token, 'mostRecent', TRUE_COLOR_EVALSCRIPT),
          fetchSentinelImage(bbox, formatDate(fromDateRecent), formatDate(toDate), token, 'mostRecent', NDVI_EVALSCRIPT),
          // "Past" images
          fetchSentinelImage(bbox, formatDate(fromDatePast), formatDate(toDatePast), token, 'leastCC', TRUE_COLOR_EVALSCRIPT),
          fetchSentinelImage(bbox, formatDate(fromDatePast), formatDate(toDatePast), token, 'leastCC', NDVI_EVALSCRIPT),
        ]);

        // Structure the new response
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
});