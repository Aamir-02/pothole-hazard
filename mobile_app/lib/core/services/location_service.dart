import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationTelemetry {
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double accuracy;
  final double altitude;
  final DateTime timestamp;

  LocationTelemetry({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.accuracy,
    required this.altitude,
    required this.timestamp,
  });

  factory LocationTelemetry.empty() {
    return LocationTelemetry(
      latitude: 0.0,
      longitude: 0.0,
      speedKmh: 0.0,
      accuracy: 0.0,
      altitude: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<LocationTelemetry>.broadcast();
  Stream<LocationTelemetry> get locationStream => _locationController.stream;

  LocationTelemetry _latestLocation = LocationTelemetry.empty();
  LocationTelemetry get latestLocation => _latestLocation;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  /// Check and request location permissions (Foreground and Background)
  static Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Try requesting background location permission if fine location is granted
    final bgStatus = await Permission.locationAlways.status;
    if (bgStatus.isDenied) {
      await Permission.locationAlways.request();
    }

    return true;
  }

  /// Start high-accuracy GPS tracking
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return false;

    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // update on 1 meter movement
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final speedKmh = position.speed < 0 ? 0.0 : (position.speed * 3.6);
      final telemetry = LocationTelemetry(
        latitude: position.latitude,
        longitude: position.longitude,
        speedKmh: speedKmh,
        accuracy: position.accuracy,
        altitude: position.altitude,
        timestamp: DateTime.now(),
      );

      _latestLocation = telemetry;
      if (!_locationController.isClosed) {
        _locationController.add(telemetry);
      }
    }, onError: (error) {
      print('[LocationService] Location stream error: $error');
    });

    return true;
  }

  /// Get best available GPS coordinates with timeout and lastKnownPosition fallback
  static Future<Position?> getBestAvailablePosition({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      final hasPerm = await checkAndRequestPermissions();
      if (!hasPerm) return null;

      // Check last known position first for quick availability
      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && DateTime.now().difference(lastKnown.timestamp).inSeconds < 30) {
          return lastKnown;
        }
      } catch (_) {}

      // Attempt fresh high-accuracy position with strict timeout
      try {
        final freshPos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: timeout,
          ),
        );
        return freshPos;
      } catch (_) {
        // Return cached position if fresh acquisition timed out
        return lastKnown;
      }
    } catch (e) {
      print('[LocationService] Error fetching best available position: $e');
      return null;
    }
  }

  /// Get quick one-time position
  static Future<Position?> getCurrentPosition() async {
    return getBestAvailablePosition();
  }

  /// Stop position tracking
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
