import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/calc/tax_tables.dart';
import 'package:quantocobro/core/lembrete/lembrete.dart';
import 'package:quantocobro/core/model/regime.dart';

/// F7 — a decisão do lembrete é PURA (o resto é chamada de sistema). O que trava
/// aqui: cada regime lembra da SUA obrigação, no dia certo. MEI/Simples é o DAS
/// (dia 20); CPF/carnê-leão/dólar é o carnê-leão, no fim do mês.
void main() {
  test('MEI e Simples lembram do DAS no dia 20', () {
    expect(planoLembrete(RegimeId.mei).dia, kDasVencimentoDia);
    expect(planoLembrete(RegimeId.mei).dia, 20);
    expect(planoLembrete(RegimeId.simples).dia, 20);
    expect(planoLembrete(RegimeId.mei).titulo, contains('DAS'));
    expect(planoLembrete(RegimeId.simples).titulo, contains('DAS'));
  });

  test('CPF e carnê-leão lembram do carnê-leão perto do fim do mês', () {
    for (final RegimeId r in <RegimeId>[RegimeId.cpf, RegimeId.carneLeao]) {
      expect(planoLembrete(r).dia, 25);
      expect(planoLembrete(r).titulo.toLowerCase(), contains('carnê-leão'));
    }
  });

  test('intl tem um lembrete genérico de separar o imposto', () {
    final LembretePlano p = planoLembrete(RegimeId.intl);
    expect(p.dia, 25);
    expect(p.titulo.toLowerCase(), contains('imposto'));
  });

  test('todo regime tem título e corpo não-vazios, e hora válida', () {
    for (final RegimeId r in RegimeId.values) {
      final LembretePlano p = planoLembrete(r);
      expect(p.titulo.trim(), isNotEmpty, reason: '$r sem título');
      expect(p.corpo.trim(), isNotEmpty, reason: '$r sem corpo');
      expect(p.hora, inInclusiveRange(0, 23));
      expect(p.dia, inInclusiveRange(1, 28)); // seguro pra todo mês
    }
  });
}
