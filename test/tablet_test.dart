import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/trabalho.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/breakpoints.dart';
import 'package:quantocobro/features/config/config_screen.dart';
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

  testWidgets('tablet deitado: lista à esquerda, trabalho aberto à direita', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.tabletDeitado, () async {
      await _pump(tester);

      // Antes de escolher, o painel direito diz o que fazer — tela larga com
      // metade em branco parece defeito.
      expect(
        find.text('Escolha um trabalho pra ver os pagamentos dele aqui.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Augusto'));
      await tester.pumpAndSettle();

      // O ganho: o detalhe abre AO LADO, sem a tela inteira dar um pulo — a
      // lista continua ali, e trocar de trabalho é um toque.
      expect(
        find.text('Recebido neste trabalho'.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('Loja da Ana'), findsOneWidget);

      final double xLista = tester.getCenter(find.text('Loja da Ana')).dx;
      final double xDetalhe = tester
          .getCenter(find.text('Recebido neste trabalho'.toUpperCase()))
          .dx;
      expect(xLista, lessThan(xDetalhe), reason: 'lista à esquerda do detalhe');
    });
  });

  testWidgets('celular em pé: tocar num trabalho empilha a tela, como sempre', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester);

      // Sem largura pra duas colunas, mestre-detalhe seria duas tiras de
      // 160dp. O comportamento de sempre é o certo aqui.
      expect(
        find.text('Escolha um trabalho pra ver os pagamentos dele aqui.'),
        findsNothing,
      );
      final double yAugusto = tester.getCenter(find.text('Augusto')).dy;
      final double yLoja = tester.getCenter(find.text('Loja da Ana')).dy;
      expect(yAugusto, isNot(yLoja), reason: 'uma coluna, um embaixo do outro');
    });
  });

  testWidgets('a coluna de conteúdo não estica com a tela', (
    WidgetTester tester,
  ) async {
    // Ajustes de propósito: é uma tela sem mestre-detalhe, então quem segura a
    // largura é só o clamp. E em 1024dp ele MORDE — num tablet em pé de 600 o
    // clamp é um no-op por construção, e o teste passaria verde sem provar
    // nada.
    await comTela(tester, Tela.tabletDeitado, () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_done': true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(theme: AppTheme.dark, home: const ConfigScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Texto que atravessa 1000dp não se lê: o olho perde a linha na volta.
      // É o FILHO do ContentWidth que precisa ser medido — o wrapper é um
      // Center e ocupa a tela toda de propósito.
      final double largura = tester.getSize(find.byType(ListView)).width;
      expect(largura, kMaxContentWidth);
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
