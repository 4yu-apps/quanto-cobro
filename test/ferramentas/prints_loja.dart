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
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = p.tamanho * 2.0;
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
  bool solta,
  Widget Function()? tela,
  Future<void> Function(WidgetTester)? depois,
});

/// Formatos da ficha: celular (9:16) e tablet 10" (16:10 deitado).
const Size _celular = Size(414, 736);
const Size _tablet = Size(1280, 800);

Future<void> _irPraAba(WidgetTester t, IconData icone) async {
  await t.tap(find.byIcon(icone));
  await t.pumpAndSettle();
}

final List<_Print> _prints = <_Print>[
  (
    arquivo: 'celular-1-inicio',
    tamanho: _celular,
    solta: false,
    tela: null,
    depois: null,
  ),
  (
    arquivo: 'celular-2-trabalhos',
    tamanho: _celular,
    solta: false,
    tela: null,
    depois: (WidgetTester t) => _irPraAba(t, Icons.work_outline),
  ),
  (
    arquivo: 'tablet-1-inicio',
    tamanho: _tablet,
    solta: false,
    tela: null,
    depois: null,
  ),
  // O print que justifica o bloco de tablet inteiro: lista à esquerda,
  // trabalho aberto à direita, trilho de navegação na lateral.
  (
    arquivo: 'tablet-2-mestre-detalhe',
    tamanho: _tablet,
    solta: false,
    tela: null,
    depois: (WidgetTester t) async {
      await _irPraAba(t, Icons.work_outline);
      await t.tap(find.text('Augusto'));
    },
  ),
  // A calculadora em duas colunas — o valor-hora vivo parado à direita.
  // Tela solta de propósito: fluxo focado cobre a casca.
  (
    arquivo: 'tablet-3-calculadora',
    tamanho: _tablet,
    solta: true,
    tela: () => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: CalcScreen(initialDraft: Area.padrao()),
    ),
    depois: (WidgetTester t) async {
      for (int i = 0; i < 2; i++) {
        await t.tap(find.text('Continuar'));
        await t.pumpAndSettle();
      }
    },
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
Map<String, Object> _semente() {
  final DateTime agora = DateTime(2026, 7, 15);
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
        criadoEm: agora,
        valorCombinado: 4800,
      ).toJson(),
      Trabalho(
        id: 't2',
        areaId: 'a1',
        nome: 'Loja da Ana',
        criadoEm: agora,
      ).toJson(),
      Trabalho(
        id: 't3',
        areaId: 'a1',
        nome: 'Padaria Central',
        criadoEm: agora,
      ).toJson(),
    ]),
    'entradas_v1': jsonEncode(<Map<String, dynamic>>[
      Entrada(
        valor: 2400,
        separado: 268,
        regimeTag: 'MEI',
        at: agora,
        areaId: 'a1',
        trabalhoId: 't1',
      ).toJson(),
      Entrada(
        valor: 1800,
        separado: 200,
        regimeTag: 'MEI',
        at: agora.subtract(const Duration(days: 6)),
        areaId: 'a1',
        trabalhoId: 't2',
      ).toJson(),
    ]),
  };
}
