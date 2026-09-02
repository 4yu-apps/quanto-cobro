import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/model/proposta.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/money_field.dart';
import 'proposta_flow.dart';
import 'proposta_preview_screen.dart';
import '../../core/ui/breakpoints.dart';
import '../../core/ui/secao_titulo.dart';

/// O formulário da proposta (07 §A.3): curto, com tudo que dá já preenchido.
/// Sete campos, três deles opcionais — a pessoa acabou de validar um preço e
/// quer mandar antes de o cliente esfriar, não preencher um cadastro.
class PropostaScreen extends ConsumerStatefulWidget {
  const PropostaScreen({super.key, required this.args});

  final PropostaArgs args;

  @override
  ConsumerState<PropostaScreen> createState() => _PropostaScreenState();
}

class _PropostaScreenState extends ConsumerState<PropostaScreen> {
  final TextEditingController _servico = TextEditingController();
  final TextEditingController _descricao = TextEditingController();
  final TextEditingController _valor = TextEditingController();
  final TextEditingController _prazoDias = TextEditingController();
  bool _prazoUteis = true;
  final Set<String> _meios = <String>{'PIX'};
  String _condicao = Proposta.kCondicoes.first;
  final TextEditingController _pagamentoExtra = TextEditingController();
  final TextEditingController _cliente = TextEditingController();
  final TextEditingController _observacoes = TextEditingController();

  int _validadeDias = 7;
  bool _mostrarHoras = false;
  String? _erroServico;

  @override
  void initState() {
    super.initState();
    final Proposta p = widget.args.inicial;
    _servico.text = p.servico;
    _descricao.text = p.descricao;
    _valor.text = moneyFieldText(p.valor);
    final (int? dias, bool uteis) = Proposta.prazoParse(p.prazo);
    _prazoDias.text = dias?.toString() ?? '';
    _prazoUteis = uteis;
    final ({List<String> meios, String condicao, String extra}) fp =
        Proposta.formaPagamentoParse(p.formaPagamento);
    _meios
      ..clear()
      ..addAll(
        fp.meios.isEmpty && fp.extra.isEmpty ? <String>['PIX'] : fp.meios,
      );
    _condicao = fp.condicao;
    _pagamentoExtra.text = fp.extra;
    _cliente.text = p.cliente;
    _observacoes.text = p.observacoes;
    _validadeDias = p.validadeDias;
    _mostrarHoras = p.mostrarHoras;
  }

