import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String? _customBaseUrl;

  /// Allows setting custom backend base URL at runtime (e.g. for physical devices on local Wi-Fi)
  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  /// Dynamically determines backend base URL based on environment and platform
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://127.0.0.1:5000/api';
      }
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  static String get socketUrl {
    final base = baseUrl;
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4);
    }
    return base;
  }

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String register = '/auth/register';
  static const String googleLogin = '/auth/google-login';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';

  static const String startRide = '/ride/start';
  static const String stopRide = '/ride/stop';
  static const String rideHistory = '/ride/history';

  static const String createIncident = '/incident';
  static const String cancelIncident = '/incident/cancel';
  static const String incidentHistory = '/incident/history';

  static const String contacts = '/contacts';
  static const String potholes = '/potholes';
  static const String sendSos = '/notifications/send-sos';
}
