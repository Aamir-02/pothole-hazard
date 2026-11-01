import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/api_service.dart';
import '../services/crash_detection_service.dart';
import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import 'demo_crash_detection_service.dart';
import 'demo_sos_service.dart';
import 'demo_constants.dart';

class DemoState {
  final bool isDemoActive;
  final String statusMessage;
  final int potholeCount;
  final List<Map<String, dynamic>> demoIncidents;

  // Separate Demo Telemetry Values (Continuously Updating)
  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double distanceKm;
  final double totalAccelMs2;
  final double accelG;
  final double gyroRadSec;
  final double latitude;
  final double longitude;
  final bool isUsingHardwareSensors;
  final bool isSimulatingSpeed;

  const DemoState({
    this.isDemoActive = false,
    this.statusMessage = 'Demo Ready',
    this.potholeCount = 0,
    this.demoIncidents = const [],
    this.currentSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.distanceKm = 0.0,
    this.totalAccelMs2 = 9.81,
    this.accelG = 1.0,
    this.gyroRadSec = 0.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isUsingHardwareSensors = false,
    this.isSimulatingSpeed = false,
  });

  DemoState copyWith({
    bool? isDemoActive,
    String? statusMessage,
    int? potholeCount,
    List<Map<String, dynamic>>? demoIncidents,
    double? currentSpeedKmh,
    double? maxSpeedKmh,
    double? distanceKm,
    double? totalAccelMs2,
    double? accelG,
    double? gyroRadSec,
    double? latitude,
    double? longitude,
    bool? isUsingHardwareSensors,
    bool? isSimulatingSpeed,
  }) {
    return DemoState(
      isDemoActive: isDemoActive ?? this.isDemoActive,
      statusMessage: statusMessage ?? this.statusMessage,
      potholeCount: potholeCount ?? this.potholeCount,
      demoIncidents: demoIncidents ?? this.demoIncidents,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      distanceKm: distanceKm ?? this.distanceKm,
      totalAccelMs2: totalAccelMs2 ?? this.totalAccelMs2,
      accelG: accelG ?? this.accelG,
      gyroRadSec: gyroRadSec ?? this.gyroRadSec,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isUsingHardwareSensors: isUsingHardwareSensors ?? this.isUsingHardwareSensors,
      isSimulatingSpeed: isSimulatingSpeed ?? this.isSimulatingSpeed,
    );
  }
}

class DemoModeNotifier extends StateNotifier<DemoState> {
  final Ref _ref;

  SensorService? _sensorService;
  LocationService? _locationService;
  DemoCrashDetectionService? _demoCrashService;
  final DemoSosService demoSosService = DemoSosService();

  StreamSubscription? _sensorSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _detectionSub;
  Timer? _rideTimer;
  DateTime? _lastCrashDispatchTime;

  DemoModeNotifier(this._ref) : super(const DemoState());

  @visibleForTesting
  void setDemoActiveForTesting(bool active) {
    state = state.copyWith(isDemoActive: active);
  }

