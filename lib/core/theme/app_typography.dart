import 'package:flutter/painting.dart';

/// Tipografia do Design System §4. O número é o herói (Sora, figuras tabulares);
/// UI/corpo em Inter. As fontes serão empacotadas em `assets/fonts` (offline);
/// enquanto não entram, cai no default do sistema — o de-para de tamanho/peso já
/// vale e as telas finais só trocam a família.
abstract final class AppType {
  static const String numberFamily = 'Sora';
  static const String uiFamily = 'Inter';

  /// Tabulares em TUDO que é dinheiro — o número não pode "dançar".
  static const List<FontFeature> tnum = [FontFeature.tabularFigures()];

  static const TextStyle valueHero = TextStyle(
    fontFamily: numberFamily,
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.0,
    fontFeatures: tnum,
  );
  static const TextStyle valueXl = TextStyle(
    fontFamily: numberFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1.05,
    fontFeatures: tnum,
  );
  static const TextStyle valueLg = TextStyle(
    fontFamily: numberFamily,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    fontFeatures: tnum,
  );
  static const TextStyle valueMd = TextStyle(
    fontFamily: numberFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    fontFeatures: tnum,
  );
}
