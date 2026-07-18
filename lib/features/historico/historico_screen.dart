import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/common/money.dart';
import '../../core/model/reserva_entry.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/money_count_up.dart';

/// Histórico de reservas (IA §2.12) — o gancho de hábito: quanto já guardei pro
/// Leão este mês. Fecha o loop do uso recorrente.
class HistoricoScreen extends ConsumerWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ReservaEntry> all = ref.watch(reservaHistoryProvider);
    final DateTime now = DateTime.now();
    final Iterable<ReservaEntry> doMes =
        all.where((ReservaEntry e) => e.at.year == now.year && e.at.month == now.month);
    final int totalMes = doMes.fold<int>(0, (int s, ReservaEntry e) => s + e.reserva);
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de reservas')),
      body: all.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.x6),
                child: Text(
                  'Sem reservas por aqui ainda. Cada vez que um PIX cair, registre e acompanhe quanto já separou.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(Space.x4),
              children: <Widget>[
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHigh,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radii.xl)),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.x6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('GUARDADO ESTE MÊS',
                            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: Space.x1),
                        MoneyCountUp(totalMes, style: AppType.valueXl.copyWith(color: d.reserva)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Space.x4),
                for (final ReservaEntry e in all)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.savings_outlined, color: d.reserva),
                    title: Text('Recebeu ${moneyBRL(e.valor)}'),
                    subtitle: Text('${e.at.day}/${e.at.month}/${e.at.year} · ${e.regimeTag}'),
                    trailing: Text('reserve ${moneyBRL(e.reserva)}',
                        style: theme.textTheme.labelLarge?.copyWith(color: d.reserva)),
                  ),
              ],
            ),
    );
  }
}
