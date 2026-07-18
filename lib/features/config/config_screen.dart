import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';

/// Configurações: tema, backup (sem nuvem), apagar dados, telemetria opt-in,
/// Pro, legal e Sobre. Controle e confiança — o usuário manda nos próprios dados.
class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final bool isPro = ref.watch(proProvider);
    final bool telemetria = ref.watch(telemetryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Aparência', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark, label: Text('Escuro'), icon: Icon(Icons.dark_mode)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.brightness_auto)),
            ],
            selected: <ThemeMode>{mode},
            onSelectionChanged: (Set<ThemeMode> s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const Divider(height: 32),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(isPro ? Icons.workspace_premium : Icons.workspace_premium_outlined),
            title: Text(isPro ? 'Pro ativo' : 'Conhecer o Pro'),
            trailing: isPro ? const Icon(Icons.check) : const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.pro),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.switch_account_outlined),
            title: const Text('Perfis'),
            subtitle: const Text('Cenários de preço por tipo de cliente'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.perfis),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: const Text('Histórico de reservas'),
            subtitle: const Text('Quanto você já guardou pro Leão'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.historico),
          ),

          const Divider(height: 32),
          Text('Seus dados', style: Theme.of(context).textTheme.titleSmall),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.ios_share),
            title: const Text('Exportar dados (backup)'),
            subtitle: const Text('Copie e guarde onde quiser. Sem nuvem, sem conta.'),
            onTap: () => _exportar(context, ref),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download),
            title: const Text('Restaurar backup'),
            onTap: () => _importar(context, ref),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text('Apagar meus dados',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => _apagar(context, ref),
          ),

          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: telemetria,
            onChanged: (bool v) => ref.read(telemetryProvider.notifier).set(v),
            title: const Text('Ajudar a melhorar o app'),
            subtitle: const Text('Envia só métricas anônimas de uso e estabilidade. Nunca sua renda.'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Privacidade e Termos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.legal),
          ),

          const Divider(height: 32),
          Text('Sobre', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text('${AppConfig.appName} · versão 0.1.0'),
          Text('by ${AppConfig.parentBrand} · ${AppConfig.contactEmail}',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _exportar(BuildContext context, WidgetRef ref) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? json = ref.read(backupServiceProvider).exportJson();
    if (json == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Ainda não há um cálculo pra exportar.')));
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
              messenger.showSnackBar(const SnackBar(content: Text('Backup copiado')));
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
    final TextEditingController controller = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Cole aqui o texto do seu backup'),
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
      messenger.showSnackBar(const SnackBar(content: Text('Backup restaurado')));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Não consegui ler esse backup.')));
    }
  }

  Future<void> _apagar(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content: const Text('Isso remove seu cálculo do aparelho. Não dá pra desfazer.'),
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
    if (ok == true) {
      await ref.read(profileProvider.notifier).clear();
      messenger.showSnackBar(const SnackBar(content: Text('Dados apagados')));
    }
  }
}
