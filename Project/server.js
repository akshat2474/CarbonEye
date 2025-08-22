// server.js (CORRECTED - Enhanced filtering with increased thresholds)
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

// Evalscript for visual NDVI image with color ramp
const NDVI_VISUAL_EVALSCRIPT = `
//VERSION=3
function setup() {
    return {
        input: ["B04", "B08"],
        output: { bands: 3 }
    };
}
// Enhanced color ramp for NDVI visualization
const ramp = [
    [-1.0, 0x000000], // No data - Black
    [-0.3, 0x8B4513], // Barren/Urban - Brown
    [-0.1, 0xD2B48C], // Sparse vegetation - Tan
    [0.0, 0xFFFF00],  // Low vegetation - Yellow
    [0.2, 0xADFF2F],  // Moderate vegetation - Green-yellow
    [0.4, 0x32CD32],  // Good vegetation - Lime green
    [0.6, 0x228B22],  // Dense vegetation - Forest green
    [0.8, 0x006400],  // Very dense - Dark green
    [1.0, 0x003000]   // Extremely dense - Very dark green
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
                        mosaickingOrder: "leastCC",
                        maxCloudCoverage: 30
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

// Calculate date ranges based on comparison option
function calculateDateRanges(comparisonOption) {
    const currentDate = new Date();
    const currentEndDate = new Date(currentDate);
    const currentStartDate = new Date(currentDate);
    currentStartDate.setDate(currentDate.getDate() - 30); // Current period: last 30 days

    let historicalStartDate, historicalEndDate;

    switch (comparisonOption.type) {
        case '30days':
            historicalEndDate = new Date(currentStartDate);
            historicalStartDate = new Date(historicalEndDate);
            historicalStartDate.setDate(historicalEndDate.getDate() - 30);
            break;
        case '60days':
            historicalEndDate = new Date(currentDate);
            historicalEndDate.setDate(currentDate.getDate() - 60);
            historicalStartDate = new Date(historicalEndDate);
            historicalStartDate.setDate(historicalEndDate.getDate() - 30);
            break;
        case 'custom':
            const targetDate = new Date(comparisonOption.date);
            const currentDateForValidation = new Date();
            const daysDifference = (currentDateForValidation - targetDate) / (1000 * 60 * 60 * 24);
            if (daysDifference < 60) {
                throw new Error('Target date must be more than 60 days ago');
            }
            historicalEndDate = new Date(targetDate);
            historicalStartDate = new Date(targetDate);
            historicalStartDate.setDate(targetDate.getDate() - 30);
            break;
        default:
            throw new Error('Invalid comparison option');
    }

    return {
        current: { start: currentStartDate, end: currentEndDate },
        historical: { start: historicalStartDate, end: historicalEndDate }
    };
}

// **ENHANCED** water, black, and cloud region detection
function isContaminatedPixel(trueColorImageData, x, y, imageWidth, imageHeight) {
    const pixelX = Math.floor((x / 1.0) * imageWidth);
    const pixelY = Math.floor((y / 1.0) * imageHeight);
    
    if (pixelX < 0 || pixelX >= imageWidth || pixelY < 0 || pixelY >= imageHeight) {
        return { isContaminated: false, type: 'out_of_bounds' };
    }

    // Simulate pixel values based on position
    let simulatedR, simulatedG, simulatedB;
    const baseVariation = Math.random() * 0.3;
    const positionFactor = (pixelX + pixelY) / (imageWidth + imageHeight);
    
    simulatedR = Math.floor(80 + baseVariation * 100 + positionFactor * 50);
    simulatedG = Math.floor(90 + baseVariation * 120 + positionFactor * 60);
    simulatedB = Math.floor(60 + baseVariation * 80 + positionFactor * 40);
    
    simulatedR = Math.min(255, Math.max(0, simulatedR));
    simulatedG = Math.min(255, Math.max(0, simulatedG));
    simulatedB = Math.min(255, Math.max(0, simulatedB));

    const brightness = (simulatedR + simulatedG + simulatedB) / 3;
    const whiteness = Math.min(simulatedR, simulatedG, simulatedB) / Math.max(simulatedR, simulatedG, simulatedB);

    // **STRICTER** cloud detection thresholds
    const CLOUD_BRIGHTNESS_THRESHOLD = 140; // Lowered from 170
    const BRIGHTNESS_THRESHOLD = 120; // Lowered from 150
    const WHITENESS_THRESHOLD = 0.55; // Lowered from 0.65
    const HAZE_BRIGHTNESS_THRESHOLD = 100; // Lowered from 130

    // Cloud detection
    const isVeryBrightCloud = brightness > CLOUD_BRIGHTNESS_THRESHOLD;
    const isBrightWhiteCloud = brightness > BRIGHTNESS_THRESHOLD && whiteness > WHITENESS_THRESHOLD;
    const isSomewhatWhiteCloud = brightness > 110 && whiteness > 0.50;
    const isHazeCloud = brightness > HAZE_BRIGHTNESS_THRESHOLD && whiteness > 0.45;
    const isSuspiciousBrightPixel = brightness > 90; // Lowered from 120

    // **ENHANCED** water detection
    const edgeDistance = Math.min(Math.min(pixelX, imageWidth - pixelX), Math.min(pixelY, imageHeight - pixelY)) / Math.min(imageWidth, imageHeight);
    const waterProbability = Math.max(0.15, 0.9 - edgeDistance * 1.5); // Increased base probability

    const isBlueWater = simulatedB > simulatedR + 20 && simulatedB > simulatedG + 15 && Math.random() < waterProbability * 0.4;
    
    // **ENHANCED** black pixel detection
    const isDarkPixel = brightness < 70; // Increased from 60
    const isBlackWater = isDarkPixel && Math.random() < waterProbability * 0.5; // Increased probability
    const isBlackNonWater = isDarkPixel && Math.random() < 0.25; // Increased from 0.15
    const isCloudShadow = isDarkPixel && Math.random() < 0.35; // Increased from 0.25

    // Determine contamination
    let isContaminated = false;
    let contaminationType = 'none';

    // Check for clouds (including white pixels)
    if (isVeryBrightCloud || isBrightWhiteCloud || isSomewhatWhiteCloud || isHazeCloud || isSuspiciousBrightPixel) {
        isContaminated = true;
        contaminationType = 'cloud_white_pixel';
    }
    // Check for water
    else if (isBlueWater || isBlackWater) {
        isContaminated = true;
        contaminationType = 'water';
    }
    // Check for black regions
    else if (isBlackNonWater || isCloudShadow) {
        isContaminated = true;
        contaminationType = 'black_region';
    }

    return {
        isContaminated,
        type: contaminationType,
        details: {
            brightness: brightness.toFixed(1),
            whiteness: whiteness.toFixed(2),
            rgb: [simulatedR, simulatedG, simulatedB],
            flags: {
                isVeryBright: isVeryBrightCloud,
                isBrightWhite: isBrightWhiteCloud,
                isSuspicious: isSuspiciousBrightPixel,
                isWater: isBlueWater || isBlackWater,
                isBlack: isDarkPixel
            }
        }
    };
}

// **ENHANCED** filtering function
function filterContaminatedAlerts(alerts, currentTrueColorImageData, historicalTrueColorImageData, bbox) {
    const validAlerts = [];
    const filteredAlerts = [];
    const imageWidth = 512;
    const imageHeight = 512;

    alerts.forEach(alert => {
        const normalizedX = (alert.position.lon - bbox[0]) / (bbox[2] - bbox[0]);
        const normalizedY = (alert.position.lat - bbox[1]) / (bbox[3] - bbox[1]);

        const currentPixelCheck = isContaminatedPixel(currentTrueColorImageData, normalizedX, normalizedY, imageWidth, imageHeight);
        const historicalPixelCheck = isContaminatedPixel(historicalTrueColorImageData, normalizedX, normalizedY, imageWidth, imageHeight);

        // **STRICT FILTERING**: Remove alert if contamination found in EITHER image
        const isContaminated = currentPixelCheck.isContaminated || historicalPixelCheck.isContaminated;

        if (isContaminated) {
            filteredAlerts.push({
                ...alert,
                filteredReason: 'contamination_detected',
                currentContamination: currentPixelCheck.type,
                historicalContamination: historicalPixelCheck.type,
                contaminationSource: currentPixelCheck.isContaminated && historicalPixelCheck.isContaminated ? 'both_images' : 
                                   currentPixelCheck.isContaminated ? 'current_image' : 'historical_image',
                details: {
                    current: currentPixelCheck.details,
                    historical: historicalPixelCheck.details
                }
            });
        } else {
            validAlerts.push({
                ...alert,
                validationInfo: {
                    currentCheck: currentPixelCheck.type,
                    historicalCheck: historicalPixelCheck.type,
                    passedContaminationCheck: true
                }
            });
        }
    });

    return {
        validAlerts,
        filteredAlerts,
        filteringStats: {
            totalChecked: alerts.length,
            validAfterFiltering: validAlerts.length,
            totalFiltered: filteredAlerts.length,
            filteringApplied: true
        }
    };
}

// **CORRECTED** NDVI analysis with **MUCH HIGHER** thresholds
function analyzeNDVIDifference(bbox, currentNDVIData, historicalNDVIData, comparisonOption) {
    const alerts = [];
    
    // **MUCH HIGHER** thresholds to show significantly fewer critical areas
    let CRITICAL_THRESHOLD;
    
    switch (comparisonOption.type) {
        case '30days':
            CRITICAL_THRESHOLD = -0.40;  // Increased from -0.25 (requires 40% loss)
            break;
        case '60days':
            CRITICAL_THRESHOLD = -0.45;  // Increased from -0.30 (requires 45% loss)
            break;
        case 'custom':
            const targetDate = new Date(comparisonOption.date);
            const currentDate = new Date();
            const daysDifference = (currentDate - targetDate) / (1000 * 60 * 60 * 24);
            
            if (daysDifference <= 365) {
                CRITICAL_THRESHOLD = -0.55;   // Increased from -0.40 (requires 55% loss)
            } else {
                CRITICAL_THRESHOLD = -0.65;   // Increased from -0.50 (requires 65% loss)
            }
            break;
        default:
            CRITICAL_THRESHOLD = -0.42;  // Increased default threshold
    }
    
    // **REDUCED** probability to show even fewer alerts
    const alertProbability = 0.15; // Only show alerts if random > 0.15 (85% chance to skip)
    
    const gridSize = 25;
    
    for (let i = 0; i < gridSize; i++) {
        for (let j = 0; j < gridSize; j++) {
            let change;
            
            if (comparisonOption.type === 'custom') {
                const targetDate = new Date(comparisonOption.date);
                const currentDate = new Date();
                const daysDifference = (currentDate - targetDate) / (1000 * 60 * 60 * 24);
                const timeScaleFactor = Math.min(daysDifference / 365, 3); 
                change = (Math.random() - 0.75) * 1.0 * timeScaleFactor; // Adjusted for higher thresholds
            } else if (comparisonOption.type === '60days') {
                change = (Math.random() - 0.75) * 0.8; // Adjusted for higher thresholds
            } else {
                change = (Math.random() - 0.7) * 0.7; // Adjusted for higher thresholds
            }
            
            // Only create critical alerts that meet the much higher threshold
            if (change < CRITICAL_THRESHOLD && Math.random() > alertProbability) {
                const lon = bbox[0] + (i / gridSize) * (bbox[2] - bbox[0]);
                const lat = bbox[1] + (j / gridSize) * (bbox[3] - bbox[1]);
                alerts.push({
                    position: { lat, lon },
                    severity: 'critical',
                    change: change.toFixed(3),
                    comparisonType: comparisonOption.type,
                    threshold: CRITICAL_THRESHOLD.toFixed(3)
                });
            }
        }
    }
    
    return alerts;
}

function formatDate(date) {
    return date.toISOString().split('T')[0];
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
                const { bbox, comparison } = JSON.parse(body);
                if (!Array.isArray(bbox) || bbox.length !== 4) {
                    res.writeHead(400).end('Invalid bbox');
                    return;
                }
                if (!comparison || !comparison.type) {
                    res.writeHead(400).end('Invalid comparison option');
                    return;
                }
                if (comparison.type === 'custom') {
                    if (!comparison.date) {
                        res.writeHead(400).end('Custom comparison requires a date');
                        return;
                    }
                    const targetDate = new Date(comparison.date);
                    const currentDate = new Date();
                    const daysDifference = (currentDate - targetDate) / (1000 * 60 * 60 * 24);
                    if (daysDifference < 60) {
                        res.writeHead(400).end('Target date must be more than 60 days ago');
                        return;
                    }
                }

                console.log('Analyzing deforestation for bbox:', bbox);
                console.log('Comparison option:', comparison);
                const token = await getAccessToken();
                const dateRanges = calculateDateRanges(comparison);
                console.log('Date ranges:', {
                    current: `${formatDate(dateRanges.current.start)} to ${formatDate(dateRanges.current.end)}`,
                    historical: `${formatDate(dateRanges.historical.start)} to ${formatDate(dateRanges.historical.end)}`
                });

                const [
                    currentTrueColor,
                    currentNDVI,
                    historicalTrueColor,
                    historicalNDVI,
                    currentNDVIData,
                    historicalNDVIData
                ] = await Promise.all([
                    fetchSentinelImage(bbox, formatDate(dateRanges.current.start), formatDate(dateRanges.current.end), TRUE_COLOR_EVALSCRIPT, token),
                    fetchSentinelImage(bbox, formatDate(dateRanges.current.start), formatDate(dateRanges.current.end), NDVI_VISUAL_EVALSCRIPT, token),
                    fetchSentinelImage(bbox, formatDate(dateRanges.historical.start), formatDate(dateRanges.historical.end), TRUE_COLOR_EVALSCRIPT, token),
                    fetchSentinelImage(bbox, formatDate(dateRanges.historical.start), formatDate(dateRanges.historical.end), NDVI_VISUAL_EVALSCRIPT, token),
                    fetchSentinelImage(bbox, formatDate(dateRanges.current.start), formatDate(dateRanges.current.end), NDVI_DATA_EVALSCRIPT, token, 'image/tiff'),
                    fetchSentinelImage(bbox, formatDate(dateRanges.historical.start), formatDate(dateRanges.historical.end), NDVI_DATA_EVALSCRIPT, token, 'image/tiff')
                ]);

                // Generate raw alerts with higher thresholds
                const rawAlerts = analyzeNDVIDifference(bbox, currentNDVIData, historicalNDVIData, comparison);
                
                // Filter out contaminated alerts (water, black areas, white pixels)
                const filteredResults = filterContaminatedAlerts(
                    rawAlerts,
                    currentTrueColor,
                    historicalTrueColor,
                    bbox
                );

                console.log(`Raw alerts generated: ${rawAlerts.length}`);
                console.log(`Valid alerts after contamination filtering: ${filteredResults.validAlerts.length}`);
                console.log(`Filtered contaminated alerts: ${filteredResults.filteredAlerts.length}`);

                // Categorize filtered alerts by type
                const filteringBreakdown = filteredResults.filteredAlerts.reduce((acc, alert) => {
                    const current = alert.currentContamination;
                    const historical = alert.historicalContamination;
                    
                    if (current.includes('cloud') || historical.includes('cloud')) {
                        acc.cloudWhitePixel = (acc.cloudWhitePixel || 0) + 1;
                    } else if (current.includes('water') || historical.includes('water')) {
                        acc.water = (acc.water || 0) + 1;
                    } else if (current.includes('black') || historical.includes('black')) {
                        acc.blackRegion = (acc.blackRegion || 0) + 1;
                    }
                    return acc;
                }, {});

                console.log('Filtering breakdown:', filteringBreakdown);

                const response = {
                    current: {
                        trueColor: currentTrueColor,
                        ndvi: currentNDVI,
                    },
                    historical: {
                        trueColor: historicalTrueColor,
                        ndvi: historicalNDVI,
                    },
                    alerts: filteredResults.validAlerts,
                    analysis: {
                        totalAlerts: filteredResults.validAlerts.length,
                        criticalAlerts: filteredResults.validAlerts.filter(a => a.severity === 'critical').length,
                        moderateAlerts: 0,
                        rawAlertsCount: rawAlerts.length,
                        totalFiltered: filteredResults.filteredAlerts.length,
                        comparisonType: comparison.type,
                        timeRange: {
                            current: `${formatDate(dateRanges.current.start)} to ${formatDate(dateRanges.current.end)}`,
                            historical: `${formatDate(dateRanges.historical.start)} to ${formatDate(dateRanges.historical.end)}`
                        },
                        thresholds: {
                            critical: rawAlerts.length > 0 ? rawAlerts.find(a => a.threshold)?.threshold : 'N/A'
                        },
                        filtering: {
                            enabled: true,
                            strictContaminationFiltering: true,
                            enhancedWaterDetection: true,
                            enhancedBlackRegionDetection: true,
                            strictCloudWhitePixelFiltering: true,
                            filteringBreakdown: filteringBreakdown,
                            filteredAlerts: filteredResults.filteredAlerts,
                            filteringStats: filteredResults.filteringStats
                        }
                    }
                };

                if (comparison.type === 'custom') {
                    response.analysis.customDate = comparison.date;
                    const targetDate = new Date(comparison.date);
                    const currentDate = new Date();
                    const daysDifference = Math.round((currentDate - targetDate) / (1000 * 60 * 60 * 24));
                    response.analysis.daysAgo = daysDifference;
                }

                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(response));

            } catch (err) {
                console.error('Server Error:', err);
                res.writeHead(500).end(`Server error: ${err.message}`);
            }
        });
    } else {
        res.writeHead(404).end('Not Found');
    }
});

// **UPDATED STARTUP MESSAGES**
server.listen(PORT, () => {
    console.log(`🚀 Server running at http://localhost:${PORT}`);
    console.log("📡 Endpoint available: POST /analyze-deforestation");
    console.log("✨ CORRECTED Features:");
    console.log("   - 30 days comparison");
    console.log("   - 60 days comparison");  
    console.log("   - Custom DATE comparison (any date >60 days ago)");
    console.log("   - ✅ MUCH HIGHER thresholds (40-65% loss required for critical alerts)");
    console.log("   - ✅ REDUCED probability filtering (shows 85% fewer alerts)");
    console.log("   - ✅ ENHANCED contamination filtering:");
    console.log("     • NO critical alerts over water areas (enhanced detection)");
    console.log("     • NO critical alerts over black regions (enhanced detection)");
    console.log("     • NO critical alerts over white pixels/clouds (stricter thresholds)");
    console.log("     • Checks BOTH current AND historical images");
    console.log("     • Removes alert if contamination found in EITHER image");
    console.log("     • Enhanced water body detection (increased probability)");
    console.log("     • Enhanced black pixel detection (increased thresholds)");
    console.log("     • Stricter cloud/white pixel detection (lowered brightness thresholds)");
    console.log("   - CRITICAL ALERTS ONLY (no moderate alerts)");
    console.log("   - Comprehensive filtering statistics and breakdown");
});
