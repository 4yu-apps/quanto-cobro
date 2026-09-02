import 'package:flutter/material.dart';

import '../theme/divisao_colors.dart';
import '../theme/tokens.dart';
import 'cofre_mark.dart';
import 'texturas.dart';

/// Vire pra `true` quando houver ilustração raster de verdade: declare
/// `assets/ilustracoes/` no `pubspec.yaml` e as duas imagens passam a mandar.
///
/// Spec do asset, pra quem for gerar: 1024×1024, fundo transparente, 3D suave,
/// paleta esmeralda `#57E5A9` / ouro / cinza-carvão. Sem texto e sem pessoas —
/// texto em imagem não traduz nem escala com a fonte do sistema, e pessoa em
/// ilustração de produto envelhece mal.
const bool kCenaUsaRaster = false;

enum CenaTipo { inicio, folga }

/// A ilustração assinatura: o que separa "app de IA" de "app com dono".
///
/// Composta em código com o que a paleta já tem — dois blobs circulares a ≤10%
/// de alpha, o grão do [DotPainter] por cima, e o [CofreMark] como protagonista.
/// Em `folga` o cofre encolhe e cede o palco pro arco de ouro (o sol), porque
/// ali a tela fala de parar, não de guardar.
///
/// Não anima, de propósito: ilustração que se mexe sozinha rouba a atenção do
/// número, que é sempre o assunto. E é decorativa — o leitor de tela pula.
class Cena extends StatelessWidget {
  const Cena({super.key, required this.tipo, this.altura = 180});

  final CenaTipo tipo;
  final double altura;

  @override
  Widget build(BuildContext context) {
    if (kCenaUsaRaster) {
      return ExcludeSemantics(
        child: Image.asset(
          'assets/ilustracoes/${tipo.name}.webp',
          height: altura,
          fit: BoxFit.contain,
        ),
      );
    }
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final Color principal = tipo == CenaTipo.inicio ? cs.primary : d.reserva;
    final Color apoio = tipo == CenaTipo.inicio ? d.reserva : cs.primary;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: altura,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radii.xl),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Blob grande, deslocado pra fora do quadro: o acento quente
                // usado GRANDE, que é o oposto de espalhar cor em tudo.
                Positioned(
                  left: -altura * 0.2,
                  top: -altura * 0.25,
                  child: _blob(principal.withValues(alpha: 0.10), altura * 0.9),
                ),
                Positioned(
                  right: -altura * 0.15,
                  bottom: -altura * 0.3,
                  child: _blob(apoio.withValues(alpha: 0.07), altura * 0.7),
                ),
                if (tipo == CenaTipo.folga)
                  // O sol: um arco de ouro que domina a cena.
                  Positioned(
                    top: altura * 0.18,
                    child: Container(
                      width: altura * 0.5,
                      height: altura * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: principal.withValues(alpha: 0.55),
                          width: 6,
                        ),
                      ),
                    ),
                  ),
                // Grão por cima de tudo, bem sutil: é o que tira o plástico do
                // gradiente chapado.
                Positioned.fill(
                  child: CustomPaint(
                    painter: DotPainter(cs.onSurface.withValues(alpha: 0.04)),
                  ),
                ),
                if (tipo == CenaTipo.inicio)
                  CofreMark(size: altura * 0.55)
                else
                  Positioned(
                    right: altura * 0.18,
                    bottom: altura * 0.12,
                    child: CofreMark(size: altura * 0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(Color cor, double diametro) => Container(
    width: diametro,
    height: diametro,
    decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
  );
}
