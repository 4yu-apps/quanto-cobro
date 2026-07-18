import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final TextEditingController controller;
  final String label;
  final String? prefix;
  final String? suffix;
  final String? errorText;
  final String? helper;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      autofocus: autofocus,
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
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
