import 'package:flutter_test/flutter_test.dart';
import 'package:pothole_hazard/core/services/sms_service.dart';
import 'package:pothole_hazard/core/services/sensor_service.dart';
import 'package:pothole_hazard/core/services/location_service.dart';
import 'package:pothole_hazard/core/services/crash_detection_service.dart';
import 'package:pothole_hazard/core/demo/demo_mode_controller.dart';
import 'package:pothole_hazard/core/demo/demo_constants.dart';
import 'package:pothole_hazard/core/demo/demo_crash_detection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Emergency SMS Formatting & Sanitization Tests', () {
    test('formatEmergencyMessage with valid GPS coordinates includes exact required text and Google Maps URL', () {
      final msg = SmsService.formatEmergencyMessage(
        latitude: 12.971598,
        longitude: 77.594566,
      );

      expect(msg, contains('EMERGENCY ALERT!'));
      expect(msg, contains('A possible vehicle accident has been detected.'));
      expect(msg, contains('The user\'s current GPS location:'));
      expect(msg, contains('Latitude: 12.971598'));
      expect(msg, contains('Longitude: 77.594566'));
      expect(msg, contains('Google Maps Location:'));
      expect(msg, contains('https://www.google.com/maps?q=12.971598,77.594566'));
      expect(msg, contains('Please contact the user and provide emergency assistance.'));
    });

    test('formatEmergencyMessage with unavailable GPS coordinates indicates unavailable without fake coordinates', () {
      final msg = SmsService.formatEmergencyMessage(
        latitude: 0.0,
        longitude: 0.0,
      );

      expect(msg, contains('EMERGENCY ALERT!'));
      expect(msg, contains('The user\'s current GPS location:'));
      expect(msg, contains('Location unavailable (GPS fix could not be acquired)'));
      expect(msg, isNot(contains('37.7749')));
      expect(msg, isNot(contains('-122.4194')));
      expect(msg, isNot(contains('https://www.google.com/maps?q=0.0,0.0')));
      expect(msg, contains('Please contact the user and provide emergency assistance.'));
    });

    test('sanitizePhoneNumber correctly strips whitespace, hyphens, and brackets while preserving +', () {
      expect(SmsService.sanitizePhoneNumber('+91 98765 43210'), '+919876543210');
      expect(SmsService.sanitizePhoneNumber('(555) 019-2834'), '5550192834');
      expect(SmsService.sanitizePhoneNumber('+1-555-014-9912'), '+15550149912');
      expect(SmsService.sanitizePhoneNumber('   9876543210   '), '9876543210');
      expect(SmsService.sanitizePhoneNumber(''), '');
    });

    test('sendEmergencyAlerts with empty recipients returns clear error', () async {
      final result = await SmsService.sendEmergencyAlerts(
        recipients: [],
        latitude: 12.97,
        longitude: 77.59,
      );

      expect(result.success, false);
      expect(result.openedInComposer, false);
      expect(result.message, contains('No emergency contacts found'));
    });
  });

  group('DemoState Telemetry & Ride Reset Tests', () {
    test('DemoState defaults all ride statistics strictly to zero', () {
      const state = DemoState();

      expect(state.isDemoActive, false);
      expect(state.currentSpeedKmh, 0.0);
      expect(state.maxSpeedKmh, 0.0);
      expect(state.distanceKm, 0.0);
      expect(state.potholeCount, 0);
      expect(state.isSimulatingSpeed, false);
      expect(state.totalAccelMs2, 9.81);
      expect(state.gyroRadSec, 0.0);
      expect(state.demoIncidents, isEmpty);
    });

    test('DemoState contains separate live telemetry fields when updated', () {
      const state = DemoState(
        isDemoActive: true,
        currentSpeedKmh: 42.5,
        totalAccelMs2: 10.2,
        accelG: 1.04,
        gyroRadSec: 0.05,
        latitude: 12.9716,
        longitude: 77.5946,
      );

      expect(state.isDemoActive, true);
      expect(state.currentSpeedKmh, 42.5);
      expect(state.totalAccelMs2, 10.2);
      expect(state.accelG, 1.04);
      expect(state.gyroRadSec, 0.05);
      expect(state.latitude, 12.9716);
      expect(state.longitude, 77.5946);
    });

    test('DemoConstants thresholds are sensitive for demonstration while Normal Mode is protected', () {
      // Resting gravity (~9.81 m/s²) must be strictly below minPotholeAccelMs2
      expect(DemoConstants.minPotholeAccelMs2, greaterThan(9.81));
      expect(DemoConstants.minPotholeNetSpikeMs2, greaterThanOrEqualTo(3.5));
      expect(DemoConstants.potholeDebounceSeconds, greaterThanOrEqualTo(3));

      // Sensitive Demo Crash thresholds (distinct from Normal Mode: 15 km/h, 30 m/s², 5 rad/s, 8s)
      expect(DemoConstants.minCrashSpeedKmh, 0.0);
      expect(DemoConstants.crashAccelThresholdMs2, lessThan(15.0)); // 12.0 m/s²
      expect(DemoConstants.crashGyroThresholdRadSec, lessThan(0.5)); // 0.35 rad/s
      expect(DemoConstants.immobilityVerificationSeconds, lessThanOrEqualTo(1)); // 1s
    });

    test('DemoCrashDetectionService triggers on minor sensor disturbance with real sensor values', () async {
      final demoCrashService = DemoCrashDetectionService();
      CrashDetectionResult? detected;
      final sub = demoCrashService.resultStream.listen((res) {
        detected = res;
      });

      // Minor disturbance: totalAccel 12.2 m/s² (> 12.0) and gyro 0.38 rad/s (> 0.35)
      final disturbanceSensor = SensorTelemetry(
        accelX: 2.5,
        accelY: 2.0,
        accelZ: 11.8,
        totalAccel: 12.2,
        netAccelSpike: 2.39,
        gyroX: 0.2,
        gyroY: 0.3,
        gyroZ: 0.1,
        gyroRotation: 0.38,
        timestamp: DateTime.now(),
      );
      final loc = LocationTelemetry(
        latitude: 12.971598,
        longitude: 77.594566,
        speedKmh: 0.0,
        accuracy: 5.0,
        altitude: 900.0,
        timestamp: DateTime.now(),
      );

      demoCrashService.processTelemetry(
        sensor: disturbanceSensor,
        location: loc,
        sensitivity: 'medium',
      );

      // Allow the 1-second verification timer to complete
      await Future.delayed(const Duration(milliseconds: 1100));

      expect(detected, isNotNull);
      expect(detected!.isCrash, isTrue);
      expect(detected!.impactForceMs2, 12.2);
      expect(detected!.gyroRadSec, 0.38);

      await sub.cancel();
      demoCrashService.dispose();
    });
  });
}
