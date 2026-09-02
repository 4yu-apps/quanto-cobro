import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/calc/calc_engine.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/regime.dart';

void main() {
  final Area a = Area.padrao(); // 5×6, 85 h, renda 5000, provisão ligada
  const RegimeId regime = RegimeId.cpf;
  final ValorHoraResult r = computeValorHora(a, regime);

  test('zero dias: não falta nada', () {
    final FolgaResult f = computeFolga(area: a, regime: regime, diasFolga: 0, mesesAte: 3);
    expect(f.faltaTotal, 0);
    expect(f.jaCoberto, isTrue);
    expect(f.valorHoraNovo, r.valorHora);
  });

  test('faturamento perdido é a fração do mês vezes o faturamento', () {
    final FolgaResult f = computeFolga(area: a, regime: regime, diasFolga: 10, mesesAte: 3);
    final double diasUteis = 5 * 52 / 12;
    expect(f.faturamentoPerdido, closeTo(10 / diasUteis * r.faturamento, 0.01));
    expect(f.horasPerdidas, closeTo(10 / diasUteis * a.horas, 0.01));
  });

  test('a provisão de férias abate, e sem ela falta mais', () {
    final FolgaResult com = computeFolga(area: a, regime: regime, diasFolga: 20, mesesAte: 3);
    final FolgaResult sem = computeFolga(
      area: a.copyWith(provisaoOn: false),
      regime: regime,
      diasFolga: 20,
      mesesAte: 3,
    );
    expect(com.cobertoPelaProvisao, greaterThan(0));
    expect(sem.cobertoPelaProvisao, 0);
    expect(sem.faltaTotal, greaterThan(com.faltaTotal));
  });

  test('custo da viagem entra com gross-up e sobe a hora nova', () {
    final FolgaResult base = computeFolga(area: a, regime: regime, diasFolga: 10, mesesAte: 3);
    final FolgaResult viagem = computeFolga(
      area: a, regime: regime, diasFolga: 10, mesesAte: 3, custoFolga: 3000,
    );
    expect(viagem.custoFolgaBruto, greaterThan(3000));
    expect(viagem.faltaTotal, greaterThan(base.faltaTotal));
    expect(viagem.valorHoraNovo, greaterThanOrEqualTo(base.valorHoraNovo));
    expect(viagem.valorHoraNovo, greaterThan(r.valorHora));
  });

  test('mais meses até lá = menos por mês; nunca divide por zero', () {
    final FolgaResult um = computeFolga(area: a, regime: regime, diasFolga: 20, mesesAte: 1, custoFolga: 2000);
    final FolgaResult seis = computeFolga(area: a, regime: regime, diasFolga: 20, mesesAte: 6, custoFolga: 2000);
    final FolgaResult zero = computeFolga(area: a, regime: regime, diasFolga: 20, mesesAte: 0, custoFolga: 2000);
    expect(seis.faltaPorMes, closeTo(um.faltaPorMes / 6, 0.01));
    expect(zero.faltaPorMes, um.faltaPorMes);
  });

  test('horas extras que não cabem na semana marcam estouraCapacidade', () {
    final FolgaResult f = computeFolga(
      area: a, regime: regime, diasFolga: 60, mesesAte: 1, custoFolga: 20000,
    );
    expect(f.estouraCapacidade, isTrue);
  });

  test('diasSemana zero (dado malformado) não produz Infinity/NaN', () {
    final Area malformada = a.copyWith(diasSemana: 0);
    final FolgaResult f = computeFolga(
      area: malformada, regime: regime, diasFolga: 10, mesesAte: 3, custoFolga: 500,
    );
    expect(f.horasPerdidas.isFinite, isTrue);
    expect(f.faturamentoPerdido.isFinite, isTrue);
    expect(f.cobertoPelaProvisao.isFinite, isTrue);
    expect(f.custoFolgaBruto.isFinite, isTrue);
    expect(f.faltaTotal.isFinite, isTrue);
    expect(f.faltaPorMes.isFinite, isTrue);
    expect(f.valorHoraNovo.isFinite, isTrue);
    expect(f.horasExtrasMes.isFinite, isTrue);
  });
}
