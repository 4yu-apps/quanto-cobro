import 'package:flutter/material.dart';

import '../common/money.dart';
import '../theme/app_typography.dart';
import '../theme/tokens.dart';
import 'money_count_up.dart';
import 'stale_banner.dart';

/// Card-herói do valor-hora (DS §6.1) — o elemento de maior presença do app.
/// Envolve o número-herói num contêiner de profundidade (tom de superfície).
class HeroValueCard extends StatelessWidget {
  const HeroValueCard({
    super.key,
    required this.valorHora,
    required this.subtitle,
    this.onVerComoCheguei,
    this.staleAno,
  });

  final int valorHora;
  final String subtitle;
  final VoidCallback? onVerComoCheguei;
  final int? staleAno;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        // "Wash de vitrine" (COLOR-GUIDE 5.1): gradiente tonal sutil no escuro;
        // no claro, superficie chapada + borda sutil.
        gradient: dark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[cs.surfaceContainerHigh, cs.surfaceContainer],
              )
            : null,
        color: dark ? null : cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(Radii.xl),
        border: dark ? null : Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'SEU VALOR-HORA',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: Space.x1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                MoneyCountUp(
                  valorHora,
                  style: AppType.valueHero.copyWith(color: cs.primary),
                  semanticLabel: 'Seu valor-hora: ${moneyBRL(valorHora)} por hora',
                ),
                Text(' /hora',
                    style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
            Text(subtitle, style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
            if (staleAno != null) ...<Widget>[
              const SizedBox(height: Space.x3),
              StaleBanner(ano: staleAno!),
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
      ),
    );
  }
}
