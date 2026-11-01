import 'dart:async';
import 'dart:math';
import 'sensor_service.dart';
import 'location_service.dart';

enum RideStatus {
  idle,
  monitoring,
  safe,
  potholeDetected,
  crashDetected,
}

class CrashDetectionResult {
  final bool isCrash;
  final bool isPothole;
  final double impactForceMs2;
  final double gyroRadSec;
  final double speedKmh;
  final String description;
  final DateTime timestamp;

  CrashDetectionResult({
    required this.isCrash,
    required this.isPothole,
    required this.impactForceMs2,
    required this.gyroRadSec,
    required this.speedKmh,
    required this.description,
    required this.timestamp,
  });
}

class CrashDetectionService {
  final _resultController = StreamController<CrashDetectionResult>.broadcast();
  Stream<CrashDetectionResult> get resultStream => _resultController.stream;

  // Impact evaluation state tracking
  bool _isEvaluatingCrash = false;
  DateTime? _impactTimestamp;
  double _impactAccelMs2 = 0.0;
  double _impactGyroRadSec = 0.0;
  double _impactSpeedKmh = 0.0;
  final List<double> _postImpactAccelBuffer = [];
  Timer? _immobilityTimer;

  // Pothole post-check buffer
  bool _isEvaluatingPothole = false;
  DateTime? _potholeTimestamp;
  double _potholeAccelMs2 = 0.0;
  double _potholeGyroRadSec = 0.0;
  double _potholeSpeedKmh = 0.0;

  /// Process continuous sensor and location telemetry
  void processTelemetry({
    required SensorTelemetry sensor,
    required LocationTelemetry location,
    required String sensitivity, // 'low', 'medium', 'high'
  }) {
    final speedKmh = location.speedKmh;
    final totalAccel = sensor.totalAccel; // sqrt(x² + y² + z²)
    final gyroRotation = sensor.gyroRotation; // sqrt(gx² + gy² + gz²)

    // Dynamic thresholds based on sensitivity setting
    double crashAccelThreshold = 30.0; // Default Medium: 30 m/s²
    if (sensitivity == 'high') {
      crashAccelThreshold = 25.0;
    } else if (sensitivity == 'low') {
      crashAccelThreshold = 35.0;
    }

    double crashGyroThreshold = 5.0; // 5 rad/s

    // -------------------------------------------------------------
    // 1. CRASH DETECTION EVALUATION
    // -------------------------------------------------------------
    // Condition 1: Speed > 15 km/h
    // Condition 2: Acceleration spike greater than 30 m/s² (totalAccel)
    // Condition 3: Gyroscope rotation greater than 5 rad/s
    if (!_isEvaluatingCrash &&
        speedKmh > 15.0 &&
        totalAccel > crashAccelThreshold &&
        gyroRotation > crashGyroThreshold) {
      
      _isEvaluatingCrash = true;
      _impactTimestamp = DateTime.now();
      _impactAccelMs2 = totalAccel;
      _impactGyroRadSec = gyroRotation;
      _impactSpeedKmh = speedKmh;
      _postImpactAccelBuffer.clear();

      print('[CrashDetectionService] Potential crash impact detected! Verifying 8s post-impact immobility...');

      // Condition 4: After impact, phone becomes almost motionless for 8 seconds
      _startImmobilityVerification();
      return;
    }

    // Collect 8-second immobility buffer if crash evaluation is pending
    if (_isEvaluatingCrash) {
      _postImpactAccelBuffer.add(totalAccel);

      // If rider resumes high-speed vehicle movement during verification, cancel false alarm
      if (speedKmh > 20.0) {
        print('[CrashDetectionService] False alarm: Rider resumed vehicle movement (${speedKmh.toStringAsFixed(1)} km/h)');
        _cancelCrashEvaluation();
      }
    }

    // -------------------------------------------------------------
    // 2. POTHOLE DETECTION EVALUATION
    // -------------------------------------------------------------
    // Detect pothole when:
    // • Speed > 10 km/h
    // • Acceleration spike between 12 m/s² and 25 m/s²
    // • Gyroscope rotation is LOW (< 2.5 rad/s)
    // • Phone continues moving afterwards
    if (!_isEvaluatingCrash &&
        !_isEvaluatingPothole &&
        speedKmh > 10.0 &&
        totalAccel >= 12.0 &&
        totalAccel <= 25.0 &&
        gyroRotation < 2.5) {
      
      _isEvaluatingPothole = true;
      _potholeTimestamp = DateTime.now();
      _potholeAccelMs2 = totalAccel;
      _potholeGyroRadSec = gyroRotation;
      _potholeSpeedKmh = speedKmh;

      // Verify that phone continues moving afterwards
      Timer(const Duration(seconds: 2), () {
        if (_isEvaluatingPothole) {
          // If phone is still moving (speed > 5 km/h), confirm pothole
          final currentSpeed = location.speedKmh;
          if (currentSpeed > 5.0 || speedKmh > 5.0) {
            final result = CrashDetectionResult(
              isCrash: false,
              isPothole: true,
              impactForceMs2: _potholeAccelMs2,
              gyroRadSec: _potholeGyroRadSec,
              speedKmh: _potholeSpeedKmh,
              description: 'Pothole impact detected at ${_potholeAccelMs2.toStringAsFixed(1)} m/s²',
              timestamp: _potholeTimestamp ?? DateTime.now(),
            );
            if (!_resultController.isClosed) {
              _resultController.add(result);
            }
          }
          _isEvaluatingPothole = false;
        }
      });
    }
  }

