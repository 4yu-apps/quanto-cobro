import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_typography.dart';
import 'a11y.dart';

/// Campo de valor monetário grande (DS §6.5). Teclado numérico, valor em Sora
/// (`value.display`, tabular), microcopy de ajuda/erro humana.
///
/// Acessibilidade: quando o `errorText` nasce, ele é ANUNCIADO em leitor de
/// tela (erro visível ≠ erro percebido) — centralizado aqui pra valer em toda
/// tela de uma vez.
class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.prefix,
    this.suffix,
    this.errorText,
    this.helper,
    this.onChanged,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? prefix;
  final String? suffix;
  final String? errorText;
  final String? helper;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  @override
  void didUpdateWidget(MoneyField old) {
    super.didUpdateWidget(old);
    final String? erro = widget.errorText;
    if (erro != null && erro != old.errorText) {
      announce(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.number,
      autofocus: widget.autofocus,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        if (widget.prefix != null) _MilharFormatter(),
      ],
      style: AppType.valueDisplay.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: widget.prefix,
        suffixText: widget.suffix,
        errorText: widget.errorText,
        helperText: widget.helper,
        helperMaxLines: 3,
      ),
    );
  }
}

/// Texto inicial de um [MoneyField] preenchido por código (2000 -> "2.000").
///
/// Existe porque `controller.text = ...` NÃO passa pelos `inputFormatters`:
/// preencher na mão deixaria o campo mostrando "2000" enquanto digitar mostra
/// "2.000" — a mesma tela com duas caras, exatamente no número que a pessoa
/// veio conferir. Todo pré-preenchimento (Reserva de um projeto, edição de
/// projeto, valor da proposta) passa por aqui.
String moneyFieldText(num valor) =>
    valor <= 0 ? '' : _MilharFormatter._fmt.format(valor.round());

/// Separador de milhar ao vivo (12000 -> 12.000): conferir o valor digitado é
/// exatamente a ansiedade que o app existe pra tirar. Preserva a POSIÇÃO do
/// cursor (contando dígitos antes dele) — editar no meio do número funciona.
class _MilharFormatter extends TextInputFormatter {
  static final NumberFormat _fmt = NumberFormat.decimalPattern('pt_BR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final String formatted = _fmt.format(int.parse(digits));

    // Quantos dígitos existem antes do cursor no texto novo cru:
    final int rawOffset = newValue.selection.baseOffset.clamp(
      0,
      newValue.text.length,
    );
    int digitsBefore = 0;
    for (int i = 0; i < rawOffset; i++) {
      if (RegExp(r'[0-9]').hasMatch(newValue.text[i])) digitsBefore++;
    }
    // Reposiciona após o mesmo número de dígitos no texto formatado:
    int offset = formatted.length;
    int seen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        seen++;
        if (seen == digitsBefore) {
          offset = i + 1;
          break;
        }
      }
      if (digitsBefore == 0) {
        offset = 0;
        break;
      }
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
