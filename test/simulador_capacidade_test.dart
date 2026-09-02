import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/simulador/simulador_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O irmão do aviso "abaixo do alvo": se o projeto pede mais hora do que a
/// pessoa TEM no mês, o app diz. Cor de informação (aço), não de alerta.
Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    'regime': 'mei',
    'areas_v1': jsonEncode(<String, dynamic>{
      'activeId': 'a1',
      'areas': <Map<String, dynamic>>[Area.padrao().toJson()],
    }),
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(theme: AppTheme.dark, home: const SimuladorScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('horas acima da capacidade do mês mostram o aviso', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '10000');
    await tester.enterText(find.byType(TextField).at(1), '200'); // 85 é o mês
    await tester.pumpAndSettle();
    expect(find.textContaining('mais hora do que você tem'), findsOneWidget);
  });

  testWidgets('dentro da capacidade, nada de aviso', (WidgetTester tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '3000');
    await tester.enterText(find.byType(TextField).at(1), '20');
    await tester.pumpAndSettle();
    expect(find.textContaining('mais hora do que você tem'), findsNothing);
  });

  testWidgets('exatamente no limite do mês (85h), sem aviso: fronteira', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '5000');
    await tester.enterText(find.byType(TextField).at(1), '85'); // == o mês
    await tester.pumpAndSettle();
    expect(find.textContaining('mais hora do que você tem'), findsNothing);
    // Drena o debounce do anúncio de lucro que ficou pendente.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'aviso de capacidade anuncia pro leitor de tela na transição, sem repetir',
    (WidgetTester tester) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextField).at(0), '10000');
      await tester.enterText(find.byType(TextField).at(1), '200'); // acima do mês
      await tester.pumpAndSettle();
      // Drena o debounce de 900ms dos dois anúncios (lucro e capacidade).
      await tester.pump(const Duration(seconds: 1));

      final List<CapturedAccessibilityAnnouncement> primeiras = tester
          .takeAnnouncements();
      expect(
        primeiras.any(
          (CapturedAccessibilityAnnouncement a) =>
              a.message.contains('mais hora do que você tem'),
        ),
        isTrue,
        reason: 'esperava o anúncio na transição pra "estourado"',
      );

      // Continua digitando acima da capacidade: a transição já aconteceu,
      // não deve repetir o anúncio (senão fica tagarela a cada tecla).
      await tester.enterText(find.byType(TextField).at(1), '250');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      final List<CapturedAccessibilityAnnouncement> seguintes = tester
          .takeAnnouncements();
      expect(
        seguintes.any(
          (CapturedAccessibilityAnnouncement a) =>
              a.message.contains('mais hora do que você tem'),
        ),
        isFalse,
        reason: 'não deve repetir enquanto o aviso continua visível',
      );
    },
  );
}
