import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/regime.dart';

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

  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kTheme, mode.name);

  // Onboarding: mostrado uma vez no primeiro uso.
  static const String _kOnboarding = 'onboarding_done';
  bool onboardingDone() => _prefs.getBool(_kOnboarding) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboarding, true);

  // Modo BR x internacional (freela pra gringo). Capturado no onboarding; hoje
  // pré-seleciona o regime na calculadora. 'br' | 'intl'.
  static const String _kModo = 'modo';
  String modo() => _prefs.getString(_kModo) ?? 'br';
  Future<void> setModo(String value) => _prefs.setString(_kModo, value);

  // Regime tributário — da PESSOA, não da área de trabalho.
  //
  // Morava no perfil/área até 19/07/2026, e ali produzia número ERRADO: duas
  // áreas geravam dois DAS pro mesmo CNPJ, enquanto o próprio app dizia em
  // texto que "o imposto do mês é um só". Ninguém é MEI só às terças.
  static const String _kRegime = 'regime';

  RegimeId regime() {
    final String? salvo = _prefs.getString(_kRegime);
    if (salvo != null) {
      for (final RegimeId r in RegimeId.values) {
        if (r.name == salvo) return r;
      }
    }
    // Sem escolha ainda: quem marcou "recebo de fora" no onboarding começa em
    // internacional; o resto começa em MEI, o regime mais comum do público.
    return modo() == 'intl' ? RegimeId.intl : RegimeId.mei;
  }

  Future<void> setRegime(RegimeId value) =>
      _prefs.setString(_kRegime, value.name);

  // Telemetria (analytics/crash) — opt-in de verdade (LGPD + promessa do onboarding
  // "sem enviar seus dados"). Default DESLIGADO; liga só se o usuário aceitar em Config.
  static const String _kTelemetry = 'telemetry_enabled';
  bool telemetryEnabled() => _prefs.getBool(_kTelemetry) ?? false;
  Future<void> setTelemetry(bool value) => _prefs.setBool(_kTelemetry, value);

  // Reduzir transparência: habilita o fallback opaco da navbar (aparelhos mais
  // simples/baixo desempenho). Default DESLIGADO (mantém o visual translúcido).
  static const String _kReduceTransparency = 'reduce_transparency';
  bool reduceTransparency() => _prefs.getBool(_kReduceTransparency) ?? false;
  Future<void> setReduceTransparency(bool v) =>
      _prefs.setBool(_kReduceTransparency, v);

  // Escala de texto: tamanho relativo da fonte. Default 1.0 (100%).
  static const String _kTextScale = 'text_scale';
  double textScale() => _prefs.getDouble(_kTextScale) ?? 1.0;
  Future<void> setTextScale(double v) => _prefs.setDouble(_kTextScale, v);

  // Lembrete de imposto (F7) — notificação mensal. Default DESLIGADO: exige
  // permissão de notificação, então é opt-in explícito no toggle dos Ajustes.
  static const String _kLembrete = 'lembrete_enabled';
  bool lembreteEnabled() => _prefs.getBool(_kLembrete) ?? false;
  Future<void> setLembrete(bool v) => _prefs.setBool(_kLembrete, v);
}
