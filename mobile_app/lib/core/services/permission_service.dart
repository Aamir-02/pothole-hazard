import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all permissions automatically at startup or when starting a ride
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.sms,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
      Permission.activityRecognition,
      Permission.systemAlertWindow,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    for (var entry in statuses.entries) {
      print('[PermissionService] ${entry.key}: ${entry.value}');
    }

    return statuses;
  }

  /// Check if essential monitoring permissions are granted
  static Future<bool> hasEssentialPermissions() async {
    final loc = await Permission.location.isGranted;
    final sms = await Permission.sms.isGranted;
    return loc && sms;
  }
}
