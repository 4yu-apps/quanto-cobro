import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/tokens.dart';
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
  // com `areaAtivaProvider` como `AreaPronta` em 320×640/fonte 200%. Nem
  // `layout_matrix_test.dart` (pumpa cada tela isolada dentro de um
  // `MaterialApp` cru, sem `NavShell` nenhum) nem `tablet_test.dart` (roda
  // `TrabalhosScreen`/`ConfigScreen` do mesmo jeito, direto num `MaterialApp`
  // — nunca `QuantoCobroApp`, nunca `NavShell` — mesmo semeando `areas_v1` no
  // `_pump` dele) chegam perto da navbar de verdade. Um rótulo embaixo de um
  // círculo de 56dp é exatamente o tipo de coisa que estoura a barra a 2x.
  testWidgets('fonte 200%: o botão cabe na navbar sem estourar', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, comPreco: true);
      expect(find.text('Recebi'), findsOneWidget);
    }, textScale: 2.0);
  });

  // Ruling D existe porque a ativação por tecnologia assistiva é o caminho
  // que quebra em silêncio: um `Semantics(button:) + ExcludeSemantics` sem
  // `onTap` passa despercebido porque o toque BRUTO (mouse, dedo) continua
  // funcionando via o botão visual por baixo — só o `SemanticsAction.tap`
  // fica mudo. Este teste anda por esse caminho especificamente, sem tocar a
  // árvore de widgets.
  testWidgets(
    'leitor de tela ativa o botão pela ação de toque, não só pelo toque bruto',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await comTela(tester, Tela.celularEmPe, () async {
        await _pump(tester, comPreco: true);
        await tester.tap(find.text('Trabalhos'));
        await tester.pumpAndSettle();

        tester.semantics.performAction(
          find.semantics.byLabel('Recebi um pagamento'),
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();

        expect(find.byType(EntradaScreen), findsOneWidget);
      });
      handle.dispose();
    },
  );

  // Fix #3: o vão de 8dp em cima/embaixo do círculo, no trilho lateral,
  // morava FORA de `_BotaoRecebi` (num `Padding` fixo em `_GlassRail`) — um
  // botão escondido (`SizedBox.shrink()`) ainda carregava esse `Padding` pra
  // trás, a mesma assimetria que a Ruling E já tinha corrigido na barra de
  // baixo. Movido o padding pra dentro do próprio widget (só no branch que
  // roda DEPOIS do retorno antecipado), sem preço não sobra nem o ícone nem
  // o `Padding` que o envolvia — o predicado busca esse `Padding` exato em
  // QUALQUER lugar da árvore, não só dentro de `_BotaoRecebi` (que é privado
  // e não dá pra `find.byType` de fora do arquivo).
  //
  // (Não comparei a posição do primeiro destino do trilho entre "com" e
  // "sem" botão: um `NavigationRail` dentro de `IntrinsicHeight` não desloca
  // os destinos conforme o tamanho real do `leading` — verificado rodando os
  // dois cenários e vendo o mesmo Y nos dois. O sintoma do vão sobrando é
  // espaço morto no `leading`, não deslocamento dos destinos; e comparar via
  // dois `_pump` no mesmo teste também esbarrava em estado de
  // `SharedPreferences` não resetando entre os dois `pumpWidget` — motivo a
  // mais pra manter isto num `testWidgets` só, com um `_pump` só.)
  testWidgets(
    'trilho: botão escondido não deixa nem o ícone nem o vão de 8+8dp pra trás',
    (WidgetTester tester) async {
      await comTela(tester, Tela.celularDeitado, () async {
        await _pump(tester, comPreco: false);
        expect(find.byIcon(Icons.payments_outlined), findsNothing);
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Padding &&
                w.padding ==
                    const EdgeInsets.only(top: Space.x2, bottom: Space.x2),
          ),
          findsNothing,
          reason:
              'o Padding(top: Space.x2, bottom: Space.x2) só existe quando '
              'o botão existe — antes do fix ele sobrevivia mesmo escondido',
        );
      });
    },
  );
}
