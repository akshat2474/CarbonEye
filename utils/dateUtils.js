/**
 * Utility functions for date formatting and validation
 */

/**
 * Format date to ISO string for Sentinel Hub API
 * @param {Date|string} date - Date to format
 * @returns {string} ISO formatted date string
 */
function formatDateForAPI(date) {
  if (typeof date === 'string') {
    date = new Date(date);
  }
  return date.toISOString().split('T')[0];
}

/**
 * Create date range string for Sentinel Hub API
 * @param {Date|string} fromDate - Start date
 * @param {Date|string} toDate - End date
 * @returns {string} Date range in format "YYYY-MM-DD/YYYY-MM-DD"
 */
function createDateRange(fromDate, toDate) {
  const from = formatDateForAPI(fromDate);
  const to = formatDateForAPI(toDate);
  return `${from}/${to}`;
}

/**
 * Validate date range
 * @param {Date|string} fromDate - Start date
 * @param {Date|string} toDate - End date
 * @returns {boolean} True if valid range
 */
function isValidDateRange(fromDate, toDate) {
  const from = new Date(fromDate);
  const to = new Date(toDate);
  return from <= to && from <= new Date();
}

/**
 * Get date N days ago
 * @param {number} days - Number of days ago
 * @returns {Date} Date object
 */
function getDaysAgo(days) {
  const date = new Date();
  date.setDate(date.getDate() - days);
  return date;
}

module.exports = {
  formatDateForAPI,
  createDateRange,
  isValidDateRange,
  getDaysAgo
};
