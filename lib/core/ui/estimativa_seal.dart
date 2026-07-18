import 'package:flutter/material.dart';

import '../theme/divisao_colors.dart';
import '../theme/tokens.dart';

/// Selo "estimativa de planejamento" (Blueprint §5.9 / DS §6.11): onipresente e
/// CALMO. Nunca vermelho/âmbar — é informação, não alarme.
class EstimativaSeal extends StatelessWidget {
  const EstimativaSeal({super.key, this.short = false});

  final bool short;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: Space.x2),
      decoration: BoxDecoration(
        color: d.sealBg,
        borderRadius: const BorderRadius.all(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: d.sealFg),
          const SizedBox(width: Space.x2),
          Flexible(
            child: Text(
              short
                  ? 'Estimativa pra te ajudar a decidir.'
                  : 'Estimativa de planejamento, não é consultoria fiscal.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: d.sealFg),
            ),
          ),
        ],
      ),
    );
  }
}
