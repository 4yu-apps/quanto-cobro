import 'package:flutter/material.dart';

import '../common/money.dart';
import '../theme/tokens.dart';

/// Número de dinheiro que "chega" com count-up (o momento aha, DS §5.4). Use
/// onde um resultado NASCE (Painel, Resultado, Detalhamento). Nos tools ao vivo
/// (reserva/simulador) use Text normal — count-up a cada tecla atrapalharia.
/// Respeita "reduzir movimento" do sistema.
class MoneyCountUp extends StatelessWidget {
  const MoneyCountUp(this.value, {super.key, required this.style, this.semanticLabel});

  final num value;
  final TextStyle style;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bool reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      return Text(moneyBRL(value), style: style, semanticsLabel: semanticLabel);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: Motion.countUp,
      curve: Curves.easeOut,
      builder: (BuildContext context, double v, Widget? child) =>
          Text(moneyBRL(v), style: style, semanticsLabel: semanticLabel),
    );
  }
}
