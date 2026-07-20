import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/config/app_config.dart';
import 'package:quantocobro/core/ui/cofre_mark.dart';

/// O cartão de compartilhamento (Open Graph, 1200×630) da página do produto.
///
/// ```
/// flutter test test/ferramentas/og_site.dart --update-goldens
/// ```
///
/// Sai em `docs/screenshots/loja/og-1200x630.png` e é copiado pro repo do site
/// como `site/quanto-cobro/og.png`. Gerar aqui, e não lá, é de propósito: o
/// cartão mostra o ÍCONE e o nome do app, e os dois moram neste repo. Feito no
/// site, ele viraria uma cópia manual que envelhece sozinha na primeira vez que
/// a marca mudar.
///
/// A moldura segue o padrão da casa (ver `site/deixei-aqui/og.png`): fundo
/// escuro do SITE com o roxo da 4YU, e dentro dele o ícone do app com a cor
/// própria dele. É a regra do `PADRAO-4YU-APPS §Marca` em imagem: o roxo é
/// assinatura da casa, não a cor do produto.
void main() {
  setUpAll(_carregarFontes);

  testWidgets('og · 1200x630', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 630);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 1200, height: 630, child: _Cartao()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SizedBox).first,
      matchesGoldenFile('../../docs/screenshots/loja/og-1200x630.png'),
    );
  });
}

/// Roxo da 4YU (a marca-mãe) e o fundo escuro do site.
const Color _violeta = Color(0xFF743EEC);
const Color _lilas = Color(0xFFA78BFA);
const Color _fundo = Color(0xFF050507);

/// O charcoal e o esmeralda do APP, pro bloco do ícone.
const Color _appFundoCentro = Color(0xFF1B2620);
const Color _appFundoBorda = Color(0xFF050807);
const Color _esmeralda = Color(0xFF57E5A9);
const Color _ouro = Color(0xFFEFCE6F);

class _Cartao extends StatelessWidget {
  const _Cartao();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: _fundo,
      gradient: RadialGradient(
        center: Alignment(0.35, -1.1),
        radius: 1.25,
        colors: <Color>[Color(0xFF2A1258), _fundo],
      ),
    ),
    child: Stack(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(80, 62, 80, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '4YU',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                  color: _lilas,
                  height: 1,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // O ícone do app, na cor do app.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: const RadialGradient(
                        radius: 0.9,
                        colors: <Color>[_appFundoCentro, _appFundoBorda],
                        stops: <double>[0.0, 1.0],
                      ),
                    ),
                    child: const SizedBox(
                      width: 188,
                      height: 188,
                      child: Center(
                        child: CofreMark(
                          size: 143,
                          coreScale: 0.80,
                          esmeralda: _esmeralda,
                          ouro: _ouro,
                          coreColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          AppConfig.appName,
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            fontSize: 62,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Quanto cobrar, quanto guardar, quanto sobra.',
                          maxLines: 2,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: 27,
                            color: Color(0xFFC9CEDE),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                '4yu.com.br',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 22,
                  color: _lilas,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        // A faixa roxa do rodapé: a assinatura da casa.
        const Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 8,
            width: double.infinity,
            child: ColoredBox(color: _violeta),
          ),
        ),
      ],
    ),
  );
}

Future<void> _carregarFontes() async {
  Future<ByteData> ler(String caminho) => File(caminho).readAsBytes().then(
    (List<int> b) => ByteData.view(Uint8List.fromList(b).buffer),
  );
  for (final MapEntry<String, List<String>> f in <String, List<String>>{
    'Sora': <String>['assets/fonts/Sora-Bold.ttf'],
    'Inter': <String>[
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
    ],
  }.entries) {
    final FontLoader loader = FontLoader(f.key);
    for (final String c in f.value) {
      loader.addFont(ler(c));
    }
    await loader.load();
  }
}
