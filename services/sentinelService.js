const axios = require('axios');
const config = require('../config');

class SentinelService {
  constructor() {
    this.accessToken = null;
    this.tokenExpiry = null;
  }

  /**
   * Get OAuth access token for Sentinel Hub API
   */
  async getAccessToken() {
    if (this.accessToken && this.tokenExpiry && new Date() < this.tokenExpiry) {
      return this.accessToken;
    }

    try {
      const response = await axios.post(config.sentinelHub.tokenUrl, {
        grant_type: 'client_credentials',
        client_id: config.sentinelHub.clientId,
        client_secret: config.sentinelHub.clientSecret
      }, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      });

      this.accessToken = response.data.access_token;
      // Set expiry to 5 minutes before actual expiry
      this.tokenExpiry = new Date(Date.now() + (response.data.expires_in - 300) * 1000);
      
      return this.accessToken;
    } catch (error) {
      throw new Error(`Failed to get access token: ${error.message}`);
    }
  }

  /**
   * Search for available images using Catalog API
   * @param {Object} searchParams - Search parameters
   * @returns {Promise<Array>} Array of available images
   */
  async searchImages(searchParams) {
    const { bbox, dateFrom, dateTo, collection = 'sentinel-2-l2a', maxResults = 100 } = searchParams;
    
    try {
      const token = await this.getAccessToken();
      
      const requestBody = {
        bbox: bbox,
        datetime: `${dateFrom}/${dateTo}`,
        collections: [collection],
        limit: maxResults
      };

      const response = await axios.post(
        `${config.sentinelHub.baseUrl}/api/v1/catalog/1.0.0/search`,
        requestBody,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data.features || [];
    } catch (error) {
      throw new Error(`Failed to search images: ${error.message}`);
    }
  }

  /**
   * Get processed image using Process API
   * @param {Object} requestParams - Image request parameters
   * @returns {Promise<Buffer>} Image buffer
   */
  async getProcessedImage(requestParams) {
    const {
      bbox,
      datetime,
      width = 512,
      height = 512,
      format = 'image/png',
      collection = 'sentinel-2-l2a',
      evalscript = this.getDefaultEvalScript()
    } = requestParams;

    try {
      const token = await this.getAccessToken();
      
      const requestBody = {
        input: {
          bounds: {
            bbox: bbox,
            properties: {
              crs: "http://www.opengis.net/def/crs/EPSG/0/4326"
            }
          },
          data: [{
            dataFilter: {
              timeRange: {
                from: `${datetime}T00:00:00Z`,
                to: `${datetime}T23:59:59Z`
              }
            },
            type: collection
          }]
        },
        output: {
          width: width,
          height: height,
          responses: [{
            identifier: "default",
            format: {
              type: format
            }
          }]
        },
        evalscript: evalscript
      };

      const response = await axios.post(
        `${config.sentinelHub.baseUrl}/api/v1/process`,
        requestBody,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          responseType: 'arraybuffer'
        }
      );

      return Buffer.from(response.data);
    } catch (error) {
      throw new Error(`Failed to get processed image: ${error.message}`);
    }
  }

  /**
   * Get image using WCS service
   * @param {Object} wcsParams - WCS parameters
   * @returns {Promise<Buffer>} Image buffer
   */
  async getWCSImage(wcsParams) {
    const {
      bbox,
      time,
      layer,
      width = 512,
      height = 512,
      format = 'image/png'
    } = wcsParams;

    try {
      const url = `${config.sentinelHub.baseUrl}/ogc/wcs/${config.sentinelHub.instanceId}`;
      
      const params = {
        service: 'WCS',
        version: '1.1.2',
        request: 'GetCoverage',
        coverage: layer,
        bbox: bbox.join(','),
        time: time,
        width: width,
        height: height,
        format: format,
        crs: 'EPSG:4326'
      };

      const response = await axios.get(url, {
        params: params,
        responseType: 'arraybuffer'
      });

      return Buffer.from(response.data);
    } catch (error) {
      throw new Error(`Failed to get WCS image: ${error.message}`);
    }
  }

  /**
   * Default evalscript for true color images
   * @returns {string} Evalscript
   */
  getDefaultEvalScript() {
    return `
      //VERSION=3
      function setup() {
        return {
          input: ["B02", "B03", "B04"],
          output: { bands: 3 }
        };
      }
      
      function evaluatePixel(sample) {
        return [sample.B04, sample.B03, sample.B02];
      }
    `;
  }

  /**
   * Get NDVI evalscript
   * @returns {string} NDVI Evalscript
   */
  getNDVIEvalScript() {
    return `
      //VERSION=3
      function setup() {
        return {
          input: ["B04", "B08"],
          output: { bands: 3 }
        };
      }
      
      function evaluatePixel(sample) {
        let ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04);
        return colorBlend(ndvi, [-1, -0.5, 0, 0.5, 1], 
                         [[0.5, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0], [0, 0.5, 0]]);
      }
    `;
  }
}

module.exports = new SentinelService();
