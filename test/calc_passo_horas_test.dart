import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// v0.10: o passo das horas fala em UMA unidade por frase e mostra a conta
/// ("130 h por mês → dá pra cobrar 85 h"). Nada de "VOCÊ COBRA POR MÊS".
Future<void> _atePasso2(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const QuantoCobroApp(),
    ),
  );
  await tester.pumpAndSettle();
  final Finder comecar = find.text('Começar');
  await tester.ensureVisible(comecar);
  await tester.tap(comecar);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, '5000');
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('passo 2: título, três steppers e a conta explicada', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _atePasso2(tester);
      expect(find.text('Como é sua semana de trabalho?'), findsOneWidget);
      expect(find.text('Dias por semana'), findsOneWidget);
      expect(find.text('Horas num dia normal'), findsOneWidget);
      expect(find.text('Dias de folga por ano'), findsOneWidget);
      expect(find.textContaining('Você trabalha umas 130 h por mês'), findsOneWidget);
      expect(find.textContaining('dá pra cobrar umas 85 h'), findsOneWidget);
      expect(find.textContaining('VOCÊ COBRA'), findsNothing);
    });
  });

  testWidgets('mais folga derruba as horas cobráveis na hora', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _atePasso2(tester);
      // O "+" do stepper de folga (o terceiro par de botões).
      final Finder mais = find.widgetWithIcon(IconButton, Icons.add).at(2);
      await tester.ensureVisible(mais);
      await tester.tap(mais); // 30 → 35
      await tester.pumpAndSettle();
      expect(find.text('35 dias'), findsOneWidget);
      expect(find.textContaining('dá pra cobrar umas 8'), findsOneWidget);
      expect(find.textContaining('dá pra cobrar umas 85 h'), findsNothing);
    });
  });
}
