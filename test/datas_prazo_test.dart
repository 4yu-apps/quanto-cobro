import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/common/datas.dart';

void main() {
  final DateTime hoje = DateTime(2026, 9, 1, 15, 30);
  test('sem data, sem texto', () {
    expect(prazoEntregaTexto(null, hoje: hoje), isNull);
  });
  test('hoje, amanhã, futuro', () {
    expect(prazoEntregaTexto(DateTime(2026, 9, 1), hoje: hoje), 'Entrega hoje');
    expect(prazoEntregaTexto(DateTime(2026, 9, 2), hoje: hoje), 'Entrega amanhã');
    expect(
      prazoEntregaTexto(DateTime(2026, 9, 13), hoje: hoje),
      'Faltam 12 dias pra entrega',
    );
  });
  test('passado, sem pânico', () {
    expect(prazoEntregaTexto(DateTime(2026, 8, 31), hoje: hoje), 'Entrega passou ontem');
    expect(
      prazoEntregaTexto(DateTime(2026, 8, 20), hoje: hoje),
      'Entrega passou há 12 dias',
    );
  });
}
