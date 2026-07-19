import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/ads/ads.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/money.dart';
import '../../core/model/perfil.dart';
import '../../core/model/proposta.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/panel_card.dart';
import '../../core/ui/stale_banner.dart';
import '../../core/ui/vitrine_card.dart';
import '../proposta/proposta_flow.dart';

/// Resultado (Blueprint §5.3): o clímax. Regra da casa: resposta de dinheiro
/// vive numa SUPERFÍCIE, nunca solta no fundo — resposta-mãe em cima (vitrine),
/// anatomia embaixo (card de leitura).
///
/// v0.4 — o momento-ALÍVIO: o bloco do imposto conta a verdade do regime
/// (MEI: DAS fixo, ~1% — não 16%; CPF/Simples: alíquota EFETIVA, não a cheia).
/// O Salvar vive numa barra fixa (nunca abaixo da dobra) e o haptic do clímax
/// vibra no NASCIMENTO do número, não no tap do botão que trouxe até aqui.
class ResultadoScreen extends ConsumerStatefulWidget {
  const ResultadoScreen({super.key, this.perfil});

  final Perfil? perfil;

  @override
  ConsumerState<ResultadoScreen> createState() => _ResultadoScreenState();
}

class _ResultadoScreenState extends ConsumerState<ResultadoScreen> {
  @override
  void initState() {
    super.initState();
    final Perfil? p = widget.perfil;
    if (p == null) return;
    // O haptic pertence ao primeiro frame do resultado (MOTION-SPEC §1.1):
    // o corpo sente "nasceu" junto com os olhos, não 350ms antes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Haptics.resultBorn();
      // O aha chega junto pra quem ouve: anúncio após o count-up assentar.
      final ValorHoraResult r = computeValorHora(p);
      Future<void>.delayed(Motion.countUp, () {
        if (mounted) {
          announce(
            context,
            'Cobre ${moneyBRL(r.valorHora)} por hora. Esse é o seu piso.',
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Perfil? p = widget.perfil;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seu resultado')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.x6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Não recebi os dados do cálculo. Vamos refazer?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.x4),
                FilledButton(
                  onPressed: () => context.push(Routes.calc),
                  child: const Text('Refazer cálculo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final ValorHoraResult r = computeValorHora(p);
    final Divisao div = divisaoFromProfile(p, r);
    final bool custoMaiorQueMeta = p.custosTotal > p.renda;
    final bool stale = tabelasDefasadas(DateTime.now());
    final TextStyle heroStyle = AppType.valueHero.copyWith(color: cs.primary);

    return Scaffold(
      appBar: AppBar(title: const Text('Seu resultado')),
      // Salvar SEMPRE visível: a ação que completa o Ato 1 não exige rolar.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x4),
        child: FilledButton(
          onPressed: () async {
            Haptics.commit();
            announce(context, 'Trabalho salvo. Voltando pro painel.');
            await ref.read(profilesProvider.notifier).saveAndActivate(p);
            // Único corte seguro pra um intersticial (fim de tarefa). No-op até
            // ter SDK/chave — ver core/ads/ads.dart. Nunca entre calc→Resultado.
            await AdInterstitial.maybeShowOnSave(ref.read(proProvider));
            // Sem snackbar: o count-up + stagger do Painel É a confirmação
            // (e o haptic já selou o gesto).
            if (context.mounted) context.go(Routes.painel);
          },
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Salvar este trabalho'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          // Ato 1 — vitrine: a resposta-mãe, com a aurora do clímax.
          StaggerIn(
            index: 0,
            child: VitrineCard(
              climax: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'COBRE POR HORA',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: Space.x1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Stack(
                          alignment: Alignment.centerLeft,
                          children: <Widget>[
                            ExcludeSemantics(
                              child: Opacity(
                                opacity: 0,
                                child: Text(
                                  moneyBRL(r.valorHora),
                                  style: heroStyle,
                                ),
                              ),
                            ),
                            MoneyCountUp(
                              r.valorHora,
                              curve: MotionCurves.landing,
                              style: heroStyle,
                              semanticLabel:
                                  'Cobre ${moneyBRL(r.valorHora)} por hora',
                            ),
                          ],
                        ),
                        ExcludeSemantics(
                          child: Text(
                            ' /hora',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.x1),
                  Text(
                    'Esse é o seu piso. Cobre mais quando o trabalho valer mais.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Space.x2),
                  Text(
                    '≈ ${moneyBRL(r.valorDia)}/dia · ${moneyBRL(r.faturamento)}/mês faturados',
                    style: theme.textTheme.bodyMedium,
                    semanticsLabel:
                        'Cerca de ${moneyBRL(r.valorDia)} por dia, faturando ${moneyBRL(r.faturamento)} por mês',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.x4),

          // Ato 2 e 3 — anatomia: o imposto de verdade + o lucro, e a Divisão.
          StaggerIn(
            index: 1,
            child: PanelCard(
              padding: const EdgeInsets.all(Space.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _blocoImposto(context, r, d),
                  const Divider(),
                  MergeSemantics(
                    child: _bloco(
                      context,
                      'LUCRO REAL ESTIMADO',
                      '${moneyBRL(r.lucro)}/mês',
                      d.lucro,
                      semantica:
                          'Lucro real estimado: ${moneyBRL(r.lucro)} por mês',
                    ),
                  ),
                  const Divider(),
                  DivisaoBar(
                    lucro: div.lucro,
                    reserva: div.reserva,
                    custo: div.custo,
                    emphasis: DivisaoEmphasis.lucro,
                    // Nasce DEPOIS do véu do stagger: o usuário VÊ o dinheiro
                    // se repartir (K1) — e o número continua parando por último.
                    bornDelay: Motion.quick,
                  ),
                ],
              ),
            ),
          ),

          // Teto do MEI: enquadrado como CRESCIMENTO, não erro (terracota calmo).
          if (r.acimaTetoMei) ...<Widget>[
            const SizedBox(height: Space.x3),
            StaggerIn(
              index: 2,
              child: MergeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(Space.x4),
                  decoration: BoxDecoration(
                    color: d.alertaContainer,
                    borderRadius: const BorderRadius.all(Radii.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.trending_up,
                            size: 20,
                            color: d.onAlertaContainer,
                          ),
                          const SizedBox(width: Space.x2),
                          Expanded(
                            child: Text(
                              'Sua meta passou o teto do MEI',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: d.onAlertaContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.x2),
                      Text(
                        'Pra ganhar isso, você precisaria faturar ${moneyBRL(r.faturamento)}/mês — '
                        'o MEI permite até ${moneyBRL(kTetoMensalMei)}/mês. Bom sinal: seu trabalho '
                        'está maior que o MEI. Vale conversar com um contador sobre o Simples. '
                        'Seu valor-hora continua valendo.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: d.onAlertaContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          if (custoMaiorQueMeta) ...<Widget>[
            const SizedBox(height: Space.x3),
            StaggerIn(
              index: 2,
              child: Container(
                padding: const EdgeInsets.all(Space.x3),
                decoration: BoxDecoration(
                  color: d.alertaContainer,
                  borderRadius: const BorderRadius.all(Radii.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.trending_down,
                      size: 20,
                      color: d.onAlertaContainer,
                    ),
                    const SizedBox(width: Space.x2),
                    Expanded(
                      child: Text(
                        'Seus custos estão maiores que a renda que você quer. Vale rever.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: d.onAlertaContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: Space.x4),
          StaggerIn(
            index: 3,
            child: Wrap(
              spacing: Space.x2,
              children: <Widget>[
                TextButton(
                  onPressed: () => context.push(Routes.detalhe, extra: p),
                  child: const Text('Ver detalhamento'),
                ),
                // Porta secundária da proposta (07 §A.2). Discreta de
                // propósito: aqui a ação que importa é SALVAR o cálculo — a
                // proposta principal nasce do Simulador, onde a pessoa já
                // validou o preço de um projeto concreto.
                TextButton(
                  onPressed: () => abrirProposta(
                    context,
                    ref,
                    inicial: Proposta(
                      servico: '',
                      valor: 0,
                      valorHora: r.valorHora.toDouble(),
                    ),
                  ),
                  child: const Text('Fazer proposta'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x2),
          StaggerIn(
            index: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const EstimativaSeal(),
                if (stale) ...<Widget>[
                  const SizedBox(height: Space.x2),
                  // Rebaixado a footnote: informa sem carimbar desconfiança
                  // nem empurrar nada pra baixo da dobra.
                  StaleBanner(ano: kTabelasAno, footnote: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.x2),
        ],
      ),
    );
  }

  /// O bloco do imposto conta a verdade do regime — o momento-alívio.
  Widget _blocoImposto(
    BuildContext context,
    ValorHoraResult r,
    DivisaoColors d,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Perfil p = widget.perfil!;
    final String pctFino = (r.rate * 100)
        .toStringAsFixed(1)
        .replaceAll('.', ',');

    switch (p.regime) {
      case RegimeId.mei:
        return MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _label(context, 'SEU DAS FIXO'),
              const SizedBox(height: Space.x1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${moneyBRLCents(r.dasMensal!)}/mês',
                  maxLines: 1,
                  style: AppType.valueXl.copyWith(color: d.reserva),
                ),
              ),
              const SizedBox(height: Space.x1),
              Text(
                'MEI não paga % por pagamento — é um boleto fixo. '
                'Dá ~$pctFino% do que você fatura.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      case RegimeId.cpf:
        return _reservePct(
          context,
          r,
          d,
          apoio: r.reservaPct < 25
              ? 'Sua alíquota efetiva (INSS + IRPF). A tabela fala em até 27,5%, '
                    'mas com a sua renda o imposto leva bem menos.'
              : 'Sua alíquota efetiva: INSS (20%) + IRPF pela sua faixa, com o imposto já embutido.',
        );
      case RegimeId.simples:
        return _reservePct(
          context,
          r,
          d,
          apoio:
              'Alíquota efetiva do Simples pela sua faixa (estimativa pelo Anexo III — serviços).',
        );
      case RegimeId.intl:
        return _reservePct(
          context,
          r,
          d,
          apoio:
              'Regra de bolso pra quem recebe de fora: 25–30% de segurança. Ajuste com seu contador.',
        );
      case RegimeId.carneLeao:
        return _reservePct(
          context,
          r,
          d,
          apoio:
              'Sua alíquota efetiva: só o IRPF pela sua faixa (carnê-leão), sem INSS — você não contribui como autônomo.',
        );
    }
  }

  Widget _reservePct(
    BuildContext context,
    ValorHoraResult r,
    DivisaoColors d, {
    required String apoio,
  }) {
    final ThemeData theme = Theme.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _label(context, 'DE CADA PAGAMENTO, RESERVE'),
          const SizedBox(height: Space.x1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '~${r.reservaPct}%',
              maxLines: 1,
              style: AppType.valueXl.copyWith(color: d.reserva),
              semanticsLabel:
                  'Reserve cerca de ${r.reservaPct} por cento de cada pagamento',
            ),
          ),
          const SizedBox(height: Space.x1),
          Text(
            apoio,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String label) => Text(
    label,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.5,
    ),
  );

  Widget _bloco(
    BuildContext context,
    String label,
    String value,
    Color color, {
    String? semantica,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _label(context, label),
        const SizedBox(height: Space.x1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: AppType.valueXl.copyWith(color: color),
            semanticsLabel: semantica,
          ),
        ),
      ],
    );
  }
}
