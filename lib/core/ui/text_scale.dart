/// Escala de texto: multiplicador do app POR CIMA do fator do sistema, clampado.
/// Nunca substitui o zoom do sistema (baixa visão) — combina.
double effectiveTextScale(double systemFactor, double appMultiplier) =>
    (systemFactor * appMultiplier).clamp(0.85, 2.0);

/// Um nível nomeado do seletor de fonte.
class TextScaleLevel {
  const TextScaleLevel(this.label, this.value);
  final String label;
  final double value;
}

const List<TextScaleLevel> kTextScaleLevels = <TextScaleLevel>[
  TextScaleLevel('Compacto', 0.90),
  TextScaleLevel('Padrão', 1.00),
  TextScaleLevel('Grande', 1.15),
  TextScaleLevel('Enorme', 1.30),
];
