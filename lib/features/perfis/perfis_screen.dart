import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/providers.dart';

/// Perfis (Blueprint §5.7): alternar cenários de preço (cliente x avulso). No
/// MVP há 1 perfil; VÁRIOS perfis é Pro (roadmap v1.1). Aqui mostramos o perfil
/// atual e a porta pro Pro — sem prometer o que ainda não existe.
class PerfisScreen extends ConsumerWidget {
  const PerfisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileState st = ref.watch(profileProvider);
    final bool isPro = ref.watch(proProvider);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (st is ProfileReady)
            Card(
              child: ListTile(
                leading: const Icon(Icons.radio_button_checked),
                title: Text(st.perfil.nome),
                subtitle: Text('${moneyBRL(computeValorHora(st.perfil).valorHora)}/h'),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Você ainda não tem um perfil'),
                subtitle: const Text('Faça seu primeiro cálculo'),
                onTap: () => context.go(Routes.calc),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Vários perfis', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text('Preço muda por tipo de cliente? Tenha um perfil pra cada cenário.'),
                  const SizedBox(height: 12),
                  if (isPro)
                    Text('Recurso Pro liberado. Múltiplos perfis chegam numa próxima versão.',
                        style: theme.textTheme.bodyMedium)
                  else
                    FilledButton(
                      onPressed: () => context.push(Routes.pro),
                      child: const Text('Conhecer o Pro'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
