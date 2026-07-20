import 'package:flutter/material.dart';

/// Tokens de LUZ e MATERIAL (proposta Lúa) — o "Cofre Aberto" chegando nas
/// superfícies que ficaram chapadas. Croma perto de zero nas luzes (é luz, não
/// cor nova). Tetos: acento de card ≤0.08, halo da nav ≤0.12, glow nº ≤0.16.
@immutable
class Materials extends ThemeExtension<Materials> {
  const Materials({
    required this.edgeHighlight,
    required this.edgeShadow,
    required this.panelFillTop,
    required this.panelFillBottom,
    required this.glassFill,
    required this.glassBlurSigma,
    required this.navHalo,
  });

  final Color edgeHighlight; // fio-de-luz no topo da borda
  final Color edgeShadow; // sombra baixa da borda (assenta o card)
  final Color panelFillTop; // degradê do card: topo (mais claro)
  final Color panelFillBottom; // degradê do card: base
  final Color glassFill; // fill tintado da navbar (>=0.88 alpha)
  final double glassBlurSigma; // sigma do BackdropFilter da navbar
  final Color navHalo; // halo colorido da navbar (<=0.12)

  static const Materials dark = Materials(
    edgeHighlight: Color(0x14FFFFFF), // branco 8%
    edgeShadow: Color(0x1A000000), // preto 10%
    panelFillTop: Color(0xFF272B29), // surfaceContainerHigh
    panelFillBottom: Color(0xFF1E2120), // surfaceContainer
    glassFill: Color(0xE1272B29), // surfaceContainerHigh @ ~0.88
    glassBlurSigma: 18,
    navHalo: Color(0x1E57E5A9), // esmeralda ~12% (dentro do teto 0.12)
  );

  static const Materials light = Materials(
    edgeHighlight: Color(0x33FFFFFF), // branco 20% (papel precisa mais)
    edgeShadow: Color(0x0D0D211B), // verde-tinta baixíssimo
    panelFillTop: Color(0xFFFFFFFF), // branco puro flutua
    panelFillBottom: Color(0xFFFCFBF8), // surfaceContainer claro
    glassFill: Color(0xE1FDFDFC), // ~0.88 sobre papel
    glassBlurSigma: 18,
    navHalo: Color(0x14007D54), // esmeralda escuro 8% (claro é sóbrio)
  );

  @override
  Materials copyWith({
    Color? edgeHighlight,
    Color? edgeShadow,
    Color? panelFillTop,
    Color? panelFillBottom,
    Color? glassFill,
    double? glassBlurSigma,
    Color? navHalo,
  }) => Materials(
    edgeHighlight: edgeHighlight ?? this.edgeHighlight,
    edgeShadow: edgeShadow ?? this.edgeShadow,
    panelFillTop: panelFillTop ?? this.panelFillTop,
    panelFillBottom: panelFillBottom ?? this.panelFillBottom,
    glassFill: glassFill ?? this.glassFill,
    glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
    navHalo: navHalo ?? this.navHalo,
  );

  @override
  Materials lerp(ThemeExtension<Materials>? other, double t) {
    if (other is! Materials) return this;
    return Materials(
      edgeHighlight: Color.lerp(edgeHighlight, other.edgeHighlight, t)!,
      edgeShadow: Color.lerp(edgeShadow, other.edgeShadow, t)!,
      panelFillTop: Color.lerp(panelFillTop, other.panelFillTop, t)!,
      panelFillBottom: Color.lerp(panelFillBottom, other.panelFillBottom, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBlurSigma:
          (glassBlurSigma + (other.glassBlurSigma - glassBlurSigma) * t),
      navHalo: Color.lerp(navHalo, other.navHalo, t)!,
    );
  }
}
