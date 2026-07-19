import 'dart:math' as math;

/// Tabelas fiscais embutidas — ano-base 2026. Fontes (validadas em 2026-07-19):
/// - DAS MEI: Receita/Simples Nacional + Sebrae (salário mínimo 2026 R$ 1.621:
///   INSS 5% = R$ 81,05; serviços +R$ 5 ISS = R$ 86,05; vencimento dia 20).
/// - IRPF mensal: gov.br/receitafederal (tabelas/2026) + redutor Lei 15.270/2025
///   (isenção efetiva até R$ 5.000/mês; redução linear até R$ 7.350).
/// - INSS: teto do salário de contribuição 2026 = R$ 8.475,55 (gov.br/inss).
/// - Simples Anexo III: LC 123/2006 com redação da LC 155/2016 (faixas nominais
///   estáveis desde 2018).
/// Revisar ~1x/ano (regra R5). O número é "estimativa/piso", nunca boleto.
const int kTabelasAno = 2026;

/// Verdadeiro quando as tabelas embutidas estão defasadas em relação ao ano atual.
bool tabelasDefasadas(DateTime agora) => agora.year > kTabelasAno;

// ---------------------------------------------------------------------------
// MEI
// ---------------------------------------------------------------------------

/// DAS mensal do MEI prestador de serviços (INSS 5% do mínimo + R$ 5 de ISS).
const double kDasMensalMei = 86.05;

/// Dia do mês em que o DAS vence.
const int kDasVencimentoDia = 20;

/// Teto de faturamento anual do MEI (estável desde 2018).
const double kTetoAnualMei = 81000;

/// Teto mensal proporcional (81.000 / 12).
const double kTetoMensalMei = kTetoAnualMei / 12;

// ---------------------------------------------------------------------------
// IRPF mensal (carnê-leão) — tabela progressiva 2026 + redutor Lei 15.270/2025
// ---------------------------------------------------------------------------

/// Faixa da tabela progressiva mensal: limite superior da base, alíquota e
/// parcela a deduzir.
class FaixaIrpf {
  const FaixaIrpf(this.limite, this.aliquota, this.deducao);

  final double limite;
  final double aliquota;
  final double deducao;
}

const List<FaixaIrpf> kFaixasIrpfMensal = <FaixaIrpf>[
  FaixaIrpf(2428.80, 0.0, 0.0),
  FaixaIrpf(2826.65, 0.075, 182.16),
  FaixaIrpf(3751.05, 0.15, 394.16),
  FaixaIrpf(4664.68, 0.225, 675.49),
  FaixaIrpf(double.infinity, 0.275, 908.73),
];

/// Imposto pela tabela progressiva mensal sobre a base de cálculo.
double irpfTabela(double base) {
  if (base <= 0) return 0;
  for (final FaixaIrpf f in kFaixasIrpfMensal) {
    if (base <= f.limite) return math.max(0, base * f.aliquota - f.deducao);
  }
  return 0; // inalcançável (última faixa é infinita)
}

/// Redutor da Lei 15.270/2025 sobre o imposto mensal, em função do RENDIMENTO
/// tributável (não da base pós-deduções): zera o imposto até R$ 5.000/mês
/// (limite de R$ 312,89) e decresce linearmente até R$ 7.350.
double redutorIrpf(double rendimentoMensal, double impostoApurado) {
  if (impostoApurado <= 0) return 0;
  final double redutor;
  if (rendimentoMensal <= 5000) {
    redutor = 312.89;
  } else if (rendimentoMensal <= 7350) {
    redutor = 978.62 - 0.133145 * rendimentoMensal;
  } else {
    redutor = 0;
  }
  return redutor.clamp(0, impostoApurado);
}

// ---------------------------------------------------------------------------
// INSS — contribuinte individual (autônomo/CPF)
// ---------------------------------------------------------------------------

/// Alíquota do contribuinte individual sobre o salário de contribuição.
const double kInssAliquotaIndividual = 0.20;

/// Teto do salário de contribuição 2026.
const double kInssTeto = 8475.55;

/// Contribuição mensal do contribuinte individual (20% até o teto).
double inssIndividual(double rendimentoMensal) {
  if (rendimentoMensal <= 0) return 0;
  return kInssAliquotaIndividual * math.min(rendimentoMensal, kInssTeto);
}

/// Imposto mensal total do autônomo CPF: INSS (dedutível) + IRPF com redutor.
/// Estimativa de planejamento: assume todo o recebimento como rendimento
/// tributável do mês (sem livro-caixa/dependentes).
double impostoMensalCpf(double rendimentoMensal) {
  if (rendimentoMensal <= 0) return 0;
  final double inss = inssIndividual(rendimentoMensal);
  final double base = math.max(0, rendimentoMensal - inss);
  final double apurado = irpfTabela(base);
  final double irpf = apurado - redutorIrpf(rendimentoMensal, apurado);
  return inss + irpf;
}

// ---------------------------------------------------------------------------
// Simples Nacional — Anexo III (serviços), 3 primeiras faixas
// ---------------------------------------------------------------------------

/// Faixa do Anexo III: limite de receita bruta 12 meses, alíquota nominal e
/// parcela a deduzir (anuais).
class FaixaSimples {
  const FaixaSimples(this.limiteRbt12, this.aliquotaNominal, this.deducao);

  final double limiteRbt12;
  final double aliquotaNominal;
  final double deducao;
}

const List<FaixaSimples> kFaixasSimplesAnexo3 = <FaixaSimples>[
  FaixaSimples(180000, 0.06, 0),
  FaixaSimples(360000, 0.112, 9360),
  FaixaSimples(720000, 0.135, 17640),
];

/// Alíquota EFETIVA do Simples (Anexo III) a partir do faturamento mensal.
/// RBT12 estimado = mensal × 12. Assunção declarada na UI: Anexo III, sem
/// Fator R/Anexo V. Acima da 3ª faixa, mantém a efetiva da 3ª (estimativa).
double aliquotaEfetivaSimples(double faturamentoMensal) {
  final double rbt12 = math.max(0, faturamentoMensal) * 12;
  if (rbt12 <= 0) return kFaixasSimplesAnexo3.first.aliquotaNominal;
  FaixaSimples faixa = kFaixasSimplesAnexo3.last;
  for (final FaixaSimples f in kFaixasSimplesAnexo3) {
    if (rbt12 <= f.limiteRbt12) {
      faixa = f;
      break;
    }
  }
  final double efetiva =
      (rbt12 * faixa.aliquotaNominal - faixa.deducao) / rbt12;
  return efetiva.clamp(0, faixa.aliquotaNominal);
}

// ---------------------------------------------------------------------------
// Internacional / não sei — regra de bolso honesta
// ---------------------------------------------------------------------------

/// Reserva de segurança pra quem recebe do exterior ou ainda não sabe o regime.
const double kFlatIntl = 0.27;
