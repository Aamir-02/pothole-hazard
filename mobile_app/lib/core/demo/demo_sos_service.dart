import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/emergency_service.dart';
import '../services/sms_service.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class DemoSosService {
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

  double _lastLatitude = 0.0;
  double _lastLongitude = 0.0;
  double _lastSpeed = 0.0;
  double _lastImpactForce = 0.0;
  List<String> _lastEmergencyContacts = [];
  String _lastUserId = '';

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

    try {
      await WakelockPlus.enable();
    } catch (e) {
      print('[DemoSosService] Wakelock enable error: $e');
    }

    if (alarmEnabled) {
      _startSirenAndVibration();
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _remainingSeconds--;
      _countdownController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        timer.cancel();
        await _dispatchEmergencyAlerts();
      }
    });
  }

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
      print('[DemoSosService] Error stopping audio: $e');
    }

    await _dispatchEmergencyAlerts();
  }

  void _startSirenAndVibration() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm_siren.mp3'));
    } catch (e) {
      print('[DemoSosService] Siren audio play error: $e');
    }

    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      _vibrationTimer?.cancel();
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
        if (_sosState != SosState.countingDown) return;
        Vibration.vibrate(pattern: [0, 500, 200, 500], intensities: [0, 255, 0, 255]);
      });
    }
  }

  Future<void> _dispatchEmergencyAlerts() async {
    _sosState = SosState.dispatched;
    _sosStateController.add(_sosState);

    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      await _audioPlayer.stop();
      Vibration.cancel();
      await WakelockPlus.disable();
    } catch (_) {}

    // 1. Get real GPS fix (never use dummy coordinates)
    double finalLat = _lastLatitude;
    double finalLng = _lastLongitude;
    if (finalLat == 0.0 && finalLng == 0.0) {
      final pos = await LocationService.getBestAvailablePosition(timeout: const Duration(seconds: 4));
      if (pos != null) {
        finalLat = pos.latitude;
        finalLng = pos.longitude;
      }
    }

    final timestamp = DateTime.now();

    // 2. Launch SMS composer with sanitized emergency contact & formatted message
    final result = await SmsService.sendEmergencyAlerts(
      recipients: _lastEmergencyContacts,
      latitude: finalLat,
      longitude: finalLng,
      timestamp: timestamp,
    );

    if (!_smsResultController.isClosed) {
      _smsResultController.add(result);
    }

    // 3. Post Incident to Backend API if coordinates are valid
    if (finalLat != 0.0 && finalLng != 0.0) {
      await ApiService.postIncident(
        userId: _lastUserId,
        latitude: finalLat,
        longitude: finalLng,
        speed: _lastSpeed,
        impactForce: _lastImpactForce,
        time: timestamp,
      );
    }
  }

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
      print('[DemoSosService] Error stopping emergency alarms: $e');
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
