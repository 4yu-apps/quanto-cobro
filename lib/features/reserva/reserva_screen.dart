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
import '../../core/theme/tokens.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_field.dart';
import '../../core/ui/stale_banner.dart';

/// Reserva por pagamento (Blueprint §5.5) — o CAMINHO DE OURO (uso recorrente).
/// Resultado ao vivo, sem botão "calcular". Regime herdado do perfil. Pode
/// salvar no histórico (gancho de hábito).
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final ProfileState st = ref.watch(profileProvider);
    final RegimeId regimeBase = st is ProfileReady ? st.perfil.regime : RegimeId.mei;
    final RegimeId regime = _regime ?? regimeBase;

    final int amount = _digits(_valor.text);
    final bool temValor = amount > 0;
    final ReservaResult? res = temValor ? computeReserva(amount.toDouble(), regime) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recebi um pagamento'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico',
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
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.x3),
          Row(
            children: <Widget>[
              Text('Regime:', style: theme.textTheme.bodyMedium),
              const SizedBox(width: Space.x3),
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
          const SizedBox(height: Space.x6),
          if (res == null)
            Text('Digite o valor que caiu pra ver quanto guardar.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline))
          else ...<Widget>[
            Text('RESERVE PRO LEÃO',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: Space.x1),
            Text(moneyBRL(res.reserva), style: AppType.valueHero.copyWith(color: d.reserva)),
            const SizedBox(height: Space.x1),
            Text('Sobra pra usar: ${moneyBRL(res.sobra)}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: Space.x4),
            // Barra colapsada: Reserva x Sobra (DS §6.2).
            ClipRRect(
              borderRadius: const BorderRadius.all(Radii.sm),
              child: SizedBox(
                height: 20,
                child: Row(
                  children: <Widget>[
                    Expanded(flex: res.reserva, child: ColoredBox(color: d.reserva)),
                    const SizedBox(width: 2),
                    Expanded(flex: res.sobra.round(), child: ColoredBox(color: d.lucro)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.x2),
            Row(
              children: <Widget>[
                _legenda(context, d.reserva, 'Reserva', res.reserva.toDouble()),
                const SizedBox(width: Space.x4),
                _legenda(context, d.lucro, 'Sobra', res.sobra),
              ],
            ),
            const SizedBox(height: Space.x4),
            FilledButton.tonal(
              onPressed: () {
                ref.read(reservaHistoryProvider.notifier).add(
                      ReservaEntry(
                        valor: amount.toDouble(),
                        reserva: res.reserva,
                        regimeTag: Regime.of(regime).tag,
                        at: DateTime.now(),
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guardado no histórico')),
                );
              },
              child: const Text('Salvar no histórico'),
            ),
            const SizedBox(height: Space.x4),
            if (tabelasDefasadas(DateTime.now())) ...<Widget>[
              StaleBanner(ano: kTabelasAno),
              const SizedBox(height: Space.x3),
            ],
            const EstimativaSeal(short: true),
          ],
        ],
      ),
    );
  }

  Widget _legenda(BuildContext context, Color color, String label, double valor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: Space.x2),
        Text('$label ${moneyBRL(valor)}', style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
