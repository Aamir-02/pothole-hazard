const admin = require('firebase-admin');

let firebaseApp = null;

try {
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL) {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      }),
    });
    console.log('[Firebase] Admin SDK initialized successfully');
  } else {
    console.log('[Firebase] Running in simulated mode (no credentials provided)');
  }
} catch (error) {
  console.warn('[Firebase Initialization Warning]', error.message);
}

module.exports = { admin, firebaseApp };
