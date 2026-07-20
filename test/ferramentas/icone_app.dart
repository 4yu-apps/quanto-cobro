import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/ui/cofre_mark.dart';

/// Gera o ícone do app a partir da **marca de verdade**, não de uma captura.
///
/// ```
/// flutter test test/ferramentas/icone_app.dart --update-goldens
/// ```
///
/// O ícone anterior era um print da marca ANIMADA, e dava pra provar olhando:
/// tinha uma faixa clara diagonal no canto inferior esquerdo — o `sheen` (o
/// fio-de-ouro que varre a marca no splash) congelado no meio do movimento. Do
/// mesmo print vinham os outros três defeitos:
///
/// - o `R$` colidia com o anel (o `$` atravessava o verde embaixo), porque a
///   captura foi feita **sem a fonte Sora carregada** e o texto caiu num
///   fallback mais largo;
/// - o arco de ouro virava um amendoim deformado;
/// - a marca encostava nas bordas, sem respiro nenhum.
///
/// Aqui ela é **desenhada** — `sheen: 0`, `ring: 1`, `core: 1`, fonte real,
/// tamanho exato, centro exato. E é repetível: mudou a marca, roda de novo.
///
/// Fora da suíte de propósito (nome sem `_test.dart`): é ferramenta de
/// produção de arte, não asserção sobre o app.
void main() {
  setUpAll(_carregarFontes);

  // ---- Adaptive icon (Android 8+): a camada de FRENTE, transparente. ----
  //
  // O canvas do adaptive icon tem 108dp, mas o sistema só garante os 66dp
  // centrais — o resto é comido por máscara (círculo, squircle, gota) e pelo
  // parallax do launcher. A marca ocupa 62% do canvas: dentro da zona segura,
  // com folga pra não beijar o corte em nenhuma máscara.
  //
  // Era aqui o "ícone bugado": a marca antiga ocupava ~79% e era cortada por
  // qualquer launcher de máscara circular.
  for (final MapEntry<String, int> d in _densidades.entries) {
    final int px = (d.value * 108 / 48).round();
    testWidgets('foreground · ${d.key} (${px}px)', (WidgetTester tester) async {
      await _render(
        tester,
        px,
        ColoredBox(
          color: const Color(0x00000000),
          child: Center(
            child: CofreMark(size: px * 0.62, coreScale: _coreDoIcone),
          ),
        ),
        'android/app/src/main/res/mipmap-${d.key}/ic_launcher_foreground.png',
      );
    });
  }

  // ---- Ícone legado (Android 7 e abaixo, e alguns launchers). ----
  for (final MapEntry<String, int> d in _densidades.entries) {
    testWidgets('legado · ${d.key} (${d.value}px)', (
      WidgetTester tester,
    ) async {
      await _render(
        tester,
        d.value,
        _IconeCheio(lado: d.value.toDouble()),
        'android/app/src/main/res/mipmap-${d.key}/ic_launcher.png',
      );
    });
  }

  // ---- O 512×512 da ficha da Play. ----
  //
  // Obrigatório no console, e sem transparência: o Google aplica a máscara
  // dele por cima. Quadrado cheio, sem cantos arredondados nossos.
  testWidgets('ficha da Play · 512px', (WidgetTester tester) async {
    await _render(
      tester,
      512,
      const _IconeCheio(lado: 512, raio: 0),
      'docs/screenshots/loja/icone-play-512.png',
    );
  });
}