  /// Start Demo Mode Presentation Session using real device hardware sensors and GPS
  Future<bool> startDemoMode() async {
    if (state.isDemoActive) return true;

    await PermissionService.requestAllPermissions();

    // Clean up any previous subscriptions defensively
    _rideTimer?.cancel();
    _sensorSub?.cancel();
    _locationSub?.cancel();
    _detectionSub?.cancel();
    _sensorService?.stopListening();
    _locationService?.stopTracking();
    _demoCrashService?.dispose();

    _sensorService = SensorService();
    _locationService = LocationService();
    _demoCrashService = DemoCrashDetectionService();

    _sensorService!.startListening();
    await _locationService!.startTracking();

    // Fetch initial GPS fix and sensor readings
    final initialPos = await LocationService.getBestAvailablePosition(timeout: const Duration(seconds: 2));
    final initialSensor = _sensorService?.latestTelemetry ?? SensorTelemetry.empty();
    final initialLocation = _locationService?.latestLocation ?? LocationTelemetry.empty();
    final initialAccel = initialSensor.totalAccel > 0 ? initialSensor.totalAccel : 9.81;

    _lastCrashDispatchTime = null;

    // Start every new demo ride with real initial state:
    // current speed = actual GPS speed (or 0 if unavailable)
    // maximum speed = 0
    // distance = 0
    // pothole count = 0
    state = DemoState(
      isDemoActive: true,
      statusMessage: 'Demo Monitoring Active',
      potholeCount: 0,
      demoIncidents: const [],
      currentSpeedKmh: initialLocation.speedKmh,
      maxSpeedKmh: 0.0,
      distanceKm: 0.0,
      totalAccelMs2: initialAccel,
      accelG: initialAccel / 9.80665,
      gyroRadSec: initialSensor.gyroRotation,
      latitude: initialPos?.latitude ?? 0.0,
      longitude: initialPos?.longitude ?? 0.0,
      isUsingHardwareSensors: true,
      isSimulatingSpeed: false,
    );

    // Ride timer: accumulates distance only when device is physically moving by GPS (> 1.0 km/h)
    _rideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isDemoActive) {
        timer.cancel();
        return;
      }
      if (state.currentSpeedKmh > 1.0) {
        final addedDistance = state.currentSpeedKmh / 3600.0;
        state = state.copyWith(
          distanceKm: state.distanceKm + addedDistance,
        );
      }
    });

    // Listen to REAL phone accelerometer & gyroscope stream
    _sensorSub = _sensorService!.telemetryStream.listen((sensorData) {
      final locData = _locationService?.latestLocation ?? LocationTelemetry.empty();
      final settings = _ref.read(settingsProvider);

      state = state.copyWith(
        totalAccelMs2: sensorData.totalAccel,
        accelG: sensorData.totalAccel / 9.80665,
        gyroRadSec: sensorData.gyroRotation,
        isUsingHardwareSensors: true,
      );

      // Feed real hardware telemetry into ultra-sensitive demo crash detector
      _demoCrashService!.processTelemetry(
        sensor: sensorData,
        location: locData,
        sensitivity: settings.sensitivity,
      );
    });

    // Listen to live phone GPS location and speed stream
    _locationSub = _locationService!.locationStream.listen((locData) {
      double maxSpeed = state.maxSpeedKmh;
      if (locData.speedKmh > maxSpeed) {
        maxSpeed = locData.speedKmh;
      }

      state = state.copyWith(
        currentSpeedKmh: locData.speedKmh,
        maxSpeedKmh: maxSpeed,
        latitude: locData.latitude,
        longitude: locData.longitude,
      );
    });

    // Listen to Demo Crash & Pothole Detection Results
    _detectionSub = _demoCrashService!.resultStream.listen((result) async {
      if (result.isCrash) {
        _handleDemoCrash(result);
      } else if (result.isPothole) {
        _handleDemoPothole(result);
      }
    });

    return true;
  }

  /// Handle detected demo crash
  Future<void> _handleDemoCrash(CrashDetectionResult result) async {
    // Prevent duplicate rapid crash triggers (cooldown of 15 seconds)
    if (_lastCrashDispatchTime != null &&
        DateTime.now().difference(_lastCrashDispatchTime!).inSeconds < 15) {
      return;
    }
    _lastCrashDispatchTime = DateTime.now();

    // Acquire actual real GPS coordinates
    double lat = state.latitude;
    double lng = state.longitude;
    if (lat == 0.0 && lng == 0.0) {
      final pos = await LocationService.getBestAvailablePosition(timeout: const Duration(seconds: 3));
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    }

    state = state.copyWith(
      statusMessage: 'Demo Crash Detected!',
      latitude: lat != 0.0 ? lat : state.latitude,
      longitude: lng != 0.0 ? lng : state.longitude,
      demoIncidents: [
        ...state.demoIncidents,
        {
          'id': 'DEMO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          'time': 'Just now',
          'location': lat != 0.0 ? 'GPS (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})' : 'GPS Locating...',
          'confidence': '100% (Demo)',
          'severity': 'CRITICAL',
          'status': 'DEMO ALERT DISPATCHED',
          'type': DemoConstants.demoCrashType,
          'accelG': '${(result.impactForceMs2 / 9.8).toStringAsFixed(1)}G',
          'gyroRadSec': '${result.gyroRadSec.toStringAsFixed(1)} rad/s',
        }
      ],
    );

    final settings = _ref.read(settingsProvider);
    if (settings.sosEnabled) {
      final contactsState = _ref.read(contactsProvider);
      final contacts = contactsState.contacts.map((c) => c.phone).where((p) => p.isNotEmpty).toList();

      demoSosService.startEmergencySos(
        initialCountdownSeconds: settings.countdownSeconds,
        alarmEnabled: settings.alarmEnabled,
        latitude: lat,
        longitude: lng,
        speed: result.speedKmh,
        impactForce: result.impactForceMs2,
        emergencyContacts: contacts,
        userId: 'demo_presenter',
      );
    }
  }

  /// Handle detected demo pothole
  void _handleDemoPothole(CrashDetectionResult result) {
    final newCount = state.potholeCount + 1;
    state = state.copyWith(
      potholeCount: newCount,
      statusMessage: 'Demo Pothole Detected',
    );

    // Revert status message back after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (state.isDemoActive && state.statusMessage == 'Demo Pothole Detected') {
        state = state.copyWith(
          statusMessage: 'Demo Monitoring Active',
        );
      }
    });

    // Save pothole to backend if GPS coordinates are valid
    if (state.latitude != 0.0 && state.longitude != 0.0) {
      ApiService.postPothole(
        latitude: state.latitude,
        longitude: state.longitude,
        speed: result.speedKmh,
        impactForce: result.impactForceMs2,
        time: result.timestamp,
      );
    }
  }

  /// Explicit test trigger for Demo Pothole (increments pothole count by 1)
  void triggerDemoPothole() {
    if (!state.isDemoActive) return;

    final testResult = CrashDetectionResult(
      isCrash: false,
      isPothole: true,
      impactForceMs2: 16.4,
      gyroRadSec: 0.35,
      speedKmh: state.currentSpeedKmh,
      description: 'DEMO TEST POTHOLE: Impact force 16.4 m/s²',
      timestamp: DateTime.now(),
    );

    _handleDemoPothole(testResult);
  }

  /// Explicit test trigger for Demo Crash (Testing Emergency Alert & SMS)
  Future<void> triggerDemoCrash() async {
    if (!state.isDemoActive) {
      await startDemoMode();
    }

    final testResult = CrashDetectionResult(
      isCrash: true,
      isPothole: false,
      impactForceMs2: 24.8,
      gyroRadSec: 3.2,
      speedKmh: state.currentSpeedKmh,
      description: 'DEMO TEST TRIGGER: Impact 24.8 m/s², Rotation 3.2 rad/s',
      timestamp: DateTime.now(),
    );

    await _handleDemoCrash(testResult);
  }

  /// Stop Demo Mode Presentation Session
  Future<void> stopDemoMode() async {
    _rideTimer?.cancel();
    _rideTimer = null;
    _sensorSub?.cancel();
    _sensorSub = null;
    _locationSub?.cancel();
    _locationSub = null;
    _detectionSub?.cancel();
    _detectionSub = null;

    _sensorService?.stopListening();
    _sensorService = null;
    _locationService?.stopTracking();
    _locationService = null;
    _demoCrashService?.dispose();
    _demoCrashService = null;
    demoSosService.cancelEmergency();

    state = const DemoState(
      isDemoActive: false,
      statusMessage: 'Demo Stopped',
      currentSpeedKmh: 0.0,
      maxSpeedKmh: 0.0,
      distanceKm: 0.0,
      potholeCount: 0,
      isSimulatingSpeed: false,
    );
  }

  @override
  void dispose() {
    stopDemoMode();
    demoSosService.dispose();
    super.dispose();
  }
}

final demoControllerProvider = StateNotifierProvider<DemoModeNotifier, DemoState>((ref) {
  return DemoModeNotifier(ref);
});
