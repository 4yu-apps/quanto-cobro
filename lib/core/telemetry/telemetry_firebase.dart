import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'telemetry.dart';

/// O destino REAL da telemetria: Analytics (eventos) + Crashlytics (crash).
///
/// Plugada em `main.dart` no lugar do [TelemetryNoOp] quando o Firebase sobe.
/// Nenhum call site do app muda — todos falam com a interface [Telemetry].
///
/// **Opt-in de verdade (LGPD + promessa do onboarding "sem enviar seus dados"):**
/// desligada por padrão. Enquanto `setHabilitado(true)` não é chamado, nada sai
/// — nem evento nem crash. `setHabilitado` também desliga a coleta no lado
/// nativo, pra a promessa valer mesmo pro que o SDK captura sozinho.
class TelemetryFirebase implements Telemetry {
  TelemetryFirebase(this._analytics, this._crashlytics);

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;
  bool _habilitado = false;

  @override
  void evento(
    String nome, {
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    if (!_habilitado) return;
    // Analytics só aceita String/num como valor de parâmetro. Descarta nulos e
    // coage o resto pra String — a regra de baixa cardinalidade mora no
    // eventos.dart, aqui é só o piso de tipo.
    final Map<String, Object> p = <String, Object>{
      for (final MapEntry<String, Object?> e in params.entries)
        if (e.value != null) e.key: e.value is num ? e.value! : e.value.toString(),
    };
    _analytics.logEvent(name: nome, parameters: p.isEmpty ? null : p);
  }

  @override
  void erro(Object error, StackTrace? stack, {bool fatal = false}) {
    // Sem consentimento, o stack trace (que pode conter caminho de arquivo) não
    // sai — mesma regra do no-op.
    if (!_habilitado) return;
    _crashlytics.recordError(error, stack, fatal: fatal);
  }

  @override
  Future<void> setHabilitado(bool value) async {
    _habilitado = value;
    await _analytics.setAnalyticsCollectionEnabled(value);
    await _crashlytics.setCrashlyticsCollectionEnabled(value);
  }
}
