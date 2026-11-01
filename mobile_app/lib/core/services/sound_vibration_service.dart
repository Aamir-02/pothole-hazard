import 'dart:async';
import 'package:vibration/vibration.dart';

class SoundVibrationService {
  static Timer? _vibrationTimer;
  static bool _isPlayingAlert = false;

  /// Start playing continuous emergency vibration pattern & siren
  static Future<void> startEmergencyAlarm() async {
    _isPlayingAlert = true;

    // Trigger continuous heavy vibration pattern
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        if (!_isPlayingAlert) {
          timer.cancel();
          return;
        }
        Vibration.vibrate(pattern: [0, 500, 200, 500], intensities: [0, 255, 0, 255]);
      });
    }
  }

  /// Stop emergency alarm and vibration immediately
  static Future<void> stopEmergencyAlarm() async {
    _isPlayingAlert = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    Vibration.cancel();
  }
}
