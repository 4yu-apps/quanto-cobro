import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/data/entrada_repository.dart';
import '../../core/model/entrada.dart';
import '../../core/model/proposta.dart';
import '../../core/model/trabalho.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/panel_card.dart';
import '../proposta/proposta_flow.dart';
import '../../core/ui/breakpoints.dart';
import '../../core/ui/secao_titulo.dart';

/// O detalhe de um trabalho — **a tela que o dono descreveu literalmente**:
/// *"o Augusto me pagou 400 num mês, 600 no outro, 200 no outro — e quanto eu
/// separei de cada"*.
///
/// Tocar no card abre AQUI. Editar é o ⋮ — porque abrir é o que a pessoa quer
/// fazer dez vezes, e editar é o que ela faz uma.
class TrabalhoDetalheScreen extends ConsumerWidget {
  const TrabalhoDetalheScreen({super.key, required this.trabalhoId});

  final String trabalhoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa a lista (não um snapshot) pra tela refletir na hora a entrada
    // registrada na tela empilhada acima dela.
    ref.watch(trabalhosProvider);
    final Trabalho? trabalho = ref
        .read(trabalhosProvider.notifier)
        .byId(trabalhoId);

    if (trabalho == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trabalho')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.x6),
            child: Text(
              'Esse trabalho não existe mais.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final List<Entrada> todas = ref.watch(entradasProvider);
    final Map<DateTime, List<Entrada>> porMes = entradasPorMes(
      todas,
      trabalhoId,
    );
    final double total = porMes.values
        .expand((List<Entrada> l) => l)
        .fold(0.0, (double s, Entrada e) => s + e.valor);
    final int separado = porMes.values
        .expand((List<Entrada> l) => l)
        .fold(0, (int s, Entrada e) => s + e.separado);

    return Scaffold(
      appBar: AppBar(
        title: Text(trabalho.nome, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (String op) => _menu(context, ref, trabalho, op),
            itemBuilder: (BuildContext c) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'editar',
                child: Text('Editar trabalho'),
              ),
              const PopupMenuItem<String>(
                value: 'proposta',
                child: Text('Fazer proposta'),
              ),
              PopupMenuItem<String>(
                value: 'encerrar',
                child: Text(
                  trabalho.encerrado ? 'Reabrir trabalho' : 'Encerrar trabalho',
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'apagar',
                child: Text('Apagar trabalho'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: trabalho.encerrado
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                Space.x4,
                Space.x2,
                Space.x4,
                Space.x4,
              ),
              child: FilledButton.icon(
                onPressed: () {
                  Haptics.select();
                  context.push(Routes.entrada, extra: trabalho.id);
                },
                icon: const Icon(Icons.add),
                label: const Text('Nova entrada'),
              ),
            ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            PanelCard(
              padding: const EdgeInsets.all(Space.x5),
              accent: d.lucro,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'RECEBIDO NESTE TRABALHO',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: Space.x1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      moneyBRL(total),
                      maxLines: 1,
                      style: AppType.valueXl.copyWith(color: d.lucro),
                      semanticsLabel:
                          'Recebido neste trabalho: ${moneyBRL(total)}',
                    ),
                  ),
                  if (separado > 0) ...<Widget>[
                    const SizedBox(height: Space.x1),
                    Text(
                      'separou ${moneyBRL(separado)} de imposto',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: d.reserva,
                        fontFeatures: AppType.tnum,
                      ),
                    ),
                  ],
                  if (trabalho.encerrado) ...<Widget>[
                    const SizedBox(height: Space.x2),
                    Text(
                      'Trabalho encerrado.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (trabalho.observacoes != null) ...<Widget>[
              const SizedBox(height: Space.x5),
              SecaoTitulo('Anotações', bottom: Space.x2),
              Text(trabalho.observacoes!, style: theme.textTheme.bodyMedium),
            ],

            const SizedBox(height: Space.x6),
            SecaoTitulo('Entradas', bottom: Space.x2),

            if (porMes.isEmpty)
              Text(
                'Nada registrado ainda. Quando o dinheiro cair, toque em "Nova '
                'entrada" — o imposto sai separado junto.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              // Agrupado por MÊS: é assim que a pessoa pensa o próprio dinheiro,
              // e é o que responde "quanto ele me pagou em cada mês".
              for (final MapEntry<DateTime, List<Entrada>> mes
                  in porMes.entries)
                _BlocoDoMes(mes: mes.key, entradas: mes.value),

            const SizedBox(height: Space.x8),
          ],
        ),
      ),
    );
  }

  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    Trabalho trabalho,
    String op,
  ) async {
    final TrabalhosNotifier notifier = ref.read(trabalhosProvider.notifier);

    switch (op) {
      case 'editar':
        await context.push(Routes.trabalhoForm, extra: trabalho.id);
      case 'proposta':
        if (!context.mounted) return;
        await abrirProposta(
          context,
          ref,
          inicial: Proposta(
            servico: '',
            valor: trabalho.valorCombinado,
            cliente: trabalho.nome,
          ),
          trabalhoId: trabalho.id,
        );
      case 'encerrar':
        Haptics.select();
        await notifier.setEncerrado(trabalho.id, !trabalho.encerrado);
      case 'apagar':
        final bool confirmou =
            await showDialog<bool>(
              context: context,
              builder: (BuildContext c) => AlertDialog(
                title: Text('Apagar "${trabalho.nome}"?'),
                content: const Text(
                  'O trabalho sai da lista. As entradas que você já registrou '
                  'continuam no seu histórico — o que você separou de imposto '
                  'não muda.',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Apagar'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!confirmou) return;
        Haptics.select();
        await notifier.remove(trabalho.id);
        if (!context.mounted) return;
        if (context.canPop()) context.pop();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('"${trabalho.nome}" apagado'),
              action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () => notifier.save(trabalho),
              ),
            ),
          );
    }
  }
}

