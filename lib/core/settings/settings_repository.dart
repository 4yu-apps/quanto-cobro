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

  // Reserva: uma troca pontual de regime fica nesta sessão de trabalho, mas é
  // ignorada automaticamente se o regime-base do trabalho mudar.
  static const String _kReservaRegimes = 'reserva_regimes';

  String? reservaRegime(String trabalhoId, String regimeBase) {
    return (_prefs.getStringList(_kReservaRegimes) ?? <String>[])
        .cast<String>()
        .where((String item) => item.startsWith('$trabalhoId|$regimeBase|'))
        .map((String item) => item.split('|').last)
        .firstOrNull;
  }

  Future<void> setReservaRegime(
    String trabalhoId,
    String regimeBase,
    String regime,
  ) {
    final List<String> items =
        (_prefs.getStringList(_kReservaRegimes) ?? <String>[])
            .where((String item) => !item.startsWith('$trabalhoId|'))
            .toList();
    items.add('$trabalhoId|$regimeBase|$regime');
    return _prefs.setStringList(_kReservaRegimes, items);
  }

  // Lembrete mensal: avisa no Painel quando um trabalho "mensal" ainda não
  // teve renda registrada no mês. Default LIGADO (é o comportamento seguro
  // pra quem depende de renda recorrente não esquecer de registrar).
  static const String _kReminderMensal = 'reminder_mensal';
  bool reminderMensal() => _prefs.getBool(_kReminderMensal) ?? true;
  Future<void> setReminderMensal(bool v) =>
      _prefs.setBool(_kReminderMensal, v);

  // "Paguei o Leão deste mês" — quitação mensal do loop da reserva (P1-7).
  // Guardado como lista de meses 'yyyy-MM'.
  static const String _kLeaoPago = 'leao_pago_meses';
  static String _mesKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  bool leaoPago(DateTime mes) =>
      (_prefs.getStringList(_kLeaoPago) ?? <String>[]).contains(_mesKey(mes));

  Future<void> setLeaoPago(DateTime mes, bool pago) {
    final Set<String> meses = (_prefs.getStringList(_kLeaoPago) ?? <String>[])
        .toSet();
    if (pago) {
      meses.add(_mesKey(mes));
    } else {
      meses.remove(_mesKey(mes));
    }
    return _prefs.setStringList(_kLeaoPago, meses.toList()..sort());
  }
}
