import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/entrada.dart';
import 'package:quantocobro/core/model/trabalho.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/calc/calc_screen.dart';
import 'package:quantocobro/features/entrada/entrada_screen.dart';
import 'package:quantocobro/features/historico/historico_screen.dart';
import 'package:quantocobro/features/resultado/resultado_screen.dart';
import 'package:quantocobro/features/simulador/simulador_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gera as capturas da ficha da Play — **celular e tablet**.
///
/// ```
/// flutter test test/ferramentas/prints_loja.dart --update-goldens
/// ```
///
/// Saem em `docs/screenshots/loja/`.
///
/// **Por que o nome não termina em `_test.dart`:** é assim que ele fica fora do
/// `flutter test` normal. Isto não é uma asserção sobre o app — é a ferramenta
/// que produz a arte da ficha. Na suíte, ele quebraria o CI toda vez que um
/// pixel mudasse: ruído puro, num arquivo cujo trabalho é ser regenerado de
/// propósito. (Tentei `dart_test.yaml` com `presets` antes; presets só valem
/// quando pedidos com `--preset`, então não excluíam nada.)
///
/// **Por que render e não emulador:** não há device nem emulador nesta
/// máquina, e o playbook da casa é explícito que build local em WSL derruba a
/// máquina. Render dá o mesmo pixel, no tamanho exato, repetível — e as fontes
/// são as de verdade (carregadas do `assets/`), senão o texto sairia em caixas
/// pretas e a captura não serviria pra nada.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _carregarFontes();
  });

  for (final _Print p in _prints) {
    testWidgets('print · ${p.arquivo}', (WidgetTester tester) async {
      tester.view.devicePixelRatio = p.dpr;
      tester.view.physicalSize = p.tamanho * p.dpr;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(_semente());
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          // O app INTEIRO, não a tela solta: sem isto a captura sai sem a
          // navegação — barra de baixo no celular, trilho no tablet — e um
          // print de loja sem a casca parece um app pela metade.
          //
          // A exceção é a calculadora, que empilha ACIMA da casca de
          // propósito (é modo focado, cobre a barra). Ali a tela solta é o
          // enquadramento certo.
          child: p.solta ? p.tela!() : const QuantoCobroApp(),
        ),
      );
      await tester.pumpAndSettle();
      if (p.depois != null) {
        await p.depois!(tester);
        await tester.pumpAndSettle();
      }

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../docs/screenshots/loja/${p.arquivo}.png'),
      );
    });
  }
}

typedef _Print = ({
  String arquivo,
  Size tamanho,
  double dpr,
  bool solta,
  Widget Function()? tela,
  Future<void> Function(WidgetTester)? depois,
});

/// Formatos da ficha. **A Play só aceita 16:9 ou 9:16** em captura de celular e
/// de tablet — 16:10 (o formato físico de tablet Android) é recusado no upload.
/// Por isso o tablet aqui é 16:9, não a proporção do aparelho: a ficha é uma
/// vitrine com régua própria.
///
/// E o lado mínimo muda por bloco: 320px no celular, mas **1080px** pra
/// qualificar à promoção da Play (o aviso do console) e 1080px é o piso do
/// bloco de tablet. Daí o `dpr` por print em vez de 2.0 fixo — o que importa é
/// o PIXEL final, e a largura LÓGICA é o que decide o layout que aparece
/// (`WindowClass`, em core/ui/breakpoints.dart).
const Size _celular = Size(414, 736);

/// 720dp de largura → `medium`: trilho lateral e uma coluna. É o tablet de 7"
/// em pé, e é o enquadramento que PREENCHE — em pé não sobra faixa vazia.
/// 720×1280 @1.5 = **1080×1920** (9:16).
const Size _tablet7 = Size(720, 1280);
const double _dpr7 = 1.5;

/// 1280dp → `expanded`: duas colunas de verdade (mestre-detalhe, calculadora).
/// 1280×720 @2 = **2560×1440** (16:9).
const Size _tablet10 = Size(1280, 720);
const double _dpr10 = 2.0;

Future<void> _irPraAba(WidgetTester t, IconData icone) async {
  await t.tap(find.byIcon(icone));
  await t.pumpAndSettle();
}

/// Casca mínima pra uma tela que é empilhada ACIMA da navegação no app real
/// (fluxo focado). Sem ela a tela solta sai sem tema e sem Material.
Widget _solta(Widget tela) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.dark,
  home: tela,
);

Future<void> _continuar(WidgetTester t, int vezes) async {
  for (int i = 0; i < vezes; i++) {
    await t.tap(find.text('Continuar'));
    await t.pumpAndSettle();
  }
}

/// Digita nos campos de texto na ordem em que eles aparecem. Formulário vazio é
/// print ruim: o que vende é o RESULTADO — "guarde R$ 279" só existe depois de
/// alguém digitar o valor.
Future<void> _digitar(WidgetTester t, List<String> valores) async {
  final Finder campos = find.byType(TextField);
  for (int i = 0; i < valores.length; i++) {
    await t.enterText(campos.at(i), valores[i]);
    await t.pumpAndSettle();
  }
}

