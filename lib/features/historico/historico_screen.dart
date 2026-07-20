import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/data/entrada_csv.dart';
import '../../core/data/entrada_repository.dart';
import '../../core/model/entrada.dart';
import '../../core/model/trabalho.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/panel_card.dart';
import '../../core/ui/breakpoints.dart';

/// O histórico completo, mês a mês. **Deixou de ser aba** em 19/07/2026: era o
/// mesmo balde do card do Início, só que num zoom maior — e um slot de aba é
/// caro demais pra um zoom.
///
/// Também saiu daqui o "já paguei o imposto deste mês": marcar imposto pago é
/// exatamente o que este app não é.
class HistoricoScreen extends ConsumerWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Entrada> todas = ref.watch(entradasProvider);
    final List<Trabalho> trabalhos = ref.watch(trabalhosProvider);
    final ThemeData theme = Theme.of(context);

    final Map<String, String> nomePorTrabalho = <String, String>{
      for (final Trabalho t in trabalhos) t.id: t.nome,
    };

    final Map<DateTime, List<Entrada>> porMes = <DateTime, List<Entrada>>{};
    for (final Entrada e in todas) {
      (porMes[DateTime(e.at.year, e.at.month)] ??= <Entrada>[]).add(e);
    }
    final List<DateTime> meses = mesesComEntrada(todas);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: todas.isEmpty
            ? null
            : <Widget>[
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'Exportar CSV',
                  onPressed: () => _exportarCsv(context, todas),
                ),
              ],
      ),
      body: ContentWidth(
        child: todas.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(Space.x6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.savings_outlined,
                        size: 40,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: Space.x3),
                      Text(
                        'Nada registrado ainda. Quando um pagamento cair, ele '
                        'aparece aqui — com o imposto já separado.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(Space.x4),
                children: <Widget>[
                  for (final DateTime mes in meses)
                    _Mes(
                      mes: mes,
                      entradas: porMes[mes]!,
                      nomePorTrabalho: nomePorTrabalho,
                    ),
                  const SizedBox(height: Space.x4),
                  const EstimativaSeal(short: true),
                  const SizedBox(height: Space.x8),
                ],
              ),
      ),
    );
  }

  /// Exporta o histórico como CSV. **GRÁTIS, e nunca deve deixar de ser** —
  /// são os registros que a PESSOA digitou. Prender o dado dela atrás de
  /// pagamento é o crime que derrubou o MEI Fácil pra 1,92★.
  Future<void> _exportarCsv(BuildContext context, List<Entrada> todas) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final DateTime now = DateTime.now();
      final String dia =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/historico-$dia.csv');
      await file.writeAsString(entradasCsv(todas));
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'text/csv')],
          subject: 'Histórico — Quanto Cobro',
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
}

class _Mes extends StatelessWidget {
  const _Mes({
    required this.mes,
    required this.entradas,
    required this.nomePorTrabalho,
  });

  final DateTime mes;
  final List<Entrada> entradas;
  final Map<String, String> nomePorTrabalho;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final double entrou = entradas.fold(
      0.0,
      (double s, Entrada e) => s + e.valor,
    );
    final int separado = entradas.fold(0, (int s, Entrada e) => s + e.separado);
    final List<Entrada> ordenadas = List<Entrada>.of(entradas)
      ..sort((Entrada a, Entrada b) => b.at.compareTo(a.at));

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x4),
      child: PanelCard(
        padding: const EdgeInsets.all(Space.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MergeSemantics(
              child: Semantics(
                label:
                    'Em ${mesAno(mes)} entraram ${moneyBRL(entrou)}, '
                    'e você separou ${moneyBRL(separado)} de imposto.',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        mesAno(mes).toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: Space.x1),
                      Text(
                        moneyBRL(entrou),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFamily: AppType.numberFamily,
                          fontFeatures: AppType.tnum,
                          color: d.lucro,
                        ),
                      ),
                      Text(
                        'separou ${moneyBRL(separado)} de imposto',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: d.reserva,
                          fontFeatures: AppType.tnum,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.x3),
            const Divider(height: 1),
            const SizedBox(height: Space.x2),
            // Três `Text` crus num MergeSemantics viravam uma sopa de números
            // na fala: "dez barra ago ponto médio Augusto, R cifrão
            // quatrocentos, ponto médio R cifrão sessenta e oito" — e nada
            // dizia que o segundo valor é o imposto separado. É a tela que a
            // pessoa abre pra conferir o próprio dinheiro.
            for (final Entrada e in ordenadas)
              Semantics(
                label:
                    '${dataPorExtenso(e.at)}'
                    '${_nome(e) == null ? '' : ', ${_nome(e)}'}: '
                    'recebeu ${moneyBRL(e.valor)}, '
                    'separou ${moneyBRL(e.separado)} de imposto.',
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.x1),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${dataCurta(e.at)}'
                            '${_nome(e) == null ? '' : ' · ${_nome(e)}'}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Space.x2),
                        // Sem isto a linha estoura 305px em fonte 2.0 num
                        // celular de 320dp — e o que sai da tela é sempre o
                        // número, porque o número mora à direita de uma Row.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  moneyBRL(e.valor),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontFeatures: AppType.tnum,
                                  ),
                                ),
                                Text(
                                  ' · ${moneyBRL(e.separado)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: d.reserva,
                                    fontFeatures: AppType.tnum,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _nome(Entrada e) {
    final String? id = e.trabalhoId;
    return id == null ? null : nomePorTrabalho[id];
  }
}
