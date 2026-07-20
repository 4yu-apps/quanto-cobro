import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/a11y.dart';
import 'package:quantocobro/core/ui/tool_action_card.dart';
import 'package:quantocobro/features/areas/areas_screen.dart';
import 'package:quantocobro/features/calc/calc_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Os três P0 da auditoria de a11y (`docs/planning/ux-revisao/D-*`).
///
/// Cada um destes testes falhava antes da correção. São a trava pra eles não
/// voltarem — e voltam fácil, porque os três são invisíveis pra quem enxerga.
void main() {
  // P0-2. O par `Semantics(button:) + ExcludeSemantics` apagava a
  // `SemanticsAction.tap` do InkWell lá dentro. Sobrava um nó `isButton: true`
  // e SEM ação: o Switch Access não oferece o item, o VoiceOver não ativa, e o
  // `onTapHint` é descartado em silêncio pelo framework.
  //
  // No TalkBack puro funcionava por acidente (ele dispara um toque bruto no
  // centro do nó não-clicável) — e é exatamente por isso que ninguém percebeu.
  group('P0-2 · SemanticButton', () {
    testWidgets('o nó tem a ação de toque, não só a aparência de botão', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int toques = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SemanticButton(
              label: 'Augusto. Recebido 400 reais.',
              tapHint: 'abrir o trabalho',
              onTap: () => toques++,
              child: const SizedBox(width: 200, height: 80),
            ),
          ),
        ),
      );

      final SemanticsNode no = tester.getSemantics(find.byType(SemanticButton));
      expect(no.label, 'Augusto. Recebido 400 reais.');
      expect(
        no.getSemanticsData().flagsCollection.isButton,
        isTrue,
        reason: 'o card se anuncia como botão',
      );
      expect(
        no.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason:
            'sem a ação, o Switch Access não alcança o card e o onTapHint '
            'evapora — era este o P0-2',
      );

      // E a ação anunciada tem que FAZER a coisa.
      tester.semantics.performAction(
        find.semantics.byLabel('Augusto. Recebido 400 reais.'),
        SemanticsAction.tap,
      );
      expect(toques, 1);

      handle.dispose();
    });

    testWidgets('ToolActionCard — os dois botões do Início — carrega a ação', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int toques = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ToolActionCard(
              icon: Icons.payments_outlined,
              title: 'Recebi um pagamento',
              subtitle: 'separa o imposto na hora',
              onTap: () => toques++,
            ),
          ),
        ),
      );

      final SemanticsNode no = tester.getSemantics(find.byType(ToolActionCard));
      expect(no.label, 'Recebi um pagamento. separa o imposto na hora');
      expect(no.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      tester.semantics.performAction(
        find.semantics.byLabel('Recebi um pagamento. separa o imposto na hora'),
        SemanticsAction.tap,
      );
      expect(toques, 1);

      handle.dispose();
    });
  });

  // P0-1. `_tile` embrulhava o `ListTile` inteiro num `MergeSemantics`. O tile
  // tem `onTap` (ativar a área) e o trailing tem o `PopupMenuButton` (Editar ·
  // Renomear · Apagar): os dois viravam UM nó, e o gesto do nó fundido cai
  // sempre no primeiro da árvore — o tile.
  //
  // Resultado: com leitor de tela não dava pra renomear, editar nem apagar uma
  // área. E com ironia: quando a área JÁ estava ativa (`onTap: null`) o
  // conflito sumia — funcionava só na área que a pessoa menos precisa mexer.
  testWidgets('P0-1 · o menu ⋮ da área é alvo próprio, não some no merge', (
    WidgetTester tester,
  ) async {
    // Duas áreas de propósito: o defeito só existe no tile que TEM `onTap` —
    // ou seja, na área NÃO ativa. Na já ativa o `onTap` é nulo, o conflito de
    // gestos some e o menu funcionava. Funcionava só onde não importa.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
      'areas_v1': jsonEncode(<String, dynamic>{
        'activeId': 'a1',
        'areas': <Map<String, dynamic>>[
          Area.padrao(nome: 'Design').toJson(),
          Area.padrao(id: 'a2', nome: 'Fotografia').toJson(),
        ],
      }),
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: AreasScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // A área não-ativa: o tile tem onTap, e é aí que os dois gestos brigavam.
    final Finder tileFotografia = find.ancestor(
      of: find.text('Fotografia'),
      matching: find.byType(ListTile),
    );
    final SemanticsNode tile = tester.getSemantics(tileFotografia);
    expect(tile.label, contains('Toque pra ativar'));

    // O menu tem que chegar na plataforma como nó PRÓPRIO, filho do tile.
    // Fundido, ele não é enviado — e o gesto cai no `onTap` do tile, então a
    // pessoa não consegue renomear, editar nem apagar. Procuro na árvore em
    // vez de usar `getSemantics`, que sobe até o nó do tile e esconderia
    // exatamente a distinção que este teste existe pra provar.
    SemanticsNode? menu;
    tile.visitChildren((SemanticsNode filho) {
      if (filho.getSemanticsData().tooltip.contains('Fotografia')) {
        menu = filho;
        return false;
      }
      return true;
    });

    expect(
      menu,
      isNotNull,
      reason: 'o ⋮ e o tile têm que ser dois nós, não um',
    );
    expect(
      menu!.isMergedIntoParent,
      isFalse,
      reason: 'fundido, o menu não chega na ponte de acessibilidade',
    );
    expect(
      menu!.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'sem ação, abrir o menu por leitor de tela é impossível',
    );
    // "Opções" sozinho, numa lista de áreas, não diz opções DE QUÊ. (O tooltip
    // viaja em campo próprio do SemanticsData, não no `label`.)
    expect(
      menu!.getSemanticsData().tooltip,
      'Opções de Fotografia',
      reason: 'o rótulo do menu tem que dizer de QUAL área ele é',
    );

    handle.dispose();
  });

  // P0-3. `_regimeOption` passava `borderRadius:` E `shape:` pro mesmo
  // `Material` quando selecionado — e um regime está SEMPRE selecionado (MEI é
  // o default). O passo 4 estourava assert em debug, sempre.
  //
  // Em release o assert some e o usuário não vê. O preço era outro: nenhum
  // widget test conseguia chegar no passo 4, e por isso nenhum existia. Este é
  // o primeiro.
  testWidgets('P0-3 · o passo 4 da calculadora renderiza sem estourar assert', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark,
          // Area.padrao já é válida nos passos 1 e 2 — o teste é sobre chegar
          // no 4, não sobre digitar.
          home: CalcScreen(initialDraft: Area.padrao()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (int i = 1; i <= 3; i++) {
      expect(find.text('Passo $i de 4'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Passo 4 de 4'), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'borderRadius junto de shape estoura assert do Material',
    );
  });
}
