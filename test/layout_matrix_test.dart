import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/entrada.dart';
import 'package:quantocobro/core/model/trabalho.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/areas/areas_screen.dart';
import 'package:quantocobro/features/calc/calc_screen.dart';
import 'package:quantocobro/features/config/config_screen.dart';
import 'package:quantocobro/features/detalhe/detalhe_screen.dart';
import 'package:quantocobro/features/entrada/entrada_screen.dart';
import 'package:quantocobro/features/historico/historico_screen.dart';
import 'package:quantocobro/features/onboarding/onboarding_screen.dart';
import 'package:quantocobro/features/painel/painel_screen.dart';
import 'package:quantocobro/features/pro/pro_screen.dart';
import 'package:quantocobro/features/proposta/marca_screen.dart';
import 'package:quantocobro/features/resultado/resultado_screen.dart';
import 'package:quantocobro/features/simulador/simulador_screen.dart';
import 'package:quantocobro/features/trabalhos/trabalho_detalhe_screen.dart';
import 'package:quantocobro/features/trabalhos/trabalho_form_screen.dart';
import 'package:quantocobro/features/trabalhos/trabalhos_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// **A matriz.** Cada tela × cada tamanho de tela real × fonte normal e 200%.
///
/// Isto existe porque estouro de layout é o defeito de acessibilidade mais
/// fácil de flagrar automaticamente e o mais fácil de reintroduzir: volta
/// sozinho toda vez que alguém acrescenta uma palavra numa `Row`. Antes daqui,
/// `overflow_test.dart` cobria **um** widget numa **única** largura, e todo o
/// resto da suíte rodava na superfície padrão de 800×600 — que não é celular
/// nenhum.
///
/// Fonte grande é o recurso de baixa visão mais usado do mundo, muito mais que
/// leitor de tela. E o padrão do defeito é cruel: **o que some é sempre o
/// número**, porque o número está sempre do lado direito de uma `Row` sem
/// `Flexible`.
void main() {
  for (final _Cena tela in _telas) {
    for (final Tela t in Tela.values) {
      for (final double escala in <double>[1.0, 2.0]) {
        testWidgets('${tela.nome} · ${t.name} · fonte ${escala}x', (
          WidgetTester tester,
        ) async {
          await comTela(tester, t, () async {
            final FlutterErrorDetails? erro = await _pump(tester, tela, escala);
            expect(
              erro == null ? null : _descrever(erro),
              isNull,
              reason:
                  '${tela.nome} em ${t.size.width.toInt()}×'
                  '${t.size.height.toInt()}, fonte ${escala}x',
            );
          });
        });
      }
    }
  }
}

/// Uma cena da matriz: a tela e, quando ela só aparece depois de um toque, o
/// caminho até lá.
typedef _Cena = ({
  String nome,
  Widget Function() build,
  Future<void> Function(WidgetTester)? chegarAte,
});

/// As telas, com o estado semeado que faz cada uma mostrar o caso CHEIO — o
/// que estoura. Tela vazia nunca estourou nada.
///
/// As três últimas precisam de `chegarAte`: elas não existem no primeiro
/// frame. É onde moram os estouros que a auditoria mediu à mão — e sem essa
/// navegação a matriz passaria verde jurando que estão cobertos.
final List<_Cena> _telas = <_Cena>[
  (nome: 'Onboarding', build: OnboardingScreen.new, chegarAte: null),
  (nome: 'Início', build: PainelScreen.new, chegarAte: null),
  (nome: 'Trabalhos', build: TrabalhosScreen.new, chegarAte: null),
  (
    nome: 'Trabalho detalhe',
    build: () => const TrabalhoDetalheScreen(trabalhoId: 't1'),
    chegarAte: null,
  ),
  (nome: 'Trabalho form', build: TrabalhoFormScreen.new, chegarAte: null),
  (nome: 'Entrada', build: EntradaScreen.new, chegarAte: null),
  (nome: 'Histórico', build: HistoricoScreen.new, chegarAte: null),
  (nome: 'Áreas', build: AreasScreen.new, chegarAte: null),
  (nome: 'Configurações', build: ConfigScreen.new, chegarAte: null),
  (nome: 'Detalhamento', build: DetalheScreen.new, chegarAte: null),
  (nome: 'Simulador', build: SimuladorScreen.new, chegarAte: null),
  (nome: 'Resultado', build: ResultadoScreen.new, chegarAte: null),
  (nome: 'Marca', build: MarcaScreen.new, chegarAte: null),
  (nome: 'Pro', build: ProScreen.new, chegarAte: null),
  (nome: 'Calc passo 1', build: CalcScreen.new, chegarAte: null),
  // O passo 3 lista os custos (o "Total: R$ X /mês") e é do passo 3 em
  // diante que existe a prévia do valor-hora no topo. Dois dos cinco
  // estouros de fonte 200% da auditoria moram aqui.
  (
    nome: 'Calc passo 3',
    build: () => CalcScreen(initialDraft: Area.padrao()),
    chegarAte: (WidgetTester t) async {
      for (int i = 0; i < 2; i++) {
        await t.tap(find.text('Continuar'));
        await t.pumpAndSettle();
      }
    },
  ),
  (
    nome: 'Calc passo 4',
    build: () => CalcScreen(initialDraft: Area.padrao()),
    chegarAte: (WidgetTester t) async {
      for (int i = 0; i < 3; i++) {
        await t.tap(find.text('Continuar'));
        await t.pumpAndSettle();
      }
    },
  ),
  // A Entrada só mostra o card do resultado (a barra, as legendas, o
  // "Guardar") depois que a pessoa digita um valor. Vazia ela nunca
  // estourou — e era vazia que a auditoria automatizada via.
  (
    nome: 'Entrada com resultado',
    build: EntradaScreen.new,
    chegarAte: (WidgetTester t) async {
      await t.enterText(find.byType(TextField).first, '12400');
      await t.pumpAndSettle();
    },
  ),
];

