import 'dart:math' as math;

import '../model/perfil.dart';
import '../model/regime.dart';

/// Motor de cálculo — PURO e testável. É a conta que sustenta a confiança do
/// app; dinheiro errado destrói o diferencial. Portado do protótipo (model.jsx),
/// coerente em todas as telas. Ver testes em test/calc_engine_test.dart.

/// Resultado do valor-hora justo (Blueprint §6.13).
class ValorHoraResult {
  const ValorHoraResult({
    required this.rate,
    required this.provisao,
    required this.custos,
    required this.base,
    required this.faturamento,
    required this.imposto,
    required this.valorHora,
    required this.valorDia,
    required this.reservaPct,
    required this.lucro,
  });

  final double rate;
  final double provisao;
  final double custos;
  final double base; // o que precisa sobrar antes do imposto
  final double faturamento; // gross-up para cobrir o imposto
  final double imposto;
  final int valorHora;
  final int valorDia;
  final int reservaPct;
  final double lucro;
}

ValorHoraResult computeValorHora(Perfil p) {
  final double rate = Regime.of(p.regime).reserveRate;
  final double provisao = p.provisaoOn ? p.provisao : 0;
  final double custos = p.custosTotal;
  final double base = p.renda + custos + provisao;
  final double faturamento = base / (1 - rate);
  final double imposto = faturamento - base;
  final double valorHora = faturamento / math.max(1, p.horas);
  return ValorHoraResult(
    rate: rate,
    provisao: provisao,
    custos: custos,
    base: base,
    faturamento: faturamento,
    imposto: imposto,
    valorHora: valorHora.round(),
    valorDia: (valorHora * 8).round(),
    reservaPct: (rate * 100).round(),
    lucro: p.renda,
  );
}

/// A Divisão: Lucro (é seu + provisão) · Reserva (imposto) · Custos.
class Divisao {
  const Divisao({
    required this.lucro,
    required this.reserva,
    required this.custo,
    required this.base,
  });

  final double lucro;
  final double reserva;
  final double custo;
  final double base;
}

Divisao divisaoFromProfile(Perfil p, ValorHoraResult c) => Divisao(
      lucro: p.renda + c.provisao,
      reserva: c.imposto,
      custo: c.custos,
      base: c.faturamento,
    );

/// Tool: reserva por pagamento (Blueprint §5.5) — o caminho de ouro.
class ReservaResult {
  const ReservaResult({
    required this.rate,
    required this.reserva,
    required this.sobra,
    required this.pct,
  });

  final double rate;
  final int reserva;
  final double sobra;
  final int pct;
}

ReservaResult computeReserva(double amount, RegimeId regime) {
  final double rate = Regime.of(regime).reserveRate;
  final int reserva = (amount * rate).round();
  return ReservaResult(
    rate: rate,
    reserva: reserva,
    sobra: amount - reserva,
    pct: (rate * 100).round(),
  );
}

/// Tool: simulador de projeto (Blueprint §5.6) — com aviso comparativo.
class SimuladorResult {
  const SimuladorResult({
    required this.rate,
    required this.reserva,
    required this.lucro,
    required this.effVH,
    required this.abaixo,
    required this.sugestao,
    required this.divisao,
  });

  final double rate;
  final int reserva;
  final double lucro;
  final int effVH; // valor-hora efetivo
  final bool abaixo; // abaixo do valor-hora alvo?
  final int sugestao; // preço sugerido p/ atingir o alvo
  final Divisao divisao;
}

/// Estima horas faturáveis/mês a partir de 3 perguntas simples (Blueprint §7.1):
/// semanas de férias, % do tempo que é trabalho pago, feriados. Resolve o erro
/// nº1 (dividir por 160h) sem o usuário precisar saber a fórmula.
int estimarHorasFaturaveis({required int ferias, required int pct, required int feriados}) {
  final int semanas = (52 - ferias).clamp(1, 52);
  final int rawAno = semanas * 40 - feriados * 8;
  final double faturavel = rawAno * pct / 100;
  return (faturavel / 12).round().clamp(1, 400);
}

SimuladorResult computeSimulador(
  double valor,
  int horas,
  double custos,
  RegimeId regime,
  int alvoVH,
) {
  final double rate = Regime.of(regime).reserveRate;
  final int reserva = (valor * rate).round();
  final double lucro = valor - reserva - custos;
  final int effVH = horas > 0 ? (lucro / horas).round() : 0;
  final bool abaixo = horas > 0 && effVH < alvoVH;
  final int sugestao = (((alvoVH * horas) + custos) / (1 - rate) / 10).round() * 10;
  return SimuladorResult(
    rate: rate,
    reserva: reserva,
    lucro: lucro,
    effVH: effVH,
    abaixo: abaixo,
    sugestao: sugestao,
    divisao: Divisao(
      lucro: math.max(0, lucro),
      reserva: reserva.toDouble(),
      custo: custos,
      base: valor,
    ),
  );
}
