const express = require('express');
const router = express.Router();
const { startRide, stopRide, getRideHistory } = require('../controllers/rideController');
const { protect } = require('../middleware/auth');

router.post('/start', protect, startRide);
router.post('/stop', protect, stopRide);
router.get('/history', protect, getRideHistory);

module.exports = router;
