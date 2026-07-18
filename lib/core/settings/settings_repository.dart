import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings locais (tema, etc.). O ESCURO é o padrão (Design System §3).
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _kTheme = 'theme_mode';

  ThemeMode themeMode() {
    switch (_prefs.getString(_kTheme)) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_kTheme, mode.name);
}
