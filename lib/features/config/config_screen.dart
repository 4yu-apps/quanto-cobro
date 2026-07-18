import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/config/app_config.dart';
import '../../core/model/reserva_entry.dart';
import '../../core/providers.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';

/// Configurações: tema, backup (sem nuvem), apagar dados, telemetria opt-in,
/// Pro, legal e Sobre. Seções em cards (gramática premium), rótulos na mesma
/// voz do resto do app.
class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final bool isPro = ref.watch(proProvider);
    final bool telemetria = ref.watch(telemetryProvider);
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          _secao(context, 'APARÊNCIA'),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark, label: Text('Escuro'), icon: Icon(Icons.dark_mode)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto)),
            ],
            selected: <ThemeMode>{mode},
            onSelectionChanged: (Set<ThemeMode> s) {
              Haptics.select();
              ref.read(themeModeProvider.notifier).set(s.first);
            },
          ),
          const SizedBox(height: Space.x6),

          _secao(context, 'FERRAMENTAS'),
          Card(
            color: theme.colorScheme.surfaceContainer,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                      isPro ? Icons.workspace_premium : Icons.workspace_premium_outlined),
                  title: Text(isPro ? 'Pro ativo' : 'Conhecer o Pro'),
                  trailing:
                      isPro ? const Icon(Icons.check) : const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.pro),
                ),
                const Divider(height: 1, indent: Space.x4),
                ListTile(
                  leading: const Icon(Icons.switch_account_outlined),
                  title: const Text('Perfis'),
                  subtitle: const Text('Cenários de preço por tipo de cliente'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.perfis),
                ),
                const Divider(height: 1, indent: Space.x4),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Histórico de reservas'),
                  subtitle: const Text('Quanto você já guardou pro Leão'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.historico),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x6),

          _secao(context, 'SEUS DADOS'),
          Card(
            color: theme.colorScheme.surfaceContainer,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: const Text('Exportar dados (backup)'),
                  subtitle: const Text('Seu cálculo e seu histórico, sem nuvem, sem conta.'),
                  onTap: () => _exportar(context, ref),
                ),
                const Divider(height: 1, indent: Space.x4),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Restaurar backup'),
                  onTap: () => _importar(context, ref),
                ),
                const Divider(height: 1, indent: Space.x4),
                ListTile(
                  leading:
                      Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  title: Text('Apagar meus dados',
                      style: TextStyle(color: theme.colorScheme.error)),
                  onTap: () => _apagar(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x6),

          _secao(context, 'PRIVACIDADE'),
          Card(
            color: theme.colorScheme.surfaceContainer,
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  value: telemetria,
                  onChanged: (bool v) {
                    Haptics.select();
                    ref.read(telemetryProvider.notifier).set(v);
                  },
                  title: const Text('Ajudar a melhorar o app'),
                  subtitle: const Text(
                      'Envia só métricas anônimas de uso e estabilidade. Nunca sua renda.'),
                ),
                const Divider(height: 1, indent: Space.x4),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacidade e Termos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.legal),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x6),

          _secao(context, 'SOBRE'),
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: d.brand4yu, shape: BoxShape.circle),
              ),
              const SizedBox(width: Space.x2),
              Text('by ${AppConfig.parentBrand}',
                  style: theme.textTheme.labelMedium?.copyWith(color: d.brand4yu)),
            ],
          ),
          const SizedBox(height: Space.x1),
          Text('${AppConfig.appName} · versão 0.1.0 · ${AppConfig.contactEmail}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _secao(BuildContext context, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: Text(
        titulo,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  void _exportar(BuildContext context, WidgetRef ref) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? json = ref.read(backupServiceProvider).exportJson();
    if (json == null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
            const SnackBar(content: Text('Ainda não há um cálculo pra exportar.')));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Backup dos seus dados'),
        content: SingleChildScrollView(child: SelectableText(json)),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(c);
              messenger
                ..clearSnackBars()
                ..showSnackBar(const SnackBar(content: Text('Backup copiado')));
            },
            child: const Text('Copiar'),
          ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _importar(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool temCalculoAtual = ref.read(profileProvider) is ProfileReady;
    final TextEditingController controller = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (temCalculoAtual) ...<Widget>[
              const Text('Isso substitui seu cálculo atual.'),
              const SizedBox(height: Space.x3),
            ],
            TextField(
              controller: controller,
              maxLines: 6,
              decoration:
                  const InputDecoration(hintText: 'Cole aqui o texto do seu backup'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Restaurar')),
        ],
      ),
    );
    final String texto = controller.text;
    controller.dispose();
    if (ok != true) return;
    try {
      await ref.read(backupServiceProvider).importJson(texto);
      ref.invalidate(profileProvider);
      ref.invalidate(reservaHistoryProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Backup restaurado')));
    } on FormatException catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Não consegui ler esse backup.')));
    }
  }

  Future<void> _apagar(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content:
            const Text('Isso remove seu cálculo e seu histórico de reservas do aparelho.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Guarda em memória pro Desfazer (substitui a 2ª confirmação com elegância).
    final ProfileState antigo = ref.read(profileProvider);
    final List<ReservaEntry> historicoAntigo = ref.read(reservaHistoryProvider);

    Haptics.commit();
    await ref.read(profileProvider.notifier).clear();
    await ref.read(reservaHistoryProvider.notifier).clear();

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Dados apagados'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              if (antigo is ProfileReady) {
                await ref.read(profileProvider.notifier).save(antigo.perfil);
              }
              for (final ReservaEntry e in historicoAntigo.reversed) {
                await ref.read(reservaHistoryProvider.notifier).restore(e);
              }
            },
          ),
        ),
      );
  }
}
