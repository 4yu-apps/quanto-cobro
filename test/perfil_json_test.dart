import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/perfil.dart';

void main() {
  test('Perfil sobrevive a um round-trip por JSON (backup/restore)', () {
    final Perfil p = Perfil.padrao().copyWith(
      provisao: 600,
      provisaoCustom: true,
    );
    final Perfil back = Perfil.fromJson(p.toJson());
    expect(back.id, p.id);
    expect(back.nome, p.nome);
    expect(back.renda, p.renda);
    expect(back.horas, p.horas);
    expect(back.provisao, p.provisao);
    expect(back.provisaoOn, p.provisaoOn);
    expect(back.provisaoCustom, isTrue);
    expect(back.provisaoEfetiva, 600);
    expect(back.regime, p.regime);
    expect(back.custos.length, p.custos.length);
    expect(back.custosTotal, p.custosTotal);
  });

  test(
    'JSON legado (v0.3, sem provisaoCustom) migra pra provisão que escala',
    () {
      final Map<String, dynamic> legado = Perfil.padrao().toJson()
        ..remove('provisaoCustom')
        ..['provisao'] = 458.0; // o valor fixo antigo, calibrado pra demo
      final Perfil back = Perfil.fromJson(legado);
      expect(back.provisaoCustom, isFalse);
      // A provisão efetiva escala com a renda (1 mês por ano), não fica em 458:
      expect(back.provisaoEfetiva, closeTo(back.renda / 12, 0.01));
    },
  );
}
