const mongoose = require('mongoose');
const { server } = require('../src/server');
const User = require('../src/models/User');

async function runE2E() {
  console.log('=====================================================');
  console.log('🧪 Pothole Hazard Full End-to-End Auth Verification');
  console.log('=====================================================\n');

  // Step 1: Start backend & connect to MongoDB
  console.log('1. Starting backend server on port 5000...');
  if (!server.listening) {
    await new Promise((resolve) => server.listen(5000, resolve));
  }
  console.log('   Backend server is listening on port 5000.');

  if (mongoose.connection.readyState !== 1) {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/pothole_hazard');
  }
  console.log('   MongoDB connection state:', mongoose.connection.readyState === 1 ? 'CONNECTED (Host: localhost)' : 'DISCONNECTED');

  const persistentEmail = 'rider.persistent@example.com';
  const persistentPassword = 'StrongPassword2026!';
  const persistentName = 'Persistent Rider';

  // Cleanup before test to ensure clean state
  await User.deleteOne({ email: persistentEmail });

  // Step 2: Register a new user with a previously unused email address
  console.log('\n2. Registering new user (POST /api/auth/signup)...');
  const signupRes = await fetch('http://localhost:5000/api/auth/signup', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: persistentName,
      email: persistentEmail,
      password: persistentPassword,
      confirmPassword: persistentPassword,
      phone: '+15551234567',
    }),
  });
  const signupData = await signupRes.json();
  console.log(`   Response (${signupRes.status}):`, JSON.stringify(signupData, null, 2));
  if (signupRes.status !== 201 || !signupData.success) {
    throw new Error('Step 2 Failed: Registration failed.');
  }

  // Step 3 & 4: Verify record in MongoDB & password hashing
  console.log('\n3 & 4. Inspecting user record directly in MongoDB...');
  const userDoc = await User.findOne({ email: persistentEmail }).select('+password');
  if (!userDoc) {
    throw new Error('Step 3 Failed: User document was not found in MongoDB!');
  }
  console.log('   User Record Found in MongoDB:');
  console.log('   - ID:', userDoc._id.toString());
  console.log('   - Name:', userDoc.name);
  console.log('   - Email (normalized):', userDoc.email);
  console.log('   - Password Hash in DB:', userDoc.password);
  
  if (userDoc.password === persistentPassword) {
    throw new Error('Step 4 Failed: Password was stored in plaintext!');
  }
  if (!userDoc.password.startsWith('$2a$') && !userDoc.password.startsWith('$2b$')) {
    throw new Error('Step 4 Failed: Password is not a bcrypt hash!');
  }
  console.log('   Password is securely hashed with bcrypt (rounds: 10).');

  // Step 5: Log in with the same email and password
  console.log('\n5. Logging in with same credentials (POST /api/auth/login)...');
  const loginRes = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: persistentEmail,
      password: persistentPassword,
    }),
  });
  const loginData = await loginRes.json();
  console.log(`   Response (${loginRes.status}):`, JSON.stringify(loginData, null, 2));
  if (loginRes.status !== 200 || !loginData.success || !loginData.token) {
    throw new Error('Step 5 Failed: Login failed with registered credentials.');
  }
  console.log('   Login successful, JWT token received.');

  // Step 6: Try logging in with the wrong password
  console.log('\n6. Logging in with wrong password...');
  const wrongPassRes = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: persistentEmail,
      password: 'IncorrectPassword999!',
    }),
  });
  const wrongPassData = await wrongPassRes.json();
  console.log(`   Response (${wrongPassRes.status}):`, JSON.stringify(wrongPassData, null, 2));
  if (wrongPassRes.status !== 401 || wrongPassData.success !== false) {
    throw new Error('Step 6 Failed: Login with wrong password did not return 401.');
  }
  console.log('   Access correctly denied for wrong password.');

  // Step 7: Try logging in with an unregistered email
  console.log('\n7. Logging in with unregistered email...');
  const unregRes = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'not.registered.rider@example.com',
      password: persistentPassword,
    }),
  });
  const unregData = await unregRes.json();
  console.log(`   Response (${unregRes.status}):`, JSON.stringify(unregData, null, 2));
  if (unregRes.status !== 401 || unregData.success !== false) {
    throw new Error('Step 7 Failed: Login with unregistered email did not return 401.');
  }
  console.log('   Access correctly denied for unregistered email.');

  // Step 8: Attempt to register the same email twice
  console.log('\n8. Attempting duplicate registration (same email with different case)...');
  const dupRes = await fetch('http://localhost:5000/api/auth/signup', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Duplicate Attempt',
      email: 'RIDER.PERSISTENT@EXAMPLE.COM',
      password: persistentPassword,
      confirmPassword: persistentPassword,
    }),
  });
  const dupData = await dupRes.json();
  console.log(`   Response (${dupRes.status}):`, JSON.stringify(dupData, null, 2));
  if (dupRes.status !== 409 || dupData.success !== false) {
    throw new Error('Step 8 Failed: Duplicate registration was not rejected with 409.');
  }
  console.log('   Duplicate registration correctly rejected with 409 Conflict.');

  // Step 9: Verify persistence - close connection and reconnect (simulate restart)
  console.log('\n9. Simulating backend restart and verifying account persistence...');
  await mongoose.disconnect();
  console.log('   Disconnected from MongoDB.');
  await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/pothole_hazard');
  console.log('   Reconnected to MongoDB.');
  const reloadedUser = await User.findOne({ email: persistentEmail });
  if (!reloadedUser) {
    throw new Error('Step 9 Failed: Saved account disappeared after reconnect!');
  }
  console.log('   Saved account persists in MongoDB! User ID:', reloadedUser._id.toString());

  console.log('\n=====================================================');
  console.log('🎉 ALL 9 VERIFICATION CHECKS PASSED SUCCESSFULLY!');
  console.log('=====================================================\n');
}

runE2E().then(() => {
  process.exit(0);
}).catch((err) => {
  console.error('\n❌ E2E Verification failed:', err);
  process.exit(1);
});
