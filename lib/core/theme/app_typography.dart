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

  // 72 competia com a anatomia embaixo (56): só 16px separavam o herói do
  // resto, e a tela toda "gritava". 64 dá respiro sem tirar o protagonismo do
  // valor-hora — o número-herói continua sendo o maior da tela por larga margem.
  static const TextStyle valueHero = TextStyle(
    fontFamily: numberFamily,
    fontSize: 64,
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

  /// Campo monetário em foco (DS §4.2).
  static const TextStyle valueDisplay = TextStyle(
    fontFamily: numberFamily,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    height: 1.0,
    fontFeatures: tnum,
  );

  /// Teclas do keypad numérico próprio (DS §4.2 — uso opcional).
  static const TextStyle valueKeypadKey = TextStyle(
    fontFamily: numberFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    fontFeatures: tnum,
  );
}
