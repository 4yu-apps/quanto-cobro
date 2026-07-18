import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/common/money.dart';
import '../../core/model/reserva_entry.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_count_up.dart';

/// Histórico de reservas (IA §2.12) — o gancho de hábito: quanto já guardei pro
/// Leão. Registro errado sai com um swipe (Desfazer no snackbar).
class HistoricoScreen extends ConsumerWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ReservaEntry> all = ref.watch(reservaHistoryProvider);
    final DateTime now = DateTime.now();
    bool doMes(ReservaEntry e) => e.at.year == now.year && e.at.month == now.month;
    final int totalMes =
        all.where(doMes).fold<int>(0, (int s, ReservaEntry e) => s + e.reserva);
    final List<ReservaEntry> atuais = all.where(doMes).toList();
    final List<ReservaEntry> anteriores =
        all.where((ReservaEntry e) => !doMes(e)).toList();
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final DateFormat df = DateFormat('d/M/y');

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de reservas')),
      body: all.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.x6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.savings_outlined, size: 40, color: cs.onSurfaceVariant),
                    const SizedBox(height: Space.x3),
                    Text(
                      'Sem reservas por aqui ainda. Cada vez que um PIX cair, registre e acompanhe quanto já separou.',
                      textAlign: TextAlign.center,
                      style:
                          theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: Space.x6),
                    FilledButton.tonal(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.push(Routes.reserva);
                        }
                      },
                      child: const Text('Recebi um pagamento'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(Space.x4),
              children: <Widget>[
                Card(
                  color: cs.surfaceContainerHigh,
                  shape:
                      const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radii.xl)),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.x6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('GUARDADO ESTE MÊS',
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant, letterSpacing: 0.5)),
                        const SizedBox(height: Space.x1),
                        MoneyCountUp(
                          totalMes,
                          style: AppType.valueXl.copyWith(color: d.reserva),
                          semanticLabel: '${moneyBRL(totalMes)} guardados este mês',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Space.x4),
                if (atuais.isNotEmpty)
                  Card(
                    color: cs.surfaceContainer,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < atuais.length; i++) ...<Widget>[
                          if (i > 0) const Divider(height: 1, indent: Space.x4),
                          _entry(context, ref, atuais[i], d, df),
                        ],
                      ],
                    ),
                  ),
                if (anteriores.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Space.x4),
                  Text('MESES ANTERIORES',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.5)),
                  const SizedBox(height: Space.x2),
                  Card(
                    color: cs.surfaceContainer,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < anteriores.length; i++) ...<Widget>[
                          if (i > 0) const Divider(height: 1, indent: Space.x4),
                          _entry(context, ref, anteriores[i], d, df),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Space.x4),
                const EstimativaSeal(short: true),
              ],
            ),
    );
  }

  Widget _entry(BuildContext context, WidgetRef ref, ReservaEntry e, DivisaoColors d,
      DateFormat df) {
    return Dismissible(
      key: ValueKey<String>('${e.at.toIso8601String()}-${e.valor}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.x4),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(Icons.delete_outline,
            color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      onDismissed: (_) {
        Haptics.select();
        ref.read(reservaHistoryProvider.notifier).remove(e);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: const Text('Registro removido'),
              action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () => ref.read(reservaHistoryProvider.notifier).restore(e),
              ),
            ),
          );
      },
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(Icons.savings_outlined,
              size: 20, color: Theme.of(context).colorScheme.onSecondaryContainer),
        ),
        title: Text('Recebeu ${moneyBRL(e.valor)}'),
        subtitle: Text('${df.format(e.at)} · ${e.regimeTag}'),
        trailing: Text(
          moneyBRL(e.reserva),
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: d.reserva, fontFeatures: AppType.tnum),
        ),
      ),
    );
  }
}
