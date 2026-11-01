import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';

class WeatherState {
  final bool isLoading;
  final WeatherData? weather;
  final String? errorMessage;
  final DateTime? lastChecked;

  const WeatherState({
    this.isLoading = false,
    this.weather,
    this.errorMessage,
    this.lastChecked,
  });

  WeatherState copyWith({
    bool? isLoading,
    WeatherData? weather,
    String? errorMessage,
    DateTime? lastChecked,
  }) {
    return WeatherState(
      isLoading: isLoading ?? this.isLoading,
      weather: weather ?? this.weather,
      errorMessage: errorMessage,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  Timer? _periodicRefreshTimer;

  WeatherNotifier() : super(const WeatherState()) {
    refreshWeather();
    // Refresh periodically every 20 minutes without continuous battery-draining polling
    _periodicRefreshTimer = Timer.periodic(const Duration(minutes: 20), (_) {
      refreshWeather();
    });
  }

  /// Refreshes local weather using the phone's actual current GPS location
  Future<void> refreshWeather({bool force = false}) async {
    // Check in-memory cache to prevent excessive requests
    if (!force && state.weather != null && state.lastChecked != null) {
      final elapsed = DateTime.now().difference(state.lastChecked!);
      if (elapsed.inMinutes < 20) {
        return; // Valid cache within 20 minutes
      }
    }

    state = state.copyWith(isLoading: state.weather == null);

    try {
      // 1. Fetch current position with reasonable timeout
      final position = await LocationService.getBestAvailablePosition(
        timeout: const Duration(seconds: 4),
      );

      if (position == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Weather unavailable (Location disabled)',
          lastChecked: DateTime.now(),
        );
        return;
      }

      // 2. Fetch real weather for coordinates
      final weather = await WeatherService.fetchWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (weather != null) {
        state = WeatherState(
          isLoading: false,
          weather: weather,
          errorMessage: null,
          lastChecked: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Weather unavailable (Network/API error)',
          lastChecked: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Weather unavailable',
        lastChecked: DateTime.now(),
      );
    }
  }

  @override
  void dispose() {
    _periodicRefreshTimer?.cancel();
    super.dispose();
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});
