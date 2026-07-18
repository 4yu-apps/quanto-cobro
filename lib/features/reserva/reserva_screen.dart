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

/// Reserva por pagamento (Blueprint §5.5) — o CAMINHO DE OURO (uso recorrente).
/// Resultado ao vivo, sem botão "calcular". Regime herdado do perfil, editável
/// pontualmente. Estados: campo vazio (sem resultado) · valor válido.
class ReservaScreen extends ConsumerStatefulWidget {
  const ReservaScreen({super.key});

  @override
  ConsumerState<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends ConsumerState<ReservaScreen> {
  final TextEditingController _valor = TextEditingController();
  RegimeId? _regime;

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  int _digits(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Widget _legenda(BuildContext context, Color color, String label, double valor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text('$label ${moneyBRL(valor)}', style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    // Regime padrão herdado do perfil salvo (editável pontualmente aqui).
    final ProfileState st = ref.watch(profileProvider);
    final RegimeId regimeBase =
        st is ProfileReady ? (st).perfil.regime : RegimeId.mei;
    final RegimeId regime = _regime ?? regimeBase;

    final int amount = _digits(_valor.text);
    final bool temValor = amount > 0;
    final ReservaResult? res = temValor ? computeReserva(amount.toDouble(), regime) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Recebi um pagamento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Quanto você recebeu?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _valor,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(prefixText: r'R$ '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text('Regime:', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 12),
              DropdownButton<RegimeId>(
                value: regime,
                onChanged: (RegimeId? v) => setState(() => _regime = v),
                items: <DropdownMenuItem<RegimeId>>[
                  for (final Regime r in Regime.all.values)
                    DropdownMenuItem<RegimeId>(value: r.id, child: Text(r.tag)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (res == null)
            Text('Digite o valor recebido pra ver quanto guardar.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline))
          else ...<Widget>[
            Text('RESERVE PARA IMPOSTO', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(moneyBRL(res.reserva), style: AppType.valueHero.copyWith(color: d.reserva)),
            const SizedBox(height: 4),
            Text('Sobra pra usar: ${moneyBRL(res.sobra)}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('${res.pct}% do que entrou é do leão, o resto é seu.',
                style: theme.textTheme.bodyMedium?.copyWith(color: d.reserva)),
            const SizedBox(height: 16),
            // Barra colapsada: Reserva x Sobra (DS §6.2).
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 18,
                child: Row(
                  children: <Widget>[
                    Expanded(flex: res.reserva, child: ColoredBox(color: d.reserva)),
                    Expanded(flex: res.sobra.round(), child: ColoredBox(color: d.lucro)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                _legenda(context, d.reserva, 'Reserva', res.reserva.toDouble()),
                const SizedBox(width: 16),
                _legenda(context, d.lucro, 'Sobra', res.sobra),
              ],
            ),
            const SizedBox(height: 24),
            const EstimativaSeal(short: true),
          ],
        ],
      ),
    );
  }
}
