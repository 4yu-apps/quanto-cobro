import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/calc/calc_engine.dart';
import 'package:quantocobro/core/calc/tax_tables.dart';
import 'package:quantocobro/core/model/custo.dart';
import 'package:quantocobro/core/model/area.dart';
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

    test('carnê-leão puro: IRPF progressivo com redutor, SEM INSS', () {
      const double r = 8000;
      final double apurado = irpfTabela(r);
      final double esperado = apurado - redutorIrpf(r, apurado);

      // Mesma tabela/redutor, aplicada direto sobre o rendimento cheio
      // (base = r, não r − INSS):
      expect(impostoCarneLeao(r), closeTo(esperado, 0.01));

      // Sem INSS ⇒ sempre menor que o CPF autônomo no mesmo rendimento:
      expect(impostoCarneLeao(r), lessThan(impostoMensalCpf(r)));

      // A diferença NÃO é só "tirar o INSS de cima" do total do CPF — o CPF
      // apura o IRPF numa base MENOR (r − INSS), então o IRPF do CPF sozinho
      // é diferente do IRPF do carnê-leão puro (base cheia). Isso prova que a
      // base usada é a certa, não um atalho aritmético.
      final double irpfDoCpfSozinho = impostoMensalCpf(r) - inssIndividual(r);
      expect(impostoCarneLeao(r), isNot(closeTo(irpfDoCpfSozinho, 0.01)));
    });

    test('carnê-leão puro: renda 0 não gera imposto negativo', () {
      expect(impostoCarneLeao(0), 0);
      expect(impostoCarneLeao(-100), 0);
    });
  });

  group('computeValorHora', () {
    test('MEI: DAS fixo somado (nunca 16% do faturamento) e alíquota ~1%', () {
      final ValorHoraResult r = computeValorHora(Area.padrao(), RegimeId.mei);
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
        Area.padrao().copyWith(renda: 10000),
        RegimeId.mei,
      );
      expect(r.acimaTetoMei, isTrue);
    });

    test('CPF: gross-up progressivo converge e cobra INSS + IRPF', () {
      final ValorHoraResult r = computeValorHora(Area.padrao(), RegimeId.cpf);
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
        Area.padrao().copyWith(renda: 2500, custos: const <Custo>[]),
        RegimeId.cpf,
      );
      expect(r.rate, closeTo(0.20, 0.02));
    });

    test('Simples: renda típica cai na 1ª faixa (6%), não em 12% flat', () {
      final ValorHoraResult r = computeValorHora(
        Area.padrao(),
        RegimeId.simples,
      );
      expect(r.reservaPct, 6);
    });

    test('horas 0 não estoura (usa mínimo 1, sem divisão por zero)', () {
      final ValorHoraResult r = computeValorHora(
        Area.padrao().copyWith(horas: 0),
        RegimeId.mei,
      );
      expect(r.valorHora, greaterThan(0));
    });

    test('Carnê-leão puro: gross-up progressivo converge, sem INSS, e cobra '
        'menos imposto total que o CPF autônomo no mesmo perfil', () {
      final Area base = Area.padrao();
      final ValorHoraResult carneLeao = computeValorHora(
        base,
        RegimeId.carneLeao,
      );
      final ValorHoraResult cpf = computeValorHora(base, RegimeId.cpf);

      // f = base + imposto(f) precisa fechar (ponto-fixo estável):
      expect(
        carneLeao.faturamento,
        closeTo(carneLeao.base + impostoCarneLeao(carneLeao.faturamento), 1.0),
      );
      // Progressivo, mas sem o INSS: alíquota efetiva positiva e sensata.
      expect(carneLeao.rate, greaterThan(0));
      expect(carneLeao.rate, lessThan(0.30));
      expect(carneLeao.dasMensal, isNull);
      expect(carneLeao.acimaTetoMei, isFalse);

      // Mesmo perfil, mesmo faturamento-alvo de base: carnê-leão puro sai
      // mais barato que CPF autônomo (que soma INSS por cima do IRPF).
      expect(carneLeao.imposto, lessThan(cpf.imposto));
      expect(carneLeao.rate, lessThan(cpf.rate));
    });
  });

  group('computeReserva', () {
    test('MEI: reserva vira o DAS do mês, não % do pagamento', () {
      final ReservaResult r = computeReserva(2000, RegimeId.mei);
      expect(r.isMei, isTrue);
      expect(r.separado, kDasMensalMei.round());
      expect(r.sobra, closeTo(2000 - kDasMensalMei.round(), 0.01));
      expect(r.dasMensal, kDasMensalMei);
    });

    test('MEI: pagamento menor que o DAS não fica negativo', () {
      final ReservaResult r = computeReserva(50, RegimeId.mei);
      expect(r.separado, 50);
      expect(r.sobra, 0);
    });

    test('CPF com alíquota efetiva do perfil aplica exatamente ela', () {
      final ReservaResult r = computeReserva(
        2000,
        RegimeId.cpf,
        taxaEfetiva: 0.20,
      );
      expect(r.separado, 400);
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
      expect(
        horasFaturaveisPorRotina(diasSemana: 1, horasDia: 1),
        greaterThan(0),
      );
    });
  });

  group('regime carnê-leão puro', () {
    // O regime saiu da Área e virou ajuste da PESSOA (settings) — duas áreas
    // não podem gerar dois DAS pro mesmo CNPJ. O round-trip que importa agora
    // é o da Área sem ele.
    test('Area sobrevive a um round-trip por JSON', () {
      final Area p = Area.padrao().copyWith(renda: 7000, horas: 100);
      final Area back = Area.fromJson(p.toJson());
      expect(back.renda, p.renda);
      expect(back.horas, p.horas);
      expect(back.custos.length, p.custos.length);
    });
  });
}
