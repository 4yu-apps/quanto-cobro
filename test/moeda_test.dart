import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/common/money.dart';
import 'package:quantocobro/core/model/moeda.dart';

void main() {
  test('moneyBRL formata com o símbolo e separador do pt_BR (intl)', () {
    // intl usa espaço NBSP (U+00A0) entre "R\$" e o valor, não espaço comum.
    expect(moneyBRL(92), 'R\$ 92');
  });

  test('money com USD usa símbolo, separador de milhar e 2 casas', () {
    expect(money(1000, Moeda.usd), r'US$1,000.00');
  });

  test('Moeda sobrevive a um round-trip por JSON', () {
    final Moeda back = Moeda.fromJson(Moeda.usd.toJson());
    expect(back.codigo, 'USD');
    expect(back.simbolo, Moeda.usd.simbolo);
    expect(back.casas, Moeda.usd.casas);
    expect(back.locale, Moeda.usd.locale);
  });

  test(
    'Moeda.byCodigo acha a moeda curada certa e cai pra BRL se não achar',
    () {
      expect(Moeda.byCodigo('EUR').simbolo, '€');
      expect(Moeda.byCodigo('ZZZ').codigo, 'BRL');
    },
  );
}
