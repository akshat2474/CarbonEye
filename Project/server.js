const CLIENT_ID = process.env.CLIENT_ID || 'a1420e11-f01e-4994-a21f-cff9498e40ac';
const CLIENT_SECRET = process.env.CLIENT_SECRET || 'h3aZm5UYPhAhySeOaD0qA1NmxGpJKFTx';
const PORT = process.env.PORT || 3000;

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const url = require('url');

// Create output directory if it doesn't exist
const outputDir = path.join(__dirname, 'output');
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// Create public directory if it doesn't exist
const publicDir = path.join(__dirname, 'public');
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
}

function getAccessToken(callback) {
  const postData = `grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}`;
  const options = {
    hostname: 'services.sentinel-hub.com',
    path: '/oauth/token',
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  const req = https.request(options, res => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      try {
        const json = JSON.parse(data);
        if (json.access_token) {
          callback(null, json.access_token);
        } else {
          callback(new Error('No access token received'), null);
        }
      } catch (err) {
        callback(err, null);
      }
    });
  });

  req.on('error', err => callback(err, null));
  req.write(postData);
  req.end();
}

function fetchSentinelImage(bbox, accessToken, res) {
  console.log('Fetching image for bbox:', bbox);
  const postData = JSON.stringify({
    input: {
      bounds: {
        bbox: [bbox.west, bbox.south, bbox.east, bbox.north],
        properties: { crs: "http://www.opengis.net/def/crs/EPSG/0/4326" }
      },
      data: [{
        type: "sentinel-2-l2a",
        dataFilter: {
          timeRange: {
            from: "2024-06-01T00:00:00Z",
            to: "2024-06-30T23:59:59Z"
          },
          maxCloudCoverage: 20
        }
      }]
    },
    output: {
      width: 512,
      height: 512,
      responses: [{
        identifier: "default",
        format: { type: "image/png" }
      }]
    },
    evalscript: `//VERSION=3
      function setup() {
        return {
          input: ["B04", "B03", "B02"],
          output: { bands: 3 }
        };
      }
      function evaluatePixel(sample) {
        return [sample.B04, sample.B03, sample.B02];
      }`
  });

  const options = {
    hostname: 'services.sentinel-hub.com',
    path: '/api/v1/process',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  const apiReq = https.request(options, apiRes => {
    if (apiRes.statusCode !== 200) {
      console.error('API Error:', apiRes.statusCode);
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Error fetching satellite image');
      return;
    }

    const filename = 'image_' + Date.now() + '.png';
    const filepath = path.join(outputDir, filename);
    const fileStream = fs.createWriteStream(filepath);
    
    res.writeHead(200, { 'Content-Type': 'image/png' });
    
    apiRes.pipe(fileStream);
    apiRes.pipe(res);
  });

  apiReq.on('error', err => {
    console.error('Request error:', err);
    res.writeHead(500, { 'Content-Type': 'text/plain' });
    res.end('Error making API request');
  });

  apiReq.write(postData);
  apiReq.end();
}

function serveStaticFile(req, res) {
  let pathname = url.parse(req.url).pathname;
  if (pathname === '/') pathname = '/index.html';
  
  const filePath = path.join(publicDir, pathname);
  
  console.log('Serving file:', filePath);

  fs.readFile(filePath, (err, data) => {
    if (err) {
      console.error('File not found:', filePath);
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end(`404 Not Found: ${pathname}`);
      return;
    }
    
    const ext = path.extname(filePath).toLowerCase();
    const contentType = {
      '.html': 'text/html',
      '.css': 'text/css',
      '.js': 'application/javascript',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.gif': 'image/gif'
    }[ext] || 'application/octet-stream';

    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

const server = http.createServer((req, res) => {
  // Enable CORS for all requests
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  console.log(`${req.method} ${req.url}`);

  if (req.method === 'POST' && req.url === '/get-image') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const bbox = JSON.parse(body);
        getAccessToken((err, token) => {
          if (err) {
            console.error('Auth error:', err);
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end('Authentication failed');
            return;
          }
          fetchSentinelImage(bbox, token, res);
        });
      } catch (err) {
        console.error('Parse error:', err);
        res.writeHead(400, { 'Content-Type': 'text/plain' });
        res.end('Invalid request body');
      }
    });
  } else {
    serveStaticFile(req, res);
  }
});

server.listen(PORT, () => {
  console.log(`🌍 Server running at http://localhost:${PORT}`);
  console.log(`📁 Serving files from: ${publicDir}`);
  console.log(`💾 Saving images to: ${outputDir}`);
});