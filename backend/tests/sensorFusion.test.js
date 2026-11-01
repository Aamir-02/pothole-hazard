const assert = require('assert');
const SensorFusionService = require('../src/services/sensorFusionService');

console.log('🧪 Running Sensor Fusion Algorithm Unit Tests...');

// Test 1: Normal Road Bump (High Accel, Zero Rotation, Constant Speed)
const bumpData = {
  accelG: 3.2,
  gyroRadSec: 0.8,
  speedBeforeKmh: 40,
  speedAfterKmh: 38,
  pitchDeg: 5,
  rollDeg: 3,
  isRiderImmobile: false,
};

const bumpResult = SensorFusionService.evaluateCrashConfidence(bumpData, 'medium');
assert.strictEqual(bumpResult.isCrashDetected, false, 'Road bump should NOT trigger accident alert');
console.log('✅ Test 1 Passed: Normal road bump ignored correctly (Confidence:', bumpResult.confidenceScore + '%)');

// Test 2: Severe Motorcycle Accident (High G-force, High Rotation, Sudden Speed Drop, Immobility)
const crashData = {
  accelG: 5.2,
  gyroRadSec: 6.4,
  speedBeforeKmh: 55,
  speedAfterKmh: 0,
  pitchDeg: 78,
  rollDeg: 82,
  isRiderImmobile: true,
};

const crashResult = SensorFusionService.evaluateCrashConfidence(crashData, 'medium');
assert.strictEqual(crashResult.isCrashDetected, true, 'Severe accident MUST trigger accident alert');
assert.ok(crashResult.confidenceScore >= 90, 'Confidence score should be >= 90%');
console.log('✅ Test 2 Passed: High-confidence accident detected correctly (Confidence:', crashResult.confidenceScore + '%)');

// Test 3: Phone Dropped while Walking (Low speed, high rotation, accel spike)
const walkDropData = {
  accelG: 4.0,
  gyroRadSec: 1.2,
  speedBeforeKmh: 3,
  speedAfterKmh: 0,
  pitchDeg: 12,
  rollDeg: 10,
  isRiderImmobile: false,
};

const walkDropResult = SensorFusionService.evaluateCrashConfidence(walkDropData, 'medium');
assert.strictEqual(walkDropResult.isCrashDetected, false, 'Phone drop while walking should NOT trigger accident alert');
console.log('✅ Test 3 Passed: Phone drop while walking filtered out (Confidence:', walkDropResult.confidenceScore + '%)');

console.log('\n🎉 ALL SENSOR FUSION UNIT TESTS PASSED SUCCESSFULLY!\n');
