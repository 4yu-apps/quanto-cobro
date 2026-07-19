import 'package:flutter/material.dart';

import '../common/money.dart';
import '../theme/app_typography.dart';
import '../theme/tokens.dart';
import 'money_count_up.dart';
import 'stale_banner.dart';
import 'vitrine_card.dart';

/// Card-herói do valor-hora (DS §6.1) — o elemento de maior presença do app.
/// Vive numa VitrineCard (aurora do Cofre). O número-herói fica ESTÁVEL
/// durante o count-up (largura final reservada por um texto-fantasma) e escala
/// pra baixo com fonte grande do sistema (FittedBox — o herói tem prioridade
/// de espaço, nunca estoura).
class HeroValueCard extends StatelessWidget {
  const HeroValueCard({
    super.key,
    required this.valorHora,
    required this.subtitle,
    this.perfilNome,
    this.onPerfilTap,
    this.onVerComoCheguei,
    this.staleAno,
  });

  final int valorHora;
  final String subtitle;
  final String? perfilNome;
  final VoidCallback? onPerfilTap;
  final VoidCallback? onVerComoCheguei;
  final int? staleAno;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    // "Número iluminado por dentro" (DS §6): glow sutil só no escuro — no
    // claro smudge sobre branco. Nunca gradiente no dígito, cor sólida.
    final TextStyle heroStyle = AppType.valueHero.copyWith(
      color: cs.primary,
      shadows: theme.brightness == Brightness.dark
          ? <Shadow>[
              Shadow(color: cs.primary.withValues(alpha: 0.16), blurRadius: 18),
            ]
          : null,
    );
    return VitrineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (perfilNome != null) ...<Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Trabalho ativo: $perfilNome',
                hint: 'Toque duas vezes pra trocar de trabalho',
                child: ExcludeSemantics(
                  child: Material(
                    color: cs.secondaryContainer,
                    borderRadius: const BorderRadius.all(Radii.full),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radii.full),
                      onTap: onPerfilTap,
                      // Alvo ≥48dp (DS §7); a pintura interna continua compacta.
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.x3,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.work_outline,
                              size: 14,
                              color: cs.onSecondaryContainer,
                            ),
                            const SizedBox(width: Space.x1),
                            Text(
                              perfilNome!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: cs.onSecondaryContainer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.x2),
          ],
          Text(
            'SEU VALOR-HORA',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: Space.x1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                // Largura final reservada: o número sobe DENTRO de uma moldura
                // estável; o sufixo não cavalga durante o count-up.
                Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    ExcludeSemantics(
                      child: Opacity(
                        opacity: 0,
                        child: Text(moneyBRL(valorHora), style: heroStyle),
                      ),
                    ),
                    MoneyCountUp(
                      valorHora,
                      style: heroStyle,
                      semanticLabel:
                          'Seu valor-hora: ${moneyBRL(valorHora)} por hora',
                    ),
                  ],
                ),
                ExcludeSemantics(
                  child: Text(
                    ' /hora',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          if (staleAno != null) ...<Widget>[
            const SizedBox(height: Space.x3),
            StaleBanner(ano: staleAno!, footnote: true),
          ],
          if (onVerComoCheguei != null) ...<Widget>[
            const SizedBox(height: Space.x2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onVerComoCheguei,
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Ver como cheguei aqui'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
