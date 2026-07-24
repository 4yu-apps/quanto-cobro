import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/calc/calc_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// F6 — o passo do Fator R. Ele SÓ existe pro Simples (um passo a mais na
/// calculadora), e é onde a pessoa informa pró-labore + folha de funcionários.
/// Sem isso, o Simples solo ficaria preso no anexo mais caro sem saber.
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

Future<void> _escolher(WidgetTester tester, String regime) async {
  final Finder f = find.text(regime);
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('MEI termina no regime; Simples ganha o passo do Fator R', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _ateORegime(tester);

      // Default MEI: o regime é o último passo (4 de 4), botão "Ver resultado".
      expect(find.text('Passo 4 de 4'), findsOneWidget);
      expect(find.text('Ver resultado'), findsOneWidget);

      // Escolhe Simples → aparece um 5º passo (o botão volta a "Continuar").
      await _escolher(tester, 'Tenho empresa no Simples');
      expect(find.text('Passo 4 de 5'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);

      // Avança → o passo do Fator R, com os dois campos.
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Passo 5 de 5'), findsOneWidget);
      expect(find.text('Seu pró-labore por mês'), findsOneWidget);
      expect(find.text('Salários de funcionários por mês'), findsOneWidget);
    });
  });

  testWidgets('o passo do Simples dá o feedback do anexo ao vivo', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletEmPe, () async {
      await _ateORegime(tester);
      await _escolher(tester, 'Tenho empresa no Simples');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Sem folha: o feedback diz que usamos o Anexo V (o conservador).
      expect(find.textContaining('Sem folha informada'), findsOneWidget);

      // Informa um pró-labore alto → passa de 28% → o feedback vira Anexo III.
      await tester.enterText(find.byType(TextField).first, '3000');
      await tester.pumpAndSettle();
      expect(find.textContaining('Sua folha passa de 28%'), findsOneWidget);
    });
  });
}
