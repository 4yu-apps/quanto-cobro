import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/common/datas.dart';
import '../../core/data/area_repository.dart';
import '../../core/model/area.dart';
import '../../core/model/trabalho.dart';
import '../../core/providers.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/money_field.dart';
import '../../core/ui/breakpoints.dart';
import '../../core/ui/secao_titulo.dart';

/// Cadastrar/editar um trabalho — **três campos**, e dois deles opcionais.
///
/// Eram oito (status, recorrência, intervalo, próximo recebimento, anotações,
/// quem paga…). Sete perguntas de gestão feitas a quem só queria dizer que o
/// Augusto pagou. No caminho principal este formulário nem aparece: o trabalho
/// nasce do nome digitado na primeira entrada.
class TrabalhoFormScreen extends ConsumerStatefulWidget {
  const TrabalhoFormScreen({super.key, this.trabalhoId});

  /// Id de um trabalho existente (edição). Null = criar.
  final String? trabalhoId;

  @override
  ConsumerState<TrabalhoFormScreen> createState() => _TrabalhoFormScreenState();
}

class _TrabalhoFormScreenState extends ConsumerState<TrabalhoFormScreen> {
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _valor = TextEditingController();
  final TextEditingController _observacoes = TextEditingController();

  String? _areaId;
  String? _erroNome;
  Trabalho? _original;
  DateTime? _entregaEm;

  @override
  void initState() {
    super.initState();
    _original = ref.read(trabalhosProvider.notifier).byId(widget.trabalhoId);
    final Trabalho? t = _original;
    if (t != null) {
      _nome.text = t.nome;
      _valor.text = moneyFieldText(t.valorCombinado);
      _observacoes.text = t.observacoes ?? '';
      _areaId = t.areaId;
      _entregaEm = t.entregaEm;
    }
    _areaId ??= ref.read(areasProvider).activeId;
  }

  @override
  void dispose() {
    _nome.dispose();
    _valor.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool get _editando => _original != null;

  Future<void> _salvar() async {
    final String nome = _nome.text.trim();
    if (nome.isEmpty) {
      const String msg = 'Dá um nome pro trabalho pra eu continuar.';
      setState(() => _erroNome = msg);
      announce(context, msg);
      return;
    }
    Haptics.commit();

    final Trabalho trabalho = Trabalho(
      id: _original?.id ?? 'tr_${DateTime.now().microsecondsSinceEpoch}',
      areaId: _areaId ?? '',
      nome: nome,
      criadoEm: _original?.criadoEm ?? DateTime.now(),
      valorCombinado: _digits(_valor.text).toDouble(),
      encerrado: _original?.encerrado ?? false,
      observacoes: _observacoes.text.trim().isEmpty
          ? null
          : _observacoes.text.trim(),
      entregaEm: _entregaEm,
    );

    await ref.read(trabalhosProvider.notifier).save(trabalho);
    if (!mounted) return;
    Navigator.of(context).pop(trabalho.id);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AreasData areas = ref.watch(areasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar trabalho' : 'Novo trabalho'),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            TextField(
              controller: _nome,
              autofocus: !_editando,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nome do trabalho',
                hintText: 'Ex.: Augusto, Loja da Ana, Site da Padaria',
                errorText: _erroNome,
              ),
              onChanged: (_) {
                if (_erroNome != null) setState(() => _erroNome = null);
              },
            ),
            const SizedBox(height: Space.x4),
            MoneyField(
              controller: _valor,
              label: 'Valor combinado (opcional)',
              prefix: r'R$ ',
              helper: 'Serve só pra já vir preenchido quando você registrar.',
            ),

            const SizedBox(height: Space.x4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Prazo de entrega (opcional)'),
              subtitle: Text(
                _entregaEm == null
                    ? 'O app conta os dias pra você.'
                    : dataPorExtenso(_entregaEm!),
              ),
              trailing: _entregaEm == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      tooltip: 'Tirar o prazo',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _entregaEm = null),
                    ),
              onTap: () async {
                final DateTime agora = DateTime.now();
                final DateTime primeiro = DateTime(agora.year - 1);
                final DateTime ultimo = DateTime(agora.year + 3);
                // O prazo salvo pode ter envelhecido pra fora dessa janela (um
                // trabalho antigo, editado hoje). O calendário some, mas o
                // `initialDate` do showDatePicker EXIGE estar dentro do
                // intervalo — sem o clamp, abrir editar derruba o app.
                final DateTime sugerido =
                    _entregaEm ?? agora.add(const Duration(days: 15));
                final DateTime inicial = sugerido.isBefore(primeiro)
                    ? primeiro
                    : (sugerido.isAfter(ultimo) ? ultimo : sugerido);
                final DateTime? d = await showDatePicker(
                  context: context,
                  initialDate: inicial,
                  firstDate: primeiro,
                  lastDate: ultimo,
                  locale: const Locale('pt', 'BR'),
                  helpText: 'Quando você combinou entregar?',
                );
                if (d != null) setState(() => _entregaEm = d);
              },
            ),

            // O seletor de área só existe pra quem TEM mais de uma. Pra todo o
            // resto, a palavra "área" nunca aparece no app.
            if (areas.hierarquiaVisivel) ...<Widget>[
              const SizedBox(height: Space.x6),
              SecaoTitulo('Área', bottom: Space.x2),
              Wrap(
                spacing: Space.x2,
                runSpacing: Space.x2,
                children: <Widget>[
                  for (final Area a in areas.areas)
                    ChoiceChip(
                      label: Text(a.nome),
                      selected: _areaId == a.id,
                      backgroundColor: cs.surfaceContainerLow,
                      selectedColor: cs.secondaryContainer,
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: _areaId == a.id
                            ? cs.onSecondaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      side: _areaId == a.id
                          ? BorderSide(color: cs.primary, width: 1.5)
                          : BorderSide(color: cs.outlineVariant),
                      onSelected: (_) {
                        Haptics.select();
                        setState(() => _areaId = a.id);
                      },
                    ),
                ],
              ),
            ],

            const SizedBox(height: Space.x6),
            TextField(
              controller: _observacoes,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Anotações (opcional)',
                hintText: 'O que só você precisa lembrar',
              ),
            ),
            const SizedBox(height: Space.x8),
            FilledButton(
              onPressed: _salvar,
              child: Text(_editando ? 'Salvar' : 'Criar trabalho'),
            ),
            const SizedBox(height: Space.x4),
          ],
        ),
      ),
    );
  }
}