/// Pumpa a tela e devolve a **primeira** falha de layout, inteira.
///
/// Sequestrar o `FlutterError.onError` em vez de usar `takeException()` é de
/// propósito: o `takeException` devolve só o `FlutterError`, e a linha do
/// widget que estourou mora no `FlutterErrorDetails`, que ele descarta. Sem
/// isso a matriz diz QUE quebrou e nunca ONDE — e aí cada falha vira uma
/// caçada manual em quatro tamanhos de tela.
Future<FlutterErrorDetails?> _pump(
  WidgetTester tester,
  _Cena cena,
  double escala,
) async {
  FlutterErrorDetails? capturado;
  final void Function(FlutterErrorDetails)? anterior = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails d) => capturado ??= d;

  SharedPreferences.setMockInitialValues(_semente());
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (BuildContext context) => comFonte(escala, cena.build()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (capturado == null) await cena.chegarAte?.call(tester);

  FlutterError.onError = anterior;
  return capturado;
}

/// A mensagem que o desenvolvedor lê: o estouro E o `arquivo:linha` do widget
/// que o causou. `FlutterErrorDetails.toString()` já traz a cadeia de criação;
/// pegar só as primeiras linhas mantém a falha legível sem despejar a árvore
/// inteira no terminal.
String _descrever(FlutterErrorDetails d) =>
    d.toString().split('\n').take(8).join('\n');

/// Duas áreas (pra hierarquia aparecer), dois trabalhos e três entradas no mês
/// — nomes longos de propósito, porque nome curto esconde estouro.
Map<String, Object> _semente() {
  final DateTime agora = DateTime(2026, 7, 15);
  return <String, Object>{
    'onboarding_done': true,
    'areas_v1': jsonEncode(<String, dynamic>{
      'activeId': 'a1',
      'areas': <Map<String, dynamic>>[
        Area.padrao(nome: 'Design de identidade').toJson(),
        Area.padrao(id: 'a2', nome: 'Fotografia de produto').toJson(),
      ],
    }),
    'trabalhos_v1': jsonEncode(<Map<String, dynamic>>[
      Trabalho(
        id: 't1',
        areaId: 'a1',
        nome: 'Augusto da Padaria Central',
        criadoEm: agora,
        valorCombinado: 4800,
      ).toJson(),
      Trabalho(
        id: 't2',
        areaId: 'a2',
        nome: 'Loja da Ana',
        criadoEm: agora,
      ).toJson(),
    ]),
    'entradas_v1': jsonEncode(<Map<String, dynamic>>[
      Entrada(
        valor: 12400,
        separado: 1380,
        regimeTag: 'MEI',
        at: agora,
        areaId: 'a1',
        trabalhoId: 't1',
      ).toJson(),
      Entrada(
        valor: 3600,
        separado: 400,
        regimeTag: 'MEI',
        at: agora.subtract(const Duration(days: 3)),
        areaId: 'a1',
        trabalhoId: 't1',
      ).toJson(),
      Entrada(
        valor: 980,
        separado: 108,
        regimeTag: 'MEI',
        at: agora.subtract(const Duration(days: 40)),
        areaId: 'a2',
        trabalhoId: 't2',
      ).toJson(),
    ]),
  };
}
