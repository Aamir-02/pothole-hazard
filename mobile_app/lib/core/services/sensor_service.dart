import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorTelemetry {
  final double accelX;
  final double accelY;
  final double accelZ;
  final double totalAccel; // sqrt(x² + y² + z²)
  final double netAccelSpike; // |totalAccel - 9.81|
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double gyroRotation; // sqrt(gx² + gy² + gz²)
  final DateTime timestamp;

  SensorTelemetry({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.totalAccel,
    required this.netAccelSpike,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.gyroRotation,
    required this.timestamp,
  });

  factory SensorTelemetry.empty() {
    return SensorTelemetry(
      accelX: 0.0,
      accelY: 0.0,
      accelZ: 9.81,
      totalAccel: 9.81,
      netAccelSpike: 0.0,
      gyroX: 0.0,
      gyroY: 0.0,
      gyroZ: 0.0,
      gyroRotation: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  double _currentAccelX = 0.0;
  double _currentAccelY = 0.0;
  double _currentAccelZ = 9.81;

  double _currentGyroX = 0.0;
  double _currentGyroY = 0.0;
  double _currentGyroZ = 0.0;

  Timer? _samplingTimer;

  final _telemetryController = StreamController<SensorTelemetry>.broadcast();
  Stream<SensorTelemetry> get telemetryStream => _telemetryController.stream;

  SensorTelemetry _latestTelemetry = SensorTelemetry.empty();
  SensorTelemetry get latestTelemetry => _latestTelemetry;

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Start reading sensors every 50 ms
  void startListening() {
    if (_isListening) return;
    _isListening = true;

    // Listen to accelerometer
    _accelSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen((AccelerometerEvent event) {
      _currentAccelX = event.x;
      _currentAccelY = event.y;
      _currentAccelZ = event.z;
    }, onError: (error) {
      print('[SensorService] Accelerometer error: $error');
    });

    // Listen to gyroscope
    _gyroSubscription = gyroscopeEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen((GyroscopeEvent event) {
      _currentGyroX = event.x;
      _currentGyroY = event.y;
      _currentGyroZ = event.z;
    }, onError: (error) {
      print('[SensorService] Gyroscope error: $error');
    });

    // Enforce strict 50 ms sampling rate (20 Hz)
    _samplingTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final totalAccel = sqrt(
        _currentAccelX * _currentAccelX +
        _currentAccelY * _currentAccelY +
        _currentAccelZ * _currentAccelZ,
      );
      final netAccelSpike = (totalAccel - 9.81).abs();
      final gyroRotation = sqrt(
        _currentGyroX * _currentGyroX +
        _currentGyroY * _currentGyroY +
        _currentGyroZ * _currentGyroZ,
      );

      final telemetry = SensorTelemetry(
        accelX: _currentAccelX,
        accelY: _currentAccelY,
        accelZ: _currentAccelZ,
        totalAccel: totalAccel,
        netAccelSpike: netAccelSpike,
        gyroX: _currentGyroX,
        gyroY: _currentGyroY,
        gyroZ: _currentGyroZ,
        gyroRotation: gyroRotation,
        timestamp: DateTime.now(),
      );

      _latestTelemetry = telemetry;
      if (!_telemetryController.isClosed) {
        _telemetryController.add(telemetry);
      }
    });
  }

  /// Stop reading sensors
  void stopListening() {
    _isListening = false;
    _samplingTimer?.cancel();
    _samplingTimer = null;
    _accelSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }

  void dispose() {
    stopListening();
    _telemetryController.close();
  }
}
