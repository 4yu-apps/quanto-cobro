import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/ui/estimativa_seal.dart';

/// Simulador de projeto (Blueprint §5.6): diz se um valor dá lucro real e liga
/// de volta ao valor-hora alvo. O aviso comparativo é o que DEFENDE o usuário —
/// o que diferencia de uma calculadora burra.
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
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _campo(_valor, 'Valor do projeto', prefix: r'R$ '),
          const SizedBox(height: 12),
          _campo(_horas, 'Horas estimadas', suffix: 'h'),
          const SizedBox(height: 12),
          _campo(_custos, 'Custos do projeto (opcional)', prefix: r'R$ '),
          const SizedBox(height: 24),
          if (res == null)
            Text('Preencha valor e horas pra ver o lucro real.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline))
          else ...<Widget>[
            Text('LUCRO REAL', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(moneyBRL(res.lucro), style: AppType.valueXl.copyWith(color: d.lucro)),
            const SizedBox(height: 8),
            Text('Valor-hora efetivo: ${moneyBRL(res.effVH)}/h', style: theme.textTheme.bodyLarge),
            if (res.abaixo && alvoVH > 0) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: d.alertaContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.trending_down, color: d.onAlertaContainer, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Abaixo do seu alvo (${moneyBRL(alvoVH)}/h).',
                            style: theme.textTheme.titleSmall?.copyWith(color: d.onAlertaContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cobre ~${moneyBRL(res.sugestao)} pra manter seu lucro.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: d.onAlertaContainer),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => setState(() => _valor.text = res.sugestao.toString()),
                      child: Text('Usar ${moneyBRL(res.sugestao)}'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const EstimativaSeal(short: true),
          ],
        ],
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, {String? prefix, String? suffix}) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, prefixText: prefix, suffixText: suffix),
      onChanged: (_) => setState(() {}),
    );
  }
}
