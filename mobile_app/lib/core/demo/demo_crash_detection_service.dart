import 'dart:async';
import 'dart:math';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import '../services/crash_detection_service.dart';
import 'demo_constants.dart';

class DemoCrashDetectionService {
  final _resultController = StreamController<CrashDetectionResult>.broadcast();
  Stream<CrashDetectionResult> get resultStream => _resultController.stream;

  bool _isEvaluatingCrash = false;
  DateTime? _impactTimestamp;
  DateTime? _lastCrashTriggeredTime;
  double _impactAccelMs2 = 0.0;
  double _impactGyroRadSec = 0.0;
  double _impactSpeedKmh = 0.0;
  final List<double> _postImpactAccelBuffer = [];
  Timer? _immobilityTimer;

  bool _isEvaluatingPothole = false;
  DateTime? _potholeTimestamp;
  DateTime? _lastPotholeDetectedTime;
  double _potholeAccelMs2 = 0.0;
  double _potholeGyroRadSec = 0.0;
  double _potholeSpeedKmh = 0.0;

  DemoCrashDetectionService() {
    print('===== SENSITIVE DEMO CRASH DETECTOR INITIALIZED =====');
  }

  /// Process telemetry specifically tailored for Demo Mode presentation
  void processTelemetry({
    required SensorTelemetry sensor,
    required LocationTelemetry location,
    required String sensitivity,
  }) {
    final speedKmh = location.speedKmh;
    final totalAccel = sensor.totalAccel;
    final gyroRotation = sensor.gyroRotation;

    // Configurable sensitive demo crash thresholds based on user setting
    double accelThreshold = DemoConstants.crashAccelThresholdMs2;
    double netSpikeThreshold = DemoConstants.crashNetSpikeThresholdMs2;
    double gyroThreshold = DemoConstants.crashGyroThresholdRadSec;

    if (sensitivity == 'high') {
      accelThreshold = 11.0;
      netSpikeThreshold = 1.8;
      gyroThreshold = 0.25;
    } else if (sensitivity == 'low') {
      accelThreshold = 13.5;
      netSpikeThreshold = 2.8;
      gyroThreshold = 0.50;
    }

    // Sensitive Demo Crash Thresholds:
    // Works while standing still or at desk (Speed >= 0 km/h)
    // Any minor physical disturbance, gentle shake, or wrist tilt triggers alert
    final double netAccelSpike = (totalAccel - 9.80665).abs();
    final bool isDisturbance = (totalAccel >= accelThreshold || netAccelSpike >= netSpikeThreshold) &&
        gyroRotation >= gyroThreshold;

    final now = DateTime.now();
    final bool crashCooldownElapsed = _lastCrashTriggeredTime == null ||
        now.difference(_lastCrashTriggeredTime!).inSeconds >= DemoConstants.crashCooldownSeconds;

    if (!_isEvaluatingCrash && crashCooldownElapsed && isDisturbance) {
      _isEvaluatingCrash = true;
      _impactTimestamp = now;
      _impactAccelMs2 = totalAccel;
      _impactGyroRadSec = gyroRotation;
      _impactSpeedKmh = speedKmh;
      _postImpactAccelBuffer.clear();

      print('[DemoCrashDetectionService] SENSITIVE DEMO CRASH: Minor disturbance detected (Accel: ${totalAccel.toStringAsFixed(1)} m/s², NetSpike: ${netAccelSpike.toStringAsFixed(1)} m/s², Gyro: ${gyroRotation.toStringAsFixed(2)} rad/s). Verifying ${DemoConstants.immobilityVerificationSeconds}s...');

      _startDemoImmobilityVerification();
      return;
    }

    if (_isEvaluatingCrash) {
      _postImpactAccelBuffer.add(totalAccel);
      // NOTE: Do NOT cancel crash evaluation due to speed changes in Demo Mode
    }

    // Demo Pothole Thresholds:
    // Requires a true vertical shock spike above resting gravity (net spike >= 3.8 m/s² or totalAccel >= 13.5 m/s²),
    // low gyroscope rotation (< 2.0 rad/s), and a minimum 3-second debounce cooldown.
    // Resting phone at 9.81 m/s² gravity will NEVER trigger a pothole!
    final bool potholeCooldownElapsed = _lastPotholeDetectedTime == null ||
        now.difference(_lastPotholeDetectedTime!).inSeconds >= DemoConstants.potholeDebounceSeconds;

    if (!_isEvaluatingCrash &&
        !_isEvaluatingPothole &&
        potholeCooldownElapsed &&
        (totalAccel >= DemoConstants.minPotholeAccelMs2 || netAccelSpike >= DemoConstants.minPotholeNetSpikeMs2) &&
        totalAccel <= DemoConstants.maxPotholeAccelMs2 &&
        gyroRotation < DemoConstants.maxPotholeGyroRadSec) {
      
      _isEvaluatingPothole = true;
      _potholeTimestamp = now;
      _lastPotholeDetectedTime = now;
      _potholeAccelMs2 = totalAccel;
      _potholeGyroRadSec = gyroRotation;
      _potholeSpeedKmh = speedKmh;

      print('[DemoCrashDetectionService] Demo Pothole detected (Impact: ${totalAccel.toStringAsFixed(1)} m/s², Net Spike: ${netAccelSpike.toStringAsFixed(1)} m/s²)');

      Timer(const Duration(milliseconds: 500), () {
        if (_isEvaluatingPothole) {
          final result = CrashDetectionResult(
            isCrash: false,
            isPothole: true,
            impactForceMs2: _potholeAccelMs2,
            gyroRadSec: _potholeGyroRadSec,
            speedKmh: _potholeSpeedKmh,
            description: 'Demo Pothole impact detected at ${_potholeAccelMs2.toStringAsFixed(1)} m/s²',
            timestamp: _potholeTimestamp ?? DateTime.now(),
          );

          if (!_resultController.isClosed) {
            _resultController.add(result);
          }
          _isEvaluatingPothole = false;
        }
      });
    }
  }

