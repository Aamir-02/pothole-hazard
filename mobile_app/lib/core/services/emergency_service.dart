import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'sms_service.dart';
import 'api_service.dart';
import 'location_service.dart';

enum SosState {
  idle,
  countingDown,
  dispatched,
  cancelled,
}

class EmergencyService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _vibrationTimer;
  Timer? _countdownTimer;

  SosState _sosState = SosState.idle;
  SosState get sosState => _sosState;

  int _remainingSeconds = 15;
  int get remainingSeconds => _remainingSeconds;

  final _sosStateController = StreamController<SosState>.broadcast();
  Stream<SosState> get sosStateStream => _sosStateController.stream;

  final _countdownController = StreamController<int>.broadcast();
  Stream<int> get countdownStream => _countdownController.stream;

  final _smsResultController = StreamController<SmsDispatchResult>.broadcast();
  Stream<SmsDispatchResult> get smsResultStream => _smsResultController.stream;

  // Stored telemetry for immediate manual dispatch
  double _lastLatitude = 0.0;
  double _lastLongitude = 0.0;
  double _lastSpeed = 0.0;
  double _lastImpactForce = 0.0;
  List<String> _lastEmergencyContacts = [];
  String _lastUserId = '';

  /// Start Emergency SOS Countdown & Alarms
  Future<void> startEmergencySos({
    required int initialCountdownSeconds,
    required bool alarmEnabled,
    required double latitude,
    required double longitude,
    required double speed,
    required double impactForce,
    required List<String> emergencyContacts,
    required String userId,
  }) async {
    if (_sosState == SosState.countingDown) return;

    _lastLatitude = latitude;
    _lastLongitude = longitude;
    _lastSpeed = speed;
    _lastImpactForce = impactForce;
    _lastEmergencyContacts = emergencyContacts;
    _lastUserId = userId;

    _sosState = SosState.countingDown;
    _remainingSeconds = initialCountdownSeconds;
    _sosStateController.add(_sosState);
    _countdownController.add(_remainingSeconds);

    // Keep screen awake during emergency
    try {
      await WakelockPlus.enable();
    } catch (e) {
      print('[EmergencyService] Wakelock enable error: $e');
    }

    // Play Alarm Sound & Vibration if enabled
    if (alarmEnabled) {
      _startSirenAndVibration();
    }

    // Start 1-second interval countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _remainingSeconds--;
      _countdownController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        timer.cancel();
        await _dispatchEmergencyAlerts(
          latitude: latitude,
          longitude: longitude,
          speed: speed,
          impactForce: impactForce,
          emergencyContacts: emergencyContacts,
          userId: userId,
        );
      }
    });
  }

  /// Immediately dispatch SOS without waiting for countdown timer
  Future<void> triggerImmediateSos() async {
    if (_sosState != SosState.countingDown) return;

    _countdownTimer?.cancel();
    _countdownTimer = null;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      await _audioPlayer.stop();
      Vibration.cancel();
    } catch (e) {
      print('[EmergencyService] Siren audio stop error: $e');
    }

    await _dispatchEmergencyAlerts(
      latitude: _lastLatitude,
      longitude: _lastLongitude,
      speed: _lastSpeed,
      impactForce: _lastImpactForce,
      emergencyContacts: _lastEmergencyContacts,
      userId: _lastUserId,
    );
  }

  /// Start playing siren sound and continuous vibration
  void _startSirenAndVibration() async {
    try {
      // Loop siren sound
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm_siren.mp3'));
    } catch (e) {
      print('[EmergencyService] Siren audio play error (asset or audio focus): $e');
    }

    // Continuous vibration pattern
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
        if (_sosState != SosState.countingDown) return;
        Vibration.vibrate(pattern: [0, 500, 200, 500], intensities: [0, 255, 0, 255]);
      });
    }
  }

  /// Execute SOS Dispatch when countdown hits zero or user triggers immediate SOS
  Future<void> _dispatchEmergencyAlerts({
    required double latitude,
    required double longitude,
    required double speed,
    required double impactForce,
    required List<String> emergencyContacts,
    required String userId,
  }) async {
    _sosState = SosState.dispatched;
    _sosStateController.add(_sosState);

    // Stop alarms on dispatch
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      await _audioPlayer.stop();
      Vibration.cancel();
      await WakelockPlus.disable();
    } catch (_) {}

    // Fetch fresh GPS position if coordinates are zero
    double finalLat = latitude;
    double finalLng = longitude;
    if (finalLat == 0.0 && finalLng == 0.0) {
      final pos = await LocationService.getBestAvailablePosition(timeout: const Duration(seconds: 4));
      if (pos != null) {
        finalLat = pos.latitude;
        finalLng = pos.longitude;
      }
    }

    final timestamp = DateTime.now();

    // 1. Send SMS to all emergency contacts
    final result = await SmsService.sendEmergencyAlerts(
      recipients: emergencyContacts,
      latitude: finalLat,
      longitude: finalLng,
      timestamp: timestamp,
    );

    if (!_smsResultController.isClosed) {
      _smsResultController.add(result);
    }

    // 2. Post Incident to Backend API
    if (finalLat != 0.0 && finalLng != 0.0) {
      await ApiService.postIncident(
        userId: userId,
        latitude: finalLat,
        longitude: finalLng,
        speed: speed,
        impactForce: impactForce,
        time: timestamp,
      );
    }
  }

  /// Cancel emergency countdown immediately ("I'M SAFE")
  Future<void> cancelEmergency() async {
    _sosState = SosState.cancelled;
    _sosStateController.add(_sosState);

    _countdownTimer?.cancel();
    _countdownTimer = null;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    try {
      await _audioPlayer.stop();
      Vibration.cancel();
      await WakelockPlus.disable();
    } catch (e) {
      print('[EmergencyService] Error stopping emergency alarms: $e');
    }

    _sosState = SosState.idle;
  }

  void dispose() {
    cancelEmergency();
    _audioPlayer.dispose();
    _sosStateController.close();
    _countdownController.close();
    _smsResultController.close();
  }
}
