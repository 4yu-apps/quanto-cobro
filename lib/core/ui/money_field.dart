import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_typography.dart';

/// Campo de valor monetário grande (DS §6.5). Teclado numérico, valor em Sora
/// (`value.display`, tabular), microcopy de ajuda/erro humana.
class MoneyField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      autofocus: autofocus,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        if (prefix != null) _MilharFormatter(),
      ],
      style: AppType.valueDisplay.copyWith(color: Theme.of(context).colorScheme.onSurface),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        errorText: errorText,
        helperText: helper,
        helperMaxLines: 3,
      ),
    );
  }
}

/// Separador de milhar ao vivo (12000 -> 12.000): conferir o valor digitado é
/// exatamente a ansiedade que o app existe pra tirar.
class _MilharFormatter extends TextInputFormatter {
  static final NumberFormat _fmt = NumberFormat.decimalPattern('pt_BR');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final String formatted = _fmt.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
