import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static dynamic _processResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return body;
        } else {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': body['message'] ?? 'Request failed (${response.statusCode})',
            ...body,
          };
        }
      }
      return {'success': response.statusCode >= 200 && response.statusCode < 300, 'data': body};
    } catch (_) {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': 'Server returned an invalid response (${response.statusCode}).',
      };
    }
  }

  static Map<String, dynamic> _handleNetworkError(Object error) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('timeout')) {
      return {
        'success': false,
        'message': 'Connection timed out. The server took too long to respond.',
      };
    }
    if (errStr.contains('socketexception') || errStr.contains('connection refused') || errStr.contains('failed host lookup')) {
      return {
        'success': false,
        'message': 'Unable to connect to the backend server. Please make sure the backend is running.',
      };
    }
    return {
      'success': false,
      'message': 'Network communication error: ${error.toString()}',
    };
  }
}
