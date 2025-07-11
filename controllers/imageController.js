const sentinelService = require('../services/sentinelService');
const { createDateRange, isValidDateRange, getDaysAgo } = require('../utils/dateUtils');

class ImageController {
  /**
   * Search for available images
   */
  async searchImages(req, res) {
    try {
      const {
        bbox,
        dateFrom,
        dateTo,
        collection = 'sentinel-2-l2a',
        maxResults = 100
      } = req.query;

      // Validate required parameters
      if (!bbox) {
        return res.status(400).json({
          error: 'Missing required parameter: bbox',
          message: 'Bounding box must be provided as "minX,minY,maxX,maxY"'
        });
      }

      // Parse bbox
      const bboxArray = bbox.split(',').map(Number);
      if (bboxArray.length !== 4 || bboxArray.some(isNaN)) {
        return res.status(400).json({
          error: 'Invalid bbox format',
          message: 'Bounding box must be "minX,minY,maxX,maxY" with numeric values'
        });
      }

      // Set default date range if not provided
      const fromDate = dateFrom || getDaysAgo(30).toISOString().split('T')[0];
      const toDate = dateTo || new Date().toISOString().split('T')[0];

      // Validate date range
      if (!isValidDateRange(fromDate, toDate)) {
        return res.status(400).json({
          error: 'Invalid date range',
          message: 'From date must be before to date and not in the future'
        });
      }

      const searchParams = {
        bbox: bboxArray,
        dateFrom: fromDate,
        dateTo: toDate,
        collection,
        maxResults: parseInt(maxResults)
      };

      const images = await sentinelService.searchImages(searchParams);

      res.json({
        success: true,
        count: images.length,
        searchParams,
        images: images.map(image => ({
          id: image.id,
          datetime: image.properties.datetime,
          cloudCover: image.properties['eo:cloud_cover'],
          geometry: image.geometry,
          assets: Object.keys(image.assets || {})
        }))
      });

    } catch (error) {
      console.error('Search images error:', error);
      res.status(500).json({
        error: 'Failed to search images',
        message: error.message
      });
    }
  }

  /**
   * Get processed image
   */
  async getProcessedImage(req, res) {
    try {
      const {
        bbox,
        datetime,
        width = 512,
        height = 512,
        format = 'image/png',
        collection = 'sentinel-2-l2a',
        evalscript
      } = req.query;

      // Validate required parameters
      if (!bbox || !datetime) {
        return res.status(400).json({
          error: 'Missing required parameters',
          message: 'Both bbox and datetime are required'
        });
      }

      // Parse bbox
      const bboxArray = bbox.split(',').map(Number);
      if (bboxArray.length !== 4 || bboxArray.some(isNaN)) {
        return res.status(400).json({
          error: 'Invalid bbox format',
          message: 'Bounding box must be "minX,minY,maxX,maxY" with numeric values'
        });
      }

      const requestParams = {
        bbox: bboxArray,
        datetime,
        width: parseInt(width),
        height: parseInt(height),
        format,
        collection,
        evalscript: evalscript || sentinelService.getDefaultEvalScript()
      };

      const imageBuffer = await sentinelService.getProcessedImage(requestParams);

      // Set appropriate content type
      const contentType = format === 'image/jpeg' ? 'image/jpeg' : 'image/png';
      
      res.set({
        'Content-Type': contentType,
        'Content-Length': imageBuffer.length,
        'Cache-Control': 'public, max-age=3600'
      });

      res.send(imageBuffer);

    } catch (error) {
      console.error('Get processed image error:', error);
      res.status(500).json({
        error: 'Failed to get processed image',
        message: error.message
      });
    }
  }

  /**
   * Get NDVI image
   */
  async getNDVIImage(req, res) {
    try {
      const {
        bbox,
        datetime,
        width = 512,
        height = 512,
        format = 'image/png',
        collection = 'sentinel-2-l2a'
      } = req.query;

      if (!bbox || !datetime) {
        return res.status(400).json({
          error: 'Missing required parameters',
          message: 'Both bbox and datetime are required'
        });
      }

      const bboxArray = bbox.split(',').map(Number);
      if (bboxArray.length !== 4 || bboxArray.some(isNaN)) {
        return res.status(400).json({
          error: 'Invalid bbox format',
          message: 'Bounding box must be "minX,minY,maxX,maxY" with numeric values'
        });
      }

      const requestParams = {
        bbox: bboxArray,
        datetime,
        width: parseInt(width),
        height: parseInt(height),
        format,
        collection,
        evalscript: sentinelService.getNDVIEvalScript()
      };

      const imageBuffer = await sentinelService.getProcessedImage(requestParams);

      const contentType = format === 'image/jpeg' ? 'image/jpeg' : 'image/png';
      
      res.set({
        'Content-Type': contentType,
        'Content-Length': imageBuffer.length,
        'Cache-Control': 'public, max-age=3600'
      });

      res.send(imageBuffer);

    } catch (error) {
      console.error('Get NDVI image error:', error);
      res.status(500).json({
        error: 'Failed to get NDVI image',
        message: error.message
      });
    }
  }

  /**
   * Get image using WCS service
   */
  async getWCSImage(req, res) {
    try {
      const {
        bbox,
        time,
        layer,
        width = 512,
        height = 512,
        format = 'image/png'
      } = req.query;

      if (!bbox || !time || !layer) {
        return res.status(400).json({
          error: 'Missing required parameters',
          message: 'bbox, time, and layer are required'
        });
      }

      const bboxArray = bbox.split(',').map(Number);
      if (bboxArray.length !== 4 || bboxArray.some(isNaN)) {
        return res.status(400).json({
          error: 'Invalid bbox format',
          message: 'Bounding box must be "minX,minY,maxX,maxY" with numeric values'
        });
      }

      const wcsParams = {
        bbox: bboxArray,
        time,
        layer,
        width: parseInt(width),
        height: parseInt(height),
        format
      };

      const imageBuffer = await sentinelService.getWCSImage(wcsParams);

      const contentType = format === 'image/jpeg' ? 'image/jpeg' : 'image/png';
      
      res.set({
        'Content-Type': contentType,
        'Content-Length': imageBuffer.length,
        'Cache-Control': 'public, max-age=3600'
      });

      res.send(imageBuffer);

    } catch (error) {
      console.error('Get WCS image error:', error);
      res.status(500).json({
        error: 'Failed to get WCS image',
        message: error.message
      });
    }
  }
}

module.exports = new ImageController();
