import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/trabalho.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/breakpoints.dart';
import 'package:quantocobro/features/trabalhos/trabalhos_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// O que a largura extra COMPRA. A `layout_matrix_test` prova que nada quebra;
/// isto prova que alguma coisa melhora — senão o tablet ganhou só uma tela
/// esticada com margens maiores.
void main() {
  group('a régua', () {
    test('os cortes são os window size classes do Material 3', () {
      expect(WindowClass.fromWidth(320), WindowClass.compact);
      expect(WindowClass.fromWidth(599), WindowClass.compact);
      expect(WindowClass.fromWidth(600), WindowClass.medium);
      expect(WindowClass.fromWidth(839), WindowClass.medium);
      expect(WindowClass.fromWidth(840), WindowClass.expanded);
    });

    test('celular deitado é medium — e é de propósito', () {
      // 640×360: largo e BAIXO. Quem manda é a largura disponível, nunca o
      // dispositivo — e o layout que serve tablet em pé é exatamente o que
      // salva o celular deitado, tirando a navegação do rodapé.
      expect(WindowClass.fromWidth(640), WindowClass.medium);
      expect(WindowClass.fromWidth(640).usaTrilho, isTrue);
      expect(WindowClass.fromWidth(360).usaTrilho, isFalse);
    });
  });

  testWidgets('tablet deitado: os trabalhos vão de dois em dois', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletDeitado, () async {
      await _pump(tester);

      // Quatro cards em duas linhas de dois. A lista de trabalhos é o objeto
      // que mais cresce no app e é ela que a pessoa varre pra achar um nome:
      // duas colunas cortam a varredura pela metade.
      expect(find.text('Augusto'), findsOneWidget);
      expect(find.text('Pedro'), findsOneWidget);

      final double yAugusto = tester.getCenter(find.text('Augusto')).dy;
      final double yLoja = tester.getCenter(find.text('Loja da Ana')).dy;
      expect(
        yAugusto,
        yLoja,
        reason: 'os dois primeiros cards ficam na MESMA linha',
      );

      final double xAugusto = tester.getCenter(find.text('Augusto')).dx;
      final double xLoja = tester.getCenter(find.text('Loja da Ana')).dx;
      expect(xAugusto, lessThan(xLoja), reason: 'em colunas diferentes');
    });
  });

  testWidgets('celular em pé: continua uma coluna', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester);

      // Dois cards de 300dp não são melhores que um de 600 — abaixo de
      // `expanded` a grade não faz sentido nenhum.
      final double yAugusto = tester.getCenter(find.text('Augusto')).dy;
      final double yLoja = tester.getCenter(find.text('Loja da Ana')).dy;
      expect(yAugusto, isNot(yLoja));
    });
  });

  testWidgets('a coluna de conteúdo não estica com a tela', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletDeitado, () async {
      await _pump(tester);

      // Texto que atravessa 1000dp não se lê: o olho perde a linha na volta.
      // O `ContentWidth` ocupa a tela toda de propósito (é um Center); quem
      // clampa é o filho — e é o filho que precisa ser medido, senão o teste
      // mede o wrapper e passa verde sem provar nada.
      final double largura = tester.getSize(find.byType(ListView)).width;
      expect(largura, lessThanOrEqualTo(960));
      expect(largura, lessThan(Tela.tabletDeitado.size.width));
    });
  });
}

Future<void> _pump(WidgetTester tester) async {
  final DateTime agora = DateTime(2026, 7, 15);
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    'areas_v1': jsonEncode(<String, dynamic>{
      'activeId': 'a1',
      'areas': <Map<String, dynamic>>[Area.padrao(nome: 'Design').toJson()],
    }),
    'trabalhos_v1': jsonEncode(<Map<String, dynamic>>[
      Trabalho(
        id: 't1',
        areaId: 'a1',
        nome: 'Augusto',
        criadoEm: agora,
      ).toJson(),
      Trabalho(
        id: 't2',
        areaId: 'a1',
        nome: 'Loja da Ana',
        criadoEm: agora,
      ).toJson(),
      Trabalho(id: 't3', areaId: 'a1', nome: 'Pedro', criadoEm: agora).toJson(),
    ]),
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(theme: AppTheme.dark, home: const TrabalhosScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