final List<_Print> _prints = <_Print>[
  (
    arquivo: 'celular-1-inicio',
    tamanho: _celular,
    dpr: 2.0,
    solta: false,
    tela: null,
    depois: null,
  ),
  (
    arquivo: 'celular-2-trabalhos',
    tamanho: _celular,
    dpr: 2.0,
    solta: false,
    tela: null,
    depois: (WidgetTester t) => _irPraAba(t, Icons.work_outline),
  ),

  // ---------------------------------------------------------------- tablet 7"
  // Em pé, 720dp: trilho lateral + uma coluna. Em pé sobra menos fundo, então
  // aqui entram também as telas de fluxo focado (uma coluna por natureza).
  (
    arquivo: 'tablet7-1-inicio',
    tamanho: _tablet7,
    dpr: _dpr7,
    solta: false,
    tela: null,
    depois: null,
  ),
  (
    arquivo: 'tablet7-2-entrada',
    tamanho: _tablet7,
    dpr: _dpr7,
    solta: true,
    tela: () => _solta(const EntradaScreen()),
    depois: (WidgetTester t) => _digitar(t, <String>['2500']),
  ),
  (
    arquivo: 'tablet7-3-calculadora',
    tamanho: _tablet7,
    dpr: _dpr7,
    solta: true,
    tela: () => _solta(CalcScreen(initialDraft: Area.padrao())),
    depois: (WidgetTester t) => _continuar(t, 2),
  ),
  (
    arquivo: 'tablet7-4-simulador',
    tamanho: _tablet7,
    dpr: _dpr7,
    solta: true,
    tela: () => _solta(const SimuladorScreen()),
    depois: (WidgetTester t) => _digitar(t, <String>['4000', '30', '350']),
  ),
  (
    arquivo: 'tablet7-5-trabalhos',
    tamanho: _tablet7,
    dpr: _dpr7,
    solta: false,
    tela: null,
    depois: (WidgetTester t) => _irPraAba(t, Icons.work_outline),
  ),
  (
    arquivo: 'tablet7-6-historico',
    tamanho: _tablet7,
    dpr: _dpr7,
    solta: true,
    tela: () => _solta(const HistoricoScreen()),
    depois: null,
  ),

  // --------------------------------------------------------------- tablet 10"
  // Deitado, 720dp de ALTURA — o enquadramento mais apertado na vertical. Duas
  // regras de curadoria saíram de olhar os renders:
  //
  //  1. Painel e proposta em tela deitada põem uma coluna centralizada com
  //     faixa preta nas duas laterais. É o layout correto do app e uma captura
  //     ruim de loja: eles vão no bloco de 7", em pé.
  //  2. Tela cujo BOTÃO primário fica cortado na borda de baixo está fora (Pro
  //     e simulador caem aqui). Lista cortada no meio lê como rolagem e passa;
  //     botão cortado lê como app quebrado.
  (
    arquivo: 'tablet10-1-mestre-detalhe',
    tamanho: _tablet10,
    dpr: _dpr10,
    solta: false,
    tela: null,
    depois: (WidgetTester t) async {
      await _irPraAba(t, Icons.work_outline);
      await t.tap(find.text('Augusto'));
    },
  ),
  // A calculadora em duas colunas — o valor-hora vivo parado à direita.
  (
    arquivo: 'tablet10-2-calculadora',
    tamanho: _tablet10,
    dpr: _dpr10,
    solta: true,
    tela: () => _solta(CalcScreen(initialDraft: Area.padrao())),
    depois: (WidgetTester t) => _continuar(t, 2),
  ),
  (
    arquivo: 'tablet10-3-entrada',
    tamanho: _tablet10,
    dpr: _dpr10,
    solta: true,
    tela: () => _solta(const EntradaScreen()),
    depois: (WidgetTester t) => _digitar(t, <String>['2500']),
  ),
  (
    arquivo: 'tablet10-4-resultado',
    tamanho: _tablet10,
    dpr: _dpr10,
    solta: true,
    tela: () => _solta(ResultadoScreen(area: Area.padrao())),
    depois: null,
  ),
  (
    arquivo: 'tablet10-5-historico',
    tamanho: _tablet10,
    dpr: _dpr10,
    solta: true,
    tela: () => _solta(const HistoricoScreen()),
    depois: null,
  ),
  (
    arquivo: 'tablet10-6-ajustes',
    tamanho: _tablet10,
    dpr: _dpr10,
    solta: false,
    tela: null,
    depois: (WidgetTester t) => _irPraAba(t, Icons.settings_outlined),
  ),
];