  /// Verify 8 seconds of post-impact immobility
  void _startImmobilityVerification() {
    _immobilityTimer?.cancel();
    _immobilityTimer = Timer(const Duration(seconds: 8), () {
      if (!_isEvaluatingCrash) return;

      // Evaluate buffer variance / immobility
      if (_postImpactAccelBuffer.isNotEmpty) {
        double sum = _postImpactAccelBuffer.reduce((a, b) => a + b);
        double avg = sum / _postImpactAccelBuffer.length;

        double variance = 0.0;
        for (var val in _postImpactAccelBuffer) {
          variance += pow(val - avg, 2);
        }
        double stdDev = sqrt(variance / _postImpactAccelBuffer.length);

        print('[CrashDetectionService] Post-impact 8s stdDev: ${stdDev.toStringAsFixed(2)}, avg: ${avg.toStringAsFixed(2)}');

        // If stdDev is low (< 3.5 m/s²), rider is immobile after crash
        if (stdDev < 3.5) {
          final result = CrashDetectionResult(
            isCrash: true,
            isPothole: false,
            impactForceMs2: _impactAccelMs2,
            gyroRadSec: _impactGyroRadSec,
            speedKmh: _impactSpeedKmh,
            description: 'CRASH CONFIRMED: High impact (${_impactAccelMs2.toStringAsFixed(1)} m/s²) + High rotation (${_impactGyroRadSec.toStringAsFixed(1)} rad/s) + 8s Immobility',
            timestamp: _impactTimestamp ?? DateTime.now(),
          );

          if (!_resultController.isClosed) {
            _resultController.add(result);
          }
        } else {
          print('[CrashDetectionService] False alarm: Excessive motion detected during 8s immobility window.');
        }
      }

      _cancelCrashEvaluation();
    });
  }

  void _cancelCrashEvaluation() {
    _isEvaluatingCrash = false;
    _immobilityTimer?.cancel();
    _immobilityTimer = null;
    _postImpactAccelBuffer.clear();
  }

  /// Force manual crash simulation for testing/demo
  void triggerManualCrashSimulation({
    required double speedKmh,
    required double impactForceMs2,
    required double gyroRadSec,
  }) {
    final result = CrashDetectionResult(
      isCrash: true,
      isPothole: false,
      impactForceMs2: impactForceMs2,
      gyroRadSec: gyroRadSec,
      speedKmh: speedKmh,
      description: 'MANUAL TEST CRASH TRIGGERED',
      timestamp: DateTime.now(),
    );
    if (!_resultController.isClosed) {
      _resultController.add(result);
    }
  }

  void dispose() {
    _immobilityTimer?.cancel();
    _resultController.close();
  }
}
