import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/calc/calc_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// F6 — a "pergunta humana" do Fator R. Ela SÓ aparece pro Simples (MEI/CPF/dólar
/// nunca veem), e é o que permite ao solo declarar pró-labore e escapar do Anexo
/// V. Sem isso, o app o deixaria no anexo mais caro pra sempre.
Future<void> _ateORegime(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: CalcScreen(initialDraft: Area.padrao()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  for (int i = 1; i <= 3; i++) {
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('a pergunta de pró-labore só existe no fluxo do Simples', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _ateORegime(tester);

      // Default é MEI: nada de Fator R.
      expect(find.text('Tem pró-labore? Você pode reservar menos'), findsNothing);

      // Escolhe Simples → a pergunta aparece.
      final Finder simples = find.text('Tenho empresa no Simples');
      await tester.ensureVisible(simples);
      await tester.tap(simples);
      await tester.pumpAndSettle();
      expect(find.text('Tem pró-labore? Você pode reservar menos'), findsOneWidget);
      expect(find.text('Definir'), findsOneWidget);

      // Volta pra MEI → a pergunta some de novo.
      final Finder mei = find.text('Sou MEI');
      await tester.ensureVisible(mei);
      await tester.tap(mei);
      await tester.pumpAndSettle();
      expect(find.text('Tem pró-labore? Você pode reservar menos'), findsNothing);
    });
  });

  testWidgets('definir o pró-labore grava o campo e reflete na pergunta', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _ateORegime(tester);
      final Finder simples = find.text('Tenho empresa no Simples');
      await tester.ensureVisible(simples);
      await tester.tap(simples);
      await tester.pumpAndSettle();

      final Finder definir = find.text('Definir');
      await tester.ensureVisible(definir);
      await tester.tap(definir);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '4000');
      await tester.tap(find.text('Usar este valor'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pró-labore: '), findsOneWidget);
      expect(find.text('Ajustar'), findsOneWidget);

      // O controller do sheet é descartado por um timer de 600ms (deixa a folha
      // fechar antes): avança o relógio pra ele não vazar pro fim do teste.
      await tester.pump(const Duration(milliseconds: 700));
    });
  });
}
