import 'package:flutter/material.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'panel_card.dart';

/// Card-ação dos tools recorrentes (DS §6.3). Na virada, têm peso de
/// protagonista (>= card-herói). Use dois lado a lado, num Row de Expanded.
///
/// "Cofre Aberto": cartão neutro (não compete com o chip aço do herói) e o
/// ÍCONE-líder carrega a cor do destino — Reserva = ouro, Simulador = aço.
/// Acessibilidade: UMA parada de leitor de tela com título + subtítulo.
class ToolActionCard extends StatelessWidget {
  const ToolActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Cor do ícone-líder (a cor do destino). Default: primary.
  final Color? accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Semantics(
      container: true,
      button: true,
      label: subtitle == null ? title : '$title. $subtitle',
      child: ExcludeSemantics(
        child: PressableScale(
          child: PanelCard(
            accent: accent ?? cs.primary,
            padding: const EdgeInsets.all(Space.x4),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  Haptics.select();
                  onTap();
                },
                borderRadius: const BorderRadius.all(Radii.lg),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 104),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Icon(icon, size: 28, color: accent ?? cs.primary),
                      const SizedBox(height: Space.x4),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
