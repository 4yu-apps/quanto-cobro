import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/features/entrada/entrada_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

Future<void> _pump(WidgetTester tester, {required bool comPreco}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    if (comPreco)
      'areas_v1': jsonEncode(<String, dynamic>{
        'activeId': 'a1',
        'areas': <Map<String, dynamic>>[Area.padrao().toJson()],
      }),
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const QuantoCobroApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'com preço: o botão Recebi está na navbar e abre a Entrada de qualquer aba',
    (WidgetTester tester) async {
      await comTela(tester, Tela.celularEmPe, () async {
        await _pump(tester, comPreco: true);
        await tester.tap(find.text('Trabalhos'));
        await tester.pumpAndSettle();
        expect(find.text('Recebi'), findsOneWidget);
        await tester.tap(find.text('Recebi'));
        await tester.pumpAndSettle();
        expect(find.byType(EntradaScreen), findsOneWidget);
      });
    },
  );

  testWidgets('sem preço ainda: o botão não aparece', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, comPreco: false);
      expect(find.text('Recebi'), findsNothing);
    });
  });

  testWidgets('as três abas continuam sendo três', (WidgetTester tester) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, comPreco: true);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
    });
  });

  // Cobertura de layout: nenhuma matriz existente renderiza o NavShell real
  // com `areaAtivaProvider` como `AreaPronta` em 320×640/fonte 200% (a matriz
  // de `layout_matrix_test.dart` pumpa cada tela isolada, sem a casca de
  // navegação; a de `tablet_test.dart` roda o app inteiro mas nunca semeia
  // `areas_v1`, então o botão nunca chega a existir ali). Um rótulo embaixo de
  // um círculo de 56dp é exatamente o tipo de coisa que estoura a barra a 2x.
  testWidgets('fonte 200%: o botão cabe na navbar sem estourar', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, comPreco: true);
      expect(find.text('Recebi'), findsOneWidget);
    }, textScale: 2.0);
  });
}
