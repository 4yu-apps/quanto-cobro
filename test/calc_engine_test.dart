import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/calc/calc_engine.dart';
import 'package:quantocobro/core/calc/tax_tables.dart';
import 'package:quantocobro/core/model/custo.dart';
import 'package:quantocobro/core/model/perfil.dart';
import 'package:quantocobro/core/model/regime.dart';

void main() {
  group('tax_tables 2026', () {
    test('IRPF: faixa isenta não paga nada', () {
      expect(irpfTabela(2428.80), 0);
      expect(irpfTabela(0), 0);
    });

    test('IRPF: topo de cada faixa bate com a parcela a deduzir', () {
      // R$ 3.000 → 15%: 450 − 394,16 = 55,84
      expect(irpfTabela(3000), closeTo(55.84, 0.01));
      // R$ 10.000 → 27,5%: 2.750 − 908,73 = 1.841,27
      expect(irpfTabela(10000), closeTo(1841.27, 0.01));
    });

    test('Redutor Lei 15.270: zera o IRPF de quem recebe até R\$ 5.000', () {
      // Renda 4.000: INSS 800, base 3.200 → IRPF apurado 85,84 → redutor cobre tudo.
      expect(impostoMensalCpf(4000), closeTo(800, 0.01)); // só INSS
    });

    test('Redutor decresce entre 5.000 e 7.350 e some acima', () {
      final double r6000 = redutorIrpf(6000, 999);
      expect(r6000, closeTo(978.62 - 0.133145 * 6000, 0.01));
      expect(redutorIrpf(8000, 999), 0);
      // Nunca cria imposto negativo:
      expect(redutorIrpf(4500, 10), 10);
    });

    test('INSS individual respeita o teto de 2026', () {
      expect(inssIndividual(20000), closeTo(kInssTeto * 0.20, 0.01));
      expect(inssIndividual(3000), closeTo(600, 0.01));
    });

    test('Simples Anexo III: 1ª faixa é 6% flat; 2ª usa parcela a deduzir', () {
      expect(aliquotaEfetivaSimples(10000), closeTo(0.06, 0.0001));
      // RBT12 270k (mensal 22.5k) → (270k×11,2% − 9.360)/270k ≈ 7,73%
      expect(aliquotaEfetivaSimples(22500), closeTo(0.0773, 0.001));
    });
  });

  group('computeValorHora', () {
    test('MEI: DAS fixo somado (nunca 16% do faturamento) e alíquota ~1%', () {
      final ValorHoraResult r = computeValorHora(Perfil.padrao());
      // base = 5000 + 850 custos + 416,67 provisão (renda/12) = 6266,67
      expect(r.base, closeTo(6266.67, 0.1));
      expect(r.imposto, closeTo(kDasMensalMei, 0.01));
      expect(r.faturamento, closeTo(6352.72, 0.1));
      expect(r.valorHora, 75); // 6352,72 / 85h
      expect(r.reservaPct, lessThanOrEqualTo(2));
      expect(r.dasMensal, kDasMensalMei);
      expect(r.acimaTetoMei, isFalse);
    });

    test('MEI: meta alta estoura o teto e o motor avisa', () {
      final ValorHoraResult r = computeValorHora(
        Perfil.padrao().copyWith(renda: 10000),
      );
      expect(r.acimaTetoMei, isTrue);
    });

    test('CPF: gross-up progressivo converge e cobra INSS + IRPF', () {
      final ValorHoraResult r = computeValorHora(
        Perfil.padrao().copyWith(regime: RegimeId.cpf),
      );
      // f = base + imposto(f) precisa fechar (ponto-fixo estável):
      expect(
        r.faturamento,
        closeTo(r.base + impostoMensalCpf(r.faturamento), 1.0),
      );
      expect(r.rate, greaterThan(0.15));
      expect(r.rate, lessThan(0.40));
      expect(r.dasMensal, isNull);
      expect(r.acimaTetoMei, isFalse);
    });

    test('CPF renda baixa: redutor derruba a efetiva pra ~20% (só INSS)', () {
      final ValorHoraResult r = computeValorHora(
        Perfil.padrao().copyWith(
          regime: RegimeId.cpf,
          renda: 2500,
          custos: const <Custo>[],
        ),
      );
      expect(r.rate, closeTo(0.20, 0.02));
    });

    test('Simples: renda típica cai na 1ª faixa (6%), não em 12% flat', () {
      final ValorHoraResult r = computeValorHora(
        Perfil.padrao().copyWith(regime: RegimeId.simples),
      );
      expect(r.reservaPct, 6);
    });

    test('horas 0 não estoura (usa mínimo 1, sem divisão por zero)', () {
      final ValorHoraResult r = computeValorHora(
        Perfil.padrao().copyWith(horas: 0),
      );
      expect(r.valorHora, greaterThan(0));
    });
  });

  group('computeReserva', () {
    test('MEI: reserva vira o DAS do mês, não % do pagamento', () {
      final ReservaResult r = computeReserva(2000, RegimeId.mei);
      expect(r.isMei, isTrue);
      expect(r.reserva, kDasMensalMei.round());
      expect(r.sobra, closeTo(2000 - kDasMensalMei.round(), 0.01));
      expect(r.dasMensal, kDasMensalMei);
    });

    test('MEI: pagamento menor que o DAS não fica negativo', () {
      final ReservaResult r = computeReserva(50, RegimeId.mei);
      expect(r.reserva, 50);
      expect(r.sobra, 0);
    });

    test('CPF com alíquota efetiva do perfil aplica exatamente ela', () {
      final ReservaResult r = computeReserva(
        2000,
        RegimeId.cpf,
        taxaEfetiva: 0.20,
      );
      expect(r.reserva, 400);
      expect(r.pct, 20);
      expect(r.isMei, isFalse);
    });
  });

  group('computeSimulador', () {
    test('detecta projeto abaixo do alvo e sugere preço maior', () {
      final SimuladorResult s = computeSimulador(
        3000,
        30,
        200,
        RegimeId.cpf,
        100,
        taxaEfetiva: 0.20,
      );
      expect(s.abaixo, isTrue);
      expect(s.sugestao, greaterThan(3000));
    });

    test(
      'MEI: sem imposto marginal por projeto (DAS fixo já está no plano)',
      () {
        final SimuladorResult s = computeSimulador(
          3000,
          30,
          200,
          RegimeId.mei,
          92,
        );
        expect(s.isMei, isTrue);
        expect(s.reserva, 0);
        expect(s.lucro, 2800);
      },
    );
  });

  group('horasFaturaveisPorRotina', () {
    test('rotina padrão 5×6 cai na faixa realista (~85h, nunca 160h)', () {
      final int h = horasFaturaveisPorRotina(diasSemana: 5, horasDia: 6);
      expect(h, 85); // 5*6*52/12 = 130 → ×0,65 = 84,5 → 85
    });

    test('mais dias/horas = mais horas cobráveis (monotônico)', () {
      final int a = horasFaturaveisPorRotina(diasSemana: 3, horasDia: 4);
      final int b = horasFaturaveisPorRotina(diasSemana: 6, horasDia: 8);
      expect(b, greaterThan(a));
    });

    test('nunca retorna zero (evita divisão por zero adiante)', () {
      expect(horasFaturaveisPorRotina(diasSemana: 1, horasDia: 1), greaterThan(0));
    });
  });
}
