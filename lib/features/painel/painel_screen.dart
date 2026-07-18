import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/config/app_config.dart';
import '../../core/model/perfil.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';

/// Painel (hub). No esqueleto já fia o motor de cálculo na UI (prova a
/// arquitetura ponta a ponta). O layout final vem depois, guiado pela IA e pelo
/// Design System — aqui a hierarquia só sinaliza a virada: a Divisão e "Recebi
/// um pagamento" são protagonistas, não só o valor-hora.
class PainelScreen extends StatelessWidget {
  const PainelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors divisao = theme.extension<DivisaoColors>()!;
    final Perfil perfil = Perfil.padrao();
    final ValorHoraResult r = computeValorHora(perfil);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.config),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('SEU VALOR-HORA', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            'R\$ ${r.valorHora}',
            style: AppType.valueHero.copyWith(color: theme.colorScheme.primary),
          ),
          Text('pra ganhar R\$ ${r.lucro.round()}/mês', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(Routes.reserva),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Recebi um pagamento'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.simulador),
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Vou orçar um projeto'),
          ),
          const SizedBox(height: 24),
          Text('De cada pagamento, reserve', style: theme.textTheme.labelLarge),
          Text(
            '~${r.reservaPct}%  (regime: MEI)',
            style: theme.textTheme.titleLarge?.copyWith(color: divisao.reserva),
          ),
          const SizedBox(height: 8),
          Text('Lucro real estimado: R\$ ${r.lucro.round()}/mês'),
          Text('Custos cadastrados: R\$ ${r.custos.round()}/mês'),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.push(Routes.detalhe),
            child: const Text('Ver como cheguei'),
          ),
          TextButton(
            onPressed: () => context.push(Routes.calc),
            child: const Text('Recalcular'),
          ),
          const SizedBox(height: 24),
          Text(
            'Estimativa de planejamento, não é consultoria fiscal.',
            style: theme.textTheme.labelMedium?.copyWith(color: divisao.sealFg),
          ),
        ],
      ),
    );
  }
}
