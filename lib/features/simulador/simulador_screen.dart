import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/money.dart';
import '../../core/model/proposta.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/money_field.dart';
import '../../core/ui/stale_banner.dart';
import '../proposta/proposta_flow.dart';

/// Simulador de projeto (Blueprint §5.6): diz se um valor dá lucro real e liga
/// de volta ao valor-hora alvo. O aviso comparativo DEFENDE o usuário.
class SimuladorScreen extends ConsumerStatefulWidget {
  const SimuladorScreen({super.key});

  @override
  ConsumerState<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends ConsumerState<SimuladorScreen> {
  final TextEditingController _valor = TextEditingController();
  final TextEditingController _horas = TextEditingController();
  final TextEditingController _custos = TextEditingController();
  Timer? _announceTimer;
  bool _alertaVisivel = false;

  @override
  void dispose() {
    _valor.dispose();
    _horas.dispose();
    _custos.dispose();
    _announceTimer?.cancel();
    super.dispose();
  }

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _announceResult(SimuladorResult? result) {
    _announceTimer?.cancel();
    if (result == null) return;
    _announceTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      announce(
        context,
        'Lucro real de ${moneyBRL(result.lucro)}. Valor-hora efetivo ${moneyBRL(result.effVH)}.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final ProfileState st = ref.watch(profileProvider);
    final int alvoVH = st is ProfileReady
        ? computeValorHora(st.perfil).valorHora
        : 0;
    final RegimeId regime = st is ProfileReady
        ? st.perfil.regime
        : RegimeId.mei;
    final double? taxaEfetiva = st is ProfileReady
        ? computeValorHora(st.perfil).rate
        : null;

    final int valor = _digits(_valor.text);
    final int horas = _digits(_horas.text);
    final int custos = _digits(_custos.text);
    final bool pronto = valor > 0 && horas > 0;
    final SimuladorResult? res = pronto
        ? computeSimulador(
            valor.toDouble(),
            horas,
            custos.toDouble(),
            regime,
            alvoVH,
            taxaEfetiva: taxaEfetiva,
          )
        : null;
    final bool reduce = reduceMotionOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Vou orçar um projeto')),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          MoneyField(
            controller: _valor,
            label: 'Valor do projeto',
            prefix: r'R$ ',
            autofocus: true,
            onChanged: (_) {
              setState(() {});
              _announceResult(
                _result(
                  valor: _digits(_valor.text),
                  horas: _digits(_horas.text),
                  custos: _digits(_custos.text),
                  regime: regime,
                  alvo: alvoVH,
                  taxa: taxaEfetiva,
                ),
              );
            },
          ),
          const SizedBox(height: Space.x4),
          MoneyField(
            controller: _horas,
            label: 'Horas estimadas',
            suffix: 'h',
            onChanged: (_) {
              setState(() {});
              _announceResult(
                _result(
                  valor: _digits(_valor.text),
                  horas: _digits(_horas.text),
                  custos: _digits(_custos.text),
                  regime: regime,
                  alvo: alvoVH,
                  taxa: taxaEfetiva,
                ),
              );
            },
          ),
          const SizedBox(height: Space.x4),
          MoneyField(
            controller: _custos,
            label: 'Custos do projeto (opcional)',
            prefix: r'R$ ',
            onChanged: (_) {
              setState(() {});
              _announceResult(
                _result(
                  valor: _digits(_valor.text),
                  horas: _digits(_horas.text),
                  custos: _digits(_custos.text),
                  regime: regime,
                  alvo: alvoVH,
                  taxa: taxaEfetiva,
                ),
              );
            },
          ),
          const SizedBox(height: Space.x6),
          AnimatedSwitcher(
            duration: reduce ? Duration.zero : Motion.base,
            child: res == null
                ? Padding(
                    key: const ValueKey<bool>(true),
                    padding: const EdgeInsets.only(top: Space.x8),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.request_quote_outlined,
                          size: 40,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: Space.x3),
                        Text(
                          'Preencha valor e horas pra ver o lucro real.',
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
                      Card(
                        color: cs.surfaceContainerHigh,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radii.xl),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Space.x6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'LUCRO REAL',
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
                                  res.lucro,
                                  duration: Motion.quick,
                                  style: AppType.valueHero.copyWith(
                                    color: d.lucro,
                                  ),
                                  semanticLabel:
                                      'Lucro real de ${moneyBRL(res.lucro)}',
                                ),
                              ),
                              const SizedBox(height: Space.x1),
                              Text(
                                'Valor-hora efetivo: ${moneyBRL(res.effVH)}/h',
                                style: theme.textTheme.bodyLarge,
                              ),
                              if (res.isMei) ...<Widget>[
                                const SizedBox(height: Space.x1),
                                Text(
                                  'No MEI, o DAS fixo já entra na sua conta mensal.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (alvoVH == 0) ...<Widget>[
                                const SizedBox(height: Space.x2),
                                Text(
                                  'Faça seu cálculo de valor-hora pra eu comparar com seu alvo.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () => context.push(Routes.calc),
                                    child: const Text(
                                      'Calcular meu valor-hora',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Aviso comparativo: entra/sai com transição, nunca num frame seco.
                      AnimatedSize(
                        duration: reduce ? Duration.zero : Motion.base,
                        curve: MotionCurves.standard,
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: reduce ? Duration.zero : Motion.base,
                          child: (res.abaixo && alvoVH > 0)
                              ? Padding(
                                  key: const ValueKey<bool>(true),
                                  padding: const EdgeInsets.only(top: Space.x3),
                                  child: Container(
                                    padding: const EdgeInsets.all(Space.x3),
                                    decoration: BoxDecoration(
                                      color: d.alertaContainer,
                                      borderRadius: const BorderRadius.all(
                                        Radii.md,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Icon(
                                              Icons.trending_down,
                                              color: d.onAlertaContainer,
                                              size: 20,
                                            ),
                                            const SizedBox(width: Space.x2),
                                            Expanded(
                                              child: Text(
                                                'Abaixo do seu alvo (${moneyBRL(alvoVH)}/h).',
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color:
                                                          d.onAlertaContainer,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: Space.x2),
                                        Text(
                                          'Cobre ~${moneyBRL(res.sugestao)} pra manter seu lucro.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: d.onAlertaContainer,
                                              ),
                                        ),
                                        const SizedBox(height: Space.x2),
                                        FilledButton.tonal(
                                          onPressed: () {
                                            Haptics.select();
                                            setState(
                                              () => _valor.text = res.sugestao
                                                  .toString(),
                                            );
                                            announce(
                                              context,
                                              'Valor atualizado pra ${moneyBRL(res.sugestao)}.',
                                            );
                                          },
                                          child: Text(
                                            'Usar ${moneyBRL(res.sugestao)}',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox(key: ValueKey<bool>(false)),
                        ),
                      ),
                      const SizedBox(height: Space.x6),
                      DivisaoBar(
                        lucro: res.divisao.lucro,
                        reserva: res.divisao.reserva,
                        custo: res.divisao.custo,
                        emphasis: DivisaoEmphasis.lucro,
                      ),
                      const SizedBox(height: Space.x6),

                      // A porta principal da proposta (07 §A.2): ela aparece
                      // logo depois de a pessoa CONFIRMAR que o preço fecha —
                      // o momento em que "então manda pro cliente" é a
                      // pergunta natural, e o medo de parecer amador está mais
                      // vivo. Aparece mesmo abaixo do alvo (é escolha dela),
                      // mas só o preço que fecha ganha o empurrãozinho.
                      FilledButton.icon(
                        onPressed: () => abrirProposta(
                          context,
                          ref,
                          inicial: Proposta(
                            servico: '',
                            valor: valor.toDouble(),
                            horas: horas,
                            valorHora: res.effVH.toDouble(),
                          ),
                        ),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Fazer proposta pro cliente'),
                      ),
                      if (!res.abaixo || alvoVH == 0) ...<Widget>[
                        const SizedBox(height: Space.x2),
                        Text(
                          'Esse preço fecha. Manda bonito.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: d.lucro,
                          ),
                        ),
                      ],

                      const SizedBox(height: Space.x6),
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

  SimuladorResult? _result({
    required int valor,
    required int horas,
    required int custos,
    required RegimeId regime,
    required int alvo,
    required double? taxa,
  }) {
    if (valor <= 0 || horas <= 0) return null;
    final SimuladorResult result = computeSimulador(
      valor.toDouble(),
      horas,
      custos.toDouble(),
      regime,
      alvo,
      taxaEfetiva: taxa,
    );
    final bool alerta = result.abaixo && alvo > 0;
    if (alerta && !_alertaVisivel) {
      _announceTimer?.cancel();
      _announceTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) {
          announce(
            context,
            'Atenção: abaixo do seu alvo de ${moneyBRL(alvo)} por hora. Cobre cerca de ${moneyBRL(result.sugestao)}.',
          );
        }
      });
    }
    _alertaVisivel = alerta;
    return result;
  }
}
