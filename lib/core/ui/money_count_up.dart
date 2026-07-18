import 'package:flutter/material.dart';

import '../common/money.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

/// Número de dinheiro que "chega" animado (o momento aha, DS §5.4).
/// - Nascimento (Resultado/Painel): default `Motion.countUp` (600ms).
/// - Tools ao vivo (Reserva/Simulador): passe `duration: Motion.quick` — o
///   número "corre atrás do dedo" (o TweenAnimationBuilder anima do valor
///   exibido atual para o novo; o zero só vale no primeiro build).
/// Respeita "reduzir movimento" do sistema.
class MoneyCountUp extends StatelessWidget {
  const MoneyCountUp(
    this.value, {
    super.key,
    required this.style,
    this.semanticLabel,
    this.duration = Motion.countUp,
    this.curve = MotionCurves.easeOut,
    this.suffix = '',
  });

  final num value;
  final TextStyle style;
  final String? semanticLabel;
  final Duration duration;
  final Curve curve;

  /// Sufixo não-monetário (ex.: ' h/mês') — quando presente, formata sem R$.
  final String suffix;

  String _fmt(num v) => suffix.isEmpty ? moneyBRL(v) : '${v.round()}$suffix';

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context)) {
      return Text(_fmt(value), style: style, semanticsLabel: semanticLabel);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (BuildContext context, double v, Widget? child) =>
          Text(_fmt(v), style: style, semanticsLabel: semanticLabel),
    );
  }
}
