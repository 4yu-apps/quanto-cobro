import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/breakpoints.dart';

/// Tela Pro (Blueprint §11): oferta transparente, no momento de valor. Preço e
/// o que é Pro aparecem ANTES de o usuário investir trabalho (anti-★1 R2). O
/// núcleo do app é sempre grátis; um único CTA primário fecha a escolha.
class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key, this.gatilho = GatilhoPro.config});

  /// De ONDE a pessoa chegou aqui. Sem isso, "conversão" é um número só e não
  /// responde a pergunta que decide o roadmap: qual recurso puxa a compra?
  final String gatilho;

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  bool _activating = false;

  static const List<(IconData, String)> _hoje = <(IconData, String)>[
    (
      Icons.switch_account_outlined,
      'Vários trabalhos (cliente recorrente x avulso)',
    ),
    (Icons.block, 'Sem anúncios — quando eles chegarem, você nunca os verá'),
  ];

  static const List<(IconData, String)> _chegando = <(IconData, String)>[
    (Icons.picture_as_pdf_outlined, 'Orçamento em PDF pra mandar ao cliente'),
    (Icons.tune, 'Modo avançado por regime (faixas, INSS, deduções)'),
    (Icons.public, 'Módulo freela pra gringo (USD)'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isPro = ref.watch(proProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pro')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            if (isPro)
              Card(
                color: cs.surfaceContainer,
                child: const ListTile(
                  leading: Icon(Icons.check_circle),
                  title: Text('Pro ativo'),
                  subtitle: Text(
                    'Obrigado! Todos os recursos Pro estão liberados.',
                  ),
                ),
              )
            else ...<Widget>[
              // Header de venda: presença, não recibo.
              Center(
                child: AnimatedScale(
                  duration: reduceMotionOf(context)
                      ? Duration.zero
                      : Motion.emphasized,
                  scale: _activating ? 1.06 : 1,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      size: 40,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.x4),
              Text(
                'Faça mais com o Pro',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: Space.x1),
              Text(
                'O cálculo, a reserva e o simulador são grátis pra sempre.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Space.x6),
            Text('O que o Pro libera hoje', style: theme.textTheme.titleMedium),
            const SizedBox(height: Space.x3),
            for (final (IconData icon, String label) in _hoje)
              _beneficio(context, icon, label),
            const SizedBox(height: Space.x3),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Chegando — já incluso no seu Pro',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  'em desenvolvimento',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x3),
            for (final (IconData icon, String label) in _chegando)
              _beneficio(context, icon, label),
            if (!isPro) ...<Widget>[
              const SizedBox(height: Space.x4),
              // Um plano só (decisão de 19/07/2026). Três opções obrigavam a
              // pessoa a comparar antes de entender o que compra — e a comparação
              // acontecia justamente no instante em que ela ainda estava
              // decidindo SE quer, não COMO paga.
              _plano_(
                context,
                'Pro',
                'R\$ 6,90 por mês · cancela quando quiser',
                destaque: true,
              ),
              const SizedBox(height: Space.x4),
              FilledButton(
                onPressed: _activating
                    ? null
                    : () async {
                        Haptics.commit();
                        await ref.read(proProvider.notifier).grant();
                        telemetry.evento(
                          Evento.proAtivado,
                          params: <String, Object?>{'gatilho': widget.gatilho},
                        );
                        if (!context.mounted) return;
                        setState(() => _activating = true);
                        announce(
                          context,
                          'Pro ativo. Seus vários trabalhos estão liberados.',
                        );
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            const SnackBar(content: Text('Pro ativado')),
                          );
                        if (!reduceMotionOf(context)) {
                          // Sem espera: segurar 600ms quem acabou de
                          // pagar é o pior momento pra fazer alguém esperar.
                        }
                        if (!context.mounted) return;
                        GoRouter.of(context).pop();
                      },
                child: AnimatedSwitcher(
                  duration: reduceMotionOf(context)
                      ? Duration.zero
                      : Motion.base,
                  child: _activating
                      ? const Row(
                          key: ValueKey<String>('ativo'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.check),
                            SizedBox(width: Space.x2),
                            Text('Pro ativo'),
                          ],
                        )
                      : const Text('Assinar', key: ValueKey<String>('comprar')),
                ),
              ),
              const SizedBox(height: Space.x2),
              Text(
                'Preços provisórios. O pagamento real é ligado com a configuração da loja; '
                'por ora o Pro é ativado localmente pra você testar.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'A restauração fica disponível quando a compra pela loja for ativada. Você não perde nada.',
                        ),
                      ),
                    );
                },
                child: const Text('Restaurar compras'),
              ),
            ] else
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Voltar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _beneficio(BuildContext context, IconData icon, String label) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: const BorderRadius.all(Radii.sm),
            ),
            child: Icon(icon, size: 22, color: cs.primary),
          ),
          const SizedBox(width: Space.x3),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }

  /// O card do preço. Com um plano só ele não é uma ESCOLHA — é uma
  /// informação. Por isso não tem rádio (não há o que selecionar) nem selo
  /// "melhor valor" (não há com o que comparar): os dois convidariam a pessoa
  /// a procurar a opção que não existe.
  Widget _plano_(
    BuildContext context,
    String titulo,
    String valor, {
    bool destaque = false,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: MergeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: const BorderRadius.all(Radii.md),
            border: destaque ? Border.all(color: cs.primary, width: 1.5) : null,
          ),
          padding: const EdgeInsets.all(Space.x4),
          child: Row(
            children: <Widget>[
              Icon(Icons.workspace_premium_outlined, color: cs.primary),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(titulo, style: theme.textTheme.titleMedium),
                    Text(
                      valor,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
