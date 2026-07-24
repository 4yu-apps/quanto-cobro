import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/custo.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/detalhe/detalhe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// F4 — a folha do detalhamento é PROFUNDIDADE Pro (doc 15 §4.2). O que não pode
/// mudar: o valor que a pessoa guarda continua grátis; só a conta POR DENTRO é
/// que é do Pro. Estes testes travam as duas metades dessa promessa.
Area _area() => Area(
  id: 'a1',
  nome: 'Teste',
  renda: 6000,
  horas: 120,
  provisao: 0,
  provisaoOn: false,
  custos: const <Custo>[],
);

Future<void> _pump(
  WidgetTester tester, {
  required bool pro,
  String regime = 'cpf',
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    'regime': regime,
    'entitlement_pro': pro,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: DetalheScreen(area: _area()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tocarImposto(WidgetTester tester) async {
  final Finder linha = find.textContaining('Imposto estimado');
  expect(linha, findsOneWidget);
  await tester.ensureVisible(linha);
  await tester.tap(linha);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('grátis: tocar o imposto mostra o convite Pro, não a conta', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _pump(tester, pro: false);
      await _tocarImposto(tester);

      expect(find.text('A conta por dentro é do Pro'), findsOneWidget);
      // A promessa que a pesquisa manda cumprir: o valor guardado segue grátis.
      expect(find.textContaining('grátis, sempre'), findsOneWidget);
      // NÃO vaza a conta por dentro:
      expect(find.text('Imposto do mês'), findsNothing);
    });
  });

  testWidgets('Pro: tocar o imposto abre a conta por dentro (INSS + total)', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _pump(tester, pro: true);
      await _tocarImposto(tester);

      expect(find.text('De onde vem esse imposto'), findsOneWidget);
      expect(find.text('INSS'), findsOneWidget);
      expect(find.text('Imposto do mês'), findsOneWidget);
      // Não é o convite Pro:
      expect(find.text('A conta por dentro é do Pro'), findsNothing);
    });
  });

  testWidgets('MEI: a linha do DAS não abre folha (é a frente do teto, F5)', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _pump(tester, pro: true, regime: 'mei');
      // MEI mostra o DAS fixo, sem "Imposto estimado" tocável.
      expect(find.textContaining('Imposto estimado'), findsNothing);
      expect(find.textContaining('DAS'), findsWidgets);
    });
  });
}
