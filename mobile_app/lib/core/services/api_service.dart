import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Post Incident to backend API
  /// POST /api/incidents
  /// Body: { userId, latitude, longitude, speed, impactForce, time }
  static Future<bool> postIncident({
    required String userId,
    required double latitude,
    required double longitude,
    required double speed,
    required double impactForce,
    required DateTime time,
  }) async {
    final body = {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'impactForce': impactForce,
      'time': time.toIso8601String(),
    };

    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/incidents'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('[ApiService] Successfully posted incident to backend: ${response.statusCode}');
        return true;
      } else {
        print('[ApiService] Failed to post incident: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('[ApiService] Network error posting incident: $e');
      return false;
    }
  }

  /// Post Pothole incident to backend API
  /// POST /api/potholes
  /// Body: { latitude, longitude, speed, impactForce, time }
  static Future<bool> postPothole({
    required double latitude,
    required double longitude,
    required double speed,
    required double impactForce,
    required DateTime time,
  }) async {
    final body = {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'impactForce': impactForce,
      'time': time.toIso8601String(),
    };

    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/potholes'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('[ApiService] Successfully logged pothole: ${response.statusCode}');
        return true;
      } else {
        print('[ApiService] Failed to log pothole: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('[ApiService] Network error posting pothole: $e');
      return false;
    }
  }
}
