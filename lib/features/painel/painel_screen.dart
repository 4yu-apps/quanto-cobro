import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/config/app_config.dart';
import '../../core/data/area_repository.dart';
import '../../core/data/entrada_repository.dart';
import '../../core/model/area.dart';
import '../../core/model/entrada.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/empty_state_hero.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/hero_value_card.dart';
import '../../core/ui/panel_card.dart';
import '../../core/ui/tool_action_card.dart';

/// **Início** — o hub, e o objetivo nº 1 do app: responder *"quanto custa a
/// minha hora?"*.
///
/// O que saiu daqui em 19/07/2026, e por quê:
/// - **o nudge mensal** ("já te pagou?") — o gatilho de voltar ao app é o
///   dinheiro cair, não o app cutucar;
/// - **o lembrete de vencimento do DAS** e o "já paguei o imposto" — o dono foi
///   explícito: isto não é um app de marcar imposto pago.
///
/// O que entrou: o **card do mês**, que era a aba "Guardado". É o mesmo balde,
/// num zoom menor — não precisava de um slot de aba pra existir.
class PainelScreen extends ConsumerWidget {
  const PainelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AreaState state = ref.watch(areaAtivaProvider);
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
      ),
      body: switch (state) {
        AreaVazia() => EmptyStateHero(
          onComecar: () => context.push(Routes.calc),
        ),
        AreaErro(message: final String m) => _ErrorView(message: m),
        AreaPronta(area: final Area a) => _Corpo(area: a),
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
              message,
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

class _Corpo extends ConsumerWidget {
  const _Corpo({required this.area});

  final Area area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final RegimeId regime = ref.watch(regimeProvider);
    final ValorHoraResult r = computeValorHora(area, regime);
    final Divisao div = divisaoFromArea(area, r);
    final bool stale = tabelasDefasadas(DateTime.now());
    final DateTime now = DateTime.now();

    final AreasData areas = ref.watch(areasProvider);
    final List<Entrada> entradas = ref.watch(entradasProvider);
    final double entrou = entrouNoMes(entradas, now);
    final int separado = separadoNoMes(entradas, now);

    final String impostoTexto = regime == RegimeId.mei
        ? 'Seu imposto: ${moneyBRLCents(r.dasMensal!)}/mês, já dentro da conta. De cada pagamento, o resto é seu.'
        : 'Separe ~${r.reservaPct}% de cada pagamento (sua faixa real, ${Regime.of(regime).tag}).';

    return _ambientWash(
      context,
      ListView(
        padding: EdgeInsets.fromLTRB(
          Space.x4,
          Space.x4,
          Space.x4,
          kFloatingNavReserve + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: <Widget>[
          StaggerIn(
            index: 0,
            child: HeroValueCard(
              valorHora: r.valorHora,
              subtitle: 'pra ganhar ${moneyBRL(r.lucro)}/mês',
              // O chip da área só aparece pra quem tem mais de uma — pro resto,
              // a palavra "área" não existe no app.
              perfilNome: areas.hierarquiaVisivel ? area.nome : null,
              onPerfilTap: areas.hierarquiaVisivel
                  ? () => context.push(Routes.areas)
                  : null,
              onVerComoCheguei: () => context.push(Routes.detalhe),
              staleAno: stale ? kTabelasAno : null,
            ),
          ),
          const SizedBox(height: Space.x6),

          // As duas ações recorrentes.
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
                      subtitle: 'separa o imposto na hora',
                      accent: d.reserva,
                      onTap: () => context.push(Routes.entrada),
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

          // O card do mês — o que era a aba "Guardado", agora no zoom certo.
          if (entrou > 0) ...<Widget>[
            StaggerIn(
              index: 2,
              child: _CardDoMes(entrou: entrou, separado: separado, mes: now),
            ),
            const SizedBox(height: Space.x6),
          ],

          StaggerIn(
            index: 3,
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
                        child: Text(
                          impostoTexto,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: d.reserva,
                            fontFeatures: AppType.tnum,
                          ),
                        ),
                      ),
                    ],
                  ),
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
      ),
    );
  }
}

/// "Este mês entrou X · separou Y". Toca e abre o histórico completo.
class _CardDoMes extends StatelessWidget {
  const _CardDoMes({
    required this.entrou,
    required this.separado,
    required this.mes,
  });

  final double entrou;
  final int separado;
  final DateTime mes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    return SemanticButton(
      label:
          'Em ${mesAno(mes)} entraram ${moneyBRL(entrou)}, e você separou '
          '${moneyBRL(separado)} de imposto.',
      tapHint: 'abre o histórico',
      onTap: () => context.push(Routes.historico),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push(Routes.historico),
          borderRadius: const BorderRadius.all(Radii.lg),
          child: PanelCard(
            padding: const EdgeInsets.all(Space.x5),
            accent: d.reserva,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'ESTE MÊS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: Space.x1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    moneyBRL(entrou),
                    maxLines: 1,
                    style: AppType.valueXl.copyWith(color: d.lucro),
                  ),
                ),
                const SizedBox(height: Space.x1),
                Text(
                  'e você separou ${moneyBRL(separado)} de imposto',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: d.reserva,
                    fontFeatures: AppType.tnum,
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

Widget _ambientWash(BuildContext context, Widget child) {
  final ColorScheme cs = Theme.of(context).colorScheme;
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  if (!dark) return child; // claro é sóbrio
  return RepaintBoundary(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.9, -1),
          radius: 1.3,
          colors: <Color>[
            cs.primary.withValues(alpha: 0.04),
            cs.surface.withValues(alpha: 0),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1, 1),
            radius: 1.3,
            colors: <Color>[
              cs.tertiary.withValues(alpha: 0.025),
              cs.surface.withValues(alpha: 0),
            ],
          ),
        ),
        child: child,
      ),
    ),
  );
}
