const twilio = require('twilio');

let twilioClient = null;
if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && !process.env.TWILIO_ACCOUNT_SID.includes('mock')) {
  try {
    twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
  } catch (e) {
    console.warn('[SMS Service] Failed to initialize Twilio client:', e.message);
  }
}

/**
 * Send Emergency Alert SMS to contact numbers
 * @param {Array} contacts - Array of emergency contacts [{ name, phone }]
 * @param {Object} incidentDetails - { riderName, timestamp, latitude, longitude }
 */
const sendEmergencySMS = async (contacts, incidentDetails) => {
  const { riderName, timestamp, latitude, longitude } = incidentDetails;
  const mapsUrl = `https://maps.google.com/?q=${latitude},${longitude}`;
  const timeFormatted = new Date(timestamp || Date.now()).toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  });

  const smsMessage = `🚨 EMERGENCY ALERT 🚨\n\nPossible motorcycle accident detected.\n\nRider:\n${riderName}\n\nTime:\n${timeFormatted}\n\nLocation:\n${mapsUrl}\n\nPlease check immediately.`;

  const results = [];

  for (const contact of contacts) {
    if (!contact.phone) continue;
    try {
      if (twilioClient) {
        const msg = await twilioClient.messages.create({
          body: smsMessage,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: contact.phone,
        });
        results.push({ phone: contact.phone, status: 'SENT', sid: msg.sid });
      } else {
        console.log(`[Simulated SMS Sent to ${contact.name} (${contact.phone})]:\n${smsMessage}\n---`);
        results.push({ phone: contact.phone, status: 'SIMULATED_SENT' });
      }
    } catch (err) {
      console.error(`[SMS Error for ${contact.phone}]:`, err.message);
      results.push({ phone: contact.phone, status: 'FAILED', error: err.message });
    }
  }

  return results;
};

module.exports = {
  sendEmergencySMS,
};
