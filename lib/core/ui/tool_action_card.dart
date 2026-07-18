import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Card-ação dos tools recorrentes (DS §6.3). Na virada, têm peso de
/// protagonista (>= card-herói). Use dois lado a lado, num Row de Expanded.
class ToolActionCard extends StatelessWidget {
  const ToolActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: cs.secondaryContainer,
        borderRadius: const BorderRadius.all(Radii.lg),
        child: InkWell(
          onTap: onTap,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
