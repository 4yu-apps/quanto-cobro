import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Curvas do Design System §5.4. As durações vivem em [Motion] (tokens.dart);
/// aqui ficam as curvas e o gate único de "reduzir movimento".
abstract final class MotionCurves {
  /// standard: cubic-bezier(0.2, 0, 0, 1)
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// emphasized-decelerate: cubic-bezier(0.05, 0.7, 0.1, 1)
  static const Curve emphasizedDecel = Cubic(0.05, 0.7, 0.1, 1);

  static const Curve easeOut = Curves.easeOut;
}

/// Gate único de reduce-motion: toda animação do app consulta aqui.
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Mapa de haptics do app (MOTION-SPEC §4): feedback físico discreto nos
/// momentos de valor. Nunca em digitação contínua (vira ruído).
abstract final class Haptics {
  /// Resultado/valor "nasce" (aha calmo).
  static void resultBorn() => HapticFeedback.lightImpact();

  /// Ação de compromisso: salvar perfil, salvar no histórico, ativar Pro.
  static void commit() => HapticFeedback.mediumImpact();

  /// Seleção leve: chip de custo, escolher regime, trocar tema/segmento.
  static void select() => HapticFeedback.selectionClick();
}

/// Envolve qualquer card/botão custom com o press-scale 0.98 do DS §6.4.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || reduceMotionOf(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: Motion.quick,
        curve: MotionCurves.standard,
        child: widget.child,
      ),
    );
  }
}

/// Entrada em cascata (stagger) para listas de blocos: fade + leve subida.
/// Uso: envolver cada bloco com index crescente. Em reduce-motion, estático.
class StaggerIn extends StatelessWidget {
  const StaggerIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context)) return child;
    final int delayMs = 60 * index;
    final int totalMs = Motion.emphasized.inMilliseconds + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(
        delayMs / totalMs,
        1,
        curve: MotionCurves.emphasizedDecel,
      ),
      builder: (BuildContext context, double t, Widget? c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}
