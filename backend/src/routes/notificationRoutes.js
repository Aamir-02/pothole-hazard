const express = require('express');
const router = express.Router();
const {
  sendManualSos,
  cancelSosNotification,
  registerDeviceToken,
} = require('../controllers/notificationController');
const { protect } = require('../middleware/auth');

router.post('/send-sos', protect, sendManualSos);
router.post('/cancel-sos', protect, cancelSosNotification);
router.post('/register-token', protect, registerDeviceToken);

module.exports = router;
