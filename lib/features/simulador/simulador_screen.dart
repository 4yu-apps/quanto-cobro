import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_field.dart';

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

  @override
  void dispose() {
    _valor.dispose();
    _horas.dispose();
    _custos.dispose();
    super.dispose();
  }

  int _digits(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final ProfileState st = ref.watch(profileProvider);
    final int alvoVH = st is ProfileReady ? computeValorHora(st.perfil).valorHora : 0;
    final RegimeId regime = st is ProfileReady ? st.perfil.regime : RegimeId.mei;

    final int valor = _digits(_valor.text);
    final int horas = _digits(_horas.text);
    final int custos = _digits(_custos.text);
    final bool pronto = valor > 0 && horas > 0;
    final SimuladorResult? res =
        pronto ? computeSimulador(valor.toDouble(), horas, custos.toDouble(), regime, alvoVH) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Vou orçar um projeto')),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          MoneyField(controller: _valor, label: 'Valor do projeto', prefix: r'R$ ', onChanged: (_) => setState(() {})),
          const SizedBox(height: Space.x4),
          MoneyField(controller: _horas, label: 'Horas estimadas', suffix: 'h', onChanged: (_) => setState(() {})),
          const SizedBox(height: Space.x4),
          MoneyField(controller: _custos, label: 'Custos do projeto (opcional)', prefix: r'R$ ', onChanged: (_) => setState(() {})),
          const SizedBox(height: Space.x6),
          if (res == null)
            Text('Preencha valor e horas pra ver o lucro real.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline))
          else ...<Widget>[
            Text('LUCRO REAL',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: Space.x1),
            Text(moneyBRL(res.lucro), style: AppType.valueHero.copyWith(color: d.lucro)),
            const SizedBox(height: Space.x1),
            Text('Valor-hora efetivo: ${moneyBRL(res.effVH)}/h', style: theme.textTheme.bodyLarge),
            if (res.abaixo && alvoVH > 0) ...<Widget>[
              const SizedBox(height: Space.x4),
              Container(
                padding: const EdgeInsets.all(Space.x3),
                decoration: BoxDecoration(
                  color: d.alertaContainer,
                  borderRadius: const BorderRadius.all(Radii.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.trending_down, color: d.onAlertaContainer, size: 20),
                        const SizedBox(width: Space.x2),
                        Expanded(
                          child: Text('Abaixo do seu alvo (${moneyBRL(alvoVH)}/h).',
                              style: theme.textTheme.titleSmall?.copyWith(color: d.onAlertaContainer)),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.x2),
                    Text('Cobre ~${moneyBRL(res.sugestao)} pra manter seu lucro.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: d.onAlertaContainer)),
                    const SizedBox(height: Space.x2),
                    FilledButton.tonal(
                      onPressed: () => setState(() => _valor.text = res.sugestao.toString()),
                      child: Text('Usar ${moneyBRL(res.sugestao)}'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Space.x6),
            DivisaoBar(
              lucro: res.divisao.lucro,
              reserva: res.divisao.reserva,
              custo: res.divisao.custo,
              emphasis: DivisaoEmphasis.lucro,
            ),
            const SizedBox(height: Space.x4),
            const EstimativaSeal(short: true),
          ],
        ],
      ),
    );
  }
}
