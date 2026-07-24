import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/calc/calc_engine.dart';
import 'package:quantocobro/core/calc/tax_tables.dart';
import 'package:quantocobro/core/model/regime.dart';

/// F4 — o detalhamento do imposto. A regra de ouro do raio-x: a SOMA das peças
/// tem que fechar EXATO com o mesmo `impostoMensal` que o app inteiro usa. Se
/// a folha mostrasse peças que não somam o total, seria pior que não mostrar —
/// num app fiscal, uma conta que não bate destrói a confiança na hora.
void main() {
  group('detalharImposto fecha com impostoMensal', () {
    for (final double f in <double>[0, 1500, 4000, 8000, 22500, 40000]) {
      for (final RegimeId regime in RegimeId.values) {
        test('$regime · faturamento $f', () {
          final ImpostoDetalhe d = detalharImposto(regime, f);
          expect(d.imposto, closeTo(impostoMensal(regime, f), 0.001));
          expect(d.efetiva, closeTo(aliquotaEfetiva(regime, f), 0.0001));
          expect(d.faturamento, f < 0 ? 0 : f);
        });
      }
    }
  });

  group('CPF — INSS + IRPF, peça a peça', () {
    test('renda alta: INSS 20%, faixa de 27,5%, sem redutor', () {
      final ImpostoDetalhe d = detalharImposto(RegimeId.cpf, 8000);
      expect(d.inss, closeTo(inssIndividual(8000), 0.01)); // 1600
      expect(d.baseIrpf, closeTo(8000 - d.inss, 0.01)); // 6400
      expect(d.faixaAliquota, 0.275);
      expect(d.redutor, 0);
      // As peças somam o total:
      expect(d.inss + d.irpf, closeTo(d.imposto, 0.01));
      expect(d.semIrpf, isFalse);
    });

    test('renda baixa: redutor cobre o IRPF, sobra só o INSS', () {
      final ImpostoDetalhe d = detalharImposto(RegimeId.cpf, 4000);
      expect(d.inss, closeTo(800, 0.01));
      expect(d.irpf, closeTo(0, 0.01));
      expect(d.semIrpf, isTrue);
      expect(d.imposto, closeTo(800, 0.01)); // só INSS
    });
  });

  group('carnê-leão — só IRPF, sem INSS', () {
    test('não soma INSS e apura sobre o rendimento cheio', () {
      final ImpostoDetalhe d = detalharImposto(RegimeId.carneLeao, 8000);
      expect(d.inss, 0);
      expect(d.baseIrpf, 8000); // base cheia, não descontada de INSS
      expect(d.irpf, closeTo(d.imposto, 0.01));
      // Sem o INSS, o total é menor que o do CPF no mesmo rendimento:
      expect(d.imposto, lessThan(detalharImposto(RegimeId.cpf, 8000).imposto));
    });
  });

  group('Simples — faixa do Anexo III', () {
    test('1ª faixa: 6% nominal, RBT12 = mês × 12', () {
      final ImpostoDetalhe d = detalharImposto(RegimeId.simples, 10000);
      expect(d.rbt12, 120000);
      expect(d.simplesNominal, 0.06);
      expect(d.simplesDeducao, 0);
      expect(d.efetiva, closeTo(0.06, 0.0001));
    });

    test('2ª faixa: usa parcela a deduzir e efetiva < nominal', () {
      final ImpostoDetalhe d = detalharImposto(RegimeId.simples, 22500);
      expect(d.rbt12, 270000);
      expect(d.simplesNominal, 0.112);
      expect(d.simplesDeducao, 9360);
      expect(d.efetiva, lessThan(d.simplesNominal));
    });
  });

  group('lookups de faixa', () {
    test('faixaIrpfDe cai na faixa certa', () {
      expect(faixaIrpfDe(2000).aliquota, 0.0); // isenta
      expect(faixaIrpfDe(3000).aliquota, 0.15);
      expect(faixaIrpfDe(100000).aliquota, 0.275); // topo
    });

    test('faixaSimplesDe cai na faixa certa', () {
      expect(faixaSimplesDe(100000).aliquotaNominal, 0.06);
      expect(faixaSimplesDe(300000).aliquotaNominal, 0.112);
      expect(faixaSimplesDe(9999999).aliquotaNominal, 0.135); // acima → 3ª
    });
  });
}
