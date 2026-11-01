import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const SettingsModel()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _repository.loadSettings();
    state = settings;
  }

  Future<void> setSensitivity(String value) async {
    state = state.copyWith(sensitivity: value);
    await _repository.saveSensitivity(value);
  }

  Future<void> setCountdownSeconds(int value) async {
    state = state.copyWith(countdownSeconds: value);
    await _repository.saveCountdown(value);
  }

  Future<void> setSosEnabled(bool value) async {
    state = state.copyWith(sosEnabled: value);
    await _repository.saveSosEnabled(value);
  }

  Future<void> setAlarmEnabled(bool value) async {
    state = state.copyWith(alarmEnabled: value);
    await _repository.saveAlarmEnabled(value);
  }

  Future<void> toggleDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    await _repository.saveDarkMode(value);
  }

  Future<void> setUnits(String value) async {
    state = state.copyWith(units: value);
    await _repository.saveUnits(value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});
