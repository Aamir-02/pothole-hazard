class DemoConstants {
  // Demo Mode Crash Thresholds (Sensitive for live demonstration on real hardware)
  // Normal Mode requires: speed > 15 km/h, accel > 25-35 m/s², gyro > 5.0 rad/s, 8s immobility.
  // Demo Mode allows demonstration at rest or small movement with gentle shake/tilt:
  static const double minCrashSpeedKmh = 0.0;
  static const double crashAccelThresholdMs2 = 12.0;
  static const double crashNetSpikeThresholdMs2 = 2.2;
  static const double crashGyroThresholdRadSec = 0.35;
  static const int immobilityVerificationSeconds = 1;
  static const double stdDevThreshold = 15.0;
  static const int crashCooldownSeconds = 10;

  static const double minPotholeSpeedKmh = 0.0;
  static const double minPotholeAccelMs2 = 13.5;
  static const double maxPotholeAccelMs2 = 25.0;
  static const double minPotholeNetSpikeMs2 = 3.8;
  static const double maxPotholeGyroRadSec = 2.0;
  static const int potholeDebounceSeconds = 3;

  static const String bannerText = '🧪 DEMO MODE ACTIVE';
  static const String demoCrashType = 'Demo Crash';
  static const String demoPotholeType = 'Demo Pothole';
}
