import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/money.dart';
import '../../core/config/app_config.dart';
import '../../core/model/perfil.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/empty_state_hero.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/hero_value_card.dart';
import '../../core/ui/tool_action_card.dart';

/// Painel (hub). Três estados (Blueprint §5.9). A virada validada dá à Divisão
/// e aos tools recorrentes o peso de protagonistas (UI-SPEC §2.1).
class PainelScreen extends ConsumerWidget {
  const PainelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileState state = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => context.push(Routes.config),
          ),
        ],
      ),
      body: switch (state) {
        ProfileEmpty() => EmptyStateHero(onComecar: () => context.push(Routes.calc)),
        ProfileError(message: final String m) => _ErrorView(message: m),
        ProfileReady(perfil: final Perfil p) => _PainelBody(perfil: p),
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: Space.x3),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: Space.x6),
            FilledButton(
              onPressed: () => context.push(Routes.calc),
              child: const Text('Começar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PainelBody extends StatelessWidget {
  const _PainelBody({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final ValorHoraResult r = computeValorHora(perfil);
    final Divisao div = divisaoFromProfile(perfil, r);
    final String regimeTag = Regime.of(perfil.regime).tag;
    final bool stale = tabelasDefasadas(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(Space.x4),
      children: <Widget>[
        HeroValueCard(
          valorHora: r.valorHora,
          subtitle: 'pra ganhar ${moneyBRL(r.lucro)}/mês',
          onVerComoCheguei: () => context.push(Routes.detalhe),
          staleAno: stale ? kTabelasAno : null,
        ),
        const SizedBox(height: Space.x6),

        // Os dois tools recorrentes, protagonistas (a virada) — peso >= herói.
        Row(
          children: <Widget>[
            Expanded(
              child: ToolActionCard(
                icon: Icons.payments_outlined,
                title: 'Recebi um\npagamento',
                onTap: () => context.push(Routes.reserva),
              ),
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: ToolActionCard(
                icon: Icons.request_quote_outlined,
                title: 'Vou orçar\num projeto',
                onTap: () => context.push(Routes.simulador),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x6),

        Text('DE CADA MÊS',
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: Space.x3),
        DivisaoBar(lucro: div.lucro, reserva: div.reserva, custo: div.custo),
        const SizedBox(height: Space.x2),
        Text('Reserve ~${r.reservaPct}% de cada pagamento (regime: $regimeTag).',
            style: theme.textTheme.bodyMedium?.copyWith(color: d.reserva)),
        const SizedBox(height: Space.x6),

        FilledButton.icon(
          onPressed: () => context.push(Routes.calc),
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('Recalcular'),
        ),
        const SizedBox(height: Space.x4),
        const EstimativaSeal(),
      ],
    );
  }
}
