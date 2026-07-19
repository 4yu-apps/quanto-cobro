import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/common/datas.dart';
import '../../core/model/projeto.dart';
import '../../core/providers.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/money_field.dart';

/// Cadastrar/editar um projeto. O setup é RARO (07 §B.4) — por isso ele pode
/// ser um formulário honesto de uma tela, sem wizard: o que precisa ser rápido
/// é o "Recebi", que acontece toda semana, não isto aqui.
///
/// `draft` chega preenchido quando o projeto nasce de uma proposta (§C).
class ProjetoFormScreen extends ConsumerStatefulWidget {
  const ProjetoFormScreen({super.key, this.projetoId, this.draft});

  /// Id de um projeto existente (edição).
  final String? projetoId;

  /// Rascunho pré-preenchido (nasce de uma proposta) — ainda não salvo.
  final Projeto? draft;

  @override
  ConsumerState<ProjetoFormScreen> createState() => _ProjetoFormScreenState();
}

class _ProjetoFormScreenState extends ConsumerState<ProjetoFormScreen> {
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _cliente = TextEditingController();
  final TextEditingController _valor = TextEditingController();
  final TextEditingController _observacoes = TextEditingController();

  Recorrencia _recorrencia = Recorrencia.avulso;
  int _intervaloMeses = 2;
  ProjetoStatus _status = ProjetoStatus.ativo;
  DateTime? _proximo;
  String? _erroNome;

  Projeto? _original;

  @override
  void initState() {
    super.initState();
    final Projeto? base =
        widget.draft ??
        ref.read(projetosProvider.notifier).byId(widget.projetoId);
    _original = widget.projetoId == null ? null : base;
    if (base == null) return;

    _nome.text = base.nome;
    _cliente.text = base.cliente ?? '';
    _valor.text = moneyFieldText(base.valor);
    _observacoes.text = base.observacoes ?? '';
    _recorrencia = base.recorrencia;
    _intervaloMeses = base.intervaloMeses;
    _status = base.status;
    _proximo = base.proximoRecebimento;
  }

  @override
  void dispose() {
    _nome.dispose();
    _cliente.dispose();
    _valor.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool get _editando => widget.projetoId != null && _original != null;

  Future<void> _escolherData() async {
    final DateTime hoje = DateTime.now();
    final DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: _proximo ?? hoje,
      firstDate: DateTime(hoje.year - 1),
      lastDate: DateTime(hoje.year + 5),
      helpText: 'Próximo recebimento',
      cancelText: 'Cancelar',
      confirmText: 'Escolher',
    );
    if (escolhida == null) return;
    setState(() => _proximo = escolhida);
  }

