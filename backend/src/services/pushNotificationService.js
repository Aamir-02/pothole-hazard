const { firebaseApp } = require('../config/firebase');
const admin = require('firebase-admin');

/**
 * Send push notification to target FCM tokens or topic
 * @param {string|Array<string>} tokens - FCM device token(s)
 * @param {Object} notificationPayload - { title, body, data }
 */
const sendPushNotification = async (tokens, notificationPayload) => {
  const { title, body, data = {} } = notificationPayload;

  if (!tokens || (Array.isArray(tokens) && tokens.length === 0)) {
    return { success: false, message: 'No valid device tokens provided' };
  }

  const tokenList = Array.isArray(tokens) ? tokens : [tokens];

  try {
    if (firebaseApp) {
      const message = {
        notification: { title, body },
        data: { ...data, timestamp: new Date().toISOString() },
        tokens: tokenList,
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(`[FCM Push Sent] Success: ${response.successCount}, Failures: ${response.failureCount}`);
      return { success: true, successCount: response.successCount, failureCount: response.failureCount };
    } else {
      console.log(`[Simulated FCM Push Notification] Title: "${title}" | Body: "${body}" | Tokens: ${tokenList.length}`);
      return { success: true, simulated: true };
    }
  } catch (error) {
    console.error('[Push Notification Error]', error.message);
    return { success: false, error: error.message };
  }
};

/**
 * Broadcast emergency SOS to nearby riders or system topic
 */
const broadcastEmergencyAlert = async (topic, title, body, data) => {
  try {
    if (firebaseApp) {
      await admin.messaging().send({
        topic: topic || 'emergency_broadcasts',
        notification: { title, body },
        data,
      });
      console.log(`[FCM Topic Broadcast] Topic: ${topic}`);
    } else {
      console.log(`[Simulated FCM Topic Broadcast] Topic: ${topic} | Title: "${title}"`);
    }
  } catch (error) {
    console.error('[FCM Topic Broadcast Error]', error.message);
  }
};

module.exports = {
  sendPushNotification,
  broadcastEmergencyAlert,
};
