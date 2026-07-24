import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/lembrete/lembrete.dart';
import 'core/providers.dart';
import 'core/settings/settings_repository.dart';
import 'core/telemetry/telemetry.dart';
import 'core/telemetry/telemetry_firebase.dart';

Future<void> main() async {
  // A captura de erros é a PRIMEIRA coisa: erro no próprio boot (prefs
  // corrompido, plugin faltando) é justamente o que derruba o app antes de
  // qualquer tela — e era o que a gente não teria como ver.
  await rodarComCapturaDeErros(() async {
    WidgetsFlutterBinding.ensureInitialized();
    instalarCapturaDeErros();

    // Local-first: roda 100% offline, sem login. Carrega os settings/perfil do
    // aparelho no boot.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Firebase é o destino real da telemetria. DEFENSIVO: se o init falhar
    // (config ausente, plugin), fica no no-op e o app SOBE — crash no boot é o
    // pior lugar pra decepcionar, e foi o que o MobileAdsInitProvider já causou.
    try {
      await Firebase.initializeApp();
      telemetry = TelemetryFirebase(
        FirebaseAnalytics.instance,
        FirebaseCrashlytics.instance,
      );
    } catch (e, s) {
      // Segue no TelemetryNoOp; em debug o erro aparece no log local.
      telemetry.erro(e, s);
    }

    // Opt-in de verdade (LGPD + a promessa do onboarding "sem enviar seus
    // dados"): sai desligada, e só liga se a pessoa aceitou em Configurações.
    // Vale pro no-op E pro Firebase — a instância acima já está no lugar.
    final SettingsRepository settings = SettingsRepository(prefs);
    await telemetry.setHabilitado(settings.telemetryEnabled());

    // Lembrete (F7): se está ligado, REAGENDA com o regime atual — pega uma
    // troca de regime desde a última vez e reforça o agendamento pós-reboot (o
    // boot receiver nativo já faz o básico). Fire-and-forget e blindado (o
    // serviço já engole erro por dentro): nunca segura nem derruba o boot.
    if (settings.lembreteEnabled()) {
      unawaited(LembreteService().agendar(settings.regime()));
    }

    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const QuantoCobroApp(),
      ),
    );
  });
}