  Future<void> _salvar() async {
    final String nome = _nome.text.trim();
    if (nome.isEmpty) {
      const String msg = 'Dá um nome pro projeto pra eu continuar.';
      setState(() => _erroNome = msg);
      announce(context, msg);
      return;
    }
    Haptics.commit();

    final Projeto projeto = Projeto(
      id:
          _original?.id ??
          widget.draft?.id ??
          'pj_${DateTime.now().microsecondsSinceEpoch}',
      nome: nome,
      cliente: _cliente.text.trim().isEmpty ? null : _cliente.text.trim(),
      valor: _digits(_valor.text).toDouble(),
      recorrencia: _recorrencia,
      intervaloMeses: _intervaloMeses,
      status: _status,
      criadoEm: _original?.criadoEm ?? widget.draft?.criadoEm ?? DateTime.now(),
      proximoRecebimento: _proximo,
      // O projeto aponta pro preset de preço ATIVO: é dele que sai a % de
      // reserva. O imposto segue sendo por-pessoa, não por-projeto.
      perfilId:
          _original?.perfilId ??
          widget.draft?.perfilId ??
          ref.read(profilesProvider).activeId,
      observacoes: _observacoes.text.trim().isEmpty
          ? null
          : _observacoes.text.trim(),
    );

    await ref.read(projetosProvider.notifier).save(projeto);
    if (!mounted) return;
    Navigator.of(context).pop(projeto.id);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar projeto' : 'Novo projeto'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          TextField(
            controller: _nome,
            autofocus: !_editando,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nome do projeto ou cliente',
              hintText: 'Ex.: Loja da Ana, Site Padaria',
              errorText: _erroNome,
            ),
            onChanged: (_) {
              if (_erroNome != null) setState(() => _erroNome = null);
            },
          ),
          const SizedBox(height: Space.x4),
          MoneyField(
            controller: _valor,
            label: 'Valor combinado',
            prefix: r'R$ ',
            helper: _recorrencia == Recorrencia.avulso
                ? 'O total desse trabalho.'
                : 'Por ciclo — o que entra a cada recebimento.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.x6),

          _rotulo(context, 'DE QUANTO EM QUANTO TEMPO'),
          const SizedBox(height: Space.x2),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: <Widget>[
              for (final Recorrencia r in Recorrencia.values)
                ChoiceChip(
                  label: Text(
                    r == Recorrencia.custom
                        ? 'A cada N meses'
                        : r.label(intervaloMeses: _intervaloMeses),
                  ),
                  selected: _recorrencia == r,
                  backgroundColor: cs.surfaceContainerLow,
                  selectedColor: cs.secondaryContainer,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: _recorrencia == r
                        ? cs.onSecondaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  side: _recorrencia == r
                      ? BorderSide(color: cs.primary, width: 1.5)
                      : BorderSide(color: cs.outlineVariant),
                  onSelected: (_) {
                    Haptics.select();
                    setState(() => _recorrencia = r);
                  },
                ),
            ],
          ),
          if (_recorrencia == Recorrencia.custom) ...<Widget>[
            const SizedBox(height: Space.x3),
            Row(
              children: <Widget>[
                Text(
                  'A cada',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Space.x3),
                // Stepper e não campo livre: são poucos valores plausíveis e o
                // teclado numérico aqui abriria espaço pra "a cada 0 meses".
                IconButton.filledTonal(
                  onPressed: _intervaloMeses > 2
                      ? () {
                          Haptics.select();
                          setState(() => _intervaloMeses--);
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                  tooltip: 'Menos um mês',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                  child: Text(
                    '$_intervaloMeses',
                    style: theme.textTheme.titleLarge,
                    semanticsLabel: '$_intervaloMeses meses',
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _intervaloMeses < 24
                      ? () {
                          Haptics.select();
                          setState(() => _intervaloMeses++);
                        }
                      : null,
                  icon: const Icon(Icons.add),
                  tooltip: 'Mais um mês',
                ),
                const SizedBox(width: Space.x3),
                Text(
                  'meses',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Space.x6),

          _rotulo(context, 'PRÓXIMO RECEBIMENTO'),
          const SizedBox(height: Space.x1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(
              _proximo == null ? 'Sem data marcada' : dataPorExtenso(_proximo!),
            ),
            subtitle: Text(
              _proximo == null
                  ? 'Marque quando esperar o dinheiro — é o que te lembra a tempo.'
                  : 'Toque pra mudar',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            trailing: _proximo == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Tirar a data',
                    onPressed: () => setState(() => _proximo = null),
                  ),
            onTap: _escolherData,
          ),
          const SizedBox(height: Space.x4),

          if (_editando) ...<Widget>[
            _rotulo(context, 'STATUS'),
            const SizedBox(height: Space.x2),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: <Widget>[
                for (final ProjetoStatus s in ProjetoStatus.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _status == s,
                    backgroundColor: cs.surfaceContainerLow,
                    selectedColor: cs.secondaryContainer,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: _status == s
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant,
                    ),
                    side: _status == s
                        ? BorderSide(color: cs.primary, width: 1.5)
                        : BorderSide(color: cs.outlineVariant),
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _status = s);
                    },
                  ),
              ],
            ),
            const SizedBox(height: Space.x6),
          ],

          TextField(
            controller: _cliente,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Quem paga (opcional)',
              hintText: 'Só se for diferente do nome acima',
            ),
          ),
          const SizedBox(height: Space.x4),
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
            child: Text(_editando ? 'Salvar' : 'Criar projeto'),
          ),
          const SizedBox(height: Space.x4),
        ],
      ),
    );
  }

  Widget _rotulo(BuildContext context, String texto) => Text(
    texto,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.5,
    ),
  );
}
