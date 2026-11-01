import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import '../services/crash_detection_service.dart';
import '../services/emergency_service.dart';
import '../services/background_service.dart';
import '../services/api_service.dart';
import '../services/api_client.dart';
import '../constants/api_constants.dart';
import '../services/permission_service.dart';
import 'contacts_provider.dart';
import 'settings_provider.dart';

class RideState {
  final bool isRiding;
  final bool isSaving;
  final RideStatus rideStatus; // idle, monitoring, safe, potholeDetected, crashDetected
  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double distanceKm;
  final int rideTimeSeconds;
  final double totalAccelMs2;
  final double accelG;
  final double gyroRadSec;
  final double latitude;
  final double longitude;
  final int potholeCount;
  final CrashDetectionResult? lastCrashResult;
  final String statusMessage;
  final String? activeRideId;
  final DateTime? rideStartTime;
  final String? saveMessage;
  final bool? saveSuccess;

  const RideState({
    this.isRiding = false,
    this.isSaving = false,
    this.rideStatus = RideStatus.idle,
    this.currentSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.distanceKm = 0.0,
    this.rideTimeSeconds = 0,
    this.totalAccelMs2 = 9.81,
    this.accelG = 1.0,
    this.gyroRadSec = 0.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.potholeCount = 0,
    this.lastCrashResult,
    this.statusMessage = 'Safe',
    this.activeRideId,
    this.rideStartTime,
    this.saveMessage,
    this.saveSuccess,
  });

  RideState copyWith({
    bool? isRiding,
    bool? isSaving,
    RideStatus? rideStatus,
    double? currentSpeedKmh,
    double? maxSpeedKmh,
    double? distanceKm,
    int? rideTimeSeconds,
    double? totalAccelMs2,
    double? accelG,
    double? gyroRadSec,
    double? latitude,
    double? longitude,
    int? potholeCount,
    CrashDetectionResult? lastCrashResult,
    String? statusMessage,
    String? activeRideId,
    DateTime? rideStartTime,
    String? saveMessage,
    bool? saveSuccess,
  }) {
    return RideState(
      isRiding: isRiding ?? this.isRiding,
      isSaving: isSaving ?? this.isSaving,
      rideStatus: rideStatus ?? this.rideStatus,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      distanceKm: distanceKm ?? this.distanceKm,
      rideTimeSeconds: rideTimeSeconds ?? this.rideTimeSeconds,
      totalAccelMs2: totalAccelMs2 ?? this.totalAccelMs2,
      accelG: accelG ?? this.accelG,
      gyroRadSec: gyroRadSec ?? this.gyroRadSec,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      potholeCount: potholeCount ?? this.potholeCount,
      lastCrashResult: lastCrashResult ?? this.lastCrashResult,
      statusMessage: statusMessage ?? this.statusMessage,
      activeRideId: activeRideId ?? this.activeRideId,
      rideStartTime: rideStartTime ?? this.rideStartTime,
      saveMessage: saveMessage ?? this.saveMessage,
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}

class RideNotifier extends StateNotifier<RideState> {
  final Ref _ref;

  SensorService? _sensorService;
  LocationService? _locationService;
  CrashDetectionService? _crashDetectionService;
  final EmergencyService _emergencyService = EmergencyService();

  StreamSubscription? _sensorSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _detectionSub;
  Timer? _rideTimer;

  String? _currentBackendRideId;
  DateTime? _rideStartTime;
  final List<Map<String, dynamic>> _routePoints = [];
  bool _isSavingRide = false;

  RideNotifier(this._ref) : super(const RideState());

  EmergencyService get emergencyService => _emergencyService;

  /// Start Ride Monitoring
  Future<bool> startRide({void Function()? onCrashDetected}) async {
    if (state.isRiding) return true;

    // Check permissions
    await PermissionService.requestAllPermissions();

    _sensorService = SensorService();
    _locationService = LocationService();
    _crashDetectionService = CrashDetectionService();

    // Start services
    _sensorService!.startListening();
    final locSuccess = await _locationService!.startTracking();
    if (!locSuccess) {
      print('[RideNotifier] Could not start location service.');
    }

    // Start background service
    try {
      await BackgroundRideService.startService();
    } catch (e) {
      print('[RideNotifier] Background service start error: $e');
    }

    _rideStartTime = DateTime.now();
    _routePoints.clear();
    _currentBackendRideId = null;
    _isSavingRide = false;

    state = state.copyWith(
      isRiding: true,
      isSaving: false,
      rideStatus: RideStatus.monitoring,
      statusMessage: 'Monitoring',
      rideTimeSeconds: 0,
      distanceKm: 0.0,
      maxSpeedKmh: 0.0,
      currentSpeedKmh: 0.0,
      potholeCount: 0,
      rideStartTime: _rideStartTime,
      activeRideId: null,
      saveMessage: null,
      saveSuccess: null,
    );

    // Register fresh ride session with backend API
    _registerBackendRide();

    // Ride timer
    _rideTimer?.cancel();
    _rideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isRiding) {
        timer.cancel();
        return;
      }
      final newTime = state.rideTimeSeconds + 1;
      // Only accumulate distance when moving (speed > 1.0 km/h)
      double addedDistance = 0.0;
      if (state.currentSpeedKmh > 1.0) {
        addedDistance = (state.currentSpeedKmh / 3600.0);
      }
      state = state.copyWith(
        rideTimeSeconds: newTime,
        distanceKm: state.distanceKm + addedDistance,
      );
    });

