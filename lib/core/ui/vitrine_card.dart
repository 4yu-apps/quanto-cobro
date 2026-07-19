import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Vitrine do "Cofre Aberto" — a superfície onde dinheiro é apresentado
/// (herói do Painel, clímax do Resultado, cofre da Reserva, total do Histórico).
///
/// Material por tema (proposta Lúa §5, custo declarado ≈ zero — pinta UMA vez
/// sob RepaintBoundary, sem shader por frame):
/// - Escuro: base tonal + "Aurora do Cofre" (2 glows radiais estáticos,
///   esmeralda no topo-esquerda e ouro no rodapé-direita, ≤8% alpha) +
///   fio-de-ouro (stroke 1px gradiente, o reflexo na porta do cofre) +
///   grain finíssimo (pontos determinísticos, alpha 0.025).
/// - Claro: cartão BRANCO flutuando sobre o papel com 2 sombras tintadas de
///   verde-tinta (ambiente + chave) e aurora a alpha mais baixo. Sem grain
///   (sobre branco leria como sujeira de impressão).
class VitrineCard extends StatelessWidget {
  const VitrineCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.x6),
    this.climax = false,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Clímax (Resultado): aurora mais presente.
  final bool climax;

  /// Realce de estado (ex.: cofre "trancado" na Reserva): acende a borda.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radii.xl),
          boxShadow: dark
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radii.xl),
          child: CustomPaint(
            painter: _CofrePainter(
              base: cs.surfaceContainerHigh,
              esmeralda: cs.primary,
              ouro: cs.tertiary,
              dark: dark,
              climax: climax,
              highlight: highlight,
              highlightColor: cs.tertiary,
              borderFallback: cs.outlineVariant,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _CofrePainter extends CustomPainter {
  const _CofrePainter({
    required this.base,
    required this.esmeralda,
    required this.ouro,
    required this.dark,
    required this.climax,
    required this.highlight,
    required this.highlightColor,
    required this.borderFallback,
  });

  final Color base;
  final Color esmeralda;
  final Color ouro;
  final bool dark;
  final bool climax;
  final bool highlight;
  final Color highlightColor;
  final Color borderFallback;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, Radii.xl).deflate(0.5);

    // Base da vitrine.
    canvas.drawRect(rect, Paint()..color = base);

    // Aurora do Cofre: 2 glows radiais estáticos, nunca acima de 8% de alpha.
    final double boost = climax ? 1.4 : 1.0;
    final double aEsm = (dark ? 0.07 : 0.04) * boost;
    final double aOuro = (dark ? 0.05 : 0.03) * boost;
    final double raio = size.width * 1.2;

    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                esmeralda.withValues(alpha: aEsm),
                esmeralda.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.1, 0),
                radius: raio,
              ),
            ),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                ouro.withValues(alpha: aOuro),
                ouro.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.95, size.height),
                radius: raio,
              ),
            ),
    );

    // Grain finíssimo — só no escuro, determinístico, pintado uma vez.
    if (dark) {
      final math.Random rnd = math.Random(42);
      final Paint grain = Paint()
        ..color = Colors.white.withValues(alpha: 0.025)
        ..strokeWidth = 1;
      final int n = (size.width * size.height / 220).round();
      final List<Offset> pts = List<Offset>.generate(
        n,
        (_) => Offset(
          rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height,
        ),
      );
      canvas.drawPoints(PointMode.points, pts, grain);
    }

    // Contorno: fio-de-ouro no escuro (reflexo do cofre); hairline no claro.
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlight ? 1.5 : 1.0;
    if (dark) {
      stroke.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          ouro.withValues(alpha: highlight ? 0.8 : 0.35),
          ouro.withValues(alpha: 0.05),
          esmeralda.withValues(alpha: highlight ? 0.5 : 0.25),
        ],
      ).createShader(rect);
    } else {
      stroke.color = highlight ? highlightColor : borderFallback;
    }
    canvas.drawRRect(rrect, stroke);
  }

  @override
  bool shouldRepaint(_CofrePainter old) =>
      old.base != base ||
      old.esmeralda != esmeralda ||
      old.ouro != ouro ||
      old.dark != dark ||
      old.climax != climax ||
      old.highlight != highlight;
}
