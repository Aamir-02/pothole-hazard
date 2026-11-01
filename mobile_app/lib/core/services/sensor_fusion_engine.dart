import 'dart:math';

class SensorFusionEvaluation {
  final bool isCrashDetected;
  final double confidenceScore; // 0.0 to 100.0
  final String severity; // LOW, MEDIUM, HIGH, CRITICAL
  final List<String> reasons;
  final double peakAccelG;
  final double peakGyroRadSec;

  SensorFusionEvaluation({
    required this.isCrashDetected,
    required this.confidenceScore,
    required this.severity,
    required this.reasons,
    required this.peakAccelG,
    required this.peakGyroRadSec,
  });
}

class SensorFusionEngine {
  /// Evaluates telemetry parameters for crash confirmation.
  /// Ignores normal road bumps, speed breakers, walking, or phone drops without high rotation/speed drop.
  static SensorFusionEvaluation evaluate({
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    required double speedBeforeKmh,
    required double speedAfterKmh,
    required double pitchDeg,
    required double rollDeg,
    required bool isRiderImmobile,
    String sensitivity = 'medium',
  }) {
    // Calculate total G-force magnitude: sqrt(x^2 + y^2 + z^2) / 9.80665
    double accelMagnitudeMs2 = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
    double accelG = accelMagnitudeMs2 / 9.80665;

    // Calculate peak angular velocity magnitude: sqrt(gx^2 + gy^2 + gz^2)
    double gyroRadSec = sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);

    double accelThresholdG = sensitivity == 'high' ? 3.0 : sensitivity == 'low' ? 4.5 : 3.8;
    double gyroThresholdRad = sensitivity == 'high' ? 3.0 : sensitivity == 'low' ? 5.0 : 4.0;

    double accelScore = 0.0;
    double gyroScore = 0.0;
    double speedScore = 0.0;
    double orientationScore = 0.0;
    double immobilityScore = 0.0;

    List<String> reasons = [];

    // 1. Accel G-force Spike Check
    if (accelG >= accelThresholdG) {
      double factor = min((accelG - accelThresholdG) / 3.0, 1.0);
      accelScore = 0.35 + factor * 0.15;
      reasons.add('High G-force impact: ${accelG.toStringAsFixed(1)}G');
    } else if (accelG >= 2.2) {
      accelScore = 0.15; // Road bump candidate
    }

    // 2. Gyroscope Rotation Check
    if (gyroRadSec >= gyroThresholdRad) {
      gyroScore = 0.25;
      reasons.add('Rapid phone/bike spin: ${gyroRadSec.toStringAsFixed(1)} rad/s');
    } else if (gyroRadSec >= 2.0) {
      gyroScore = 0.10;
    }

    // 3. GPS Deceleration Check
    double speedDrop = max(0, speedBeforeKmh - speedAfterKmh);
    if (speedBeforeKmh > 15 && speedAfterKmh < 5) {
      speedScore = 0.25;
      reasons.add('Sudden velocity drop: ${speedBeforeKmh.toStringAsFixed(0)} -> ${speedAfterKmh.toStringAsFixed(0)} km/h');
    } else if (speedDrop > 20) {
      speedScore = 0.15;
    }

    // 4. Phone Tilt Check
    double maxTilt = max(pitchDeg.abs(), rollDeg.abs());
    if (maxTilt > 45) {
      orientationScore = 0.15;
      reasons.add('Severe bike tilt angle: ${maxTilt.toStringAsFixed(0)}°');
    }

    // 5. Post-Impact Immobility Check
    if (isRiderImmobile && accelG >= accelThresholdG) {
      immobilityScore = 0.15;
      reasons.add('Rider post-impact immobility');
    }

    double totalScore = accelScore + gyroScore + speedScore + orientationScore + immobilityScore;

    // False Alarm Suppression:
    // - Low speed walking / dropped phone while stationary
    if (speedBeforeKmh < 6 && gyroRadSec < 2.0) {
      totalScore *= 0.2;
    }

    // - Speed breaker bump (no rotation, speed controlled)
    if (gyroRadSec < 1.5 && maxTilt < 20 && speedBeforeKmh < 35) {
      totalScore *= 0.4;
    }

    double confidence = min((totalScore * 100).roundToDouble(), 100.0);
    bool isCrashDetected = confidence >= 90.0;

    String severity = 'LOW';
    if (confidence >= 90) {
      severity = 'CRITICAL';
    } else if (confidence >= 75) {
      severity = 'HIGH';
    } else if (confidence >= 50) {
      severity = 'MEDIUM';
    }

    return SensorFusionEvaluation(
      isCrashDetected: isCrashDetected,
      confidenceScore: confidence,
      severity: severity,
      reasons: reasons,
      peakAccelG: accelG,
      peakGyroRadSec: gyroRadSec,
    );
  }
}
