import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/money.dart';
import '../../core/common/datas.dart';
import '../../core/config/app_config.dart';
import '../../core/data/area_repository.dart';
import '../../core/data/entrada_repository.dart';
import '../../core/model/area.dart';
import '../../core/model/entrada.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/empty_state_hero.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/help_dot.dart';
import '../../core/ui/panel_card.dart';
import '../../core/ui/stale_banner.dart';
import '../../core/ui/breakpoints.dart';
import '../../core/ui/pro_selo.dart';

/// **Início** — o hub, e o objetivo nº 1 do app: responder *"quanto custa a
/// minha hora?"*.
///
/// Redesenhado sob a **doutrina de contenção** (docs/design-build): 1 herói por
/// tela (o valor-hora, número SOLTO, sem caixa), glow racionado (só o wash de
/// ambiente), e variedade de componente pra fugir do card-soup — gráfico do mês,
/// anel de reserva, Divisão com R$, ações assimétricas (primária + fantasma).
class PainelScreen extends ConsumerWidget {
  const PainelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AreaState state = ref.watch(areaAtivaProvider);
    final bool isPro = ref.watch(proProvider);
    return Scaffold(
      appBar: AppBar(
        // O selo Pro entra à direita do nome. Flexible no título pra ele nunca
        // empurrar o selo pra fora nem estourar em fonte grande.
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: AppType.numberFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isPro) ...<Widget>[
              const SizedBox(width: 8),
              const ProSelo(),
            ],
          ],
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
    final RegimeId regime = ref.watch(regimeProvider);
    final ValorHoraResult r = computeValorHora(area, regime);
    final Divisao div = divisaoFromArea(area, r);
    final bool stale = tabelasDefasadas(DateTime.now());
    final DateTime now = DateTime.now();

    final AreasData areas = ref.watch(areasProvider);
    final List<Entrada> entradas = ref.watch(entradasProvider);
    final double entrou = entrouNoMes(entradas, now);
    final int separado = separadoNoMes(entradas, now);
    // O gráfico e o anel só existem quando há movimento no mês — sem dado, some
    // (doutrina §3.1: nada de barra fake nem "0" na cara).
    final bool temMovimento = entrou > 0;

    // Teto do MEI (F5): a única coisa que o MEI de verdade precisa (doc 16 §3.1).
    // Só aparece pro MEI e só quando já faturou algo no ano — mesma regra de
    // empty-state do gráfico (sem dado, nada de "R$ 0 de R$ 81 mil" na cara).
    final double faturadoAno = entrouNoAno(entradas, now.year);
    final TetoMei? teto = (regime == RegimeId.mei && faturadoAno > 0)
        ? avaliarTetoMei(faturado: faturadoAno, mesAtual: now.month)
        : null;
    final bool isPro = ref.watch(proProvider);

    return _ambientWash(
      context,
      ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Space.x4,
            Space.x5,
            Space.x4,
            reservaDaNavbar(context),
          ),
          children: <Widget>[
            // 1) HERÓI — número solto (o único destaque forte da tela).
            StaggerIn(
              index: 0,
              child: _HeroValorHora(
                valorHora: r.valorHora,
                lucro: r.lucro,
                perfilNome: areas.hierarquiaVisivel ? area.nome : null,
                onPerfilTap: areas.hierarquiaVisivel
                    ? () => context.push(Routes.areas)
                    : null,
                onVerComoCheguei: () => context.push(Routes.detalhe),
                staleAno: stale ? kTabelasAno : null,
              ),
            ),
            const SizedBox(height: Space.x6),

            // 2) AÇÕES — assimétricas: primária (accent) + fantasma.
            StaggerIn(
              index: 1,
              child: _Acoes(
                onRecebi: () => context.push(Routes.entrada),
                onOrcar: () => context.push(Routes.simulador),
              ),
            ),
            const SizedBox(height: Space.x6),

            // 3) TETO DO MEI — só pro MEI, e só depois do primeiro recebimento
            // do ano. A zona e o quanto falta são grátis (perigo real); a
            // projeção "quando você encosta" é Pro (doc 16 §8, decisão 3).
            if (teto != null) ...<Widget>[
              StaggerIn(
                index: 2,
                child: _TetoMeiCard(
                  teto: teto,
                  isPro: isPro,
                  onVerPro: () {
                    telemetry.evento(
                      Evento.proParedeVista,
                      params: <String, Object?>{'gatilho': GatilhoPro.tetoMei},
                    );
                    context.push(Routes.pro, extra: GatilhoPro.tetoMei);
                  },
                ),
              ),
              const SizedBox(height: Space.x6),
            ],

            // 4) GRÁFICO + 5) ANEL — só com movimento no mês.
            if (temMovimento) ...<Widget>[
              StaggerIn(
                index: 2,
                child: _GraficoMensal(
                  entradas: entradas,
                  agora: now,
                  entrouMes: entrou,
                ),
              ),
              const SizedBox(height: Space.x5),
              StaggerIn(
                index: 3,
                child: _AnelReserva(
                  separado: separado.toDouble(),
                  meta: entrou * r.reservaPct / 100,
                  onTap: () => context.push(Routes.historico),
                ),
              ),
              const SizedBox(height: Space.x6),
            ],

            // 5) DIVISÃO — com R$, plana; toque abre o detalhamento.
            StaggerIn(
              index: 4,
              child: _DivisaoBloco(
                div: div,
                onTap: () => context.push(Routes.detalhe),
              ),
            ),
            const SizedBox(height: Space.x6),

            Center(
              child: TextButton.icon(
                onPressed: () => context.push(Routes.calc),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Recalcular'),
              ),
            ),
            const SizedBox(height: Space.x2),
            const EstimativaSeal(),
          ],
        ),
      ),
    );
  }
}

