import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/routes.dart';
import '../../core/common/money.dart';
import '../../core/data/reserva_history_csv.dart';
import '../../core/data/reserva_history_repository.dart';
import '../../core/model/perfil.dart';
import '../../core/model/reserva_entry.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/vitrine_card.dart';

/// O fechamento do loop: registros por trabalho, quitação mensal e remoção
/// acessível tanto por gesto quanto pela ação do leitor de tela.
class HistoricoScreen extends ConsumerStatefulWidget {
  const HistoricoScreen({super.key});

  @override
  ConsumerState<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends ConsumerState<HistoricoScreen> {
  String? _perfilId;

  @override
  Widget build(BuildContext context) {
    final List<ReservaEntry> all = ref.watch(reservaHistoryProvider);
    final List<Perfil> perfis = ref.watch(profilesProvider).perfis;
    final ReservaHistoryRepository repo = ref.watch(
      reservaHistoryRepositoryProvider,
    );
    final bool isPro = ref.watch(proProvider);
    final DateTime now = DateTime.now();
    final List<ReservaEntry> filtered = _perfilId == null
        ? all
        : all.where((ReservaEntry e) => e.perfilId == _perfilId).toList();
    bool doMes(ReservaEntry e) =>
        e.at.year == now.year && e.at.month == now.month;
    final List<ReservaEntry> atuais = filtered.where(doMes).toList();
    final int totalMes = atuais.fold<int>(
      0,
      (int total, ReservaEntry e) => total + e.reserva,
    );

    // Agrupa "filtered" por mês (ano+mês) — cada seção mostra quanto ENTROU
    // (bruto) e quanto foi GUARDADO naquele mês. mesesComReserva() dá a
    // ordem canônica (mais recente primeiro); filtra aqui pra só listar
    // meses com registro depois do filtro por trabalho dos chips.
    final Map<DateTime, List<ReservaEntry>> porMes =
        <DateTime, List<ReservaEntry>>{};
    for (final ReservaEntry e in filtered) {
      final DateTime chave = DateTime(e.at.year, e.at.month);
      (porMes[chave] ??= <ReservaEntry>[]).add(e);
    }
    final List<DateTime> meses = repo
        .mesesComReserva()
        .where((DateTime mes) => porMes.containsKey(mes))
        .toList();

    final bool pago = ref.watch(leaoPagoProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final DateFormat df = DateFormat('d MMM', 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardado'),
        actions: all.isEmpty
            ? null
            : <Widget>[
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'Exportar CSV',
                  onPressed: () => _exportarCsv(context, all, isPro),
                ),
              ],
      ),
      body: all.isEmpty
          ? _empty(context)
          : ListView(
              padding: EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, kFloatingNavReserve + MediaQuery.viewPaddingOf(context).bottom),
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _perfilId == null,
                        onSelected: (_) => setState(() => _perfilId = null),
                      ),
                      for (final Perfil perfil in perfis) ...<Widget>[
                        const SizedBox(width: Space.x2),
                        ChoiceChip(
                          label: Text(perfil.nome),
                          selected: _perfilId == perfil.id,
                          onSelected: (_) =>
                              setState(() => _perfilId = perfil.id),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Space.x4),
                VitrineCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'GUARDADO ESTE MÊS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: Space.x1),
                      MoneyCountUp(
                        totalMes,
                        curve: MotionCurves.landing,
                        style: AppType.valueXl.copyWith(color: d.reserva),
                        semanticLabel:
                            '${moneyBRL(totalMes)} guardados este mês',
                      ),
                      const SizedBox(height: Space.x3),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await ref.read(leaoPagoProvider.notifier).set(!pago);
                          if (!context.mounted) return;
                          final String message = pago
                              ? 'Marque quando a guia for quitada.'
                              : 'Imposto de ${_mesNome(now)}: pago. Guia quitada. Mês limpo.';
                          announce(context, message);
                        },
                        icon: Icon(
                          pago ? Icons.undo : Icons.check_circle_outline,
                        ),
                        label: Text(
                          pago
                              ? 'Desfazer quitação'
                              : 'Já paguei o imposto deste mês',
                        ),
                      ),
                      if (pago) ...<Widget>[
                        const SizedBox(height: Space.x2),
                        Text(
                          'Imposto de ${_mesNome(now)}: pago. Guia quitada. Mês limpo.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: d.lucro,
                          ),
                        ),
                      ],
                      // Com >1 trabalho, deixa claro que o imposto é por-PESSOA,
                      // não por-trabalho (1 CNPJ, 1 DAS/mês).
                      if (perfis.length > 1) ...<Widget>[
                        const SizedBox(height: Space.x2),
                        Text(
                          'O imposto do mês é um só, pra você — vale pros seus trabalhos todos. Não é por trabalho.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Space.x4),
                if (meses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.x6),
                    child: Text(
                      'Nenhuma reserva neste filtro ainda.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < meses.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: Space.x4),
                    StaggerIn(
                      index: i,
                      child: _mesHeader(
                        context,
                        meses[i],
                        porMes[meses[i]]!,
                        repo,
                        now,
                        theme,
                        cs,
                      ),
                    ),
                    const SizedBox(height: Space.x2),
                    _list(context, porMes[meses[i]]!, perfis, d, df),
                  ],
                const SizedBox(height: Space.x4),
                const EstimativaSeal(short: true),
              ],
            ),
    );
  }

  /// Cabeçalho de uma seção de mês: quanto ENTROU (bruto) e quanto foi
  /// GUARDADO naquele mês. Mês corrente fala "este mês"; meses passados
  /// nomeiam o mês, senão "ganhou este mês" em janeiro passado confundiria.
  Widget _mesHeader(
    BuildContext context,
    DateTime mes,
    List<ReservaEntry> entries,
    ReservaHistoryRepository repo,
    DateTime now,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final bool ehMesAtual = mes.year == now.year && mes.month == now.month;
    final double ganhou = repo.brutoDoMes(mes, perfilId: _perfilId);
    final int guardou = entries.fold<int>(
      0,
      (int total, ReservaEntry e) => total + e.reserva,
    );
    final String rotulo = ehMesAtual
        ? 'GANHOU ESTE MÊS'
        : 'GANHOU EM ${_mesNome(mes).toUpperCase()} DE ${mes.year}';
    return Semantics(
      header: true,
      label:
          '$rotulo: ${moneyBRL(ganhou)}. Guardou ${moneyBRL(guardou)} nesse mês.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              rotulo,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: Space.x1),
            Row(
              children: <Widget>[
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      moneyBRL(ganhou),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFeatures: AppType.tnum,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Space.x2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'guardou ${moneyBRL(guardou)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontFeatures: AppType.tnum,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Exporta o histórico (todos os registros, sem o filtro dos chips) como
  /// CSV e abre o share sheet — mesmo padrão do backup em config_screen.dart.
  /// Pro: se ainda não é, avisa e leva pra tela Pro; volta e retoma sozinho
  /// se a compra aconteceu (mesmo padrão de trabalho_switcher.novoTrabalho).
  Future<void> _exportarCsv(
    BuildContext context,
    List<ReservaEntry> entries,
    bool isPro,
  ) async {
    if (!isPro) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Exportar CSV é recurso Pro.')),
        );
      await context.push(Routes.pro);
      if (!context.mounted || !ref.read(proProvider)) return;
      announce(context, 'Pro ativado. Exportando seu CSV.');
    }
    if (!context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final String csv = reservaHistoryCsv(entries);
      final DateTime now = DateTime.now();
      final String dia =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/guardado-$dia.csv');
      await file.writeAsString(csv);
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'text/csv')],
          subject: 'Guardado — Quanto Cobro',
          text: 'Histórico de reservas exportado do Quanto Cobro?.',
        ),
      );
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Não consegui gerar o CSV.')),
        );
    }
  }

  Widget _empty(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Space.x6),
            FilledButton.tonal(
              onPressed: () => context.push(Routes.reserva),
              child: const Text('Recebi um pagamento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<ReservaEntry> entries,
    List<Perfil> perfis,
    DivisaoColors d,
    DateFormat df,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: <Widget>[
          for (int index = 0; index < entries.length; index++) ...<Widget>[
            if (index > 0) const Divider(height: 1, indent: Space.x4),
            _entry(context, entries[index], perfis, d, df),
          ],
        ],
      ),
    );
  }

  Widget _entry(
    BuildContext context,
    ReservaEntry entry,
    List<Perfil> perfis,
    DivisaoColors colors,
    DateFormat df,
  ) {
    final String trabalho =
        perfis
            .where((Perfil perfil) => perfil.id == entry.perfilId)
            .map((Perfil perfil) => perfil.nome)
            .firstOrNull ??
        'Trabalho anterior';
    final String titulo = entry.isDas
        ? 'DAS separado'
        : 'Recebeu ${moneyBRL(entry.valor)}';
    final String label =
        '$titulo, ${df.format(entry.at)}, ${entry.regimeTag}, '
        '${entry.isDas ? 'DAS de' : 'reserva de'} ${moneyBRL(entry.reserva)}, $trabalho';
    return Semantics(
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        const CustomSemanticsAction(label: 'Remover registro'): () =>
            _remove(context, entry),
      },
      child: Dismissible(
        key: ValueKey<String>(
          '${entry.at.toIso8601String()}-${entry.valor}-${entry.tipo}',
        ),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: Space.x4),
          color: Theme.of(context).colorScheme.errorContainer,
          child: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        onDismissed: (_) => _remove(context, entry),
        child: Semantics(
          label: label,
          child: ExcludeSemantics(
            child: ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                child: Icon(
                  entry.isDas
                      ? Icons.receipt_long_outlined
                      : Icons.savings_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(titulo),
              subtitle: Text(
                '${df.format(entry.at)} · ${entry.regimeTag} · $trabalho',
              ),
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    moneyBRL(entry.reserva),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.reserva,
                      fontFeatures: AppType.tnum,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _remove(BuildContext context, ReservaEntry entry) {
    Haptics.select();
    final ReservaHistoryNotifier history = ref.read(
      reservaHistoryProvider.notifier,
    );
    history.remove(entry);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Registro removido'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => history.restore(entry),
          ),
        ),
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
