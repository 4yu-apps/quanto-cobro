import 'package:flutter/material.dart';

import '../theme/materials.dart';
import '../theme/motion.dart';
import '../theme/pro_colors.dart';
import '../theme/tokens.dart';

/// A pílula "✦ PRO" — a conquista, em roxo-marca (ver [ProColors]).
///
/// Reaproveitada em três lugares: ao lado do título na home, no recibo da tela
/// Pro e no trailing das Configurações. "Premium alegre" sem ouro: pintura
/// chapada + degradê estático (sheen, custo ~zero) + a faísca. A cor nunca vem
/// sozinha — a palavra "PRO" e o glifo carregam o sinal se o roxo sumir.
///
/// No nascimento faz um "pop" one-shot (escala 0.8→1): quando o Pro é ativado e
/// a pessoa volta pra home, o selo entra comemorando — o feedback que o dono
/// pediu. Respeita reduce-motion (aparece seco).
class ProSelo extends StatelessWidget {
  const ProSelo({super.key, this.animar = true});

  /// Desliga o "pop" — pra usos onde o selo é decoração estável (config), não
  /// uma conquista que acabou de acontecer.
  final bool animar;

  @override
  Widget build(BuildContext context) {
    final ProColors pc = Theme.of(context).extension<ProColors>()!;
    final Materials m = Theme.of(context).extension<Materials>()!;

    final Widget selo = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // Degradê topo-mais-claro: ametista polida sob luz, não pigmento chapado.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.alphaBlend(Colors.white.withValues(alpha: 0.06), pc.proSolid),
            pc.proSolid,
          ],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        // Fio-de-luz no topo: o mesmo material dos cards.
        border: Border(top: BorderSide(color: m.edgeHighlight)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.auto_awesome, size: 13, color: pc.onProSolid),
          const SizedBox(width: 4),
          Text(
            'PRO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: pc.onProSolid,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );

    // Semântica: um selo só, "Pro ativo" — não "faísca, P, R, O".
    final Widget rotulado = Semantics(
      label: 'Pro ativo',
      excludeSemantics: true,
      child: selo,
    );

    if (!animar || reduceMotionOf(context)) return rotulado;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1),
      duration: Motion.emphasized,
      curve: MotionCurves.emphasizedDecel,
      builder: (BuildContext context, double t, Widget? child) =>
          Transform.scale(scale: t, child: Opacity(opacity: t, child: child)),
      child: rotulado,
    );
  }
}
