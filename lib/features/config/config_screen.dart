import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/routes.dart';
import '../../core/config/app_config.dart';
import '../../core/data/area_repository.dart';
import '../../core/model/marca.dart';
import '../../core/model/regime.dart';
import '../../core/model/area.dart';
import '../../core/model/trabalho.dart';
import '../../core/model/entrada.dart';
import '../../core/lembrete/lembrete.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/pro_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/pro_selo.dart';
import '../../core/ui/text_scale.dart';
import '../../core/ui/breakpoints.dart';
import '../../core/ui/secao_titulo.dart';

enum _ImportChoice { arquivo, colar }

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
    final bool reduzirTransp = ref.watch(reduceTransparencyProvider);
    final double textScale = ref.watch(textScaleProvider);
    final Marca marca = ref.watch(marcaProvider);
    final AreasData areas = ref.watch(areasProvider);
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final ProColors pc = theme.extension<ProColors>()!;

    return Scaffold(
      // A aba se chama "Ajustes"; a tela se anunciava "Configurações". Quem
      // navega por fala confere o nome pra saber que chegou no lugar certo
      // (WCAG 3.2.4) — dois nomes pro mesmo destino quebram essa conferência.
      appBar: AppBar(title: const Text('Ajustes')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            _secao(context, 'Aparência'),
            SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Escuro'),
                  icon: Icon(Icons.dark_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto),
                ),
              ],
              selected: <ThemeMode>{mode},
              onSelectionChanged: (Set<ThemeMode> s) {
                Haptics.select();
                ref.read(themeModeProvider.notifier).set(s.first);
              },
            ),
            const SizedBox(height: Space.x3),
            Card(
              color: theme.colorScheme.surfaceContainer,
              child: SwitchListTile(
                value: reduzirTransp,
                onChanged: (bool v) {
                  Haptics.select();
                  ref.read(reduceTransparencyProvider.notifier).set(v);
                },
                title: const Text('Reduzir transparência'),
                subtitle: const Text(
                  'Deixa a barra de navegação sólida (melhor em aparelhos mais simples).',
                ),
              ),
            ),
            const SizedBox(height: Space.x3),
            Card(
              color: theme.colorScheme.surfaceContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.x4,
                      Space.x4,
                      Space.x4,
                      Space.x2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Tamanho do texto',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: Space.x2),
                        Text('Prévia: R\$ 1.234/hora', style: AppType.valueMd),
                      ],
                    ),
                  ),
                  RadioGroup<double>(
                    groupValue: textScale,
                    onChanged: (double? v) {
                      if (v == null) return;
                      final TextScaleLevel level = kTextScaleLevels.firstWhere(
                        (TextScaleLevel l) => l.value == v,
                      );
                      Haptics.select();
                      ref.read(textScaleProvider.notifier).set(v);
                      announce(context, 'Tamanho da fonte: ${level.label}');
                    },
                    child: Column(
                      children: <Widget>[
                        for (final TextScaleLevel level in kTextScaleLevels)
                          RadioListTile<double>(
                            value: level.value,
                            title: Text(level.label),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.x4,
                      0,
                      Space.x4,
                      Space.x4,
                    ),
                    child: Text(
                      'Isto ajusta sobre o tamanho de fonte do seu celular.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.x6),

            // Trabalhos e Histórico agora são ABAS (nav bar) — não duplicar aqui.
            _secao(context, 'Pro'),
            Card(
              color: theme.colorScheme.surfaceContainer,
              child: ListTile(
                // A faísca roxa é o convite inteiro — sem badge "novo!" nem CTA
                // gritado. Num app de decisão de preço o convite chama pela cor,
                // não pelo volume. Pro ativo: a mesma pílula da home vira uma
                // micro-recompensa cada vez que se abre Ajustes.
                leading: Icon(
                  isPro ? Icons.workspace_premium : Icons.auto_awesome,
                  color: pc.pro,
                ),
                title: Text(isPro ? 'Pro ativo' : 'Conhecer o Pro'),
                subtitle: isPro
                    ? null
                    : const Text('Recursos extras, sem anúncios'),
                trailing: isPro
                    ? const ProSelo(animar: false)
                    : const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.pro),
              ),
            ),
            const SizedBox(height: Space.x6),

            _secao(context, 'Gestão'),
            Card(
              color: theme.colorScheme.surfaceContainer,
              child: Column(
                children: <Widget>[
                  // O regime é da PESSOA, e é daqui que ele se ajusta: duas
                  // áreas não geram dois DAS pro mesmo CNPJ.
                  ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: const Text('Meu regime'),
                    subtitle: Text(
                      '${Regime.of(ref.watch(regimeProvider)).label}: define quanto separar de cada pagamento',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _escolherRegime(context, ref),
                  ),
                  const Divider(height: 1, indent: Space.x4),
                  // Lembrete de imposto (F7): notificação real, mensal. Mora
                  // colado no regime porque é o regime que define O QUE lembrar
                  // (DAS dia 20 do MEI, carnê-leão no fim do mês do CPF).
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Lembrete de imposto'),
                    subtitle: Text(
                      ref.watch(lembreteProvider)
                          ? 'Ligado: todo mês, dia ${planoLembrete(ref.watch(regimeProvider)).dia}, um aviso pra separar'
                          : 'Um aviso mensal pra não esquecer de separar o imposto',
                    ),
                    value: ref.watch(lembreteProvider),
                    onChanged: (bool v) => _aplicarLembrete(context, ref, v),
                  ),
                  const Divider(height: 1, indent: Space.x4),
                  // A marca vive aqui, mas quase ninguém chega por aqui: ela é
                  // pedida inline na 1ª proposta. Este é o lugar de VOLTAR nela.
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Minha marca'),
                    subtitle: Text(
                      marca.pronta
                          ? '${marca.nome}: aparece no topo das suas propostas'
                          : 'Nome, logo e contato que vão nas suas propostas',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.marca),
                  ),
                  const Divider(height: 1, indent: Space.x4),
                  // Os presets de preço saíram do slot de aba (07 §B.2). Aqui é
                  // uma das duas casas novas deles — a outra é o switcher do
                  // chip do herói, no Painel.
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text('Meus preços'),
                    subtitle: Text(
                      areas.areas.length <= 1
                          ? 'O cálculo que define quanto você cobra'
                          : '${areas.areas.length} áreas. A ativa é "${areas.active?.nome ?? ''}"',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.areas),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.x6),

            _secao(context, 'Seus dados'),
            Card(
              color: theme.colorScheme.surfaceContainer,
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.ios_share),
                    title: const Text('Salvar um backup'),
                    subtitle: const Text(
                      'Gera um arquivo com seus cálculos e seu histórico pra você guardar onde quiser.',
                    ),
                    onTap: () => _exportar(context, ref),
                  ),
                  const Divider(height: 1, indent: Space.x4),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Restaurar de um arquivo'),
                    subtitle: const Text(
                      'Escolha o arquivo de backup que você salvou antes.',
                    ),
                    onTap: () => _importar(context, ref),
                  ),
                  const Divider(height: 1, indent: Space.x4),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Apagar meus dados',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () => _apagar(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.x6),

            _secao(context, 'Privacidade'),
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
                      'Envia só métricas anônimas de uso e estabilidade. Nunca sua renda.',
                    ),
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

            _secao(context, 'Sobre'),
            Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: d.brand4yu,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Space.x2),
                Text(
                  'by ${AppConfig.parentBrand}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: d.brand4yu,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x1),
            Text(
              '${AppConfig.appName} · versão 0.5.0 · ${AppConfig.contactEmail}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// As seções de Ajustes são a lista mais longa do app — e é justamente numa
  /// lista longa que a navegação por cabeçalhos deixa de ser conforto e vira a
  /// diferença entre achar o backup e desistir.
  Widget _secao(BuildContext context, String titulo) => SecaoTitulo(titulo);

  /// Exporta = grava um arquivo .json e abre o share sheet (Drive, Arquivos,
  /// WhatsApp pra si mesmo). Fim do JSON cru no clipboard.
  Future<void> _exportar(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? json;
    try {
      json = ref.read(backupServiceProvider).exportJson();
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não consegui ler seus dados pra exportar.'),
          ),
        );
      return;
    }
    if (json == null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Ainda não há um cálculo pra exportar.'),
          ),
        );
      return;
    }
    try {
      final DateTime now = DateTime.now();
      final String dia =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/quanto-cobro-backup-$dia.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'application/json')],
          subject: 'Backup Quanto Cobro',
          text: 'Backup do Quanto Cobro? Guarde num lugar seguro.',
        ),
      );
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Backup gerado. Guarde num lugar seguro.'),
          ),
        );
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não consegui gerar o arquivo de backup.'),
          ),
        );
    }
  }

  /// Importa. Caminho principal = escolher o arquivo .json; fallback = colar
  /// texto (troca entre aparelhos por WhatsApp/e-mail).
  Future<void> _importar(BuildContext context, WidgetRef ref) async {
    final bool temCalculoAtual = ref.read(areaAtivaProvider) is AreaPronta;
    final _ImportChoice? choice = await showModalBottomSheet<_ImportChoice>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheet) => SafeArea(
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
                    'Restaurar backup',
                    style: Theme.of(sheet).textTheme.titleLarge,
                  ),
                  if (temCalculoAtual) ...<Widget>[
                    const SizedBox(height: Space.x2),
                    Text(
                      'Isso substitui seu cálculo atual.',
                      style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(sheet).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Escolher arquivo'),
              subtitle: const Text('O arquivo .json que você salvou antes'),
              onTap: () => Navigator.pop(sheet, _ImportChoice.arquivo),
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('Prefiro colar o texto'),
              onTap: () => Navigator.pop(sheet, _ImportChoice.colar),
            ),
            const SizedBox(height: Space.x2),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == _ImportChoice.arquivo) {
      await _importarArquivo(context, ref);
    } else {
      await _importarColando(context, ref);
    }
  }

  Future<void> _importarArquivo(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final PlatformFile pf = picked.files.first;
    String? texto;
    if (pf.bytes != null) {
      texto = utf8.decode(pf.bytes!, allowMalformed: true);
    } else if (pf.path != null) {
      texto = await File(pf.path!).readAsString();
    }
    if (texto == null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Não consegui abrir esse arquivo.')),
        );
      return;
    }
    await _aplicarImport(messenger, ref, texto, arquivo: true);
  }

  Future<void> _importarColando(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController controller = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Colar backup em texto'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Cole aqui o texto do seu backup',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    final String texto = controller.text;
    Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);
    if (ok != true) return;
    await _aplicarImport(messenger, ref, texto, arquivo: false);
  }

  Future<void> _aplicarImport(
    ScaffoldMessengerState messenger,
    WidgetRef ref,
    String texto, {
    required bool arquivo,
  }) async {
    try {
      await ref.read(backupServiceProvider).importJson(texto);
      ref.invalidate(areasProvider);
      ref.invalidate(entradasProvider);
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
        ..showSnackBar(
          SnackBar(
            content: Text(
              arquivo
                  ? 'Não consegui ler esse arquivo. Confere se é o backup certo (.json).'
                  : 'Não consegui ler esse backup. Confere se o texto foi colado inteiro.',
            ),
          ),
        );
    }
  }

  Future<void> _apagar(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content: const Text(
          'Isso remove seus cálculos, seu histórico de reservas, seus projetos '
          'e a sua marca do aparelho.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(c).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Guarda em memória pro Desfazer (substitui a 2ª confirmação com elegância).
    final AreasData antigos = ref.read(areasProvider);
    final List<Entrada> historicoAntigo = ref.read(entradasProvider);
    final List<Trabalho> projetosAntigos = ref.read(trabalhosProvider);
    final Marca marcaAntiga = ref.read(marcaProvider);
    // Captura os notifiers ANTES do snackbar: o Desfazer pode ser tocado depois
    // da tela morrer, e ref pós-dispose crasha.
    final AreasNotifier profilesN = ref.read(areasProvider.notifier);
    final EntradasNotifier historyN = ref.read(entradasProvider.notifier);
    final TrabalhosNotifier projetosN = ref.read(trabalhosProvider.notifier);
    final MarcaNotifier marcaN = ref.read(marcaProvider.notifier);

    Haptics.commit();
    await profilesN.clearAll();
    await historyN.clear();
    await projetosN.clearAll();
    await marcaN.save(const Marca());

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Dados apagados'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              for (final Area p in antigos.areas) {
                await profilesN.saveAndActivate(p);
              }
              if (antigos.activeId != null) {
                await profilesN.select(antigos.activeId!);
              }
              for (final Entrada e in historicoAntigo.reversed) {
                await historyN.restore(e);
              }
              for (final Trabalho p in projetosAntigos) {
                await projetosN.save(p);
              }
              if (!marcaAntiga.vazia) await marcaN.save(marcaAntiga);
            },
          ),
        ),
      );
  }

  /// Trocar o regime é raro e pesa: uma folha com as opções e a explicação de
  /// cada uma, no mesmo texto que a calculadora usa.
  /// Liga/desliga o lembrete. Ligar PEDE a permissão de notificação primeiro:
  /// negada, o toggle não sobe e a pessoa é orientada — degradar com elegância,
  /// nunca um switch que finge estar ligado sem poder notificar.
  Future<void> _aplicarLembrete(
    BuildContext context,
    WidgetRef ref,
    bool ligar,
  ) async {
    final Lembretes lembretes = ref.read(lembretesProvider);
    if (ligar) {
      final bool ok = await lembretes.pedirPermissao();
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Pra receber o lembrete, ative as notificações do app nas '
                  'configurações do sistema.',
                ),
              ),
            );
        }
        return; // não liga: sem permissão, o switch não sobe
      }
      await lembretes.agendar(ref.read(regimeProvider));
      await ref.read(lembreteProvider.notifier).set(true);
      if (context.mounted) announce(context, 'Lembrete de imposto ligado.');
    } else {
      await lembretes.cancelar();
      await ref.read(lembreteProvider.notifier).set(false);
      if (context.mounted) announce(context, 'Lembrete de imposto desligado.');
    }
  }

  Future<void> _escolherRegime(BuildContext context, WidgetRef ref) async {
    final RegimeId atual = ref.read(regimeProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheet) => SafeArea(
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
              child: Text(
                'Como você trabalha?',
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
            ),
            RadioGroup<RegimeId>(
              groupValue: atual,
              onChanged: (RegimeId? v) {
                if (v == null) return;
                Haptics.select();
                ref.read(regimeProvider.notifier).set(v);
                Navigator.pop(sheet);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final Regime r in Regime.all.values)
                    RadioListTile<RegimeId>(
                      value: r.id,
                      title: Text(r.label),
                      subtitle: Text(r.sub),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.x2),
          ],
        ),
      ),
    );
  }
}