    // Listen to Sensor telemetry
    _sensorSub = _sensorService!.telemetryStream.listen((sensorData) {
      final settings = _ref.read(settingsProvider);
      final locData = _locationService?.latestLocation ?? LocationTelemetry.empty();

      state = state.copyWith(
        totalAccelMs2: sensorData.totalAccel,
        accelG: sensorData.totalAccel / 9.80665,
        gyroRadSec: sensorData.gyroRotation,
      );

      // Process crash & pothole detection algorithm
      _crashDetectionService!.processTelemetry(
        sensor: sensorData,
        location: locData,
        sensitivity: settings.sensitivity,
      );
    });

    // Listen to Location telemetry
    _locationSub = _locationService!.locationStream.listen((locData) {
      double maxSpeed = state.maxSpeedKmh;
      if (locData.speedKmh > maxSpeed) {
        maxSpeed = locData.speedKmh;
      }

      // Collect GPS route points for route replay
      if (locData.latitude != 0.0 && locData.longitude != 0.0) {
        if (_routePoints.length < 500) {
          _routePoints.add({
            'latitude': locData.latitude,
            'longitude': locData.longitude,
            'speedKmh': locData.speedKmh,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }

      state = state.copyWith(
        currentSpeedKmh: locData.speedKmh,
        maxSpeedKmh: maxSpeed,
        latitude: locData.latitude,
        longitude: locData.longitude,
      );
    });

    // Listen to Crash & Pothole Detection Results
    _detectionSub = _crashDetectionService!.resultStream.listen((result) async {
      if (result.isCrash) {
        state = state.copyWith(
          rideStatus: RideStatus.crashDetected,
          statusMessage: 'Crash Detected',
          lastCrashResult: result,
        );

        if (onCrashDetected != null) {
          onCrashDetected();
        }

        // Trigger SOS Countdown if SOS is enabled in Settings
        final settings = _ref.read(settingsProvider);
        if (settings.sosEnabled) {
          final contactsState = _ref.read(contactsProvider);
          final contacts = contactsState.contacts.map((c) => c.phone).where((p) => p.isNotEmpty).toList();

          _emergencyService.startEmergencySos(
            initialCountdownSeconds: settings.countdownSeconds,
            alarmEnabled: settings.alarmEnabled,
            latitude: state.latitude,
            longitude: state.longitude,
            speed: result.speedKmh,
            impactForce: result.impactForceMs2,
            emergencyContacts: contacts,
            userId: 'rider_main',
          );
        }
      } else if (result.isPothole) {
        final newCount = state.potholeCount + 1;
        state = state.copyWith(
          rideStatus: RideStatus.potholeDetected,
          statusMessage: 'Pothole Detected',
          potholeCount: newCount,
        );

        // Store pothole in backend API (Do NOT trigger SOS)
        ApiService.postPothole(
          latitude: state.latitude,
          longitude: state.longitude,
          speed: result.speedKmh,
          impactForce: result.impactForceMs2,
          time: result.timestamp,
        );

        // Reset status message back to Monitoring after 3 seconds
        Timer(const Duration(seconds: 3), () {
          if (state.isRiding && state.rideStatus == RideStatus.potholeDetected) {
            state = state.copyWith(
              rideStatus: RideStatus.monitoring,
              statusMessage: 'Monitoring',
            );
          }
        });
      }
    });

    return true;
  }

  /// Register new ride session with backend
  Future<void> _registerBackendRide() async {
    try {
      final loc = _locationService?.latestLocation;
      final Map<String, dynamic> body = {};
      if (loc != null && loc.latitude != 0.0 && loc.longitude != 0.0) {
        body['initialPoint'] = {
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'speedKmh': loc.speedKmh,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      final res = await ApiClient.post(ApiConstants.startRide, body);
      if (res is Map<String, dynamic> && res['success'] == true && res['ride'] != null) {
        _currentBackendRideId = res['ride']['_id']?.toString();
        state = state.copyWith(activeRideId: _currentBackendRideId);
        print('[RideNotifier] Fresh ride session registered in backend: $_currentBackendRideId');
      }
    } catch (e) {
      print('[RideNotifier] Backend session init error (offline ride mode active): $e');
    }
  }

  /// Stop Ride Monitoring and persist to backend Ride History
  Future<Map<String, dynamic>> stopRide() async {
    if (_isSavingRide) {
      return {'success': false, 'message': 'Ride save is already in progress'};
    }
    _isSavingRide = true;

    state = state.copyWith(
      isSaving: true,
      statusMessage: 'Saving ride...',
    );

    _rideTimer?.cancel();
    _rideTimer = null;

    _sensorSub?.cancel();
    _locationSub?.cancel();
    _detectionSub?.cancel();

    _sensorService?.stopListening();
    _locationService?.stopTracking();
    _crashDetectionService?.dispose();
    _emergencyService.cancelEmergency();

    try {
      await BackgroundRideService.stopService();
    } catch (e) {
      print('[RideNotifier] Background service stop error: $e');
    }

    // Compute actual ride metrics (no fabricated numbers)
    final durationMinutes = (state.rideTimeSeconds / 60).ceil();
    final distanceKm = double.parse(state.distanceKm.toStringAsFixed(2));
    final maxSpeedKmh = double.parse(state.maxSpeedKmh.toStringAsFixed(1));
    final avgSpeedKmh = distanceKm > 0 && durationMinutes > 0
        ? double.parse((distanceKm / (durationMinutes / 60.0)).toStringAsFixed(1))
        : 0.0;
    final potholesCount = state.potholeCount;

    bool saveSuccess = false;
    String saveMessage = '';

    try {
      final response = await ApiClient.post(ApiConstants.stopRide, {
        if (_currentBackendRideId != null && _currentBackendRideId!.isNotEmpty)
          'rideId': _currentBackendRideId,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'avgSpeedKmh': avgSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'potholesCount': potholesCount,
        if (_routePoints.isNotEmpty) 'routePoints': _routePoints,
      });

      if (response is Map<String, dynamic> && (response['success'] == true || response['ride'] != null)) {
        saveSuccess = true;
        saveMessage = 'Ride saved successfully to Ride History!';
        print('[RideNotifier] Ride successfully saved to backend database.');
      } else {
        saveSuccess = false;
        final err = response is Map<String, dynamic>
            ? (response['message'] ?? 'Backend error')
            : 'Failed to communicate with backend';
        saveMessage = 'Failed to save ride: $err';
        print('[RideNotifier] Failed to save ride: $saveMessage');
      }
    } catch (e) {
      saveSuccess = false;
      saveMessage = 'Network error saving ride: ${e.toString()}';
      print('[RideNotifier] Network error: $e');
    } finally {
      _isSavingRide = false;
    }

    state = state.copyWith(
      isRiding: false,
      isSaving: false,
      rideStatus: RideStatus.idle,
      statusMessage: saveSuccess ? 'Safe' : 'Save Failed',
      saveSuccess: saveSuccess,
      saveMessage: saveMessage,
    );

    return {
      'success': saveSuccess,
      'message': saveMessage,
    };
  }

  /// Manual simulation trigger for user testing
  void simulateCrashEvent({required void Function() onCrashDetected}) {
    state = state.copyWith(
      rideStatus: RideStatus.crashDetected,
      statusMessage: 'Crash Detected',
    );

    onCrashDetected();

    final settings = _ref.read(settingsProvider);
    if (settings.sosEnabled) {
      final contactsState = _ref.read(contactsProvider);
      final contacts = contactsState.contacts.map((c) => c.phone).where((p) => p.isNotEmpty).toList();

      _emergencyService.startEmergencySos(
        initialCountdownSeconds: settings.countdownSeconds,
        alarmEnabled: settings.alarmEnabled,
        latitude: state.latitude,
        longitude: state.longitude,
        speed: state.currentSpeedKmh > 0 ? state.currentSpeedKmh : 42.0,
        impactForce: 34.5,
        emergencyContacts: contacts,
        userId: 'rider_main',
      );
    }
  }

  @override
  void dispose() {
    stopRide();
    _emergencyService.dispose();
    super.dispose();
  }
}

final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  return RideNotifier(ref);
});
