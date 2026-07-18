import 'package:flutter/material.dart';

import 'color_scheme.dart';
import 'divisao_colors.dart';

/// Monta os dois ThemeData a partir do Design System. O ESCURO é o padrão.
abstract final class AppTheme {
  static ThemeData get dark => _build(AppColorSchemes.dark, DivisaoColors.dark);
  static ThemeData get light => _build(AppColorSchemes.light, DivisaoColors.light);

  static ThemeData _build(ColorScheme scheme, DivisaoColors divisao) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[divisao],
    );
  }
}
