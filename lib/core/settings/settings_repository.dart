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

  // Onboarding: mostrado uma vez no primeiro uso.
  static const String _kOnboarding = 'onboarding_done';
  bool onboardingDone() => _prefs.getBool(_kOnboarding) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboarding, true);

  // Telemetria (analytics/crash) — opt-in de verdade (LGPD + promessa do onboarding
  // "sem enviar seus dados"). Default DESLIGADO; liga só se o usuário aceitar em Config.
  static const String _kTelemetry = 'telemetry_enabled';
  bool telemetryEnabled() => _prefs.getBool(_kTelemetry) ?? false;
  Future<void> setTelemetry(bool value) => _prefs.setBool(_kTelemetry, value);
}