  void _startDemoImmobilityVerification() {
    _immobilityTimer?.cancel();
    _immobilityTimer = Timer(const Duration(seconds: DemoConstants.immobilityVerificationSeconds), () {
      if (!_isEvaluatingCrash) return;

      double stdDev = 0.0;
      if (_postImpactAccelBuffer.isNotEmpty) {
        double sum = _postImpactAccelBuffer.reduce((a, b) => a + b);
        double avg = sum / _postImpactAccelBuffer.length;

        double variance = 0.0;
        for (var val in _postImpactAccelBuffer) {
          variance += pow(val - avg, 2);
        }
        stdDev = sqrt(variance / _postImpactAccelBuffer.length);
      }

      print('[DemoCrashDetectionService] Post-impact ${DemoConstants.immobilityVerificationSeconds}s stdDev: ${stdDev.toStringAsFixed(2)}');

      // For sensitive demo mode, confirm if buffer is empty or stdDev is within forgiving presentation threshold
      if (_postImpactAccelBuffer.isEmpty || stdDev < DemoConstants.stdDevThreshold) {
        _lastCrashTriggeredTime = DateTime.now();
        print('[DemoCrashDetectionService] SENSITIVE DEMO CRASH CONFIRMED!');
        final result = CrashDetectionResult(
          isCrash: true,
          isPothole: false,
          impactForceMs2: _impactAccelMs2,
          gyroRadSec: _impactGyroRadSec,
          speedKmh: _impactSpeedKmh,
          description: 'DEMO CRASH DETECTED: Impact (${_impactAccelMs2.toStringAsFixed(1)} m/s²) + Rotation (${_impactGyroRadSec.toStringAsFixed(2)} rad/s)',
          timestamp: _impactTimestamp ?? DateTime.now(),
        );

        if (!_resultController.isClosed) {
          _resultController.add(result);
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

  void reset() {
    _cancelCrashEvaluation();
    _isEvaluatingPothole = false;
    _lastPotholeDetectedTime = null;
    _lastCrashTriggeredTime = null;
  }

  void dispose() {
    reset();
    _resultController.close();
  }
}
