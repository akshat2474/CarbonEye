const express = require('express');
const router = express.Router();
const imageController = require('../controllers/imageController');

/**
 * @route GET /api/images/search
 * @desc Search for available satellite images
 * @query {string} bbox - Bounding box (minX,minY,maxX,maxY)
 * @query {string} [dateFrom] - Start date (YYYY-MM-DD)
 * @query {string} [dateTo] - End date (YYYY-MM-DD)
 * @query {string} [collection=sentinel-2-l2a] - Data collection
 * @query {number} [maxResults=100] - Maximum number of results
 */
router.get('/search', imageController.searchImages);

/**
 * @route GET /api/images/process
 * @desc Get processed satellite image
 * @query {string} bbox - Bounding box (minX,minY,maxX,maxY)
 * @query {string} datetime - Date (YYYY-MM-DD)
 * @query {number} [width=512] - Image width
 * @query {number} [height=512] - Image height
 * @query {string} [format=image/png] - Image format
 * @query {string} [collection=sentinel-2-l2a] - Data collection
 * @query {string} [evalscript] - Custom evalscript
 */
router.get('/process', imageController.getProcessedImage);

/**
 * @route GET /api/images/ndvi
 * @desc Get NDVI processed image
 * @query {string} bbox - Bounding box (minX,minY,maxX,maxY)
 * @query {string} datetime - Date (YYYY-MM-DD)
 * @query {number} [width=512] - Image width
 * @query {number} [height=512] - Image height
 * @query {string} [format=image/png] - Image format
 * @query {string} [collection=sentinel-2-l2a] - Data collection
 */
router.get('/ndvi', imageController.getNDVIImage);

/**
 * @route GET /api/images/wcs
 * @desc Get image using WCS service
 * @query {string} bbox - Bounding box (minX,minY,maxX,maxY)
 * @query {string} time - Date (YYYY-MM-DD)
 * @query {string} layer - Layer name
 * @query {number} [width=512] - Image width
 * @query {number} [height=512] - Image height
 * @query {string} [format=image/png] - Image format
 */
router.get('/wcs', imageController.getWCSImage);

module.exports = router;
