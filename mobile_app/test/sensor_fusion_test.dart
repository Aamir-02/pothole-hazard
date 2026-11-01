import 'package:flutter_test/flutter_test.dart';
import 'package:pothole_hazard/core/services/sensor_fusion_engine.dart';

void main() {
  group('Sensor Fusion Engine Tests', () {
    test('Normal Road Bump does NOT trigger crash alert', () {
      final result = SensorFusionEngine.evaluate(
        accelX: 0,
        accelY: 30, // ~3G
        accelZ: 9.8,
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.1,
        speedBeforeKmh: 42,
        speedAfterKmh: 40,
        pitchDeg: 5,
        rollDeg: 2,
        isRiderImmobile: false,
      );

      expect(result.isCrashDetected, false);
      expect(result.confidenceScore < 90, true);
    });

    test('Severe Motorcycle Accident triggers >90% confidence crash alert', () {
      final result = SensorFusionEngine.evaluate(
        accelX: 25,
        accelY: 45, // ~5.2G
        accelZ: 15,
        gyroX: 4.5,
        gyroY: 5.2,
        gyroZ: 2.1,
        speedBeforeKmh: 55,
        speedAfterKmh: 0,
        pitchDeg: 75,
        rollDeg: 80,
        isRiderImmobile: true,
      );

      expect(result.isCrashDetected, true);
      expect(result.confidenceScore >= 90.0, true);
      expect(result.severity, 'CRITICAL');
    });
  });
}
