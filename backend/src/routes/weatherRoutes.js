const express = require('express');
const router = express.Router();
const https = require('https');

// @desc Get real weather for latitude & longitude via Open-Meteo
// @route GET /api/weather?lat=...&lng=...
router.get('/', (req, res) => {
  const { lat, lng } = req.query;
  if (!lat || !lng) {
    return res.status(400).json({
      success: false,
      message: 'lat and lng parameters are required',
    });
  }

  const url = `https://api.open-meteo.com/v1/forecast?latitude=${encodeURIComponent(lat)}&longitude=${encodeURIComponent(lng)}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m`;

  https
    .get(url, (apiRes) => {
      let data = '';
      apiRes.on('data', (chunk) => {
        data += chunk;
      });
      apiRes.on('end', () => {
        try {
          const json = JSON.parse(data);
          return res.status(200).json({
            success: true,
            data: json,
          });
        } catch (e) {
          return res.status(502).json({
            success: false,
            message: 'Failed to parse weather provider response',
          });
        }
      });
    })
    .on('error', (err) => {
      return res.status(502).json({
        success: false,
        message: 'Weather service request failed: ' + err.message,
      });
    });
});

module.exports = router;
