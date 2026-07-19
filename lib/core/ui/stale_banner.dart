import 'package:flutter/material.dart';

import '../theme/divisao_colors.dart';
import '../theme/tokens.dart';

/// Faixa calma "valores base de [ano]" (DS §2.4). Aço = informação, nunca
/// alarme. Aparece quando as tabelas fiscais embutidas estão defasadas.
///
/// [footnote]: variante rebaixada (linha discreta sem container) — pra viver
/// junto do selo de estimativa, nunca empurrando o CTA pra baixo da dobra.
class StaleBanner extends StatelessWidget {
  const StaleBanner({super.key, required this.ano, this.footnote = false});

  final int ano;
  final bool footnote;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    final String texto = footnote
        ? 'Tabelas de $ano — confirme as alíquotas do ano atual.'
        : 'Valores base de $ano. Confirme as alíquotas atuais.';
    if (footnote) {
      final Color fg = Theme.of(context).colorScheme.onSurfaceVariant;
      return Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 14, color: fg),
          const SizedBox(width: Space.x2),
          Flexible(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: fg),
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x3,
        vertical: Space.x2,
      ),
      decoration: BoxDecoration(
        color: d.staleBg,
        borderRadius: const BorderRadius.all(Radii.md),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: d.staleFg),
          const SizedBox(width: Space.x2),
          Flexible(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: d.staleFg),
            ),
          ),
        ],
      ),
    );
  }
}