class _BlocoDoMes extends StatelessWidget {
  const _BlocoDoMes({required this.mes, required this.entradas});

  final DateTime mes;
  final List<Entrada> entradas;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final double total = entradas.fold(
      0.0,
      (double s, Entrada e) => s + e.valor,
    );
    final int separado = entradas.fold(0, (int s, Entrada e) => s + e.separado);

    // O ExcludeSemantics cobria o PanelCard INTEIRO — inclusive a lista de
    // pagamentos individuais. Ou seja: a tela que o dono descreveu como "o
    // Augusto me pagou 400 num mês, 600 no outro" dava o total do mês e nunca
    // os pagamentos, pra quem usa leitor de tela. E o rótulo não dizia nem
    // quantos foram.
    //
    // Agora o Exclude cobre só o que o rótulo conta; cada pagamento fica fora,
    // porque pagamento é conteúdo, não decoração.
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: PanelCard(
        padding: const EdgeInsets.all(Space.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MergeSemantics(
              child: Semantics(
                header: true,
                label:
                    'Em ${mesAno(mes)}: recebeu ${moneyBRL(total)}, '
                    'separou ${moneyBRL(separado)} de imposto'
                    '${entradas.length > 1 ? ', em ${entradas.length} pagamentos' : ''}.',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              mesAno(mes),
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                moneyBRL(total),
                                maxLines: 1,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontFamily: AppType.numberFamily,
                                  fontFeatures: AppType.tnum,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.x1),
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
            // Só detalha quando houve mais de um pagamento no mês —
            // repetir a mesma linha embaixo do total seria ruído.
            if (entradas.length > 1) ...<Widget>[
              const SizedBox(height: Space.x2),
              for (final Entrada e in entradas)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${dataCurta(e.at)} · ${moneyBRL(e.valor)}',
                    // "10/ago" na fala vira "dez barra ago". O helper que
                    // resolve isso já existia e não estava sendo usado aqui.
                    semanticsLabel:
                        '${dataPorExtenso(e.at)}: ${moneyBRL(e.valor)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: AppType.tnum,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
