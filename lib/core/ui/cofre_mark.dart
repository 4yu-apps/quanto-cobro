import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// A marca "Cofre Aberto" (proposta Lúa) — o anel-moeda que se ABRE: um arco
/// esmeralda dominante ("é seu") + um arco de ouro (a reserva) com uma FRESTA
/// aberta no topo-direita (o tesouro escapando = o cofre está aberto), e um
/// "R$" no centro (o que mora dentro, e a assinatura brasileira do produto).
///
/// Três canais de animação 0..1 (regência do Kenji), independentes:
/// - [ring]  desenha os dois arcos (sweep crescente).
/// - [core]  faz o "R$" nascer (opacity + innerScale 0.92→1.0).
/// - [sheen] varre uma banda especular de ouro pela marca (o fio-de-ouro).
/// Estático (ícone/header) = ring 1, core 1, sheen 0.
class CofreMark extends StatelessWidget {
  const CofreMark({
    super.key,
    this.size = 96,
    this.ring = 1,
    this.core = 1,
    this.sheen = 0,
    this.esmeralda,
    this.ouro,
    this.coreColor,
    this.coreScale = 1,
  });

  final double size;
  final double ring;
  final double core;
  final double sheen;

  /// Tamanho do `R$` em relação ao anel. 1 é a marca como ela nasceu.
  ///
  /// Existe por causa do ÍCONE: no tamanho de lançador, o `$` encostava no
  /// arco esmeralda e os dois viravam uma mancha só. A folga geométrica era
  /// real mas mínima — ~4% do raio interno —, e 4% some no antialiasing de um
  /// ícone de 48dp. O splash e o cabeçalho continuam em 1: quem precisa de ar
  /// é o ícone, não a marca grande.
  final double coreScale;

  /// Cores; default puxa do tema (primary/tertiary/onSurface).
  final Color? esmeralda;
  final Color? ouro;
  final Color? coreColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CofreMarkPainter(
          ring: ring,
          core: core,
          sheen: sheen,
          coreScale: coreScale,
          esmeralda: esmeralda ?? cs.primary,
          ouro: ouro ?? cs.tertiary,
          coreColor: coreColor ?? cs.onSurface,
        ),
      ),
    );
  }
}

class CofreMarkPainter extends CustomPainter {
  CofreMarkPainter({
    required this.ring,
    required this.core,
    required this.sheen,
    required this.esmeralda,
    required this.ouro,
    required this.coreColor,
    this.coreScale = 1,
  });

  final double ring;
  final double core;
  final double sheen;
  final double coreScale;
  final Color esmeralda;
  final Color ouro;
  final Color coreColor;

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 0..100 → escala para o tamanho real.
    final double s = size.shortestSide / 100;
    canvas.save();
    canvas.scale(s);

    const Offset c = Offset(50, 50);
    const double r = 34;
    const double stroke = 11;
    final Rect ringRect = Rect.fromCircle(center: c, radius: r);

    // Arco de OURO (reserva): 11h→1:30, sweep 55°, cresce com `ring`.
    final Paint ouroPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = ouro;
    canvas.drawArc(
      ringRect,
      _rad(-100),
      _rad(55 * ring.clamp(0, 1)),
      false,
      ouroPaint,
    );

    // Arco ESMERALDA ("é seu"): 2:30 dando a volta até 10:30, sweep 260°.
    final Paint esmPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = esmeralda;
    canvas.drawArc(
      ringRect,
      _rad(-12),
      _rad(260 * ring.clamp(0, 1)),
      false,
      esmPaint,
    );

    // Núcleo "R$": nasce depois do anel (opacity + innerScale).
    final double coreT = core.clamp(0, 1);
    if (coreT > 0.01) {
      final double scale = (0.92 + 0.08 * coreT) * coreScale;
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: r'R$',
          style: TextStyle(
            fontFamily: AppType.numberFamily,
            fontWeight: FontWeight.w700,
            fontSize: 34,
            height: 1.0,
            color: coreColor.withValues(alpha: coreT),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(scale);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Fio-de-ouro: banda especular diagonal varrendo a marca (clipada ao disco).
    final double sheenT = sheen.clamp(0, 1);
    if (sheenT > 0.001 && sheenT < 0.999) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: c, radius: r + stroke / 2)),
      );
      final double x = -30 + 160 * sheenT; // -0.3w → 1.3w
      final Rect band = Rect.fromLTWH(x, -10, 26, 120);
      final Paint sheenPaint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            ouro.withValues(alpha: 0),
            ouro.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.35),
            ouro.withValues(alpha: 0),
          ],
          stops: const <double>[0.0, 0.45, 0.55, 1.0],
        ).createShader(band);
      canvas.save();
      canvas.translate(band.center.dx, band.center.dy);
      canvas.rotate(_rad(-22));
      canvas.translate(-band.center.dx, -band.center.dy);
      canvas.drawRect(band, sheenPaint);
      canvas.restore();
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CofreMarkPainter old) =>
      old.ring != ring ||
      old.core != core ||
      old.sheen != sheen ||
      old.esmeralda != esmeralda ||
      old.ouro != ouro ||
      old.coreColor != coreColor ||
      old.coreScale != coreScale;
}
