import 'package:flutter/material.dart';

import '../common/money.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

/// Número de dinheiro que "chega" animado (o momento aha, DS §5.4).
/// - Nascimento (Resultado/Painel/Histórico): default `Motion.countUp`
///   (600ms) + passe `curve: MotionCurves.landing` explicitamente — o número
///   "pousa" (freio forte no fim) só nos 3 sites onde o valor nasce ao
///   carregar a tela.
/// - Tools ao vivo (Reserva/Simulador/Calc/Detalhe): passe
///   `duration: Motion.quick` e NÃO passe `curve` — mantém o default
///   `MotionCurves.easeOut`, senão o freio de pouso atrapalha o número
///   "correndo atrás do dedo" (o TweenAnimationBuilder anima do valor
///   exibido atual para o novo; o zero só vale no primeiro build).
/// Respeita "reduzir movimento" do sistema.
///
/// Acessibilidade: o label semântico é SEMPRE o valor final (nunca um frame
/// intermediário da animação) — fallback interno, impossível de esquecer.
class MoneyCountUp extends StatelessWidget {
  const MoneyCountUp(
    this.value, {
    super.key,
    required this.style,
    this.semanticLabel,
    this.duration = Motion.countUp,
    this.curve = MotionCurves.easeOut,
    this.suffix = '',
    this.endTint,
    this.from,
  });

  final num value;

  /// De onde a contagem parte. `null` = do zero.
  ///
  /// A diferença é semântica, não técnica: `0 → 412` diz "você tem 412";
  /// `344 → 412` diz "você acabou de crescer 68". A segunda frase é a razão de
  /// voltar mês que vem — e é ela que o acúmulo precisa contar.
  final num? from;
  final TextStyle style;
  final String? semanticLabel;
  final Duration duration;
  final Curve curve;

  /// Sufixo não-monetário (ex.: ' h/mês') — quando presente, formata sem R$.
  final String suffix;

  /// "Acende" na chegada (Lúa §5.6): interpola a cor do estilo até [endTint]
  /// nos ~20% finais da animação — o número termina de contar e vira ouro.
  /// Em reduce-motion, usa a cor final direto.
  final Color? endTint;

  String _fmt(num v) => suffix.isEmpty ? moneyBRL(v) : '${v.round()}$suffix';

  @override
  Widget build(BuildContext context) {
    final String label = semanticLabel ?? _fmt(value);
    if (reduceMotionOf(context)) {
      final TextStyle s = endTint == null
          ? style
          : style.copyWith(color: endTint);
      return Text(_fmt(value), style: s, semanticsLabel: label);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: (from ?? 0).toDouble(),
        end: value.toDouble(),
      ),
      duration: duration,
      curve: curve,
      builder: (BuildContext context, double v, Widget? child) {
        TextStyle s = style;
        final Color? tint = endTint;
        final double inicio = (from ?? 0).toDouble();
        final double span = value.toDouble() - inicio;
        if (tint != null && span != 0) {
          final double p = ((v - inicio) / span).clamp(0.0, 1.0);
          final double t = ((p - 0.8) / 0.2).clamp(0.0, 1.0);
          s = style.copyWith(color: Color.lerp(style.color, tint, t));
        }
        return Text(_fmt(v), style: s, semanticsLabel: label);
      },
    );
  }
}
