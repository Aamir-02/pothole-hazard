const http = require('http');
const mongoose = require('mongoose');
const { app, server } = require('../src/server');
const User = require('../src/models/User');

async function runTests() {
  console.log('🧪 Starting Authentication Verification Tests...');
  
  if (!server.listening) {
    await new Promise((resolve) => server.listen(5000, resolve));
    console.log('Server started on port 5000 for verification test.');
  }
  
  // Cleanup any previous test users
  const testEmail = 'tester_' + Date.now() + '@example.com';
  const testPassword = 'TestPassword123!';
  const testName = 'Verified Tester';
  
  console.log(`Using test email: ${testEmail}`);
  
  // Test 1: Register endpoint with valid user
  console.log('\n--- TEST 1: Register new user (POST /api/auth/signup) ---');
  let res = await fetch('http://localhost:5000/api/auth/signup', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: testName,
      email: testEmail,
      password: testPassword,
      confirmPassword: testPassword,
      phone: '+1234567890',
    }),
  });
  let data = await res.json();
  console.log(`Status: ${res.status}`, data);
  if (res.status !== 201 || !data.success || !data.token) {
    throw new Error('Test 1 Failed: Registration did not succeed');
  }
  console.log('✅ Test 1 Passed: User registered successfully.');

  // Test 2: Verify in MongoDB and check password hash
  console.log('\n--- TEST 2: Verify User in MongoDB & Password Hashing ---');
  const userInDb = await User.findOne({ email: testEmail }).select('+password');
  if (!userInDb) {
    throw new Error('Test 2 Failed: User was not found in MongoDB');
  }
  console.log(`User found in DB. ID: ${userInDb._id}, Name: ${userInDb.name}, Email: ${userInDb.email}`);
  console.log(`Password in DB: ${userInDb.password}`);
  if (userInDb.password === testPassword || !userInDb.password.startsWith('$2')) {
    throw new Error('Test 2 Failed: Password was stored in plaintext or not bcrypt hashed!');
  }
  console.log('✅ Test 2 Passed: User record verified in MongoDB and password is secure bcrypt hash.');

  // Test 3: Attempt duplicate registration with same email (case variation)
  console.log('\n--- TEST 3: Duplicate Registration (Same email with uppercase) ---');
  res = await fetch('http://localhost:5000/api/auth/signup', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Another User',
      email: testEmail.toUpperCase(),
      password: 'AnotherPassword456!',
      confirmPassword: 'AnotherPassword456!',
    }),
  });
  data = await res.json();
  console.log(`Status: ${res.status}`, data);
  if (res.status !== 409 || data.success !== false) {
    throw new Error('Test 3 Failed: Duplicate registration was not rejected with 409');
  }
  console.log('✅ Test 3 Passed: Duplicate email registration properly rejected.');

  // Test 4: Login with correct credentials
  console.log('\n--- TEST 4: Login with valid credentials (POST /api/auth/login) ---');
  res = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: testEmail,
      password: testPassword,
    }),
  });
  data = await res.json();
  console.log(`Status: ${res.status}`, data);
  if (res.status !== 200 || !data.success || !data.token) {
    throw new Error('Test 4 Failed: Valid login did not succeed');
  }
  const authToken = data.token;
  console.log('✅ Test 4 Passed: Login succeeded and issued JWT token.');

  // Test 5: Login with wrong password
  console.log('\n--- TEST 5: Login with wrong password ---');
  res = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: testEmail,
      password: 'WrongPassword999!',
    }),
  });
  data = await res.json();
  console.log(`Status: ${res.status}`, data);
  if (res.status !== 401 || data.success !== false) {
    throw new Error('Test 5 Failed: Wrong password did not return 401');
  }
  console.log('✅ Test 5 Passed: Login with wrong password rejected.');

  // Test 6: Login with unregistered email
  console.log('\n--- TEST 6: Login with unregistered email ---');
  res = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'nonexistent_' + Date.now() + '@example.com',
      password: testPassword,
    }),
  });
  data = await res.json();
  console.log(`Status: ${res.status}`, data);
  if (res.status !== 401 || data.success !== false) {
    throw new Error('Test 6 Failed: Unregistered email did not return 401');
  }
  console.log('✅ Test 6 Passed: Unregistered email rejected.');

  // Test 7: Fetch current profile with token (GET /api/auth/me)
  console.log('\n--- TEST 7: Get Profile (/api/auth/me) with token ---');
  res = await fetch('http://localhost:5000/api/auth/me', {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Accept': 'application/json',
    },
  });
  data = await res.json();
  console.log(`Status: ${res.status}`, data);
  if (res.status !== 200 || !data.success || data.user.email !== testEmail.toLowerCase()) {
    throw new Error('Test 7 Failed: Could not get profile with token');
  }
  console.log('✅ Test 7 Passed: Successfully retrieved profile with JWT token.');

  // Test 8: Forgot password endpoint
  console.log('\n--- TEST 8: Forgot Password (/api/auth/forgot-password) ---');
  res = await fetch('http://localhost:5000/api/auth/forgot-password', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: testEmail }),
  });
  data = await res.json();
  console.log(`Status: ${res.status}`, data);
  if (res.status !== 200 || !data.success) {
    throw new Error('Test 8 Failed: Forgot password failed');
  }
  console.log('✅ Test 8 Passed: Forgot password returned transparent status.');

  // Clean up test user
  await User.deleteOne({ email: testEmail });
  console.log('\n🧹 Test user cleaned up.');
  console.log('\n🎉 ALL BACKEND AUTH TESTS PASSED!\n');
}

runTests().then(() => {
  process.exit(0);
}).catch((err) => {
  console.error('❌ Test failed with error:', err);
  process.exit(1);
});
