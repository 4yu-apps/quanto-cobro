import 'dart:math' as math;

import '../model/perfil.dart';
import '../model/regime.dart';
import 'tax_tables.dart';

/// Motor de cálculo — PURO e testável. É a conta que sustenta a confiança do
/// app; dinheiro errado destrói o diferencial. v0.4: modelo fiscal honesto por
/// regime (MEI = DAS fixo; CPF = IRPF progressivo + INSS; Simples = faixa
/// efetiva do Anexo III). Ver testes em test/calc_engine_test.dart.

/// Imposto mensal estimado do regime para um dado faturamento mensal.
double impostoMensal(RegimeId regime, double faturamentoMensal) {
  switch (Regime.of(regime).kind) {
    case TaxKind.fixoMensal:
      return kDasMensalMei;
    case TaxKind.progressivo:
      return impostoMensalCpf(faturamentoMensal);
    case TaxKind.progressivoSemInss:
      return impostoCarneLeao(faturamentoMensal);
    case TaxKind.faixasSimples:
      return faturamentoMensal * aliquotaEfetivaSimples(faturamentoMensal);
    case TaxKind.flat:
      return faturamentoMensal * kFlatIntl;
  }
}

/// Alíquota efetiva (imposto ÷ faturamento) do regime num faturamento mensal.
double aliquotaEfetiva(RegimeId regime, double faturamentoMensal) {
  if (faturamentoMensal <= 0) return 0;
  return (impostoMensal(regime, faturamentoMensal) / faturamentoMensal).clamp(
    0,
    1,
  );
}

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
    required this.dasMensal,
    required this.acimaTetoMei,
  });

  /// Alíquota EFETIVA (imposto ÷ faturamento), 0..1.
  final double rate;
  final double provisao;
  final double custos;
  final double base; // o que precisa sobrar antes do imposto
  final double faturamento; // quanto precisa faturar para cobrir o imposto
  final double imposto;
  final int valorHora;
  final int valorDia;

  /// Alíquota efetiva em % inteiro (para UI).
  final int reservaPct;
  final double lucro;

  /// DAS mensal quando o regime é MEI; null nos demais.
  final double? dasMensal;

  /// Verdadeiro quando o faturamento necessário estoura o teto mensal do MEI.
  final bool acimaTetoMei;
}

ValorHoraResult computeValorHora(Perfil p) {
  final double provisao = p.provisaoOn ? p.provisaoEfetiva : 0;
  final double custos = p.custosTotal;
  final double base = p.renda + custos + provisao;

  // Gross-up: f = base + imposto(f). Para MEI é soma direta; para taxas
  // progressivas, ponto-fixo (marginal < 50% ⇒ converge rápido; 8 iterações
  // dão erro < 0,3%).
  double faturamento = base;
  for (int i = 0; i < 8; i++) {
    faturamento = base + impostoMensal(p.regime, faturamento);
  }
  final double imposto = faturamento - base;
  final double rate = faturamento > 0 ? imposto / faturamento : 0;
  final double valorHora = faturamento / math.max(1, p.horas);
  final bool mei = p.regime == RegimeId.mei;

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
    dasMensal: mei ? kDasMensalMei : null,
    acimaTetoMei: mei && faturamento > kTetoMensalMei,
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
/// No MEI o conceito muda: não existe % por pagamento — o que existe é o DAS
/// fixo do mês. `isMei` liga o modo "esse dinheiro é seu" na tela.
class ReservaResult {
  const ReservaResult({
    required this.rate,
    required this.reserva,
    required this.sobra,
    required this.pct,
    required this.isMei,
    required this.dasMensal,
  });

  final double rate;
  final int reserva;
  final double sobra;
  final int pct;
  final bool isMei;
  final double? dasMensal;
}

/// [taxaEfetiva] (0..1) vem do perfil ativo quando o regime bate com o dele —
/// a alíquota da RENDA PLANEJADA do mês, não do pagamento avulso. Sem perfil,
/// estima pela efetiva do próprio valor (melhor aproximação disponível).
ReservaResult computeReserva(
  double amount,
  RegimeId regime, {
  double? taxaEfetiva,
}) {
  if (regime == RegimeId.mei) {
    final int reserva = math.min(amount, kDasMensalMei).round();
    return ReservaResult(
      rate: amount > 0 ? kDasMensalMei / amount : 0,
      reserva: reserva,
      sobra: amount - reserva,
      pct: 0,
      isMei: true,
      dasMensal: kDasMensalMei,
    );
  }
  final double rate = (taxaEfetiva ?? aliquotaEfetiva(regime, amount)).clamp(
    0,
    1,
  );
  final int reserva = (amount * rate).round();
  return ReservaResult(
    rate: rate,
    reserva: reserva,
    sobra: amount - reserva,
    pct: (rate * 100).round(),
    isMei: false,
    dasMensal: null,
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
    required this.isMei,
  });

  final double rate;
  final int reserva;
  final double lucro;
  final int effVH; // valor-hora efetivo
  final bool abaixo; // abaixo do valor-hora alvo?
  final int sugestao; // preço sugerido p/ atingir o alvo
  final Divisao divisao;

  /// MEI: nenhum imposto marginal por projeto (o DAS fixo já está no plano
  /// do mês) — a tela explica em vez de descontar % que não existe.
  final bool isMei;
}

/// Horas cobráveis/mês a partir da ROTINA real (Passo 2, v0.5). Um leigo não
/// sabe "horas faturáveis" — mas sabe quantos dias por semana trabalha e quantas
/// horas num dia normal. O app deduz, aplicando o desconto honesto do tempo
/// não-pago (e-mail, proposta, imprevisto, férias, feriados) num fator só, que a
/// pessoa NUNCA vê. Regra de segurança: na dúvida, MENOS horas (o valor-hora
/// sobe; o app existe pra provar que a pessoa cobra pouco, nunca pra baratear).
int horasFaturaveisPorRotina({
  required int diasSemana,
  required int horasDia,
  double fatorPago = 0.65,
}) {
  final double brutasMes = diasSemana * horasDia * 52 / 12;
  return (brutasMes * fatorPago).round().clamp(1, 400);
}

SimuladorResult computeSimulador(
  double valor,
  int horas,
  double custos,
  RegimeId regime,
  int alvoVH, {
  double? taxaEfetiva,
}) {
  final bool mei = regime == RegimeId.mei;
  final double rate = mei
      ? 0
      : (taxaEfetiva ?? aliquotaEfetiva(regime, valor)).clamp(0, 1);
  final int reserva = (valor * rate).round();
  final double lucro = valor - reserva - custos;
  final int effVH = horas > 0 ? (lucro / horas).round() : 0;
  final bool abaixo = horas > 0 && effVH < alvoVH;
  final int sugestao =
      (((alvoVH * horas) + custos) / (1 - rate) / 10).round() * 10;
  return SimuladorResult(
    rate: rate,
    reserva: reserva,
    lucro: lucro,
    effVH: effVH,
    abaixo: abaixo,
    sugestao: sugestao,
    isMei: mei,
    divisao: Divisao(
      lucro: math.max(0, lucro),
      reserva: reserva.toDouble(),
      custo: custos,
      base: valor,
    ),
  );
}
