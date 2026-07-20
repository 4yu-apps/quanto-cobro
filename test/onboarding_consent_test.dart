import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O consentimento de telemetria (LGPD): última tela do onboarding, escolha
/// real, nada ligado sem o "sim". Confirmar é o caminho fácil, mas recusar é
/// alcançável — e é o default se a pessoa sair sem escolher.
void main() {
  Future<ProviderContainer> boot(WidgetTester tester) async {
    // Sem 'onboarding_done': o app cai no onboarding.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const QuantoCobroApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> irParaConsentimento(WidgetTester tester) async {
    // Duas telas de "Continuar" (dor, privacidade) até o consentimento.
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
  }

  testWidgets('consentimento é a última tela, honesto sobre o que vai/não vai', (
    WidgetTester tester,
  ) async {
    await boot(tester);
    await irParaConsentimento(tester);

    expect(find.text('Me ajuda a melhorar?'), findsOneWidget);
    expect(find.textContaining('anônima'), findsOneWidget);
    // As duas opções existem, e recusar NÃO é texto morto: é um botão de verdade.
    expect(find.widgetWithText(FilledButton, 'Sim, pode ajudar'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Agora não'), findsOneWidget);
  });

  testWidgets('confirmar liga a telemetria e fecha o onboarding', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await boot(tester);
    await irParaConsentimento(tester);

    await tester.tap(find.text('Sim, pode ajudar'));
    await tester.pumpAndSettle();

    expect(c.read(telemetryProvider), isTrue);
    // Saiu do onboarding.
    expect(find.text('Me ajuda a melhorar?'), findsNothing);
  });

  testWidgets('recusar deixa a telemetria desligada (o default seguro)', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await boot(tester);
    await irParaConsentimento(tester);

    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();

    expect(c.read(telemetryProvider), isFalse);
    expect(find.text('Me ajuda a melhorar?'), findsNothing);
  });
}
