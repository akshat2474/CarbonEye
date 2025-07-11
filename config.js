module.exports = {
  sentinelHub: {
    baseUrl: 'https://services.sentinel-hub.com',
    instanceId: process.env.SENTINEL_HUB_INSTANCE_ID,
    clientId: process.env.SENTINEL_HUB_CLIENT_ID,
    clientSecret: process.env.SENTINEL_HUB_CLIENT_SECRET,
    tokenUrl: 'https://services.sentinel-hub.com/oauth/token'
  },
  server: {
    port: process.env.PORT || 3000,
    host: process.env.HOST || 'localhost'
  },
  api: {
    version: 'v1',
    prefix: '/api'
  }
};