/// Sem isto o `flutter test` usa a fonte Ahem e todo texto vira caixa preta.
///
/// E os **ícones** precisam da mesma atenção, por outro motivo: eles não vêm do
/// `assets/`, vêm do SDK. Sem carregar o `MaterialIcons-Regular.otf` toda
/// `Icon()` sai como um quadrado vazio — o que passa despercebido num teste de
/// layout e destrói uma captura de loja.
Future<void> _carregarFontes() async {
  Future<ByteData> ler(String caminho) => File(caminho).readAsBytes().then(
    (List<int> b) => ByteData.view(Uint8List.fromList(b).buffer),
  );

  for (final MapEntry<String, List<String>> familia in <String, List<String>>{
    'Sora': <String>[
      'assets/fonts/Sora-SemiBold.ttf',
      'assets/fonts/Sora-Bold.ttf',
    ],
    'Inter': <String>[
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ],
    'MaterialIcons': <String>[_caminhoDosIcones()],
  }.entries) {
    final FontLoader loader = FontLoader(familia.key);
    for (final String caminho in familia.value) {
      loader.addFont(ler(caminho));
    }
    await loader.load();
  }
}

/// A fonte de ícones mora no cache do SDK, não no projeto.
String _caminhoDosIcones() {
  final String? raiz =
      Platform.environment['FLUTTER_ROOT'] ?? _acharFlutterRoot();
  if (raiz == null) {
    throw StateError(
      'Não achei o FLUTTER_ROOT — sem ele os ícones saem como quadrados '
      'vazios e a captura não serve. Exporte FLUTTER_ROOT e rode de novo.',
    );
  }
  return '$raiz/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
}

String? _acharFlutterRoot() {
  final ProcessResult r = Process.runSync('which', <String>['flutter']);
  final String saida = (r.stdout as String).trim();
  if (saida.isEmpty) return null;
  // <raiz>/bin/flutter -> <raiz>
  return File(saida).parent.parent.path;
}

/// Dados de vitrine: números redondos e nomes plausíveis. Nada de "Teste 1".
///
/// **Por que seis trabalhos e meio ano de entradas** e não os dois de antes: em
/// tela de tablet, lista curta vira dois terços de fundo preto — a captura
/// parece um app vazio. E o gráfico "quanto entrou por mês" só existe com
/// movimento: com um mês só ele sai como uma barra sozinha. A semente é a arte
/// da ficha, não um fixture de teste; ela precisa ser densa o bastante pra
/// PREENCHER o enquadramento mais largo.
Map<String, Object> _semente() {
  DateTime mes(int m, int dia) => DateTime(2026, m, dia);

  // 1% do valor. **Isto tem que casar com o regime da semente (MEI)**: o painel
  // calcula a meta do anel de reserva como `entrou * reservaPct/100`, e no MEI
  // o DAS é boleto fixo — dá ~1% do faturado, não os ~11% de um regime por
  // percentual. Com 11% aqui, o print saía com "guardei R$ 469 de ~R$ 42": uma
  // conta que não fecha, estampada na ficha da loja.
  int reserva(double valor) => (valor * 0.01).round();

  Map<String, dynamic> entrada(double valor, DateTime at, String trabalho) =>
      Entrada(
        valor: valor,
        separado: reserva(valor),
        regimeTag: 'MEI',
        at: at,
        areaId: 'a1',
        trabalhoId: trabalho,
      ).toJson();

  return <String, Object>{
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
        criadoEm: mes(7, 2),
        valorCombinado: 4800,
      ).toJson(),
      Trabalho(
        id: 't2',
        areaId: 'a1',
        nome: 'Loja da Ana',
        criadoEm: mes(6, 18),
        valorCombinado: 3200,
      ).toJson(),
      Trabalho(
        id: 't3',
        areaId: 'a1',
        nome: 'Studio Lume',
        criadoEm: mes(5, 9),
        valorCombinado: 2600,
      ).toJson(),
      Trabalho(
        id: 't4',
        areaId: 'a1',
        nome: 'Clínica Nova',
        criadoEm: mes(4, 21),
        valorCombinado: 1900,
      ).toJson(),
      Trabalho(
        id: 't5',
        areaId: 'a1',
        nome: 'Café do Porto',
        criadoEm: mes(3, 14),
        valorCombinado: 1450,
      ).toJson(),
    ]),
    'entradas_v1': jsonEncode(<Map<String, dynamic>>[
      entrada(2400, mes(7, 15), 't1'),
      entrada(1800, mes(7, 9), 't2'),
      entrada(2400, mes(6, 27), 't1'),
      entrada(1400, mes(6, 12), 't3'),
      entrada(2600, mes(5, 22), 't3'),
      entrada(1900, mes(5, 6), 't4'),
      entrada(1450, mes(4, 24), 't5'),
      entrada(2100, mes(4, 8), 't2'),
      entrada(1600, mes(3, 19), 't5'),
      entrada(2200, mes(2, 26), 't4'),
    ]),
  };
}