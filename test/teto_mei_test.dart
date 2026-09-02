import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/calc/calc_engine.dart';
import 'package:quantocobro/core/calc/tax_tables.dart';
import 'package:quantocobro/core/data/entrada_repository.dart';
import 'package:quantocobro/core/model/entrada.dart';

/// F5 — o rastreador de teto do MEI. O achado que afia a feature (doc 16 §7.1):
/// não é UMA barra até 81k, são TRÊS zonas com desfechos diferentes. O medo do
/// MEI é não saber em qual está — então a zona é o que estes testes travam.
void main() {
  group('agregação do ano', () {
    Entrada e(double v, DateTime at) =>
        Entrada(valor: v, separado: 0, regimeTag: 'MEI', at: at);

    test('entrouNoAno soma só o ano pedido', () {
      final List<Entrada> todas = <Entrada>[
        e(1000, DateTime(2026, 1, 10)),
        e(2000, DateTime(2026, 7, 5)),
        e(9999, DateTime(2025, 12, 31)), // outro ano, fora
      ];
      expect(entrouNoAno(todas, 2026), 3000);
      expect(entrouNoAno(todas, 2025), 9999);
      expect(entrouNoAno(todas, 2024), 0);
    });
  });

  group('as três zonas', () {
    test('verde: abaixo de 81k', () {
      final TetoMei t = avaliarTetoMei(faturado: 60000, mesAtual: 6);
      expect(t.zona, ZonaTeto.verde);
      expect(t.restante, closeTo(21000, 0.01));
      expect(t.excedente, 0);
    });

    test('no teto exato ainda é verde (o limite pertence à zona segura)', () {
      expect(
        avaliarTetoMei(faturado: kTetoAnualMei, mesAtual: 12).zona,
        ZonaTeto.verde,
      );
    });

    test('amarela: entre 81k e 97,2k (tolerância dos 20%)', () {
      final TetoMei t = avaliarTetoMei(faturado: 90000, mesAtual: 10);
      expect(t.zona, ZonaTeto.amarela);
      expect(t.restante, 0);
      expect(t.excedente, closeTo(9000, 0.01));
    });

    test('vermelha: acima de 97,2k', () {
      expect(
        avaliarTetoMei(faturado: 100000, mesAtual: 11).zona,
        ZonaTeto.vermelha,
      );
    });
  });

  group('projeção linear', () {
    test('ritmo constante projeta o mês em que encosta no teto', () {
      // R$ 40.500 em 6 meses = 6.750/mês → 81k no mês 12 (dezembro).
      final TetoMei t = avaliarTetoMei(faturado: 40500, mesAtual: 6);
      expect(t.ritmoMensal, closeTo(6750, 0.01));
      expect(t.projecaoAno, closeTo(81000, 0.01));
      expect(t.mesEncosta, 12);
    });

    test('ritmo baixo: não encosta no teto este ano (mesEncosta null)', () {
      final TetoMei t = avaliarTetoMei(faturado: 12000, mesAtual: 6);
      expect(t.mesEncosta, isNull);
      expect(t.zona, ZonaTeto.verde);
    });

    test('já passou do teto: não há mês pra encostar', () {
      expect(avaliarTetoMei(faturado: 90000, mesAtual: 9).mesEncosta, isNull);
    });

    test('faturado zero: nada quebra, ritmo zero, sem projeção', () {
      final TetoMei t = avaliarTetoMei(faturado: 0, mesAtual: 3);
      expect(t.ritmoMensal, 0);
      expect(t.mesEncosta, isNull);
      expect(t.zona, ZonaTeto.verde);
    });
  });

  // O anel do teto (painel) mostra dois números com denominadores diferentes
  // de propósito: o arco satura na tolerância (97,2k), o % do centro é sobre
  // o teto puro (81k) e pode passar de 100. Um denominador trocado seria
  // invisível pro olho, então cada razão trava aqui, sozinha.
  group('as duas razões do anel do teto', () {
    test('zero: arco vazio, 0%', () {
      expect(fracaoDoTetoComTolerancia(0), 0);
      expect(percentualDoTetoAnual(0), 0);
    });

    test('abaixo do teto (60k): arco a 61,7%, centro em 74%', () {
      // O mesmo caso que o teste de widget do cartão usa — as duas contas
      // concordam aqui, é o caso feliz.
      expect(fracaoDoTetoComTolerancia(60000), closeTo(0.6173, 0.0001));
      expect(percentualDoTetoAnual(60000), 74);
    });

    test('exatamente no teto (81k): arco a 83,3%, centro em 100%', () {
      expect(
        fracaoDoTetoComTolerancia(kTetoAnualMei),
        closeTo(0.8333, 0.0001),
      );
      expect(percentualDoTetoAnual(kTetoAnualMei), 100);
    });

    test('acima do teto, sob a tolerância (90.720 = 112% de 81k)', () {
      expect(fracaoDoTetoComTolerancia(90720), closeTo(0.9333, 0.0001));
      expect(percentualDoTetoAnual(90720), 112);
    });

    test('acima da tolerância: o arco satura em 1, o % continua livre', () {
      expect(fracaoDoTetoComTolerancia(150000), 1.0);
      expect(fracaoDoTetoComTolerancia(kTetoMeiComTolerancia), 1.0);
      // O centro não satura — é o que deixa o anel avisar "furou de vez".
      expect(percentualDoTetoAnual(150000), 185);
    });
  });
}
