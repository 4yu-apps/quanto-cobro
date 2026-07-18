import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/perfil.dart';

void main() {
  test('Perfil sobrevive a um round-trip por JSON (backup/restore)', () {
    final Perfil p = Perfil.padrao();
    final Perfil back = Perfil.fromJson(p.toJson());
    expect(back.renda, p.renda);
    expect(back.horas, p.horas);
    expect(back.provisao, p.provisao);
    expect(back.provisaoOn, p.provisaoOn);
    expect(back.regime, p.regime);
    expect(back.custos.length, p.custos.length);
    expect(back.custosTotal, p.custosTotal);
  });
}
