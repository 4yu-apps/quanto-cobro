import 'dart:math' as math;
import 'dart:ui' show PointMode, lerpDouble;

import 'package:flutter/material.dart';

import '../theme/motion.dart';
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
          // Duas camadas de propósito: o FUNDO é caro (grão + dois shaders
          // radiais) e não muda; o CONTORNO é barato e é o único que anima.
          // Juntos num painter só, o highlight de 350ms repintava ~290 pontos
          // de grão a cada frame — custo puro num app que roda em aparelho
          // fraco.
          child: CustomPaint(
            painter: _CofrePainter(
              base: cs.surfaceContainerHigh,
              esmeralda: cs.primary,
              ouro: cs.tertiary,
              dark: dark,
              climax: climax,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: highlight ? 1 : 0),
              duration: reduceMotionOf(context)
                  ? Duration.zero
                  : Motion.emphasized,
              curve: MotionCurves.emphasizedDecel,
              builder: (BuildContext context, double t, Widget? child) =>
                  CustomPaint(
                    foregroundPainter: _ContornoPainter(
                      esmeralda: cs.primary,
                      ouro: cs.tertiary,
                      dark: dark,
                      highlightT: t,
                      highlightColor: cs.tertiary,
                      borderFallback: cs.outlineVariant,
                    ),
                    child: child,
                  ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// O fundo do cofre: base, aurora e grão. **Nunca anima** — por isso
/// `shouldRepaint` só devolve true quando a cor ou o tema muda de verdade.
class _CofrePainter extends CustomPainter {
  const _CofrePainter({
    required this.base,
    required this.esmeralda,
    required this.ouro,
    required this.dark,
    required this.climax,
  });

  final Color base;
  final Color esmeralda;
  final Color ouro;
  final bool dark;
  final bool climax;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Base da vitrine.
    canvas.drawRect(rect, Paint()..color = base);

    // Aurora do Cofre: 2 glows radiais estáticos. Com o fundo agora NEUTRO, o
    // glow esmeralda aparece mais — baixei pela metade (0.07→0.035) pra não
    // voltar a "lavar" o cartão de verde; o ouro (a joia do canto) fica.
    final double boost = climax ? 1.4 : 1.0;
    final double aEsm = (dark ? 0.035 : 0.04) * boost;
    final double aOuro = (dark ? 0.045 : 0.03) * boost;
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
        ..color = Colors.white.withValues(alpha: 0.020)
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
  }

  @override
  bool shouldRepaint(_CofrePainter old) =>
      old.base != base ||
      old.esmeralda != esmeralda ||
      old.ouro != ouro ||
      old.dark != dark ||
      old.climax != climax;
}

/// O contorno — o fio-de-ouro que ACENDE quando o cofre fecha.
///
/// Vive separado do fundo porque é a única coisa que anima: durante os 350ms
/// do highlight, só estas duas chamadas de desenho repintam.
class _ContornoPainter extends CustomPainter {
  const _ContornoPainter({
    required this.esmeralda,
    required this.ouro,
    required this.dark,
    required this.highlightT,
    required this.highlightColor,
    required this.borderFallback,
  });

  final Color esmeralda;
  final Color ouro;
  final bool dark;

  /// Progresso do "acender o cofre" (0 = apagado, 1 = aceso).
  final double highlightT;
  final Color highlightColor;
  final Color borderFallback;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, Radii.xl).deflate(0.5);

    // Fio-de-ouro no escuro (reflexo do cofre); hairline no claro.
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 + 0.5 * highlightT;
    if (dark) {
      stroke.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          ouro.withValues(alpha: lerpDouble(0.35, 0.8, highlightT)!),
          ouro.withValues(alpha: 0.05),
          esmeralda.withValues(alpha: lerpDouble(0.25, 0.5, highlightT)!),
        ],
      ).createShader(rect);
    } else {
      stroke.color =
          Color.lerp(borderFallback, highlightColor, highlightT) ??
          borderFallback;
    }
    canvas.drawRRect(rrect, stroke);
  }

  @override
  bool shouldRepaint(_ContornoPainter old) =>
      old.highlightT != highlightT ||
      old.dark != dark ||
      old.ouro != ouro ||
      old.esmeralda != esmeralda ||
      old.highlightColor != highlightColor ||
      old.borderFallback != borderFallback;
}
