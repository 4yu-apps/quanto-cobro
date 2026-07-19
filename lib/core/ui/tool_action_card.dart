import 'package:flutter/material.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

/// Card-ação dos tools recorrentes (DS §6.3). Na virada, têm peso de
/// protagonista (>= card-herói). Use dois lado a lado, num Row de Expanded.
class ToolActionCard extends StatelessWidget {
  const ToolActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: title,
      child: PressableScale(
        child: Material(
        color: cs.secondaryContainer,
        borderRadius: const BorderRadius.all(Radii.lg),
        child: InkWell(
          onTap: () {
            Haptics.select();
            onTap();
          },
          borderRadius: const BorderRadius.all(Radii.lg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.all(Space.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(icon, size: 28, color: cs.onSecondaryContainer),
                const SizedBox(height: Space.x4),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: cs.onSecondaryContainer),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.onSecondaryContainer.withValues(alpha: 0.8)),
                  ),
                ],
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
