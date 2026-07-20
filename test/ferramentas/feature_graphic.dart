import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/config/app_config.dart';
import 'package:quantocobro/core/ui/cofre_mark.dart';

/// O feature graphic (1024×500) da ficha da Play Store.
///
/// ```
/// flutter test test/ferramentas/feature_graphic.dart --update-goldens
/// ```
///
/// Sai em `docs/screenshots/loja/feature-graphic-1024x500.png`. É OPACO de
/// propósito (a Play recusa transparência) e usa a identidade do APP, não o
/// roxo da casa: o "Cofre Aberto" no escuro (esmeralda + ouro), porque aqui a
/// peça É o produto, não a assinatura da 4YU. A margem de 80px é folga de
/// segurança: a Play pode recortar as bordas conforme a superfície.
void main() {
  setUpAll(_carregarFontes);

  testWidgets('feature graphic · 1024x500', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1024, 500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 1024, height: 500, child: _Banner()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SizedBox).first,
      matchesGoldenFile(
        '../../docs/screenshots/loja/feature-graphic-1024x500.png',
      ),
    );
  });
}

// Cores do "Cofre Aberto" (as mesmas do splash e do og).
const Color _fundoCentro = Color(0xFF16221C);
const Color _fundoBorda = Color(0xFF050907);
const Color _tileCentro = Color(0xFF1B2620);
const Color _tileBorda = Color(0xFF050907);
const Color _esmeralda = Color(0xFF57E5A9);
const Color _ouro = Color(0xFFEFCE6F);
const Color _lilas = Color(0xFFA78BFA);

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      // Base escura com a leve luz do centro.
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.5, -0.65),
            radius: 1.35,
            colors: <Color>[_fundoCentro, _fundoBorda],
          ),
        ),
      ),
      // Aurora esmeralda (topo-esquerda) = "é seu".
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.62, -0.6),
            radius: 0.95,
            colors: <Color>[
              _esmeralda.withValues(alpha: 0.20),
              _esmeralda.withValues(alpha: 0),
            ],
          ),
        ),
      ),
      // Fresta de ouro (baixo-direita) = a reserva escapando.
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.0, 0.9),
            radius: 0.95,
            colors: <Color>[
              _ouro.withValues(alpha: 0.13),
              _ouro.withValues(alpha: 0),
            ],
          ),
        ),
      ),
      // Conteúdo, dentro da margem de segurança.
      Padding(
        padding: const EdgeInsets.fromLTRB(80, 56, 80, 56),
        child: Row(
          children: <Widget>[
            // O selo do Cofre num tile arredondado, com um halo esmeralda.
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(52),
                gradient: const RadialGradient(
                  radius: 0.95,
                  colors: <Color>[_tileCentro, _tileBorda],
                ),
                border: Border.all(
                  color: _esmeralda.withValues(alpha: 0.16),
                  width: 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _esmeralda.withValues(alpha: 0.16),
                    blurRadius: 64,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const SizedBox(
                width: 224,
                height: 224,
                child: Center(
                  child: CofreMark(
                    size: 162,
                    coreScale: 0.82,
                    esmeralda: _esmeralda,
                    ouro: _ouro,
                    coreColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 52),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    AppConfig.appName,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 60,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Quanto cobrar, quanto guardar, quanto sobra.',
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 27,
                      color: Color(0xFFC9CEDE),
                      height: 1.32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Assinatura da casa, discreta.
      const Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsets.fromLTRB(84, 0, 0, 34),
          child: Text(
            '4yu.com.br',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: _lilas,
              height: 1,
            ),
          ),
        ),
      ),
    ],
  );
}

Future<void> _carregarFontes() async {
  Future<ByteData> ler(String caminho) => File(caminho).readAsBytes().then(
    (List<int> b) => ByteData.view(Uint8List.fromList(b).buffer),
  );
  for (final MapEntry<String, List<String>> f in <String, List<String>>{
    'Sora': <String>['assets/fonts/Sora-Bold.ttf', 'assets/fonts/Sora-SemiBold.ttf'],
    'Inter': <String>[
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ],
  }.entries) {
    final FontLoader loader = FontLoader(f.key);
    for (final String c in f.value) {
      loader.addFont(ler(c));
    }
    await loader.load();
  }
}
