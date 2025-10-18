import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings {
  final ThemeMode mode;
  final Color seedColor;

  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.seedColor = const Color(0xFF5260FF),
  });

  ThemeSettings copyWith({ThemeMode? mode, Color? seedColor}) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._();

  ThemeManager._();

  ThemeSettings _settings = const ThemeSettings();
  SharedPreferences? _prefs;

  ThemeSettings get settings => _settings;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final modeIndex = _prefs?.getInt(_modeKey);
    final seedValue = _prefs?.getInt(_seedKey);

    _settings = ThemeSettings(
      mode: _themeModeFromIndex(modeIndex) ?? const ThemeSettings().mode,
      seedColor: seedValue != null ? Color(seedValue) : const ThemeSettings().seedColor,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _settings.mode) return;
    _settings = _settings.copyWith(mode: mode);
    await _prefs?.setInt(_modeKey, mode.index);
    notifyListeners();
  }

  Future<void> setSeedColor(Color color) async {
    if (color.value == _settings.seedColor.value) return;
    _settings = _settings.copyWith(seedColor: color);
    await _prefs?.setInt(_seedKey, color.value);
    notifyListeners();
  }

  ThemeMode? _themeModeFromIndex(int? index) {
    if (index == null) return null;
    for (final mode in ThemeMode.values) {
      if (mode.index == index) return mode;
    }
    return null;
  }

  static const String _modeKey = 'theme_mode';
  static const String _seedKey = 'theme_seed_color';
}