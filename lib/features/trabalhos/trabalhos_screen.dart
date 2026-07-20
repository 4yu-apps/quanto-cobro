import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/data/area_repository.dart';
import '../../core/data/entrada_repository.dart';
import '../../core/data/trabalho_repository.dart';
import '../../core/model/area.dart';
import '../../core/model/entrada.dart';
import '../../core/model/trabalho.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/panel_card.dart';
import '../../core/ui/breakpoints.dart';

/// Aba **Trabalhos** — os freelas da pessoa.
///
/// A hierarquia é LATENTE: com uma área só, a palavra "área" não aparece em
/// lugar nenhum e a lista é plana. O nível de cima só se revela pra quem tem a
/// segunda — que é o power user, e o único que precisa dele.
class TrabalhosScreen extends ConsumerWidget {
  const TrabalhosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AreasData areas = ref.watch(areasProvider);
    final List<Trabalho> todos = ref.watch(trabalhosProvider);
    final List<Entrada> entradas = ref.watch(entradasProvider);

    final Map<String, double> recebido = recebidoPorTrabalho(entradas);
    final Map<String, DateTime> ultima = ultimaEntradaPorTrabalho(entradas);
    final List<Trabalho> ordenados = ordenarTrabalhos(todos, ultima);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus trabalhos'),
        actions: <Widget>[
          if (ordenados.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Novo trabalho',
              onPressed: () => context.push(Routes.trabalhoForm),
            ),
        ],
      ),
      body: ContentWidth(
        child: ordenados.isEmpty
            ? const _Vazio()
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  Space.x4,
                  Space.x4,
                  Space.x4,
                  reservaDaNavbar(context),
                ),
                children: <Widget>[
                  if (areas.hierarquiaVisivel)
                    ..._porArea(
                      context,
                      ref,
                      areas,
                      ordenados,
                      recebido,
                      ultima,
                    )
                  else
                    ..._planos(context, ordenados, recebido, ultima),
                  const SizedBox(height: Space.x4),
                  OutlinedButton.icon(
                    onPressed: () => context.push(Routes.trabalhoForm),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo trabalho'),
                  ),
                ],
              ),
      ),
    );
  }

  /// Lista plana — o caso de 99% das pessoas.
  List<Widget> _planos(
    BuildContext context,
    List<Trabalho> trabalhos,
    Map<String, double> recebido,
    Map<String, DateTime> ultima,
  ) => <Widget>[
    for (int i = 0; i < trabalhos.length; i++) ...<Widget>[
      if (i > 0) const SizedBox(height: Space.x3),
      StaggerIn(
        index: i.clamp(0, 4),
        child: _TrabalhoCard(
          trabalho: trabalhos[i],
          recebido: recebido[trabalhos[i].id] ?? 0,
          ultima: ultima[trabalhos[i].id],
        ),
      ),
    ],
  ];

  /// Agrupado por área — só pra quem tem mais de uma.
  List<Widget> _porArea(
    BuildContext context,
    WidgetRef ref,
    AreasData areas,
    List<Trabalho> trabalhos,
    Map<String, double> recebido,
    Map<String, DateTime> ultima,
  ) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> out = <Widget>[];
    for (final Area area in areas.areas) {
      final List<Trabalho> daArea = trabalhos
          .where((Trabalho t) => t.areaId == area.id)
          .toList();
      if (daArea.isEmpty) continue;
      out
        ..add(
          Padding(
            padding: const EdgeInsets.only(top: Space.x2, bottom: Space.x2),
            child: Text(
              area.nome.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
        )
        ..addAll(_planos(context, daArea, recebido, ultima));
      out.add(const SizedBox(height: Space.x4));
    }
    // Trabalho cuja área foi apagada não pode sumir da tela em silêncio.
    final Set<String> conhecidas = areas.areas.map((Area a) => a.id).toSet();
    final List<Trabalho> orfaos = trabalhos
        .where((Trabalho t) => !conhecidas.contains(t.areaId))
        .toList();
    if (orfaos.isNotEmpty) {
      out
        ..add(
          Padding(
            padding: const EdgeInsets.only(top: Space.x2, bottom: Space.x2),
            child: Text(
              'SEM ÁREA',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
        )
        ..addAll(_planos(context, orfaos, recebido, ultima));
    }
    return out;
  }
}

class _TrabalhoCard extends StatelessWidget {
  const _TrabalhoCard({
    required this.trabalho,
    required this.recebido,
    required this.ultima,
  });

  final Trabalho trabalho;
  final double recebido;
  final DateTime? ultima;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    return SemanticButton(
      label: _semantica(),
      tapHint: 'abrir o trabalho',
      onTap: () => context.push(Routes.trabalhoDetalhe, extra: trabalho.id),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push(Routes.trabalhoDetalhe, extra: trabalho.id),
          borderRadius: const BorderRadius.all(Radii.lg),
          child: PanelCard(
            padding: const EdgeInsets.all(Space.x4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        trabalho.nome,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: trabalho.encerrado
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Space.x1),
                      Text(
                        _linhaApoio(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.x3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      moneyBRL(recebido),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: AppType.numberFamily,
                        fontFeatures: AppType.tnum,
                        color: recebido > 0 ? d.lucro : cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'recebido',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _linhaApoio() {
    if (trabalho.encerrado) return 'Encerrado';
    final DateTime? u = ultima;
    if (u == null) return 'Nenhuma entrada ainda';
    return 'Última entrada em ${dataCurta(u)}';
  }

  String _semantica() {
    final StringBuffer sb = StringBuffer(trabalho.nome)..write('. ');
    if (recebido > 0) {
      sb.write('Recebido ${moneyBRL(recebido)}. ');
    } else {
      sb.write('Nenhuma entrada ainda. ');
    }
    final DateTime? u = ultima;
    if (u != null) sb.write('Última entrada em ${dataPorExtenso(u)}. ');
    if (trabalho.encerrado) sb.write('Encerrado.');
    return sb.toString();
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Space.x6,
          Space.x6,
          Space.x6,
          reservaDaNavbar(context),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              Icons.folder_open_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: Space.x4),
            Text(
              'Seus trabalhos, num lugar só.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: Space.x3),
            Text(
              'Quando um pagamento cair, registre e diga de quem veio — o '
              'trabalho aparece aqui sozinho, com tudo que já entrou.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x6),
            FilledButton.icon(
              onPressed: () => context.push(Routes.entrada),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Registrar um pagamento'),
            ),
            const SizedBox(height: Space.x2),
            TextButton(
              onPressed: () => context.push(Routes.trabalhoForm),
              child: const Text('Ou cadastrar um trabalho'),
            ),
          ],
        ),
      ),
    );
  }
}
