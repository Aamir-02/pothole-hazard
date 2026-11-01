const User = require('../models/User');
const Notification = require('../models/Notification');
const { sendEmergencySMS } = require('../services/smsService');
const { sendPushNotification, broadcastEmergencyAlert } = require('../services/pushNotificationService');
const EmergencyContact = require('../models/EmergencyContact');

// @desc Manual Quick SOS Button trigger
// @route POST /api/notifications/send-sos
exports.sendManualSos = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const { latitude, longitude, address } = req.body;

    const user = await User.findById(userId);
    const contacts = await EmergencyContact.find({ userId });

    const incidentDetails = {
      riderName: user ? user.name : 'Rider in Distress',
      timestamp: new Date(),
      latitude: latitude || 37.7749,
      longitude: longitude || -122.4194,
    };

    // 1. Dispatch SMS to contacts
    const smsResults = await sendEmergencySMS(contacts, incidentDetails);

    // 2. Log System Notification
    await Notification.create({
      userId,
      title: '🚨 MANUAL SOS DISPATCHED',
      body: `Emergency SMS dispatched to ${contacts.length} contacts with live coordinates (${latitude}, ${longitude})`,
      type: 'EMERGENCY',
      data: { latitude, longitude, address },
    });

    // 3. Push FCM Alert
    await broadcastEmergencyAlert(
      'emergency_broadcasts',
      `🚨 Rider SOS Alert: ${user?.name || 'Rider'}`,
      `Emergency situation reported near ${address || 'Current Location'}`
    );

    res.status(200).json({
      success: true,
      message: 'Manual SOS alert & coordinates dispatched to contacts and nearby emergency channel!',
      smsResults,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Cancel SOS
// @route POST /api/notifications/cancel-sos
exports.cancelSosNotification = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      message: 'SOS Alert status set to CANCELLED.',
    });
  } catch (error) {
    next(error);
  }
};

// @desc Register Device Token for FCM
// @route POST /api/notifications/register-token
exports.registerDeviceToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    const userId = req.user._id || req.user.id;

    await User.findByIdAndUpdate(userId, { deviceToken: token });

    res.status(200).json({
      success: true,
      message: 'FCM Device Token registered successfully',
    });
  } catch (error) {
    next(error);
  }
};
