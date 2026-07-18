import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Estado vazio do primeiro uso (DS §6.16): fisga a dor, promete pouco esforço,
/// reforça privacidade. Um único CTA, sem ruído.
class EmptyStateHero extends StatelessWidget {
  const EmptyStateHero({super.key, required this.onComecar});

  final VoidCallback onComecar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.x6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Você provavelmente cobra menos do que deveria.',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: Space.x3),
            Text('Descubra seu valor-hora justo em 5 perguntas.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: Space.x6),
            FilledButton(onPressed: onComecar, child: const Text('Começar')),
            const SizedBox(height: Space.x3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: Space.x2),
                Text('Leva 2 minutos · 100% offline',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
