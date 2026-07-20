import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/area_repository.dart';
import '../../core/model/area.dart';
import '../../core/model/trabalho.dart';
import '../../core/providers.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/money_field.dart';

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
      body: ListView(
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

          // O seletor de área só existe pra quem TEM mais de uma. Pra todo o
          // resto, a palavra "área" nunca aparece no app.
          if (areas.hierarquiaVisivel) ...<Widget>[
            const SizedBox(height: Space.x6),
            Text(
              'ÁREA',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: Space.x2),
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
    );
  }
}
