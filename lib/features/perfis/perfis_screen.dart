import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/data/profile_repository.dart';
import '../../core/model/perfil.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import 'trabalho_switcher.dart';

/// Perfis (Blueprint §5.7): um perfil por CASO — "Freela design", "Cliente
/// fixo", "Outro emprego". Tocar ativa (o Painel inteiro muda). O 2º perfil em
/// diante é Pro (gatilho de valor, preço antes do trabalho).
class PerfisScreen extends ConsumerWidget {
  const PerfisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfilesData data = ref.watch(profilesProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus trabalhos'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo trabalho',
            onPressed: () => _novo(context, ref),
          ),
        ],
      ),
      body: data.perfis.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.x6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.switch_account_outlined,
                      size: 40,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: Space.x3),
                    Text(
                      'Cada trabalho seu pode ter um preço: freela, cliente fixo, outro serviço. Comece pelo primeiro.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Space.x6),
                    FilledButton(
                      onPressed: () => context.push(Routes.calc),
                      child: const Text('Fazer meu primeiro cálculo'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, 120),
              children: <Widget>[
                Text(
                  'Toque pra ativar. O Painel, a Reserva e o Simulador passam a usar o trabalho ativo.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.x4),
                Card(
                  color: cs.surfaceContainer,
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < data.perfis.length; i++) ...<Widget>[
                        if (i > 0) const Divider(height: 1, indent: Space.x4),
                        _tile(
                          context,
                          ref,
                          data.perfis[i],
                          ativo: data.perfis[i].id == data.active?.id,
                          unico: data.perfis.length == 1,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Space.x4),
                OutlinedButton.icon(
                  onPressed: () => _novo(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo trabalho'),
                ),
              ],
            ),
    );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    Perfil p, {
    required bool ativo,
    required bool unico,
  }) {
    final ThemeData theme = Theme.of(context);
    final int vh = computeValorHora(p).valorHora;
    return MergeSemantics(
      child: Semantics(
        button: !ativo,
        selected: ativo,
        child: ListTile(
          leading: AnimatedSwitcher(
            duration: reduceMotionOf(context) ? Duration.zero : Motion.quick,
            transitionBuilder: (Widget child, Animation<double> animation) =>
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
                  child: child,
                ),
            child: Icon(
              ativo ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              key: ValueKey<bool>(ativo),
              color: ativo
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ),
          title: Text(p.nome),
          subtitle: Text(ativo ? 'Ativo' : 'Toque pra ativar'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${moneyBRL(vh)}/h',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFeatures: AppType.tnum,
                  color: theme.colorScheme.primary,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (String op) async {
                  if (op == 'renomear') {
                    final String? nome = await _pedirNome(
                      context,
                      inicial: p.nome,
                    );
                    if (nome != null && nome.trim().isNotEmpty) {
                      await ref
                          .read(profilesProvider.notifier)
                          .rename(p.id, nome.trim());
                    }
                  } else if (op == 'editar') {
                    await ref.read(profilesProvider.notifier).select(p.id);
                    if (context.mounted) context.push(Routes.calc);
                  } else if (op == 'apagar') {
                    if (unico) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Esse é o seu único trabalho. Pra zerar tudo, use Configurações.',
                            ),
                          ),
                        );
                      return;
                    }
                    Haptics.select();
                    final ProfilesNotifier profilesN = ref.read(
                      profilesProvider.notifier,
                    );
                    await profilesN.remove(p.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('"${p.nome}" apagado'),
                            action: SnackBarAction(
                              label: 'Desfazer',
                              onPressed: () => profilesN.saveAndActivate(p),
                            ),
                          ),
                        );
                    }
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
          onTap: ativo
              ? null
              : () {
                  Haptics.select();
                  ref.read(profilesProvider.notifier).select(p.id);
                },
        ),
      ),
    );
  }

  Future<void> _novo(BuildContext context, WidgetRef ref) =>
      novoTrabalho(context, ref);

  Future<String?> _pedirNome(BuildContext context, {String? inicial}) async {
    return pedirNomeTrabalho(context, inicial: inicial);
  }
}
