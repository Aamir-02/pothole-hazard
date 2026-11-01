import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class WeatherData {
  final double temperatureC;
  final double humidity;
  final double windSpeedKmh;
  final int weatherCode;
  final String condition;
  final String roadCondition;
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperatureC,
    required this.humidity,
    required this.windSpeedKmh,
    required this.weatherCode,
    required this.condition,
    required this.roadCondition,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });

  static String mapWeatherCodeToCondition(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1) return 'Mainly Clear';
    if (code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Cloudy';
  }

  static String mapWeatherCodeToRoadCondition(int code) {
    if (code >= 51 && code <= 99) {
      return 'Wet Surface - Caution';
    }
    if (code == 45 || code == 48) {
      return 'Foggy - Low Visibility';
    }
    return 'Dry Surface';
  }
}

class WeatherService {
  /// Fetches real-time weather using exact GPS coordinates without exposing private API keys
  static Future<WeatherData?> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    // 1. First attempt via backend proxy
    try {
      final backendRes = await ApiClient.get('/weather?lat=$latitude&lng=$longitude');
      if (backendRes is Map<String, dynamic> && backendRes['success'] == true && backendRes['data'] != null) {
        final parsed = _parseOpenMeteoJson(
          Map<String, dynamic>.from(backendRes['data'] as Map),
          latitude,
          longitude,
        );
        if (parsed != null) return parsed;
      }
    } catch (_) {}

    // 2. Direct fallback to Open-Meteo (open, free, no secret key required)
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
          return _parseOpenMeteoJson(json, latitude, longitude);
        }
      }
    } catch (e) {
      print('[WeatherService] Error fetching weather: $e');
    }

    return null;
  }

  static WeatherData? _parseOpenMeteoJson(Map<String, dynamic> json, double lat, double lng) {
    try {
      final current = json['current'];
      if (current is! Map<String, dynamic>) return null;

      final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
      final hum = (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0;
      final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
      final code = (current['weather_code'] as num?)?.toInt() ?? 0;

      return WeatherData(
        temperatureC: temp,
        humidity: hum,
        windSpeedKmh: wind,
        weatherCode: code,
        condition: WeatherData.mapWeatherCodeToCondition(code),
        roadCondition: WeatherData.mapWeatherCodeToRoadCondition(code),
        latitude: lat,
        longitude: lng,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      print('[WeatherService] Parsing error: $e');
      return null;
    }
  }
}
