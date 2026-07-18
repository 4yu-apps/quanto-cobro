import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/config/app_config.dart';
import '../../core/model/perfil.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/estimativa_seal.dart';

/// Painel (hub). Três estados explícitos (Blueprint §5.9): vazio (primeiro uso),
/// pronto (com cálculo) e erro (dado salvo corrompido). A virada validada dá à
/// Divisão e a "Recebi um pagamento" o peso de protagonistas.
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
        ProfileEmpty() => const _EmptyView(),
        ProfileError(message: final String m) => _ErrorView(message: m),
        ProfileReady(perfil: final Perfil p) => _PainelBody(perfil: p),
      },
    );
  }
}

/// Estado vazio (§5.8): fisga a dor, promete pouco esforço, reforça privacidade.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Você provavelmente cobra menos do que deveria.', style: t.headlineSmall),
          const SizedBox(height: 12),
          Text('Descubra seu valor-hora justo em 5 perguntas.', style: t.bodyLarge),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push(Routes.calc),
            child: const Text('Começar'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.lock_outline, size: 16),
              const SizedBox(width: 6),
              Text('Leva 2 minutos · 100% offline', style: t.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}

/// Erro de leitura (§5.9): distinto de vazio — o dado existia mas não abriu.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push(Routes.calc),
            child: const Text('Começar'),
          ),
        ],
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('SEU VALOR-HORA', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          '${moneyBRL(r.valorHora)} /hora',
          style: AppType.valueHero.copyWith(color: theme.colorScheme.primary),
        ),
        Text('pra ganhar ${moneyBRL(r.lucro)}/mês', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),

        // Os dois tools recorrentes — protagonistas (a virada).
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

        // A Divisão — a assinatura, mostrando pra onde vai cada real.
        Text('DE CADA MÊS', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        DivisaoBar(lucro: div.lucro, reserva: div.reserva, custo: div.custo),
        const SizedBox(height: 8),
        Text(
          'Reserve ~${r.reservaPct}% de cada pagamento (regime: $regimeTag).',
          style: theme.textTheme.bodyMedium?.copyWith(color: d.reserva),
        ),
        const SizedBox(height: 24),

        TextButton(
          onPressed: () => context.push(Routes.detalhe),
          child: const Text('Ver como cheguei'),
        ),
        TextButton(
          onPressed: () => context.push(Routes.calc),
          child: const Text('Recalcular'),
        ),
        const SizedBox(height: 16),
        const EstimativaSeal(),
      ],
    );
  }
}
