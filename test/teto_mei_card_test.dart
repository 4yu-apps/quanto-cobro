import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/entrada.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/painel/painel_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// F5 — o cartão do teto no Painel. As regras que não podem quebrar: aparece SÓ
/// pro MEI, SÓ depois do primeiro recebimento do ano (empty-state), e a projeção
/// é Pro enquanto a zona e o quanto falta seguem grátis (o perigo real).
Future<void> _pump(
  WidgetTester tester, {
  required String regime,
  required bool pro,
  double faturadoAno = 60000,
  bool comEntrada = true,
  double textScale = 1.0,
}) async {
  final int ano = DateTime.now().year;
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    'regime': regime,
    'entitlement_pro': pro,
    'areas_v1': jsonEncode(<String, dynamic>{
      'activeId': 'a1',
      'areas': <Map<String, dynamic>>[Area.padrao(nome: 'Meu trabalho').toJson()],
    }),
    if (comEntrada)
      'entradas_v1': jsonEncode(<Map<String, dynamic>>[
        Entrada(
          valor: faturadoAno,
          separado: 86,
          regimeTag: 'MEI',
          at: DateTime(ano, 1, 15),
        ).toJson(),
      ]),
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (BuildContext context) =>
              comFonte(textScale, const Scaffold(body: PainelScreen())),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('MEI com faturamento: o cartão do teto aparece', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _pump(tester, regime: 'mei', pro: false);
      expect(find.text('TETO DO MEI'), findsOneWidget);
      // Zona verde (60k): mostra o quanto falta — grátis.
      expect(find.textContaining('Faltam'), findsOneWidget);
    });
  });

  testWidgets('grátis: a projeção fica atrás do Pro, não a zona', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _pump(tester, regime: 'mei', pro: false);
      expect(find.text('Ver a projeção do ano (Pro)'), findsOneWidget);
      expect(find.textContaining('Nesse ritmo'), findsNothing);
    });
  });

  testWidgets('Pro: a projeção aparece direto no cartão', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _pump(tester, regime: 'mei', pro: true);
      expect(find.textContaining('Nesse ritmo'), findsOneWidget);
      expect(find.text('Ver a projeção do ano (Pro)'), findsNothing);
    });
  });

  testWidgets('não-MEI: sem cartão de teto (é coisa de MEI)', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _pump(tester, regime: 'cpf', pro: false);
      expect(find.text('TETO DO MEI'), findsNothing);
    });
  });

  testWidgets('MEI sem recebimento no ano: sem cartão (empty-state)', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _pump(tester, regime: 'mei', pro: false, comEntrada: false);
      expect(find.text('TETO DO MEI'), findsNothing);
    });
  });

  testWidgets('celular estreito + fonte 2x, zona vermelha: sem overflow', (
    WidgetTester tester,
  ) async {
    // O pior caso do cartão: 320dp, fonte dobrada e o texto mais longo (a zona
    // vermelha, com a frase do contador). Se algo estourar, é aqui.
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(
        tester,
        regime: 'mei',
        pro: true,
        faturadoAno: 100000,
        textScale: 2.0,
      );
      // Em 320dp o cartão nasce abaixo da dobra: rola até ele (o ListView é
      // lazy — sem rolar, ele nem é construído, e um overflow ali passaria batido).
      await tester.scrollUntilVisible(
        find.text('TETO DO MEI'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('TETO DO MEI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
