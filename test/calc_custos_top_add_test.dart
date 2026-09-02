import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/calc/calc_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O "+" ao lado do título do passo de custos (fix round 1 da task 8): quem
/// já tinha uns custos cadastrados não devia precisar rolar até o fim da
/// lista pra achar "Adicionar um custo meu" de novo. Este teste trava que o
/// botão do topo existe e abre exatamente o mesmo editor que o botão de
/// baixo sempre abriu.
Future<void> _ateCustos(WidgetTester tester) async {
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
  // Passo 0 (renda) → passo 1 (horas) → passo 2 (custos).
  for (int i = 0; i < 2; i++) {
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'o "+" do topo existe com o tooltip certo e abre o mesmo editor do botão de baixo',
    (WidgetTester tester) async {
      await _ateCustos(tester);

      final Finder botaoTopo = find.byTooltip('Adicionar um custo meu');
      expect(botaoTopo, findsOneWidget);

      // Abre pelo botão do topo: é o editor de custo novo ("Seu custo").
      await tester.tap(botaoTopo);
      await tester.pumpAndSettle();
      expect(find.text('Seu custo'), findsOneWidget);

      // Fecha (toque na cortina, fora da folha) e confere que o botão de
      // baixo, que já existia antes deste fix, abre exatamente a mesma tela.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Seu custo'), findsNothing);

      final Finder botaoBaixo = find.text('Adicionar um custo meu');
      await tester.ensureVisible(botaoBaixo);
      await tester.tap(botaoBaixo);
      await tester.pumpAndSettle();
      expect(find.text('Seu custo'), findsOneWidget);
    },
  );
}