/// O herói: valor-hora como número SOLTO no canvas — sem caixa. O único destaque
/// forte da tela; o resto desce de nível (doutrina §2).
class _HeroValorHora extends StatelessWidget {
  const _HeroValorHora({
    required this.valorHora,
    required this.lucro,
    this.perfilNome,
    this.onPerfilTap,
    this.onVerComoCheguei,
    this.staleAno,
  });

  final int valorHora;
  final double lucro;
  final String? perfilNome;
  final VoidCallback? onPerfilTap;
  final VoidCallback? onVerComoCheguei;
  final int? staleAno;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;

    final Widget numero = Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: 'R\$ ',
            style: AppType.valueMd.copyWith(
              color: cs.primary.withValues(alpha: 0.85),
            ),
          ),
          TextSpan(
            text: '$valorHora',
            style: AppType.valueHero.copyWith(
              color: cs.primary,
              shadows: dark
                  ? <Shadow>[
                      Shadow(
                        color: cs.primary.withValues(alpha: 0.18),
                        blurRadius: 22,
                      ),
                    ]
                  : null,
            ),
          ),
          TextSpan(
            text: ' /hora',
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontFamily: AppType.numberFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (perfilNome != null) ...<Widget>[
          _PerfilChip(nome: perfilNome!, onTap: onPerfilTap),
          const SizedBox(height: Space.x3),
        ],
        Text(
          'SEU VALOR-HORA',
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: Space.x2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: numero,
        ),
        const SizedBox(height: Space.x2),
        Text(
          'pra ganhar ${moneyBRL(lucro)}/mês limpos',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        if (staleAno != null) ...<Widget>[
          const SizedBox(height: Space.x3),
          StaleBanner(ano: staleAno!),
        ],
        if (onVerComoCheguei != null) ...<Widget>[
          const SizedBox(height: Space.x1),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onVerComoCheguei,
              child: const Text('ver como cheguei aqui'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Chip discreto da área ativa (só pra quem tem mais de uma). Leva pra "Meus
/// preços". Sem cara de botão pesado — é ajuste raro.
class _PerfilChip extends StatelessWidget {
  const _PerfilChip({required this.nome, this.onTap});

  final String nome;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.x2,
              vertical: Space.x1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.folder_outlined, size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: Space.x2),
                Flexible(
                  child: Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
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

/// As duas ações recorrentes, agora ASSIMÉTRICAS: "Recebi" é a primária (o
/// acento verde, os 10%), "Vou orçar" é fantasma. Empilhadas e full-width pra
/// não estourar em fonte grande (antes eram dois cards iguais competindo).
class _Acoes extends StatelessWidget {
  const _Acoes({required this.onRecebi, required this.onOrcar});

  final VoidCallback onRecebi;
  final VoidCallback onOrcar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onRecebi,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Recebi um pagamento'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Space.x4),
            ),
          ),
        ),
        const SizedBox(height: Space.x3),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOrcar,
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Vou orçar um projeto'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Space.x4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Gráfico "quanto entrou por mês" — barras finas dos últimos 6 meses, mês atual
/// em destaque. Elemento plano (não card brilhante). Só existe com movimento.
class _GraficoMensal extends StatelessWidget {
  const _GraficoMensal({
    required this.entradas,
    required this.agora,
    required this.entrouMes,
  });

  final List<Entrada> entradas;
  final DateTime agora;
  final double entrouMes;

  static const List<String> _mes = <String>[
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final List<({String label, double valor, bool atual})> dados =
        <({String label, double valor, bool atual})>[];
    for (int i = 5; i >= 0; i--) {
      final DateTime m = DateTime(agora.year, agora.month - i);
      dados.add((
        label: _mes[m.month - 1],
        valor: entrouNoMes(entradas, m),
        atual: i == 0,
      ));
    }
    final double maxV = dados.fold(
      0,
      (double a, ({String label, double valor, bool atual}) e) =>
          e.valor > a ? e.valor : a,
    );

    return PanelCard(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, Space.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: Text(
                  'Quanto entrou por mês',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: AppType.numberFamily,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Space.x2),
              Text(
                '${_mes[agora.month - 1]} · ${moneyBRL(entrouMes)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontFeatures: AppType.tnum,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.x4),
          // Barras numa altura fixa (a barra cheia = a altura da caixa, nunca
          // estoura) e os rótulos numa linha PRÓPRIA abaixo — que cresce com a
          // fonte sem espremer as barras.
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final ({String label, double valor, bool atual}) e in dados)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        height: maxV > 0 ? 8 + 56 * (e.valor / maxV) : 8,
                        decoration: BoxDecoration(
                          color: e.atual
                              ? d.lucro
                              : cs.surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                            bottom: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.x2),
          Row(
            children: <Widget>[
              for (final ({String label, double valor, bool atual}) e in dados)
                Expanded(
                  child: Text(
                    e.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Guardei pro imposto este mês" — linha plana com anel circular (o elemento
/// circular que quebra o card-soup). Toca e abre o histórico.
class _AnelReserva extends StatelessWidget {
  const _AnelReserva({
    required this.separado,
    required this.meta,
    required this.onTap,
  });

  final double separado;
  final double meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final double pct = meta > 0 ? (separado / meta).clamp(0, 1).toDouble() : 0;

    return SemanticButton(
      label:
          'Este mês você guardou ${moneyBRL(separado)} de imposto, '
          'de cerca de ${moneyBRL(meta)}.',
      tapHint: 'abre o histórico',
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radii.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Space.x2,
              horizontal: Space.x1,
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 5,
                          color: d.reserva,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                      Text(
                        '${(pct * 100).round()}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: d.reserva,
                          fontFamily: AppType.numberFamily,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Guardei pro imposto este mês',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(
                                text: moneyBRL(separado),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontFamily: AppType.numberFamily,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: AppType.tnum,
                                ),
                              ),
                              TextSpan(
                                text: ' de ~${moneyBRL(meta)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontFeatures: AppType.tnum,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A Divisão — barra segmentada + legenda com R$ (não só %) em 3 colunas, pra o
/// número não ficar avulso. Plana; toque na barra abre o detalhamento (a conta).
class _DivisaoBloco extends StatelessWidget {
  const _DivisaoBloco({required this.div, required this.onTap});

  final Divisao div;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final double total = div.lucro + div.reserva + div.custo;
    int pct(double v) => total > 0 ? (v / total * 100).round() : 0;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radii.lg),
        child: PanelCard(
          padding: const EdgeInsets.all(Space.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'DE CADA MÊS',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: Space.x3),
              DivisaoBar(
                lucro: div.lucro,
                reserva: div.reserva,
                custo: div.custo,
              ),
              const SizedBox(height: Space.x4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _seg(context, d.lucro, 'É seu', div.lucro, pct(div.lucro)),
                  _seg(context, d.reserva, 'Imposto', div.reserva, pct(div.reserva)),
                  _seg(context, d.custo, 'Custos', div.custo, pct(div.custo)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seg(
    BuildContext context,
    Color dot,
    String label,
    double valor,
    int pct,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: Space.x2),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              moneyBRL(valor),
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: AppType.numberFamily,
                fontWeight: FontWeight.w700,
                fontFeatures: AppType.tnum,
              ),
            ),
          ),
          Text(
            '$pct%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// O rastreador de teto do MEI (F5). Um número e uma barra de três zonas — NÃO
/// é controle financeiro (doc 15 §4.3): só soma o que entrou no ano e mostra a
/// distância do teto. A zona e o quanto falta são grátis (o perigo real); a
/// projeção de quando encosta é Pro.
class _TetoMeiCard extends StatelessWidget {
  const _TetoMeiCard({
    required this.teto,
    required this.isPro,
    required this.onVerPro,
  });

  final TetoMei teto;
  final bool isPro;
  final VoidCallback onVerPro;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final Color zonaCor = switch (teto.zona) {
      ZonaTeto.verde => d.lucro,
      ZonaTeto.amarela => d.alerta,
      ZonaTeto.vermelha => cs.error,
    };

    return PanelCard(
      padding: const EdgeInsets.all(Space.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  'TETO DO MEI',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const HelpDot(verbeteId: 'teto_mei', size: 18),
            ],
          ),
          const SizedBox(height: Space.x1),
          // O número: faturado do ano de encontro ao teto fixo.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: moneyBRL(teto.faturado),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: AppType.numberFamily,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppType.tnum,
                    ),
                  ),
                  TextSpan(
                    text: ' de ${moneyBRL(kTetoAnualMei)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: AppType.tnum,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.x3),
          _BarraTeto(faturado: teto.faturado, cor: zonaCor),
          const SizedBox(height: Space.x3),
          _status(context, zonaCor),
          const SizedBox(height: Space.x3),
          _projecao(context),
        ],
      ),
    );
  }

  /// A frase da zona: o perigo (ou a calma) real, grátis pra todo mundo.
  Widget _status(BuildContext context, Color zonaCor) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final (String forte, String? apoio) = switch (teto.zona) {
      ZonaTeto.verde => (
        'Faltam ${moneyBRL(teto.restante)} pra encostar no teto.',
        null,
      ),
      ZonaTeto.amarela => (
        'Passou ${moneyBRL(teto.excedente)} do teto — dentro dos 20% de tolerância.',
        'Você paga um imposto a mais sobre o excedente e vira ME no ano que vem.',
      ),
      ZonaTeto.vermelha => (
        'Passou o limite dos ${moneyBRL(kTetoMeiComTolerancia)}.',
        'Risco de sair do MEI valendo desde janeiro. Vale falar com um contador.',
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          forte,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: teto.zona == ZonaTeto.verde ? cs.onSurface : zonaCor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (apoio != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            apoio,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// A projeção — Pro. Grátis vê o convite; o perigo (a zona) já ficou grátis
  /// acima, então isto nunca é uma parede na frente do que importa.
  Widget _projecao(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (!isPro) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onVerPro,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text('Ver a projeção do ano (Pro)'),
        ),
      );
    }
    final String texto = switch (teto.zona) {
      ZonaTeto.verde => teto.mesEncosta != null
          ? 'Nesse ritmo, você encosta no teto por volta de ${kMeses[teto.mesEncosta! - 1]}.'
          : 'Nesse ritmo, você não encosta no teto este ano.',
      ZonaTeto.amarela ||
      ZonaTeto.vermelha =>
        'No ritmo atual, você fecha o ano em ~${moneyBRL(teto.projecaoAno)}.',
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.trending_up,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Space.x2),
        Expanded(
          child: Text(
            texto,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// A barra de três zonas: trilho neutro, preenchimento na cor da zona atual, e
/// um traço no ponto do teto (R$ 81 mil) — a fronteira verde→amarela. A escala
/// vai até o limite dos 20% (R$ 97,2 mil); acima disso o preenchimento satura.
class _BarraTeto extends StatelessWidget {
  const _BarraTeto({required this.faturado, required this.cor});

  final double faturado;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double fill = (faturado / kTetoMeiComTolerancia).clamp(0.0, 1.0);
    final double tetoPos = kTetoAnualMei / kTetoMeiComTolerancia; // ~0,833

    return ExcludeSemantics(
      child: SizedBox(
        height: 10,
        child: Stack(
          children: <Widget>[
            // Trilho vazio.
            DecoratedBox(
              decoration: BoxDecoration(
                color: d.track,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const SizedBox.expand(),
            ),
            // Preenchimento na cor da zona.
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fill,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            // O traço do teto (81 mil).
            Align(
              alignment: Alignment(2 * tetoPos - 1, 0),
              child: Container(width: 2, color: cs.surface),
            ),
          ],
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
