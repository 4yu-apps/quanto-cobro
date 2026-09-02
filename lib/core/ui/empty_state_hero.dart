import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'cena.dart';

/// Estado vazio do primeiro uso (DS §6.16): fisga a dor, mostra a assinatura
/// da casa (a [Cena]) antes mesmo de calcular, e promete pouco esforço.
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
            // A assinatura da casa como emblema. Antes era uma DivisaoBar de
            // exemplo dentro de um Card: números inventados que a pessoa ainda
            // não tem jeito de conferir, no lugar mais nobre da primeira tela.
            // A Cena diz a mesma coisa sem fingir dado.
            const Cena(tipo: CenaTipo.inicio),
            const SizedBox(height: Space.x6),
            Text(
              'Você provavelmente cobra menos do que deveria.',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: Space.x3),
            Text(
              'Descubra seu valor-hora justo em 5 perguntas.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x6),
            FilledButton(onPressed: onComecar, child: const Text('Começar')),
            const SizedBox(height: Space.x3),
            // Em 320dp (o celular barato, que é o público) este Row estourava
            // 144px e "100% offline" saía da tela — a promessa que a primeira
            // tela do app existe pra fazer. Flexible + softWrap: o texto quebra
            // em duas linhas em vez de vazar.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.x2),
                Flexible(
                  child: Text(
                    'Leva 2 minutos · 100% offline',
                    softWrap: true,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
