import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/model/projeto.dart';
import '../../core/model/proposta.dart';
import '../../core/model/reserva_entry.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/panel_card.dart';
import '../proposta/proposta_flow.dart';

/// Detalhe de um projeto: o que já entrou, o que vem, e as duas ações que
/// importam ("Recebi" e "Fazer proposta"). Sem aba, sem timeline de tarefa —
/// o projeto é um razão de recebimentos, não um cartão de kanban (07 §D.1).
class ProjetoDetalheScreen extends ConsumerWidget {
  const ProjetoDetalheScreen({super.key, required this.projetoId});

  final String projetoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa a lista inteira (e não um snapshot do projeto) pra tela refletir
    // na hora o "Recebi" que aconteceu na Reserva empilhada acima dela.
    ref.watch(projetosProvider);
    final Projeto? projeto = ref
        .read(projetosProvider.notifier)
        .byId(projetoId);

    if (projeto == null) {
      // Apagado enquanto a tela estava aberta (ou backup restaurado por baixo).
      return Scaffold(
        appBar: AppBar(title: const Text('Projeto')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.x6),
            child: Text(
              'Esse projeto não existe mais.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final DateTime hoje = DateTime.now();

    final List<ReservaEntry> recebimentos =
        ref
            .watch(reservaHistoryProvider)
            .where((ReservaEntry e) => e.projetoId == projetoId && !e.isDas)
            .toList()
          ..sort((ReservaEntry a, ReservaEntry b) => b.at.compareTo(a.at));
    final double total = recebimentos.fold(
      0.0,
      (double s, ReservaEntry e) => s + e.valor,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(projeto.nome, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar projeto',
            onPressed: () =>
                context.push(Routes.projetoForm, extra: projeto.id),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (String op) => _menu(context, ref, projeto, op),
            itemBuilder: (BuildContext c) => <PopupMenuEntry<String>>[
              for (final ProjetoStatus s in ProjetoStatus.values)
                if (s != projeto.status)
                  PopupMenuItem<String>(
                    value: 'status:${s.name}',
                    child: Text('Marcar como ${s.label.toLowerCase()}'),
                  ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'apagar',
                child: Text('Apagar projeto'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          PanelCard(
            padding: const EdgeInsets.all(Space.x5),
            accent: d.lucro,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'VALOR COMBINADO',
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
                    moneyBRL(projeto.valor),
                    maxLines: 1,
                    style: AppType.valueXl.copyWith(color: d.lucro),
                  ),
                ),
                const SizedBox(height: Space.x1),
                Text(
                  '${projeto.status.label} · ${projeto.recorrenciaLabel}'
                  '${projeto.recorrente ? ' (por ciclo)' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (projeto.cliente != null) ...<Widget>[
                  const SizedBox(height: Space.x1),
                  Text(
                    'Quem paga: ${projeto.cliente}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.x4),

          if (projeto.proximoRecebimento != null)
            _Info(
              icon: Icons.event_outlined,
              texto:
                  'Próximo recebimento: ${dataPorExtenso(projeto.proximoRecebimento!)}',
              cor:
                  projeto.proximoRecebimento!.isBefore(
                    DateTime(hoje.year, hoje.month, hoje.day),
                  )
                  ? d.onAlertaContainer
                  : cs.onSurfaceVariant,
            ),
          if (total > 0)
            _Info(
              icon: Icons.check_circle_outline,
              texto: 'Já recebeu ${moneyBRL(total)} neste projeto',
              cor: cs.onSurfaceVariant,
            ),

          const SizedBox(height: Space.x5),
          if (projeto.status.esperaRecebimento)
            FilledButton.icon(
              onPressed: () {
                Haptics.select();
                context.push(Routes.reserva, extra: projeto.id);
              },
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Recebi'),
            ),
          const SizedBox(height: Space.x3),
          OutlinedButton.icon(
            onPressed: () => abrirProposta(
              context,
              ref,
              inicial: Proposta(
                servico: projeto.nome,
                valor: projeto.valor,
                cliente: projeto.cliente ?? '',
              ),
              projetoId: projeto.id,
            ),
            icon: const Icon(Icons.description_outlined),
            label: Text(
              projeto.status == ProjetoStatus.orcamento
                  ? 'Reenviar proposta'
                  : 'Fazer proposta',
            ),
          ),

          if (projeto.observacoes != null) ...<Widget>[
            const SizedBox(height: Space.x6),
            Text(
              'ANOTAÇÕES',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: Space.x2),
            Text(projeto.observacoes!, style: theme.textTheme.bodyMedium),
          ],

          const SizedBox(height: Space.x6),
          Text(
            'RECEBIMENTOS',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: Space.x2),
          if (recebimentos.isEmpty)
            Text(
              'Nada registrado ainda. Quando o dinheiro cair, toque em "Recebi" '
              '— a reserva do Leão sai junto.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          else
            for (final ReservaEntry e in recebimentos)
              MergeSemantics(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.savings_outlined, color: d.reserva),
                  title: Text(
                    moneyBRL(e.valor),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFeatures: AppType.tnum,
                    ),
                  ),
                  subtitle: Text(
                    '${dataPorExtenso(e.at)} · reservou ${moneyBRL(e.reserva)} (${e.regimeTag})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: Space.x8),
        ],
      ),
    );
  }

  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    Projeto projeto,
    String op,
  ) async {
    final ProjetosNotifier notifier = ref.read(projetosProvider.notifier);

    if (op.startsWith('status:')) {
      final String name = op.substring('status:'.length);
      final ProjetoStatus novo = ProjetoStatus.values.firstWhere(
        (ProjetoStatus s) => s.name == name,
      );
      Haptics.select();
      await notifier.setStatus(projeto.id, novo);
      return;
    }

    if (op == 'apagar') {
      final bool confirmou =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext c) => AlertDialog(
              title: Text('Apagar "${projeto.nome}"?'),
              content: const Text(
                'O projeto sai da lista. Os recebimentos que você já registrou '
                'continuam no Guardado — sua reserva do Leão não muda.',
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
      await notifier.remove(projeto.id);
      if (!context.mounted) return;
      // Sai da tela do que acabou de deixar de existir.
      if (context.canPop()) context.pop();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('"${projeto.nome}" apagado'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () => notifier.save(projeto),
            ),
          ),
        );
    }
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.texto, required this.cor});

  final IconData icon;
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: MergeSemantics(
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: cor),
            const SizedBox(width: Space.x2),
            Expanded(
              child: Text(
                texto,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