/// mdpi é a régua: as outras densidades são múltiplos dela.
const Map<String, int> _densidades = <String, int>{
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// Esmeralda e ouro do tema escuro — as mesmas do `ColorScheme` do app, não
/// aproximações. O ícone é a marca; se ele desbotar em relação ao app, é a
/// marca que fica com duas versões.
const Color _esmeralda = Color(0xFF57E5A9);
const Color _ouro = Color(0xFFEFCE6F);

/// O `R$` encolhe pro ícone: no tamanho de lançador ele encostava no arco
/// esmeralda e os dois viravam uma mancha. A marca grande (splash, cabeçalho)
/// continua em 1 — ver `CofreMark.coreScale`.
const double _coreDoIcone = 0.80;

/// O charcoal do splash — o fundo DE VERDADE do app.
///
/// O ícone vinha com um verde-escuro (`#0D2C21` → `#071612`) que o app já
/// tinha abandonado. O motivo está escrito no `color_scheme.dart`: *"faz o
/// esmeralda #57E5A9 BRILHAR mais — o verde só parecia sujo/antigo porque o
/// fundo também era verde"*. O ícone tinha ficado com o fundo que a decisão
/// tinha jogado fora, e sobre ele o esmeralda perdia exatamente o brilho que a
/// mudança existia pra ganhar.
///
/// Estes dois são os do `splash_overlay.dart`: charcoal levantado no centro,
/// quase preto na borda. Radial, não linear — é um spotlight, e é ele que faz
/// a marca parecer iluminada por dentro em vez de colada num retângulo.
/// Três paradas, não duas: a do meio segura o tom quase chapado até 60% do
/// raio, e aí a borda cai rápido. É o que faz a vinheta ser SENTIDA e não
/// vista — com duas paradas o degradê é linear do centro à borda e o resultado
/// parece um fundo cinza mal resolvido, não um foco de luz.
const Color _fundoCentro = Color(0xFF1B2620);
const Color _fundoMeio = Color(0xFF131A16);
const Color _fundoBorda = Color(0xFF050807);

/// A versão com fundo: usada no ícone legado e no 512 da loja.
class _IconeCheio extends StatelessWidget {
  const _IconeCheio({required this.lado, this.raio = 0.225});

  final double lado;

  /// Fração do lado. O legado carrega o próprio canto arredondado; o da Play
  /// vai quadrado, porque o Google mascara por conta.
  final double raio;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(lado * raio),
      gradient: const RadialGradient(
        center: Alignment.center,
        // 0.9 leva o fim do degradê até perto dos cantos: com raio curto a
        // vinheta fecha antes deles e sobra um anel escuro visível, que lê
        // como erro de arte.
        radius: 0.9,
        colors: <Color>[_fundoCentro, _fundoMeio, _fundoBorda],
        stops: <double>[0.0, 0.6, 1.0],
      ),
    ),
    // 76% aqui, contra 62% do adaptive. O adaptive é preso na keyline de 66dp
    // do Material (a zona que nenhuma máscara corta); o legado já tem a moldura
    // desenhada, então a marca pode ocupar o quadrado como um ícone normal —
    // e quanto maior ela é, mais pixel sobra pro `R$` em 48dp.
    child: Center(
      child: CofreMark(size: lado * 0.76, coreScale: _coreDoIcone),
    ),
  );
}

Future<void> _render(
  WidgetTester tester,
  int px,
  Widget arte,
  String destino,
) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(px.toDouble(), px.toDouble());
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: px.toDouble(),
        height: px.toDouble(),
        // `sheen: 0` é o ponto: é a diferença entre a marca e um quadro da
        // animação dela.
        child: Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.dark(
              primary: _esmeralda,
              tertiary: _ouro,
              onSurface: Colors.white,
            ),
          ),
          child: arte,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(SizedBox).first,
    matchesGoldenFile('../../$destino'),
  );
}

/// Sem a Sora carregada o `R$` cai num fallback mais largo e ATRAVESSA o anel —
/// que é literalmente o defeito do ícone antigo.
Future<void> _carregarFontes() async {
  final FontLoader loader = FontLoader('Sora');
  for (final String arquivo in <String>['Sora-SemiBold', 'Sora-Bold']) {
    loader.addFont(
      File('assets/fonts/$arquivo.ttf').readAsBytes().then(
        (List<int> b) => ByteData.view(Uint8List.fromList(b).buffer),
      ),
    );
  }
  await loader.load();
}
