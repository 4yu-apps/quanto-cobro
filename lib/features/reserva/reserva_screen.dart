import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/money.dart';
import '../../core/model/regime.dart';
import '../../core/model/reserva_entry.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/money_field.dart';
import '../../core/ui/stale_banner.dart';
import '../../core/ui/vitrine_card.dart';

/// Reserva por pagamento (Blueprint §5.5) — o CAMINHO DE OURO (uso recorrente).
/// Resultado ao vivo dentro de um "cofre" visual; salvar fecha o loop
/// (Guardado + Desfazer + Registrar outro), sem duplicata acidental.
class ReservaScreen extends ConsumerStatefulWidget {
  const ReservaScreen({super.key});

  @override
  ConsumerState<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends ConsumerState<ReservaScreen> {
  final TextEditingController _valor = TextEditingController();
  RegimeId? _regime;
  bool _saved = false;
  Timer? _announceTimer;

  @override
  void initState() {
    super.initState();
    final ProfileState state = ref.read(profileProvider);
    if (state is ProfileReady) {
      final String? saved = ref
          .read(settingsRepositoryProvider)
          .reservaRegime(state.perfil.id, state.perfil.regime.name);
      if (saved != null) _regime = RegimeId.values.byName(saved);
    }
  }

  @override
  void dispose() {
    _valor.dispose();
    _announceTimer?.cancel();
    super.dispose();
  }

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _announceResult(ReservaResult? result) {
    _announceTimer?.cancel();
    if (result == null) return;
    _announceTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final String message = result.isMei
          ? 'Esse dinheiro é seu. O DAS do mês é ${moneyBRLCents(result.dasMensal!)}.'
          : 'Reserve ${moneyBRL(result.reserva)}. Sobra pra usar ${moneyBRL(result.sobra)}.';
      announce(context, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final ProfileState st = ref.watch(profileProvider);
    final RegimeId regimeBase = st is ProfileReady
        ? st.perfil.regime
        : RegimeId.mei;
    final RegimeId regime = _regime ?? regimeBase;
    final double? taxaEfetiva = st is ProfileReady && regime == st.perfil.regime
        ? computeValorHora(st.perfil).rate
        : null;

    final int amount = _digits(_valor.text);
    final bool temValor = amount > 0;
    final ReservaResult? res = temValor
        ? computeReserva(amount.toDouble(), regime, taxaEfetiva: taxaEfetiva)
        : null;
    final String? perfilId = st is ProfileReady ? st.perfil.id : null;
    final DateTime now = DateTime.now();
    final bool dasSeparado = ref
        .watch(reservaHistoryProvider)
        .any(
          (ReservaEntry e) =>
              e.isDas &&
              e.perfilId == perfilId &&
              e.at.year == now.year &&
              e.at.month == now.month,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recebi um pagamento'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de reservas',
            onPressed: () => context.push(Routes.historico),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          MoneyField(
            controller: _valor,
            label: 'Quanto você recebeu?',
            prefix: r'R$ ',
            autofocus: true,
            onChanged: (_) {
              setState(() => _saved = false);
              final int value = _digits(_valor.text);
              _announceResult(
                value > 0
                    ? computeReserva(
                        value.toDouble(),
                        regime,
                        taxaEfetiva: taxaEfetiva,
                      )
                    : null,
              );
            },
          ),
          const SizedBox(height: Space.x3),
          // Regime: chips na linguagem do app (alvo generoso, sem dropdown 2014).
          Wrap(
            spacing: Space.x2,
            children: <Widget>[
              for (final Regime r in Regime.all.values)
                ChoiceChip(
                  label: Text(r.tag),
                  selected: regime == r.id,
                  backgroundColor: cs.surfaceContainerLow,
                  selectedColor: cs.secondaryContainer,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: regime == r.id
                        ? cs.onSecondaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  side: regime == r.id
                      ? BorderSide(color: cs.primary, width: 1.5)
                      : BorderSide(color: cs.outlineVariant),
                  onSelected: (_) async {
                    Haptics.select();
                    setState(() {
                      _regime = r.id;
                      _saved = false;
                    });
                    if (st is ProfileReady) {
                      await ref
                          .read(settingsRepositoryProvider)
                          .setReservaRegime(
                            st.perfil.id,
                            st.perfil.regime.name,
                            r.id.name,
                          );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: Space.x6),
          AnimatedSwitcher(
            duration: reduceMotionOf(context) ? Duration.zero : Motion.base,
            child: res == null
                ? Padding(
                    key: const ValueKey<bool>(true),
                    padding: const EdgeInsets.only(top: Space.x8),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.payments_outlined,
                          size: 40,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: Space.x3),
                        Text(
                          'Digite o valor que caiu pra ver quanto guardar.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: const ValueKey<bool>(false),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      VitrineCard(
                        highlight: res.isMei && dasSeparado,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              res.isMei
                                  ? 'ESSE DINHEIRO É SEU'
                                  : 'RESERVE PRO LEÃO',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: Space.x1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: MoneyCountUp(
                                res.isMei ? amount : res.reserva,
                                duration: Motion.quick,
                                endTint: res.isMei ? d.lucro : d.reserva,
                                style: AppType.valueHero.copyWith(
                                  color: res.isMei ? d.lucro : d.reserva,
                                ),
                                semanticLabel: res.isMei
                                    ? 'Esse dinheiro é seu: ${moneyBRL(amount)}'
                                    : 'Reserve ${moneyBRL(res.reserva)} deste pagamento',
                              ),
                            ),
                            const SizedBox(height: Space.x1),
                            Text(
                              res.isMei
                                  ? dasSeparado
                                        ? 'DAS de ${_mesNome(now)} separado. O resto do mês é seu.'
                                        : 'Do Leão, este mês, só o DAS: ${moneyBRLCents(res.dasMensal!)}.'
                                  : '~${res.pct}% — sua alíquota efetiva, não a cheia.',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: Space.x4),
                            _barraColapsada(context, d, res, amount),
                            const SizedBox(height: Space.x2),
                            Row(
                              children: <Widget>[
                                _legenda(
                                  context,
                                  d.custo,
                                  'Pra usar',
                                  res.sobra,
                                ),
                                const SizedBox(width: Space.x4),
                                _legenda(
                                  context,
                                  d.reserva,
                                  'Reserva',
                                  res.reserva.toDouble(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.x4),
                      if (_saved || (res.isMei && dasSeparado))
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Icon(Icons.check, size: 20),
                                    const SizedBox(width: Space.x2),
                                    Text(
                                      res.isMei ? 'DAS separado' : 'Guardado',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.x3),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _valor.clear();
                                  _saved = false;
                                });
                              },
                              child: const Text('Registrar outro'),
                            ),
                          ],
                        )
                      else
                        FilledButton.tonal(
                          onPressed: () {
                            Haptics.commit();
                            final bool mei = res.isMei;
                            final ReservaEntry entry = ReservaEntry(
                              valor: amount.toDouble(),
                              reserva: res.reserva,
                              regimeTag: Regime.of(regime).tag,
                              at: DateTime.now(),
                              perfilId: perfilId,
                              tipo: mei ? 'das' : 'pct',
                            );
                            final ReservaHistoryNotifier historyN = ref.read(
                              reservaHistoryProvider.notifier,
                            );
                            historyN.add(entry);
                            setState(() => _saved = true);
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    mei
                                        ? '${moneyBRLCents(res.dasMensal!)} guardados pro DAS de ${_mesNome(now)}'
                                        : '${moneyBRL(res.reserva)} guardado no histórico',
                                  ),
                                  action: SnackBarAction(
                                    label: 'Desfazer',
                                    onPressed: () {
                                      historyN.remove(entry);
                                      if (mounted) {
                                        setState(() => _saved = false);
                                      }
                                    },
                                  ),
                                ),
                              );
                          },
                          child: Text(
                            res.isMei
                                ? 'Separar o DAS do mês'
                                : 'Salvar no histórico',
                          ),
                        ),
                      const SizedBox(height: Space.x4),
                      if (tabelasDefasadas(DateTime.now())) ...<Widget>[
                        StaleBanner(ano: kTabelasAno),
                        const SizedBox(height: Space.x3),
                      ],
                      const EstimativaSeal(short: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _barraColapsada(
    BuildContext context,
    DivisaoColors d,
    ReservaResult res,
    int amount,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radii.sm),
      child: SizedBox(
        height: 20,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final bool reduce = reduceMotionOf(context);
            final double w = c.maxWidth - 2;
            final double fR = amount <= 0 ? 0 : res.reserva / amount;
            return Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: reduce ? Duration.zero : Motion.quick,
                  curve: MotionCurves.standard,
                  width: w * (1 - fR),
                  color: d.custo,
                ),
                const SizedBox(width: 2),
                AnimatedContainer(
                  duration: reduce ? Duration.zero : Motion.quick,
                  curve: MotionCurves.standard,
                  width: w * fR,
                  color: d.reserva,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _legenda(
    BuildContext context,
    Color color,
    String label,
    double valor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: Space.x2),
        Text(
          '$label ${moneyBRL(valor)}',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontFeatures: AppType.tnum),
        ),
      ],
    );
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
}
