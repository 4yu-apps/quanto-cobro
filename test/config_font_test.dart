import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Config mostra os 4 níveis de fonte e tocar em "Grande" ajusta o textScaleProvider',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_done': true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const QuantoCobroApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Abre a Config a partir do ícone de engrenagem no Painel.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Os 4 níveis existem, com a prévia ao vivo.
      expect(find.byType(RadioListTile<double>), findsNWidgets(4));
      expect(find.text('Pequeno'), findsOneWidget);
      expect(find.text('Padrão'), findsOneWidget);
      expect(find.text('Grande'), findsOneWidget);
      expect(find.text('Muito grande'), findsOneWidget);
      expect(find.textContaining('Prévia: R\$ 1.234/hora'), findsOneWidget);

      // Estado inicial: Padrão (1.0).
      expect(container.read(textScaleProvider), 1.0);

      // Toca em "Grande" → provider vira 1.15.
      await tester.tap(find.text('Grande'));
      await tester.pumpAndSettle();

      expect(container.read(textScaleProvider), 1.15);
    },
  );
}