  @override
  void dispose() {
    _servico.dispose();
    _descricao.dispose();
    _valor.dispose();
    _prazoDias.dispose();
    _pagamentoExtra.dispose();
    _cliente.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Proposta get _proposta => widget.args.inicial.copyWith(
    servico: _servico.text.trim(),
    descricao: _descricao.text.trim(),
    valor: _digits(_valor.text).toDouble(),
    prazo: _digits(_prazoDias.text) > 0
        ? Proposta.prazoDe(_digits(_prazoDias.text), uteis: _prazoUteis)
        : '',
    validadeDias: _validadeDias,
    formaPagamento: Proposta.formaPagamentoDe(
      meios: Proposta.kMeios.where(_meios.contains).toList(),
      condicao: _condicao,
      extra: _pagamentoExtra.text,
    ),
    cliente: _cliente.text.trim(),
    observacoes: _observacoes.text.trim(),
    mostrarHoras: _mostrarHoras,
  );

  Future<void> _verComoFica() async {
    if (_servico.text.trim().isEmpty) {
      const String msg =
          'Escreva o que você vai entregar pra eu montar o documento.';
      setState(() => _erroServico = msg);
      announce(context, msg);
      return;
    }
    if (_digits(_valor.text) <= 0) {
      const String msg = 'Falta o valor da proposta.';
      announce(context, msg);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(msg)));
      return;
    }
    Haptics.select();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PropostaPreviewScreen(
          proposta: _proposta,
          trabalhoId: widget.args.trabalhoId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool temHoras =
        (widget.args.inicial.horas ?? 0) > 0 &&
        widget.args.inicial.valorHora != null;

    final Widget prazoDiasField = MoneyField(
      controller: _prazoDias,
      label: 'Dias',
      suffix: 'dias',
      onChanged: (_) => setState(() {}),
    );
    final Widget prazoSegmentado = SegmentedButton<bool>(
      segments: const <ButtonSegment<bool>>[
        ButtonSegment<bool>(value: true, label: Text('úteis')),
        ButtonSegment<bool>(value: false, label: Text('corridos')),
      ],
      selected: <bool>{_prazoUteis},
      onSelectionChanged: (Set<bool> s) {
        Haptics.select();
        setState(() => _prazoUteis = s.first);
      },
    );
    final Widget prazoCampos = MediaQuery.sizeOf(context).width < 360
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              prazoDiasField,
              const SizedBox(height: Space.x3),
              prazoSegmentado,
            ],
          )
        : Row(
            children: <Widget>[
              SizedBox(width: 120, child: prazoDiasField),
              const SizedBox(width: Space.x3),
              Expanded(child: prazoSegmentado),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposta pro cliente'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Minha marca',
            onPressed: () => context.push(Routes.marca),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            TextField(
              controller: _servico,
              autofocus: _servico.text.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'O que você vai entregar',
                hintText:
                    'Ex.: Identidade visual completa: logo, cores e manual de marca',
                errorText: _erroServico,
              ),
              onChanged: (_) {
                if (_erroServico != null) setState(() => _erroServico = null);
              },
            ),
            const SizedBox(height: Space.x4),
            TextField(
              controller: _descricao,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'Detalhes (opcional)',
                hintText:
                    'O que está incluso, quantas revisões, o que não entra',
              ),
            ),
            const SizedBox(height: Space.x4),
            MoneyField(
              controller: _valor,
              label: 'Valor',
              prefix: r'R$ ',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.x4),
            SecaoTitulo('Prazo de entrega', bottom: Space.x2),
            prazoCampos,
            const SizedBox(height: Space.x6),

            SecaoTitulo('Validade da proposta', bottom: Space.x1),
            Text(
              'Depois disso o preço pode mudar. É o que te protege de honrar '
              'orçamento velho.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x3),
            Wrap(
              spacing: Space.x2,
              children: <Widget>[
                for (final int dias in <int>[7, 15, 30])
                  ChoiceChip(
                    label: Text('$dias dias'),
                    selected: _validadeDias == dias,
                    backgroundColor: cs.surfaceContainerLow,
                    selectedColor: cs.secondaryContainer,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: _validadeDias == dias
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant,
                    ),
                    side: _validadeDias == dias
                        ? BorderSide(color: cs.primary, width: 1.5)
                        : BorderSide(color: cs.outlineVariant),
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _validadeDias = dias);
                    },
                  ),
              ],
            ),
            const SizedBox(height: Space.x6),

            SecaoTitulo('Forma de pagamento', bottom: Space.x1),
            Text(
              'O sinal é padrão de mercado, e te protege.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x3),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: <Widget>[
                for (final String m in Proposta.kMeios)
                  FilterChip(
                    label: Text(m),
                    selected: _meios.contains(m),
                    backgroundColor: cs.surfaceContainerLow,
                    selectedColor: cs.secondaryContainer,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: _meios.contains(m)
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant,
                    ),
                    side: _meios.contains(m)
                        ? BorderSide(color: cs.primary, width: 1.5)
                        : BorderSide(color: cs.outlineVariant),
                    onSelected: (bool v) {
                      Haptics.select();
                      setState(() => v ? _meios.add(m) : _meios.remove(m));
                    },
                  ),
              ],
            ),
            const SizedBox(height: Space.x3),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: <Widget>[
                for (final String c in Proposta.kCondicoes)
                  ChoiceChip(
                    label: Text(c),
                    selected: _condicao == c,
                    backgroundColor: cs.surfaceContainerLow,
                    selectedColor: cs.secondaryContainer,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: _condicao == c
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant,
                    ),
                    side: _condicao == c
                        ? BorderSide(color: cs.primary, width: 1.5)
                        : BorderSide(color: cs.outlineVariant),
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _condicao = c);
                    },
                  ),
              ],
            ),
            const SizedBox(height: Space.x3),
            TextField(
              controller: _pagamentoExtra,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Outra condição (opcional)',
                hintText: 'Ex.: cartão em até 3x',
              ),
            ),
            const SizedBox(height: Space.x4),
            TextField(
              controller: _cliente,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Para o cliente (opcional)',
                hintText: 'Nome de quem vai receber',
              ),
            ),
            const SizedBox(height: Space.x4),
            TextField(
              controller: _observacoes,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
            ),

            if (temHoras) ...<Widget>[
              const SizedBox(height: Space.x4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _mostrarHoras,
                onChanged: (bool v) {
                  Haptics.select();
                  setState(() => _mostrarHoras = v);
                },
                title: const Text('Mostrar as horas no orçamento'),
                // Desligado por default (07 §A.6): cliente que vê "40h × R$ 92"
                // ancora na hora e pechincha a hora, não o trabalho.
                subtitle: Text(
                  'Desligado, o cliente vê o preço do trabalho, não o preço da '
                  'sua hora.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            const SizedBox(height: Space.x8),
            FilledButton.icon(
              onPressed: _verComoFica,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver como fica'),
            ),
            const SizedBox(height: Space.x2),
            Text(
              'Você vê o documento pronto antes de mandar.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x4),
          ],
        ),
      ),
    );
  }
}
