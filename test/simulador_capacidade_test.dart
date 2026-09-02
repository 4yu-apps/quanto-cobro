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
}
