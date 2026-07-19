import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/money.dart';
import '../../core/config/app_config.dart';
import '../../core/data/profile_repository.dart';
import '../../core/model/perfil.dart';
import '../../core/model/regime.dart';
import '../../core/model/reserva_entry.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/empty_state_hero.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/hero_value_card.dart';
import '../../core/ui/panel_card.dart';
import '../../core/ui/tool_action_card.dart';
import '../perfis/trabalho_switcher.dart';

/// Painel (hub). Três estados (Blueprint §5.9). A virada validada dá à Divisão
/// e aos tools recorrentes o peso de protagonistas (UI-SPEC §2.1).
class PainelScreen extends ConsumerWidget {
  const PainelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileState state = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (BuildContext context) => Text(
            AppConfig.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: AppType.numberFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => context.push(Routes.config),
          ),
        ],
      ),
      body: switch (state) {
        ProfileEmpty() => EmptyStateHero(
          onComecar: () => context.push(Routes.calc),
        ),
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
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: Space.x3),
            Text(
              'Não consegui carregar seu cálculo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Space.x2),
            Text(
              'Seus dados podem ter se perdido. Vamos refazer, é rápido.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: Space.x6),
            FilledButton(
              onPressed: () => context.push(Routes.calc),
              child: const Text('Refazer meu cálculo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PainelBody extends ConsumerWidget {
  const _PainelBody({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final ValorHoraResult r = computeValorHora(perfil);
    final Divisao div = divisaoFromProfile(perfil, r);
    final String regimeTag = Regime.of(perfil.regime).tag;
    final bool stale = tabelasDefasadas(DateTime.now());
    final DateTime now = DateTime.now();
    final ProfilesData trabalhos = ref.watch(profilesProvider);
    final List<ReservaEntry> historico = ref.watch(reservaHistoryProvider);
    final int guardadoMes = historico
        .where(
          (ReservaEntry e) =>
              e.at.year == now.year &&
              e.at.month == now.month &&
              (e.perfilId == perfil.id ||
                  (e.perfilId == null && trabalhos.perfis.length == 1)),
        )
        .fold<int>(0, (int s, ReservaEntry e) => s + e.reserva);
    final bool leaoPago = ref.watch(leaoPagoProvider);
    final bool lembrarDas =
        perfil.regime == RegimeId.mei &&
        now.day <= kDasVencimentoDia &&
        !leaoPago;
    final String impostoTexto = perfil.regime == RegimeId.mei
        ? 'Seu DAS: ${moneyBRLCents(r.dasMensal!)}/mês, já dentro da conta. De cada pagamento, o resto é seu.'
        : 'Separe ~${r.reservaPct}% de cada pagamento (sua faixa real, regime: $regimeTag).';

    return ListView(
      padding: const EdgeInsets.all(Space.x4),
      children: <Widget>[
        StaggerIn(
          index: 0,
          child: HeroValueCard(
            valorHora: r.valorHora,
            subtitle: 'pra ganhar ${moneyBRL(r.lucro)}/mês',
            perfilNome: perfil.nome,
            onPerfilTap: () => showTrabalhoSwitcher(context, ref),
            onVerComoCheguei: () => context.push(Routes.detalhe),
            staleAno: stale ? kTabelasAno : null,
          ),
        ),
        const SizedBox(height: Space.x6),

        if (lembrarDas) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(Space.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'O DAS de ${_mesNome(now)} vence dia $kDasVencimentoDia',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: Space.x1),
                    Text(
                      '${moneyBRLCents(r.dasMensal!)} — ${guardadoMes >= r.dasMensal! ? 'você já separou o DAS.' : 'ainda não separou nada.'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: Space.x2),
                    Wrap(
                      spacing: Space.x2,
                      children: <Widget>[
                        TextButton(
                          onPressed: () =>
                              ref.read(leaoPagoProvider.notifier).set(true),
                          child: const Text('Já paguei'),
                        ),
                        TextButton(
                          onPressed: () => context.push(Routes.reserva),
                          child: const Text('Separar agora'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.x4),
        ],

        // Os dois tools recorrentes, protagonistas (a virada) — peso >= herói.
        StaggerIn(
          index: 1,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: ToolActionCard(
                    icon: Icons.payments_outlined,
                    title: 'Recebi um pagamento',
                    subtitle: 'separa o do Leão na hora',
                    accent: d.reserva,
                    onTap: () => context.push(Routes.reserva),
                  ),
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: ToolActionCard(
                    icon: Icons.request_quote_outlined,
                    title: 'Vou orçar um projeto',
                    subtitle: 'esse preço vale a pena?',
                    accent: theme.colorScheme.secondary,
                    onTap: () => context.push(Routes.simulador),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.x6),

        StaggerIn(
          index: 2,
          child: PanelCard(
            padding: const EdgeInsets.all(Space.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'DE CADA MÊS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: Space.x3),
                DivisaoBar(
                  lucro: div.lucro,
                  reserva: div.reserva,
                  custo: div.custo,
                ),
                const SizedBox(height: Space.x2),
                Row(
                  children: <Widget>[
                    Icon(Icons.lock_outline, size: 16, color: d.reserva),
                    const SizedBox(width: Space.x2),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            const TextSpan(text: ''),
                            TextSpan(
                              text: impostoTexto,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: d.reserva,
                                fontFeatures: AppType.tnum,
                              ),
                            ),
                          ],
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (guardadoMes > 0) ...<Widget>[
                  const SizedBox(height: Space.x3),
                  Semantics(
                    button: true,
                    label:
                        'Você já guardou ${moneyBRL(guardadoMes)} este mês. Ver histórico.',
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        // Troca de aba (não empilha 2ª cópia do Histórico).
                        onTap: () => context.go(Routes.historico),
                        borderRadius: const BorderRadius.all(Radii.sm),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.savings_outlined,
                                size: 16,
                                color: d.reserva,
                              ),
                              const SizedBox(width: Space.x2),
                              Expanded(
                                child: Text(
                                  'Você já guardou ${moneyBRL(guardadoMes)} este mês',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Space.x2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push(Routes.detalhe),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Ver detalhamento'),
                  ),
                ),
              ],
            ),
          ),
        ),
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

String _mesNome(DateTime date) {
  const List<String> nomes = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return nomes[date.month - 1];
}
