import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/features/legal/legal_texts.dart';

/// Decisão de 01/09/2026: a versão grátis PODE passar a exibir anúncio; o Pro
/// nunca. Os termos não podem prometer "nunca terá anúncio", e o Pro continua
/// vendendo "sem anúncios". Este teste trava as duas pontas.
void main() {
  test('privacidade não promete ausência eterna de anúncio', () {
    expect(LegalTexts.privacidade, isNot(contains('não exibe anúncios')));
    expect(LegalTexts.privacidade, isNot(contains('não tem anúncios')));
    expect(LegalTexts.privacidade, contains('pode passar a exibir anúncios'));
    expect(LegalTexts.privacidade, contains('o Pro continuará sem anúncios'));
  });

  test('termos: o Pro inclui a ausência de anúncios', () {
    expect(LegalTexts.termos, contains('sem anúncios'));
  });

  test('nenhum travessão em texto visível', () {
    expect(LegalTexts.privacidade, isNot(contains('—')));
    expect(LegalTexts.termos, isNot(contains('—')));
  });
}
