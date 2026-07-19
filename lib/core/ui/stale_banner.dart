import 'package:flutter/material.dart';

import '../theme/divisao_colors.dart';
import '../theme/tokens.dart';

/// Faixa calma "valores base de [ano]" (DS §2.4). Azul = informação, nunca
/// alarme. Aparece quando as tabelas fiscais embutidas estão defasadas.
class StaleBanner extends StatelessWidget {
  const StaleBanner({super.key, required this.ano});

  final int ano;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: Space.x2),
      decoration: BoxDecoration(color: d.staleBg, borderRadius: const BorderRadius.all(Radii.md)),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: d.staleFg),
          const SizedBox(width: Space.x2),
          Flexible(
            child: Text(
              'Valores base de $ano. Confirme as alíquotas atuais.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: d.staleFg),
            ),
          ),
        ],
      ),
    );
  }
}
