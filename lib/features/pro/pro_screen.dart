import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';

/// Tela Pro (Blueprint §11): oferta transparente, no momento de valor. Preço e
/// o que é Pro aparecem ANTES de o usuário investir trabalho (anti-★1 R2). O
/// núcleo do app é sempre grátis; um único CTA primário fecha a escolha.
class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

enum _Plano { vitalicio, anual, mensal }

class _ProScreenState extends ConsumerState<ProScreen> {
  _Plano _plano = _Plano.vitalicio;

  static const List<(IconData, String)> _beneficios = <(IconData, String)>[
    (Icons.picture_as_pdf_outlined, 'Exportar orçamento em PDF com sua marca'),
    (Icons.switch_account_outlined, 'Vários trabalhos (cliente recorrente x avulso)'),
    (Icons.tune, 'Modo avançado por regime (faixas do Simples, INSS, deduções)'),
    (Icons.public, 'Módulo freela pra gringo (USD, carnê-leão mensal)'),
    (Icons.block, 'Remover anúncios'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isPro = ref.watch(proProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pro')),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          if (isPro)
            Card(
              color: cs.surfaceContainer,
              child: const ListTile(
                leading: Icon(Icons.check_circle),
                title: Text('Pro ativo'),
                subtitle: Text('Obrigado! Todos os recursos Pro estão liberados.'),
              ),
            )
          else ...<Widget>[
            // Header de venda: presença, não recibo.
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration:
                    BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.workspace_premium, size: 40, color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: Space.x4),
            Text('Faça mais com o Pro',
                textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            const SizedBox(height: Space.x1),
            Text('O cálculo, a reserva e o simulador são grátis pra sempre.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: Space.x6),
          for (final (IconData icon, String label) in _beneficios)
            Padding(
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
            ),
          if (!isPro) ...<Widget>[
            const SizedBox(height: Space.x4),
            _plano_(context, _Plano.vitalicio, 'Vitalício (sem assinatura)', 'R\$ 129, uma vez só',
                destaque: true),
            _plano_(context, _Plano.anual, 'Anual', 'R\$ 89,90/ano'),
            _plano_(context, _Plano.mensal, 'Mensal', 'R\$ 12,90/mês'),
            const SizedBox(height: Space.x4),
            FilledButton(
              onPressed: () async {
                final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                final GoRouter router = GoRouter.of(context);
                Haptics.commit();
                await ref.read(proProvider.notifier).grant();
                messenger
                  ..clearSnackBars()
                  ..showSnackBar(const SnackBar(content: Text('Pro ativado')));
                router.pop();
              },
              child: Text(_plano == _Plano.vitalicio ? 'Desbloquear pra sempre' : 'Assinar'),
            ),
            const SizedBox(height: Space.x2),
            Text(
              'Preços provisórios. O pagamento real é ligado com a configuração da loja; '
              'por ora o Pro é ativado localmente pra você testar.',
              style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(const SnackBar(
                      content: Text(
                          'A restauração fica disponível quando a compra pela loja for ativada. Você não perde nada.')));
              },
              child: const Text('Restaurar compras'),
            ),
          ] else
            FilledButton(onPressed: () => context.pop(), child: const Text('Voltar')),
        ],
      ),
    );
  }

  Widget _plano_(BuildContext context, _Plano plano, String titulo, String valor,
      {bool destaque = false}) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool selected = _plano == plano;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: Material(
        color: selected ? cs.secondaryContainer : cs.surfaceContainerLow,
        borderRadius: const BorderRadius.all(Radii.md),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radii.md),
          onTap: () {
            Haptics.select();
            setState(() => _plano = plano);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radii.md),
              border: selected ? Border.all(color: cs.primary, width: 1.5) : null,
            ),
            padding: const EdgeInsets.all(Space.x3),
            child: Row(
              children: <Widget>[
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? cs.primary : cs.outline,
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(child: Text(titulo, style: theme.textTheme.titleMedium)),
                          if (destaque) ...<Widget>[
                            const SizedBox(width: Space.x2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Space.x2, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: const BorderRadius.all(Radii.full),
                              ),
                              child: Text('MELHOR VALOR',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onPrimaryContainer, letterSpacing: 0.5)),
                            ),
                          ],
                        ],
                      ),
                      Text(valor,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
