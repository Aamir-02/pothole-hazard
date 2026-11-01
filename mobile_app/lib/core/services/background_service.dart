import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'sensor_service.dart';
import 'location_service.dart';
import 'crash_detection_service.dart';

class BackgroundRideService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Initialize and start background foreground service
  static Future<void> initializeService() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pothole_hazard_foreground',
      'Pothole Hazard Service',
      description: 'Continuous motorcycle crash and pothole detection service',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'pothole_hazard_foreground',
        initialNotificationTitle: 'Pothole Hazard',
        initialNotificationContent: 'Monitoring Ride...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start background service
  static Future<void> startService() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
    }
  }

  /// Stop background service
  static Future<void> stopService() async {
    final isRunning = await _service.isRunning();
    if (isRunning) {
      _service.invoke('stopService');
    }
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final sensorService = SensorService();
    final locationService = LocationService();
    final crashDetectionService = CrashDetectionService();

    sensorService.startListening();
    await locationService.startTracking();

    StreamSubscription? sensorSub;
    StreamSubscription? crashSub;

    sensorSub = sensorService.telemetryStream.listen((sensorData) {
      final locData = locationService.latestLocation;
      crashDetectionService.processTelemetry(
        sensor: sensorData,
        location: locData,
        sensitivity: 'medium',
      );

      // Send telemetry updates to main app if open
      service.invoke('updateTelemetry', {
        'totalAccel': sensorData.totalAccel,
        'gyroRotation': sensorData.gyroRotation,
        'speedKmh': locData.speedKmh,
        'latitude': locData.latitude,
        'longitude': locData.longitude,
      });
    });

    crashSub = crashDetectionService.resultStream.listen((result) {
      if (result.isCrash) {
        service.invoke('crashDetected', {
          'impactForceMs2': result.impactForceMs2,
          'gyroRadSec': result.gyroRadSec,
          'speedKmh': result.speedKmh,
          'description': result.description,
        });
      } else if (result.isPothole) {
        service.invoke('potholeDetected', {
          'impactForceMs2': result.impactForceMs2,
          'gyroRadSec': result.gyroRadSec,
          'speedKmh': result.speedKmh,
        });
      }
    });

    service.on('stopService').listen((event) {
      sensorSub?.cancel();
      crashSub?.cancel();
      sensorService.dispose();
      locationService.dispose();
      crashDetectionService.dispose();
      service.stopSelf();
    });
  }
}
