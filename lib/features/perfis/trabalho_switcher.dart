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
import '../../core/ui/a11y.dart';

/// Troca rápida de trabalho (P0-4b): o chip do herói finalmente diz a verdade.
/// Bottom-sheet com a lista de trabalhos (nome + R$/h), toque ativa e fecha —
/// o count-up do herói no Painel É a confirmação (sem toast por cima).
Future<void> showTrabalhoSwitcher(BuildContext context, WidgetRef ref) async {
  final ProfilesData data = ref.read(profilesProvider);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheet) {
      final ThemeData theme = Theme.of(sheet);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.x6,
                0,
                Space.x6,
                Space.x2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Qual trabalho você quer ver?',
                    style: theme.textTheme.titleLarge,
                  ),
                  if (data.perfis.length == 1) ...<Widget>[
                    const SizedBox(height: Space.x2),
                    Text(
                      'Você tem 1 trabalho aqui. Dá pra criar outros — freela, cliente fixo, um bico — e ter um preço certo pra cada um.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            for (final Perfil p in data.perfis)
              _TrabalhoTile(
                perfil: p,
                ativo: p.id == data.active?.id,
                onTap: () {
                  Haptics.select();
                  ref.read(profilesProvider.notifier).select(p.id);
                  announce(
                    sheet,
                    'Agora usando ${p.nome}, valor-hora ${moneyBRL(computeValorHora(p).valorHora)}.',
                  );
                  Navigator.pop(sheet);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Novo trabalho'),
              onTap: () {
                Navigator.pop(sheet);
                novoTrabalho(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Gerenciar'),
              onTap: () {
                Navigator.pop(sheet);
                context.push(Routes.perfis);
              },
            ),
            const SizedBox(height: Space.x2),
          ],
        ),
      );
    },
  );
}

class _TrabalhoTile extends StatelessWidget {
  const _TrabalhoTile({
    required this.perfil,
    required this.ativo,
    required this.onTap,
  });

  final Perfil perfil;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int vh = computeValorHora(perfil).valorHora;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: ativo,
        child: ListTile(
          leading: Icon(
            ativo ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: ativo
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          title: Text(perfil.nome),
          subtitle: ativo ? const Text('Ativo') : null,
          trailing: Text(
            '${moneyBRL(vh)}/h',
            style: theme.textTheme.labelLarge?.copyWith(
              fontFeatures: AppType.tnum,
              color: theme.colorScheme.primary,
            ),
          ),
          onTap: ativo ? null : onTap,
        ),
      ),
    );
  }
}

/// Fluxo do novo trabalho — INTEIRO (P0-4a): se a parede Pro aparecer e a
/// pessoa comprar, o app RETOMA sozinho (o dialog de nome abre sem re-toque).
/// Quebrar promessa logo depois da compra era o pior lugar pra decepcionar.
Future<void> novoTrabalho(BuildContext context, WidgetRef ref) async {
  final ProfilesData data = ref.read(profilesProvider);
  final bool isPro = ref.read(proProvider);

  if (data.perfis.isNotEmpty && !isPro) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Vários trabalhos é recurso Pro.')),
      );
    await context.push(Routes.pro);
    // Na volta: virou Pro? Então a pessoa veio criar um trabalho — continua.
    if (!context.mounted || !ref.read(proProvider)) return;
    announce(context, 'Pro ativado. Continuando seu novo trabalho.');
  }
  if (!context.mounted) return;

  final String? nome = await pedirNomeTrabalho(context);
  if (nome == null || !context.mounted) return;
  Haptics.select();
  context.push(Routes.calc, extra: nome);
}

/// Dialog de nome com validação FALADA (P0-3): nunca fecha em silêncio com
/// nome vazio — explica, anuncia e mantém o dialog aberto.
Future<String?> pedirNomeTrabalho(
  BuildContext context, {
  String? inicial,
}) async {
  final TextEditingController c = TextEditingController(text: inicial ?? '');
  String? erro;
  final String? r = await showDialog<String>(
    context: context,
    builder: (BuildContext ctx) => StatefulBuilder(
      builder: (BuildContext ctx, void Function(void Function()) setDialog) {
        return AlertDialog(
          title: Text(inicial == null ? 'Nome do trabalho' : 'Renomear'),
          content: TextField(
            controller: c,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nome do trabalho',
              hintText: 'Ex.: Freela design, Cliente fixo...',
              errorText: erro,
            ),
            onSubmitted: (_) =>
                _confirmarNome(ctx, c, setDialog, (String e) => erro = e),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  _confirmarNome(ctx, c, setDialog, (String e) => erro = e),
              child: Text(inicial == null ? 'Continuar' : 'Salvar'),
            ),
          ],
        );
      },
    ),
  );
  Future<void>.delayed(const Duration(milliseconds: 600), c.dispose);
  return r?.trim().isEmpty ?? true ? null : r!.trim();
}

void _confirmarNome(
  BuildContext ctx,
  TextEditingController c,
  void Function(void Function()) setDialog,
  void Function(String) setErro,
) {
  if (c.text.trim().isEmpty) {
    const String msg = 'Dá um nome pro trabalho pra eu continuar.';
    setDialog(() => setErro(msg));
    announce(ctx, msg);
    return;
  }
  Navigator.pop(ctx, c.text);
}
