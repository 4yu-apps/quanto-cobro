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

  test('Perfil.tipoContrato sobrevive a um round-trip por JSON', () {
    final Perfil p = Perfil.padrao().copyWith(
      tipoContrato: TipoContrato.mensal,
    );
    final Perfil back = Perfil.fromJson(p.toJson());
    expect(back.tipoContrato, TipoContrato.mensal);
  });

  test(
    'JSON legado (sem tipoContrato) migra pra avulso, resto intacto',
    () {
      final Perfil original = Perfil.padrao();
      final Map<String, dynamic> legado = original.toJson()
        ..remove('tipoContrato');
      final Perfil back = Perfil.fromJson(legado);
      expect(back.tipoContrato, TipoContrato.avulso);
      expect(back.id, original.id);
      expect(back.nome, original.nome);
      expect(back.renda, original.renda);
      expect(back.horas, original.horas);
      expect(back.regime, original.regime);
      expect(back.custos.length, original.custos.length);
      expect(back.custosTotal, original.custosTotal);
    },
  );
}
