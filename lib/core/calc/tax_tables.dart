import 'dart:math' as math;

/// Tabelas fiscais embutidas — ano-base 2026. Fontes (validadas em 2026-07-19;
/// re-conferidas em 2026-07-23 contra gov.br/fazenda e a Lei 15.270/2025 —
/// teto INSS, faixas IRPF, redutor e DAS batem com o oficial):
/// - DAS MEI: Receita/Simples Nacional + Sebrae (salário mínimo 2026 R$ 1.621:
///   INSS 5% = R$ 81,05; serviços +R$ 5 ISS = R$ 86,05; vencimento dia 20).
/// - IRPF mensal: gov.br/receitafederal (tabelas/2026) + redutor Lei 15.270/2025
///   (isenção efetiva até R$ 5.000/mês; redução linear até R$ 7.350).
/// - INSS: teto do salário de contribuição 2026 = R$ 8.475,55 (gov.br/inss).
/// - Simples Anexo III e V: LC 123/2006 com redação da LC 155/2016 (faixas
///   nominais estáveis desde 2018). O anexo sai do Fator R (folha ÷ receita).
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

/// Teto com a tolerância de 20% (R$ 97.200). Achado da varredura (doc 16 §7.1):
/// entre R$ 81k e aqui, o MEI continua no ano, paga um DAS complementar sobre o
/// excedente e vira ME no ano seguinte; ACIMA daqui, desenquadra retroativo a
/// 1º de janeiro. São dois desfechos diferentes — daí as três zonas do teto.
const double kTetoMeiComTolerancia = kTetoAnualMei * 1.2;

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

/// A faixa progressiva em que uma [base] cai — pra a folha de detalhamento
/// mostrar QUAL faixa foi aplicada (F4). Base ≤ 0 fica na 1ª (isenta).
FaixaIrpf faixaIrpfDe(double base) {
  for (final FaixaIrpf f in kFaixasIrpfMensal) {
    if (base <= f.limite) return f;
  }
  return kFaixasIrpfMensal.last;
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

/// Imposto mensal do "carnê-leão puro": CPF que recebe de cliente no
/// exterior e paga só o IRPF progressivo (mesma tabela + redutor do CPF),
/// SEM INSS — não contribui como autônomo. Diferença do [impostoMensalCpf]:
/// a base é o rendimento CHEIO (não rendimento − INSS) e não há parcela de
/// INSS somada no fim.
double impostoCarneLeao(double rendimentoMensal) {
  if (rendimentoMensal <= 0) return 0;
  final double apurado = irpfTabela(rendimentoMensal);
  return apurado - redutorIrpf(rendimentoMensal, apurado);
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

/// Anexo V (serviços de baixo fator-mão-de-obra), 3 primeiras faixas — LC 123/2006.
/// É o anexo MAIS CARO. O prestador solo sem pró-labore suficiente cai aqui pelo
/// Fator R; assumir sempre o Anexo III (mais barato) fazia o app reservar de
/// MENOS pra ele — o pior erro num app fiscal (doc 16 §8.1).
const List<FaixaSimples> kFaixasSimplesAnexo5 = <FaixaSimples>[
  FaixaSimples(180000, 0.155, 0),
  FaixaSimples(360000, 0.18, 4500),
  FaixaSimples(720000, 0.195, 9900),
];

/// O piso do Fator R: folha 12m ÷ receita 12m ≥ 28% joga o prestador de
/// serviços no Anexo III (mais barato); abaixo, no Anexo V (mais caro).
const double kFatorRLimite = 0.28;

/// O Fator R (folha ÷ receita) a partir dos valores MENSAIS — o ×12 de cima e de
/// baixo se cancela, então a razão mensal já é a anual. Folha = pró-labore + 
/// salários de funcionários (no solo, só o pró-labore).
double fatorR(double folhaMensal, double faturamentoMensal) {
  if (faturamentoMensal <= 0) return 0;
  return folhaMensal / faturamentoMensal;
}

/// Verdadeiro quando o Fator R coloca o prestador no Anexo III (folha alta).
/// Sem pró-labore declarado (0) → falso → Anexo V, a estimativa conservadora:
/// na dúvida, reserva MAIS, nunca menos.
bool simplesEhAnexo3(double folhaMensal, double faturamentoMensal) =>
    fatorR(folhaMensal, faturamentoMensal) >= kFatorRLimite;

/// A faixa em que uma receita anual ([rbt12]) cai, no anexo escolhido pelo Fator
/// R ([anexo3]) — pra a folha de detalhamento nomear a faixa (F4). Acima da
/// última, mantém a 3ª (a mesma convenção de estimativa de [aliquotaEfetivaSimples]).
FaixaSimples faixaSimplesDe(double rbt12, {bool anexo3 = false}) {
  final List<FaixaSimples> anexo = anexo3
      ? kFaixasSimplesAnexo3
      : kFaixasSimplesAnexo5;
  for (final FaixaSimples f in anexo) {
    if (rbt12 <= f.limiteRbt12) return f;
  }
  return anexo.last;
}

/// Alíquota EFETIVA do Simples a partir do faturamento mensal, escolhendo o
/// anexo pelo Fator R da [folhaMensal] (Anexo III se folha ≥ 28% da receita;
/// Anexo V caso contrário). RBT12 estimado = mensal × 12. Acima da 3ª faixa,
/// mantém a efetiva da 3ª (estimativa). Sem folha → Anexo V (conservador).
double aliquotaEfetivaSimples(
  double faturamentoMensal, {
  double folhaMensal = 0,
}) {
  final double rbt12 = math.max(0, faturamentoMensal) * 12;
  final List<FaixaSimples> anexo =
      simplesEhAnexo3(folhaMensal, faturamentoMensal)
      ? kFaixasSimplesAnexo3
      : kFaixasSimplesAnexo5;
  if (rbt12 <= 0) return anexo.first.aliquotaNominal;
  FaixaSimples faixa = anexo.last;
  for (final FaixaSimples f in anexo) {
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
