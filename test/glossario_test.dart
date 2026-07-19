import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/glossario/glossario.dart';

void main() {
  test('todo verbete tem título e texto curto o bastante pro balão', () {
    for (final String id in Glossario.ids) {
      final Verbete v = Glossario.of(id);
      expect(v.titulo.trim(), isNotEmpty, reason: 'título vazio em "$id"');
      expect(v.texto.trim(), isNotEmpty, reason: 'texto vazio em "$id"');
      // Curto de propósito: o leigo tem que entender numa leitura.
      expect(
        v.texto.length,
        lessThanOrEqualTo(240),
        reason: 'verbete "$id" está longo demais (${v.texto.length})',
      );
    }
  });

  test('os termos que travaram as personas existem', () {
    for (final String id in <String>[
      'leao',
      'regime',
      'qual_regime',
      'prolabore',
      'grossup',
    ]) {
      expect(Glossario.ids, contains(id), reason: 'falta o verbete "$id"');
    }
  });
}
