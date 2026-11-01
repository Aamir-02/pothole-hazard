import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel {
  final String sensitivity; // 'low', 'medium', 'high'
  final int countdownSeconds; // 5, 10, 15, 30
  final bool sosEnabled;
  final bool alarmEnabled;
  final bool isDarkMode;
  final String units;

  const SettingsModel({
    this.sensitivity = 'medium',
    this.countdownSeconds = 15,
    this.sosEnabled = true,
    this.alarmEnabled = true,
    this.isDarkMode = true,
    this.units = 'metric',
  });

  SettingsModel copyWith({
    String? sensitivity,
    int? countdownSeconds,
    bool? sosEnabled,
    bool? alarmEnabled,
    bool? isDarkMode,
    String? units,
  }) {
    return SettingsModel(
      sensitivity: sensitivity ?? this.sensitivity,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      sosEnabled: sosEnabled ?? this.sosEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      units: units ?? this.units,
    );
  }
}

class SettingsRepository {
  static const String _keySensitivity = 'pref_sensitivity';
  static const String _keyCountdown = 'pref_countdown';
  static const String _keySosEnabled = 'pref_sos_enabled';
  static const String _keyAlarmEnabled = 'pref_alarm_enabled';
  static const String _keyDarkMode = 'pref_dark_mode';
  static const String _keyUnits = 'pref_units';

  Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsModel(
      sensitivity: prefs.getString(_keySensitivity) ?? 'medium',
      countdownSeconds: prefs.getInt(_keyCountdown) ?? 15,
      sosEnabled: prefs.getBool(_keySosEnabled) ?? true,
      alarmEnabled: prefs.getBool(_keyAlarmEnabled) ?? true,
      isDarkMode: prefs.getBool(_keyDarkMode) ?? true,
      units: prefs.getString(_keyUnits) ?? 'metric',
    );
  }

  Future<void> saveSensitivity(String sensitivity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySensitivity, sensitivity);
  }

  Future<void> saveCountdown(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCountdown, seconds);
  }

  Future<void> saveSosEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySosEnabled, enabled);
  }

  Future<void> saveAlarmEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAlarmEnabled, enabled);
  }

  Future<void> saveDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
  }

  Future<void> saveUnits(String units) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUnits, units);
  }
}
