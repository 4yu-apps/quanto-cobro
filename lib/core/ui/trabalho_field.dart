import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/money.dart';
import '../data/entrada_repository.dart';
import '../data/trabalho_repository.dart';
import '../model/entrada.dart';
import '../model/trabalho.dart';
import '../providers.dart';
import '../theme/tokens.dart';

/// **De quem?** — o campo que deixa ESCOLHER um trabalho existente em vez de
/// redigitar no escuro. É a peça reaproveitada que amarra os fluxos: a mesma
/// pergunta na entrada avulsa, no simulador (salvar orçamento) e no histórico
/// (ligar depois).
///
/// Comportamento:
/// - Sem trabalhos ainda → é um campo de texto comum (zero fricção pro
///   iniciante — esse caso não pode ganhar peso nenhum).
/// - Com trabalhos → autocompletar: digitar filtra os que existem, e cada opção
///   mostra "já recebeu R$ X". Escolher um seta o trabalho direto (mata o risco
///   de criar dois "Augusto"). Um nome inédito continua criando na hora do
///   salvar, pelo `onTrabalhoSelected(null)` que avisa o dono que o texto é novo.
class TrabalhoField extends ConsumerStatefulWidget {
  const TrabalhoField({
    super.key,
    required this.controller,
    required this.areaId,
    required this.onTrabalhoSelected,
    this.labelText = 'De quem? (opcional)',
    this.hintText,
    this.helperText,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;

  /// Área a que os trabalhos pertencem — o filtro. `null`/'' lista todos.
  final String areaId;

  /// Chamado com o trabalho ao escolher um existente; com `null` quando o texto
  /// muda (o dono passa a saber que o conteúdo é um nome novo/livre).
  final ValueChanged<Trabalho?> onTrabalhoSelected;

  final String labelText;
  final String? hintText;
  final String? helperText;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  ConsumerState<TrabalhoField> createState() => _TrabalhoFieldState();
}

class _TrabalhoFieldState extends ConsumerState<TrabalhoField> {
  // RawAutocomplete exige controller E focusNode juntos; se o chamador não dá
  // um focusNode, este é o dono dele.
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Trabalho> todos = ref.watch(trabalhosProvider);
    final List<Entrada> entradas = ref.watch(entradasProvider);
    final Map<String, double> recebido = recebidoPorTrabalho(entradas);
    final Map<String, DateTime> ultima = ultimaEntradaPorTrabalho(entradas);

    // Só os desta área e não encerrados; o encerrado não é candidato a novo
    // pagamento. Ordenados por quem pagou por último.
    final List<Trabalho> candidatos = ordenarTrabalhos(
      todos
          .where(
            (Trabalho t) =>
                !t.encerrado &&
                (widget.areaId.isEmpty || t.areaId == widget.areaId),
          )
          .toList(),
      ultima,
    );

    // Sem trabalhos: campo de texto puro. Nada de overlay vazio no iniciante.
    if (candidatos.isEmpty) {
      return TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
        ),
        onChanged: (_) => widget.onTrabalhoSelected(null),
      );
    }

    return RawAutocomplete<Trabalho>(
      textEditingController: widget.controller,
      focusNode: _focus,
      displayStringForOption: (Trabalho t) => t.nome,
      optionsBuilder: (TextEditingValue value) {
        final String q = value.text.trim().toLowerCase();
        if (q.isEmpty) return candidatos;
        return candidatos.where(
          (Trabalho t) => t.nome.toLowerCase().contains(q),
        );
      },
      onSelected: (Trabalho t) => widget.onTrabalhoSelected(t),
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController controller,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: widget.autofocus,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText ?? 'Escolha um trabalho ou digite um novo',
                helperText: widget.helperText,
                suffixIcon: const Icon(Icons.expand_more),
              ),
              onChanged: (_) => widget.onTrabalhoSelected(null),
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
      optionsViewBuilder:
          (
            BuildContext context,
            ValueChanged<Trabalho> onSelected,
            Iterable<Trabalho> options,
          ) {
            final ThemeData theme = Theme.of(context);
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: const BorderRadius.all(Radii.md),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 260,
                    maxWidth: 560,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final Trabalho t in options)
                        ListTile(
                          dense: true,
                          title: Text(t.nome),
                          subtitle: Text(
                            (recebido[t.id] ?? 0) > 0
                                ? 'já recebeu ${moneyBRL(recebido[t.id]!)}'
                                : 'ainda sem entradas',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () => onSelected(t),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }
}

/// Abre uma folha "escolher ou criar trabalho" e devolve o trabalho resolvido
/// (existente escolhido, ou criado a partir do nome digitado). `null` = a
/// pessoa saiu sem escolher.
///
/// Usada pelo simulador (salvar orçamento) e pelo histórico (ligar depois). O
/// `valorCombinado` só é gravado quando o trabalho ainda não tinha um — nunca
/// sobrescreve o que a pessoa já combinou.
Future<Trabalho?> escolherOuCriarTrabalho({
  required BuildContext context,
  required WidgetRef ref,
  required String areaId,
  required String titulo,
  String? subtitulo,
  String confirmar = 'Salvar',
  String? hintText,
  double? valorCombinado,
}) {
  final TextEditingController controller = TextEditingController();
  Trabalho? escolhido;

  return showModalBottomSheet<Trabalho>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheet) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          Space.x6,
          Space.x2,
          Space.x6,
          Space.x6 + MediaQuery.of(sheet).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheet) {
            final bool podeSalvar =
                escolhido != null || controller.text.trim().isNotEmpty;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(titulo, style: Theme.of(sheet).textTheme.titleLarge),
                if (subtitulo != null) ...<Widget>[
                  const SizedBox(height: Space.x1),
                  Text(
                    subtitulo,
                    style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(sheet).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: Space.x4),
                TrabalhoField(
                  controller: controller,
                  areaId: areaId,
                  autofocus: true,
                  labelText: 'Que trabalho é esse?',
                  hintText: hintText,
                  onTrabalhoSelected: (Trabalho? t) =>
                      setSheet(() => escolhido = t),
                ),
                const SizedBox(height: Space.x6),
                FilledButton(
                  onPressed: podeSalvar
                      ? () async {
                          Trabalho? resultado = escolhido;
                          if (resultado == null) {
                            final String nome = controller.text.trim();
                            if (nome.isEmpty) return;
                            final TrabalhosNotifier n = ref.read(
                              trabalhosProvider.notifier,
                            );
                            resultado =
                                n.porNome(nome, areaId: areaId) ??
                                await n.criarPorNome(nome, areaId: areaId);
                          }
                          if (valorCombinado != null &&
                              valorCombinado > 0 &&
                              resultado.valorCombinado == 0) {
                            resultado = resultado.copyWith(
                              valorCombinado: valorCombinado,
                            );
                            await ref
                                .read(trabalhosProvider.notifier)
                                .save(resultado);
                          }
                          if (sheet.mounted) {
                            Navigator.pop(sheet, resultado);
                          }
                        }
                      : null,
                  child: Text(confirmar),
                ),
              ],
            );
          },
        ),
      );
    },
  ).whenComplete(
    () => Future<void>.delayed(
      const Duration(milliseconds: 600),
      controller.dispose,
    ),
  );
}
