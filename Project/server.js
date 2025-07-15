// server.js (Now with True-Color and NDVI Image Support)
require('dotenv').config();
const http = require('http');
const https = require('https');

// Load environment variables
const PORT = process.env.PORT || 3000;
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;

// --- EVALSCRIPTS ---

// Evalscript for a standard true-color (RGB) image
const TRUE_COLOR_EVALSCRIPT = `
  //VERSION=3
  function setup() {
    return {
      input: ["B04", "B03", "B02"],
      output: { bands: 3 }
    };
  }
  function evaluatePixel(sample) {
    return [2.5 * sample.B04, 2.5 * sample.B03, 2.5 * sample.B02];
  }
`;

// Evalscript for a visual NDVI (Normalized Difference Vegetation Index) image
const NDVI_EVALSCRIPT = `
  //VERSION=3
  function setup() {
    return {
      input: ["B04", "B08"], // Red and Near-Infrared bands
      output: { bands: 3 }
    };
  }
  
  // Color ramp for visualization of NDVI values
  const ramp = [
    [0.0, 0x000000], // No data
    [0.01, 0x8B4513], // Brown for no vegetation
    [0.1, 0xFFE4B5], // Light yellow for sparse vegetation
    [0.25, 0x32CD32], // Lime green for moderate vegetation
    [0.5, 0x006400], // Dark green for dense vegetation
    [1.0, 0x006400]
  ];

  const visualizer = new ColorRampVisualizer(ramp);

  function evaluatePixel(sample) {
    // NDVI formula: (NIR - Red) / (NIR + Red)
    let ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04);
    // The visualizer will turn the NDVI value into a color
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