import 'package:flutter/material.dart';

import '../glossario/glossario.dart';
import '../theme/tokens.dart';

/// "?" de ajuda ao lado de um termo difícil. Abre um balão curto com o verbete
/// do [Glossario] em linguagem de gente (auditoria Bruno/leigo, Dona Marta).
///
/// Acessível de propósito: alvo de toque ≥ 48dp (Tiago/motor) e rótulo de
/// leitor de tela vindo do título do verbete (TalkBack lê "O que é regime?,
/// botão"), nunca um "?" mudo.
class HelpDot extends StatelessWidget {
  const HelpDot({super.key, required this.verbeteId, this.size = 20});

  final String verbeteId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Verbete v = Glossario.of(verbeteId);
    final ColorScheme cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(Icons.help_outline, size: size, color: cs.onSurfaceVariant),
      tooltip: v.titulo,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: EdgeInsets.zero,
      onPressed: () => showHelpSheet(context, verbeteId),
    );
  }
}

/// Abre o balão do verbete. Exposto à parte pra links de texto ("Qual é o meu?")
/// poderem chamar sem um ícone.
Future<void> showHelpSheet(BuildContext context, String verbeteId) {
  final Verbete v = Glossario.of(verbeteId);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) {
      final ThemeData theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(v.titulo, style: theme.textTheme.titleLarge),
              const SizedBox(height: Space.x3),
              Text(v.texto, style: theme.textTheme.bodyLarge),
              const SizedBox(height: Space.x4),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendi'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
