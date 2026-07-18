import 'package:flutter/material.dart';

import 'color_scheme.dart';
import 'divisao_colors.dart';
import 'tokens.dart';

/// Monta os dois ThemeData a partir do Design System. O ESCURO é o padrão.
/// Aqui vive a "fundação" (UI-SPEC §1.0): TextTheme Inter + escala M3, botões
/// pill 56dp, campos e superfícies — o que dá alma a todas as telas de uma vez.
abstract final class AppTheme {
  static ThemeData get dark => _build(AppColorSchemes.dark, DivisaoColors.dark);
  static ThemeData get light => _build(AppColorSchemes.light, DivisaoColors.light);

  static ThemeData _build(ColorScheme scheme, DivisaoColors divisao) {
    final TextTheme textTheme = _textTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[divisao],

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),

      // Botão primário: pill 56dp (UI-SPEC §1.4).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radii.md)),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radii.md),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radii.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),

      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: Space.x6),
      chipTheme: const ChipThemeData(shape: StadiumBorder()),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle s(double size, double line, FontWeight w) => TextStyle(
          fontFamily: 'Inter',
          fontSize: size,
          height: line / size,
          fontWeight: w,
        );
    return TextTheme(
      displaySmall: s(36, 44, FontWeight.w600),
      headlineMedium: s(28, 36, FontWeight.w600),
      headlineSmall: s(24, 32, FontWeight.w600),
      titleLarge: s(22, 28, FontWeight.w600),
      titleMedium: s(16, 24, FontWeight.w600),
      titleSmall: s(14, 20, FontWeight.w500),
      bodyLarge: s(16, 24, FontWeight.w400),
      bodyMedium: s(14, 20, FontWeight.w400),
      labelLarge: s(16, 20, FontWeight.w600),
      labelMedium: s(13, 16, FontWeight.w500),
      labelSmall: s(11, 16, FontWeight.w500),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
