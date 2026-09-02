import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/common/datas.dart';

void main() {
  test('saudação pela hora', () {
    expect(saudacao(DateTime(2026, 1, 1, 7)), 'Bom dia');
    expect(saudacao(DateTime(2026, 1, 1, 12)), 'Boa tarde');
    expect(saudacao(DateTime(2026, 1, 1, 18)), 'Boa noite');
    expect(saudacao(DateTime(2026, 1, 1, 2)), 'Boa noite');
  });
}
