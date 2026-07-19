import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/theme/materials.dart';

void main() {
  test('Materials está registrado nos dois temas', () {
    expect(AppTheme.dark.extension<Materials>(), isNotNull);
    expect(AppTheme.light.extension<Materials>(), isNotNull);
  });

  test('Materials.lerp interpola sem crashar e respeita os tetos', () {
    final Materials m = Materials.dark.lerp(Materials.light, 0.5);
    expect(m.glassBlurSigma, greaterThan(0));
    // Teto de brilho: o halo da nav nunca passa de 0.12 de alpha.
    expect(Materials.dark.navHalo.a, lessThanOrEqualTo(0.12 + 0.001));
    expect(m.edgeHighlight, isA<Color>());
  });
}
