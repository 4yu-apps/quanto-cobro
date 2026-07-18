import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/motion.dart';

/// Tela Pro (Blueprint §11): oferta transparente, no momento de valor. Preço e o
/// que é Pro aparecem ANTES de o usuário investir trabalho (regra anti-★1 R2).
/// O núcleo do app é sempre grátis; o Pro é escolha, com compra única disponível.
class ProScreen extends ConsumerWidget {
  const ProScreen({super.key});

  static const List<(IconData, String)> _beneficios = <(IconData, String)>[
    (Icons.picture_as_pdf_outlined, 'Exportar orçamento em PDF com sua marca'),
    (Icons.switch_account_outlined, 'Vários perfis (cliente recorrente x avulso)'),
    (Icons.tune, 'Modo avançado por regime (faixas do Simples, INSS, deduções)'),
    (Icons.public, 'Módulo freela pra gringo (USD, carnê-leão mensal)'),
    (Icons.block, 'Remover anúncios'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPro = ref.watch(proProvider);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (isPro)
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Pro ativo'),
                subtitle: const Text('Obrigado! Todos os recursos Pro estão liberados.'),
              ),
            )
          else ...<Widget>[
            Text('Faça mais com o Pro', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('O cálculo, a reserva e o simulador são grátis pra sempre.',
                style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          for (final (IconData icon, String label) in _beneficios)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon),
              title: Text(label),
              dense: true,
            ),
          const Divider(height: 32),
          if (!isPro) ...<Widget>[
            _preco(context, ref, 'Vitalício (sem assinatura)', 'R\$ 129, uma vez só',
                cta: 'Comprar', destaque: true),
            _preco(context, ref, 'Anual', 'R\$ 89,90/ano', cta: 'Assinar'),
            _preco(context, ref, 'Mensal', 'R\$ 12,90/mês', cta: 'Assinar'),
            const SizedBox(height: 8),
            Text(
              'Preços provisórios. O pagamento real é ligado com a configuração da loja; '
              'por ora o Pro é ativado localmente pra você testar.',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Nada a restaurar por enquanto.')));
              },
              child: const Text('Restaurar compras'),
            ),
          ] else
            FilledButton(onPressed: () => context.pop(), child: const Text('Voltar')),
        ],
      ),
    );
  }

  Widget _preco(BuildContext context, WidgetRef ref, String titulo, String valor,
      {required String cta, bool destaque = false}) {
    return Card(
      color: destaque ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: ListTile(
        title: Text(titulo),
        subtitle: Text(valor),
        trailing: FilledButton(
          onPressed: () async {
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
            final GoRouter router = GoRouter.of(context);
            Haptics.commit();
            await ref.read(proProvider.notifier).grant();
            messenger.showSnackBar(const SnackBar(content: Text('Pro ativado')));
            router.pop();
          },
          child: Text(cta),
        ),
      ),
    );
  }
}
