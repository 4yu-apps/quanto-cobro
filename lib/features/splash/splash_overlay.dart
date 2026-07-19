import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/cofre_mark.dart';

/// Brand reveal "Cofre Aberto" (coreografia Kenji, look Lúa). Um véu por cima do
/// app já pronto — não é espera de loading (o app é local-first). Fundo charcoal
/// com spotlight (a assinatura escura, mesmo no tema claro): a aurora acende, o
/// anel da Divisão se desenha, o núcleo R$ nasce (haptic — o mesmo tick do
/// herói), o fio-de-ouro passa, e o wordmark sobe. Tap pula. Reduce-motion = um
/// fade curto do estado final. Total ~1.7s cold-start.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> with TickerProviderStateMixin {
  late final AnimationController _reveal =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _exit =
      AnimationController(vsync: this, duration: Motion.base);
  bool _hapticFired = false;
  bool _reduce = false;
  bool _started = false;

  // Cores do "Cofre Aberto" no splash (sempre no escuro — é peça de marca).
  static const Color _esmeralda = Color(0xFF57E5A9);
  static const Color _ouro = Color(0xFFEFCE6F);
  static const Color _marfim = Color(0xFFE4E9E7);
  static const Color _bgCentro = Color(0xFF17201B);
  static const Color _bgBorda = Color(0xFF0A0C0B);

  @override
  void initState() {
    super.initState();
    _reveal.addListener(_maybeHaptic);
    _exit.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    // Começa após o 1º frame real pintar por baixo (sem flash).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reduce = reduceMotionOf(context);
      _started = true;
      if (_reduce) {
        _reveal.value = 1;
        Future<void>.delayed(const Duration(milliseconds: 500), _startExit);
      } else {
        _reveal.forward().whenComplete(_startExit);
      }
      setState(() {});
    });
  }

  void _maybeHaptic() {
    if (!_hapticFired && !_reduce && _reveal.value >= 0.44) {
      _hapticFired = true;
      Haptics.resultBorn();
    }
  }

  void _startExit() {
    if (mounted && !_exit.isAnimating && _exit.value == 0) _exit.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _exit.dispose();
    super.dispose();
  }

  double _seg(double t, double a, double b, {Curve curve = Curves.linear}) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Abrir o app',
      button: true,
      child: GestureDetector(
        onTap: _startExit,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_reveal, _exit]),
          builder: (BuildContext context, Widget? _) {
            final double t = _reveal.value;
            final double exitT = _exit.value;
            final double aurora = _started
                ? (_reduce ? 1 : _seg(t, 0.0, 0.24, curve: MotionCurves.emphasizedDecel))
                : 0;
            final double ring =
                _reduce ? 1 : _seg(t, 0.14, 0.56, curve: MotionCurves.emphasizedDecel);
            final double markIn =
                _reduce ? 1 : _seg(t, 0.14, 0.30, curve: MotionCurves.standard);
            final double core =
                _reduce ? 1 : _seg(t, 0.44, 0.74, curve: MotionCurves.emphasizedDecel);
            final double sheen =
                _reduce ? 0 : _seg(t, 0.62, 0.90, curve: MotionCurves.standard);
            final double word =
                _reduce ? 1 : _seg(t, 0.66, 1.00, curve: MotionCurves.emphasizedDecel);
            final double tag =
                _reduce ? 1 : _seg(t, 0.75, 1.00, curve: MotionCurves.emphasizedDecel);
            final double markScale = _reduce ? 1.0 : (0.90 + 0.10 * ring);
            final double overlayOpacity = _reduce ? word : 1.0; // reduce: fade tudo junto

            return Opacity(
              opacity: (1 - exitT) * overlayOpacity,
              child: Transform.scale(
                scale: 1 + 0.03 * exitT,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.12),
                      radius: 0.9,
                      colors: <Color>[_bgCentro, _bgBorda],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _AuroraPainter(aurora),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Opacity(
                            opacity: markIn,
                            child: Transform.scale(
                              scale: markScale,
                              child: CofreMark(
                                size: 132,
                                ring: ring,
                                core: core,
                                sheen: sheen,
                                esmeralda: _esmeralda,
                                ouro: _ouro,
                                coreColor: _marfim,
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.x6),
                          Opacity(
                            opacity: word,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - word)),
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontFamily: AppType.numberFamily,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 26,
                                    letterSpacing: -0.5,
                                    color: _marfim,
                                  ),
                                  children: const <InlineSpan>[
                                    TextSpan(text: 'Quanto Cobro'),
                                    TextSpan(
                                      text: '?',
                                      style: TextStyle(color: _esmeralda),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.x2),
                          Opacity(
                            opacity: tag,
                            child: Transform.translate(
                              offset: Offset(0, 8 * (1 - tag)),
                              child: Text(
                                AppConfig.tagline,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppType.uiFamily,
                                  fontSize: 13,
                                  color: Color(0xFFACB4B1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Aurora do Cofre do splash — 2 glows radiais (esmeralda topo-esquerda, ouro
/// rodapé-direita) cuja intensidade segue o canal [t] 0..1. Estático (pinta a
/// cada frame do reveal, mas é barato: 2 drawRect com shader).
class _AuroraPainter extends CustomPainter {
  const _AuroraPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final Rect rect = Offset.zero & size;
    final double raio = size.width * 0.9;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFF57E5A9).withValues(alpha: 0.10 * t),
            const Color(0xFF57E5A9).withValues(alpha: 0),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.3), radius: raio)),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFEFCE6F).withValues(alpha: 0.09 * t),
            const Color(0xFFEFCE6F).withValues(alpha: 0),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(size.width * 0.82, size.height * 0.72), radius: raio)),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}
