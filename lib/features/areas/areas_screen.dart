import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/data/area_repository.dart';
import '../../core/model/area.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';

/// **Meus preços** — as áreas de trabalho, cada uma com o seu valor-hora.
///
/// Alcançada por Configurações, não por aba: definir preço é coisa rara. A
/// segunda área em diante é Pro (é o gate de multiplicidade), mas a PRIMEIRA é
/// sempre grátis — sem o objeto salvo não há retenção nenhuma.
class AreasScreen extends ConsumerWidget {
  const AreasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AreasData data = ref.watch(areasProvider);
    final RegimeId regime = ref.watch(regimeProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus preços'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova área',
            onPressed: () => novaArea(context, ref),
          ),
        ],
      ),
      body: data.areas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.x6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.calculate_outlined,
                      size: 40,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: Space.x3),
                    Text(
                      'Faça seu cálculo pra descobrir quanto vale a sua hora.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Space.x6),
                    FilledButton(
                      onPressed: () => context.push(Routes.calc),
                      child: const Text('Calcular agora'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(Space.x4),
              children: <Widget>[
                Text(
                  data.hierarquiaVisivel
                      ? 'Toque pra ativar. O Início e a entrada passam a usar a área ativa.'
                      : 'É daqui que sai o seu valor-hora.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.x4),
                Card(
                  color: cs.surfaceContainer,
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < data.areas.length; i++) ...<Widget>[
                        if (i > 0) const Divider(height: 1, indent: Space.x4),
                        _tile(
                          context,
                          ref,
                          data.areas[i],
                          regime,
                          ativa: data.areas[i].id == data.active?.id,
                          unica: data.areas.length == 1,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Space.x4),
                OutlinedButton.icon(
                  onPressed: () => novaArea(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova área de trabalho'),
                ),
              ],
            ),
    );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    Area a,
    RegimeId regime, {
    required bool ativa,
    required bool unica,
  }) {
    final ThemeData theme = Theme.of(context);
    final int vh = computeValorHora(a, regime).valorHora;
    // SEM MergeSemantics: ele funde o tile e o ⋮ num nó só, e o gesto do nó
    // fundido cai sempre no PRIMEIRO da árvore — o onTap do tile. Com leitor de
    // tela, o menu (Editar · Renomear · Apagar) fica inalcançável: nem é falado,
    // nem abre. O ListTile já funde título + subtítulo sozinho; o merge só
    // existia pra juntar o "R$ 92/h", e isso se resolve no próprio rótulo dele.
    return Semantics(
      button: !ativa,
      selected: ativa,
      child: ListTile(
        leading: Icon(
          ativa ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: ativa ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        title: Text(a.nome),
        subtitle: Text(ativa ? 'Ativa' : 'Toque pra ativar'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${moneyBRL(vh)}/h',
              // "/h" na fala vira "barra agá".
              semanticsLabel: '${moneyBRL(vh)} por hora',
              style: theme.textTheme.labelLarge?.copyWith(
                fontFeatures: AppType.tnum,
                color: theme.colorScheme.primary,
              ),
            ),
            PopupMenuButton<String>(
              // "Opções" sozinho, numa lista de três áreas, não diz de quê.
              tooltip: 'Opções de ${a.nome}',
              onSelected: (String op) async {
                if (op == 'editar') {
                  await ref.read(areasProvider.notifier).select(a.id);
                  if (context.mounted) context.push(Routes.calc);
                } else if (op == 'renomear') {
                  final String? nome = await pedirNomeArea(
                    context,
                    inicial: a.nome,
                  );
                  if (nome != null) {
                    await ref.read(areasProvider.notifier).rename(a.id, nome);
                  }
                } else if (op == 'apagar') {
                  if (unica) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Essa é a sua única área. Pra zerar tudo, use Apagar meus dados.',
                          ),
                        ),
                      );
                    return;
                  }
                  Haptics.select();
                  final AreasNotifier n = ref.read(areasProvider.notifier);
                  await n.remove(a.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('"${a.nome}" apagada'),
                        action: SnackBarAction(
                          label: 'Desfazer',
                          onPressed: () => n.saveAndActivate(a),
                        ),
                      ),
                    );
                }
              },
              itemBuilder: (BuildContext c) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'editar',
                  child: Text('Editar cálculo'),
                ),
                PopupMenuItem<String>(
                  value: 'renomear',
                  child: Text('Renomear'),
                ),
                PopupMenuItem<String>(value: 'apagar', child: Text('Apagar')),
              ],
            ),
          ],
        ),
        onTap: ativa
            ? null
            : () {
                Haptics.select();
                ref.read(areasProvider.notifier).select(a.id);
              },
      ),
    );
  }
}

/// Criar uma área nova. A segunda em diante é Pro — e se a pessoa comprar, o
/// app RETOMA sozinho, sem exigir um segundo toque no mesmo botão.
Future<void> novaArea(BuildContext context, WidgetRef ref) async {
  final AreasData data = ref.read(areasProvider);
  final bool isPro = ref.read(proProvider);

  if (data.areas.isNotEmpty && !isPro) {
    telemetry.evento(
      Evento.proParedeVista,
      params: <String, Object?>{'gatilho': GatilhoPro.segundaArea},
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Ter várias áreas é recurso Pro.')),
      );
    await context.push(Routes.pro, extra: GatilhoPro.segundaArea);
    if (!context.mounted || !ref.read(proProvider)) return;
    announce(context, 'Pro ativado. Continuando sua nova área.');
  }
  if (!context.mounted) return;

  final String? nome = await pedirNomeArea(context);
  if (nome == null || !context.mounted) return;
  Haptics.select();
  context.push(Routes.calc, extra: nome);
}

/// Dialog de nome com validação FALADA: nunca fecha em silêncio com nome vazio.
Future<String?> pedirNomeArea(BuildContext context, {String? inicial}) async {
  final TextEditingController c = TextEditingController(text: inicial ?? '');
  String? erro;
  final String? r = await showDialog<String>(
    context: context,
    builder: (BuildContext ctx) => StatefulBuilder(
      builder: (BuildContext ctx, void Function(void Function()) setDialog) {
        return AlertDialog(
          title: Text(inicial == null ? 'Que trabalho é esse?' : 'Renomear'),
          content: TextField(
            controller: c,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nome',
              hintText: 'Ex.: Design, Consultoria, Fotografia',
              errorText: erro,
            ),
            onSubmitted: (_) =>
                _confirmar(ctx, c, setDialog, (String e) => erro = e),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  _confirmar(ctx, c, setDialog, (String e) => erro = e),
              child: Text(inicial == null ? 'Continuar' : 'Salvar'),
            ),
          ],
        );
      },
    ),
  );
  Future<void>.delayed(const Duration(milliseconds: 600), c.dispose);
  final String? limpo = r?.trim();
  return (limpo == null || limpo.isEmpty) ? null : limpo;
}

void _confirmar(
  BuildContext ctx,
  TextEditingController c,
  void Function(void Function()) setDialog,
  void Function(String) setErro,
) {
  if (c.text.trim().isEmpty) {
    const String msg = 'Dá um nome pra eu continuar.';
    setDialog(() => setErro(msg));
    announce(ctx, msg);
    return;
  }
  Navigator.pop(ctx, c.text);
}
