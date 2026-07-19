import 'package:flutter/material.dart';

/// ColorSchemes da identidade "Cofre Aberto". O ESCURO ("Cofre-Esmeralda") é o
/// padrão: tinta verde-profunda cujo croma SOBE conforme a camada eleva — o
/// veludo do cofre. O CLARO ("Recibo Premium") é papel-marfim quente com
/// cartões que clareiam até o branco puro no High (escada tonal invertida):
/// elevação no claro = mais luz + sombra tintada, não mais cinza.
/// Todos os pares críticos têm contraste WCAG calculado ≥ 4.5:1 (texto).
abstract final class AppColorSchemes {
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF57E5A9),
    onPrimary: Color(0xFF023221),
    primaryContainer: Color(0xFF004F37),
    onPrimaryContainer: Color(0xFFA5F6CB),
    secondary: Color(0xFFA1C2DF),
    onSecondary: Color(0xFF0E2A45),
    secondaryContainer: Color(0xFF213D56),
    onSecondaryContainer: Color(0xFFCAE2F3),
    tertiary: Color(0xFFEFCE6F),
    onTertiary: Color(0xFF3C2B02),
    tertiaryContainer: Color(0xFF553F05),
    onTertiaryContainer: Color(0xFFFDE6AB),
    error: Color(0xFFF8A49D),
    onError: Color(0xFF4F0A0D),
    errorContainer: Color(0xFF6F1916),
    onErrorContainer: Color(0xFFFED6D2),
    surface: Color(0xFF09120E),
    onSurface: Color(0xFFE2EBE3),
    onSurfaceVariant: Color(0xFFA2B3A7),
    surfaceContainerLowest: Color(0xFF040A07),
    surfaceContainerLow: Color(0xFF121C17),
    surfaceContainer: Color(0xFF18241E),
    surfaceContainerHigh: Color(0xFF202E27),
    surfaceContainerHighest: Color(0xFF293830),
    outline: Color(0xFF6D8073),
    outlineVariant: Color(0xFF2A3931),
    inverseSurface: Color(0xFFE2EBE3),
    onInverseSurface: Color(0xFF1A241F),
    inversePrimary: Color(0xFF007D54),
    scrim: Color(0xFF000000),
    shadow: Color(0xFF000000),
  );

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF007D54),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFBEF5D9),
    onPrimaryContainer: Color(0xFF023C28),
    secondary: Color(0xFF2E5C8A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD4E9FD),
    onSecondaryContainer: Color(0xFF0D2F4F),
    tertiary: Color(0xFF896105),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFBE0A1),
    onTertiaryContainer: Color(0xFF473100),
    error: Color(0xFFB91D1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDBD5),
    onErrorContainer: Color(0xFF55120B),
    surface: Color(0xFFF4F3EE),
    onSurface: Color(0xFF18231E),
    onSurfaceVariant: Color(0xFF45524B),
    surfaceContainerLowest: Color(0xFFFDFDFC),
    surfaceContainerLow: Color(0xFFF8F8F4),
    surfaceContainer: Color(0xFFFCFBF8),
    // O High é o BRANCO PURO: hero e vitrines flutuam sobre o papel.
    surfaceContainerHigh: Color(0xFFFFFFFF),
    // O Highest vira "poço" (mais escuro que o papel): trilhos e fills afundam.
    surfaceContainerHighest: Color(0xFFE6E7DF),
    outline: Color(0xFF69756C),
    outlineVariant: Color(0xFFD8DAD2),
    inverseSurface: Color(0xFF222B27),
    onInverseSurface: Color(0xFFF3F2ED),
    inversePrimary: Color(0xFF64E3AB),
    scrim: Color(0xFF000000),
    // Sombra tintada de verde-tinta: papelaria premium, não material default.
    shadow: Color(0xFF0D211B),
  );
}
