import 'package:flutter/material.dart';

import '../theme/materials.dart';
import '../theme/tokens.dart';

/// Card faux-glass do "Cofre Aberto": degradê tonal (luz vem de cima) +
/// fio-de-luz na borda (branco, croma zero) + glow de acento opcional no canto
/// do ícone (≤0.08). Custo ~zero: gradientes estáticos, sem shader por frame,
/// sob RepaintBoundary. NÃO usa BackdropFilter (vidro real é só a navbar).
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.x4),
    this.accent,
    this.radius = Radii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Cor do glow de acento (canto sup-esq). Null = sem glow.
  final Color? accent;
  final Radius radius;

  @override
  Widget build(BuildContext context) {
    final Materials m = Theme.of(context).extension<Materials>()!;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.all(radius),
        child: CustomPaint(
          painter: _PanelPainter(
            fillTop: m.panelFillTop,
            fillBottom: m.panelFillBottom,
            edgeHighlight: m.edgeHighlight,
            edgeShadow: m.edgeShadow,
            accent: accent,
            radius: radius,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  const _PanelPainter({
    required this.fillTop,
    required this.fillBottom,
    required this.edgeHighlight,
    required this.edgeShadow,
    required this.accent,
    required this.radius,
  });

  final Color fillTop;
  final Color fillBottom;
  final Color edgeHighlight;
  final Color edgeShadow;
  final Color? accent;
  final Radius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, radius);

    // 1) fill em degradê vertical (topo mais claro).
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[fillTop, fillBottom],
        ).createShader(rect),
    );

    // 2) glow de acento no canto sup-esq (TETO 0.08) — só se accent != null.
    if (accent != null) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader =
              RadialGradient(
                colors: <Color>[
                  accent!.withValues(alpha: 0.08),
                  accent!.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(size.width * 0.12, 0),
                  radius: size.width * 0.9,
                ),
              ),
      );
    }

    // 3) fio-de-luz na borda: stroke 1px, gradiente topo(luz)->base(sombra).
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[edgeHighlight, edgeShadow],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_PanelPainter old) =>
      old.fillTop != fillTop ||
      old.fillBottom != fillBottom ||
      old.edgeHighlight != edgeHighlight ||
      old.edgeShadow != edgeShadow ||
      old.accent != accent ||
      old.radius != radius;
}
