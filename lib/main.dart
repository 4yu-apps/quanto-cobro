import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers.dart';
import 'core/settings/settings_repository.dart';
import 'core/telemetry/telemetry.dart';

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

    // Opt-in de verdade (LGPD + a promessa do onboarding "sem enviar seus
    // dados"): sai desligada, e só liga se a pessoa aceitou em Configurações.
    // Hoje o destino é no-op; quando o Firebase entrar, é aqui que a
    // implementação real substitui a instância — ver telemetry.dart.
    await telemetry.setHabilitado(SettingsRepository(prefs).telemetryEnabled());

    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const QuantoCobroApp(),
      ),
    );
  });
}
