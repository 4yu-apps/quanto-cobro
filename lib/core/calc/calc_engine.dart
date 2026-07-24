import 'dart:math' as math;

import '../model/area.dart';
import '../model/custo.dart';
import '../model/regime.dart';
import 'tax_tables.dart';

/// O pró-labore mensal que a pessoa declarou como custo (o "salário" que tira da
/// empresa). É a folha do Fator R (F6): decide se o Simples cai no Anexo III ou
/// V. Mesmo número, dois papéis — custo do negócio E folha —, sem duplicar nada.
/// Sem o custo declarado: 0 → Anexo V (a estimativa conservadora).
double proLaboreDe(Area p) {
  for (final Custo c in p.custos) {
    if (c.id == 'prolabore') return c.valor;
  }
  return 0;
}

/// Motor de cálculo — PURO e testável. É a conta que sustenta a confiança do
/// app; dinheiro errado destrói o diferencial. v0.4: modelo fiscal honesto por
/// regime (MEI = DAS fixo; CPF = IRPF progressivo + INSS; Simples = faixa
/// efetiva do Anexo III). Ver testes em test/calc_engine_test.dart.

/// Imposto mensal estimado do regime para um dado faturamento mensal.
/// [proLaboreMensal] só pesa no Simples (escolhe o anexo pelo Fator R, F6);
/// nos outros regimes é ignorado.
double impostoMensal(
  RegimeId regime,
  double faturamentoMensal, {
  double proLaboreMensal = 0,
}) {
  switch (Regime.of(regime).kind) {
    case TaxKind.fixoMensal:
      return kDasMensalMei;
    case TaxKind.progressivo:
      return impostoMensalCpf(faturamentoMensal);
    case TaxKind.progressivoSemInss:
      return impostoCarneLeao(faturamentoMensal);
    case TaxKind.faixasSimples:
      return faturamentoMensal *
          aliquotaEfetivaSimples(
            faturamentoMensal,
            proLaboreMensal: proLaboreMensal,
          );
    case TaxKind.flat:
      return faturamentoMensal * kFlatIntl;
  }
}

/// Alíquota efetiva (imposto ÷ faturamento) do regime num faturamento mensal.
double aliquotaEfetiva(
  RegimeId regime,
  double faturamentoMensal, {
  double proLaboreMensal = 0,
}) {
  if (faturamentoMensal <= 0) return 0;
  return (impostoMensal(
            regime,
            faturamentoMensal,
            proLaboreMensal: proLaboreMensal,
          ) /
          faturamentoMensal)
      .clamp(0, 1);
}

/// Raio-x do imposto de um mês (F4 — o detalhamento Pro). PURO: só números,
/// a folha de UI é quem monta as linhas e formata. Reproduz, peça a peça, o
/// mesmo [impostoMensal] que o resto do app usa — [imposto] fecha com ele.
///
/// Campos por regime:
/// - CPF (progressivo): [inss] + [irpf]; [baseIrpf] = faturamento − INSS.
/// - Carnê-leão (sem INSS): só [irpf]; [inss] = 0, [baseIrpf] = faturamento.
/// - Simples: [rbt12], [simplesNominal] e [simplesDeducao] descrevem a faixa.
/// - MEI/intl: só [imposto]/[efetiva] (a folha não abre pra eles).
class ImpostoDetalhe {
  const ImpostoDetalhe({
    required this.regime,
    required this.faturamento,
    required this.imposto,
    required this.efetiva,
    this.inss = 0,
    this.baseIrpf = 0,
    this.faixaAliquota = 0,
    this.deducaoFaixa = 0,
    this.irpfBruto = 0,
    this.redutor = 0,
    this.irpf = 0,
    this.rbt12 = 0,
    this.simplesNominal = 0,
    this.simplesDeducao = 0,
    this.simplesAnexo3 = false,
    this.fatorR = 0,
  });

  final RegimeId regime;

  /// O faturamento do mês sobre o qual o imposto incide (já com gross-up).
  final double faturamento;

  /// Imposto total do mês — fecha com [impostoMensal].
  final double imposto;

  /// Alíquota efetiva (imposto ÷ faturamento), 0..1.
  final double efetiva;

  // --- CPF / carnê-leão ---
  final double inss; // 0 no carnê-leão
  final double baseIrpf; // base sobre a qual o IRPF incide
  final double faixaAliquota; // alíquota nominal da faixa IRPF (0..1)
  final double deducaoFaixa; // parcela a deduzir da faixa IRPF
  final double irpfBruto; // baseIrpf × faixaAliquota (antes das deduções)
  final double redutor; // desconto da Lei 15.270/2025
  final double irpf; // IRPF final (após parcela a deduzir e redutor)

  // --- Simples ---
  final double rbt12; // receita bruta 12m estimada
  final double simplesNominal; // alíquota nominal da faixa (0..1)
  final double simplesDeducao; // parcela a deduzir da faixa (anual)
  final bool simplesAnexo3; // Fator R jogou no Anexo III (true) ou V (false)
  final double fatorR; // folha ÷ receita (0..1), a razão que escolheu o anexo

  /// Verdadeiro quando a renda do mês não gera IRPF (faixa isenta / redutor
  /// cobre tudo) — a folha mostra "só INSS" em vez de uma linha zerada.
  bool get semIrpf => irpf <= 0.005;
}

/// Abre o imposto do mês em peças (F4). [faturamentoMensal] é a base já com
/// gross-up (o `ValorHoraResult.faturamento` / o valor do pagamento).
/// [proLaboreMensal] escolhe o anexo do Simples pelo Fator R (F6).
ImpostoDetalhe detalharImposto(
  RegimeId regime,
  double faturamentoMensal, {
  double proLaboreMensal = 0,
}) {
  final double f = math.max(0, faturamentoMensal);
  final double total = impostoMensal(regime, f, proLaboreMensal: proLaboreMensal);
  final double efetiva = f > 0 ? (total / f).clamp(0, 1) : 0;

  switch (Regime.of(regime).kind) {
    case TaxKind.progressivo: // CPF: INSS + IRPF sobre (f − INSS)
      final double inss = inssIndividual(f);
      final double base = math.max(0, f - inss);
      final FaixaIrpf faixa = faixaIrpfDe(base);
      final double apurado = irpfTabela(base);
      final double redutor = redutorIrpf(f, apurado);
      return ImpostoDetalhe(
        regime: regime,
        faturamento: f,
        imposto: total,
        efetiva: efetiva,
        inss: inss,
        baseIrpf: base,
        faixaAliquota: faixa.aliquota,
        deducaoFaixa: faixa.deducao,
        irpfBruto: base * faixa.aliquota,
        redutor: redutor,
        irpf: math.max(0, apurado - redutor),
      );
    case TaxKind.progressivoSemInss: // carnê-leão: só IRPF sobre f cheio
      final FaixaIrpf faixa = faixaIrpfDe(f);
      final double apurado = irpfTabela(f);
      final double redutor = redutorIrpf(f, apurado);
      return ImpostoDetalhe(
        regime: regime,
        faturamento: f,
        imposto: total,
        efetiva: efetiva,
        baseIrpf: f,
        faixaAliquota: faixa.aliquota,
        deducaoFaixa: faixa.deducao,
        irpfBruto: f * faixa.aliquota,
        redutor: redutor,
        irpf: math.max(0, apurado - redutor),
      );
    case TaxKind.faixasSimples: // Simples: efetiva por faixa, anexo pelo Fator R
      final double rbt12 = f * 12;
      final bool anexo3 = simplesEhAnexo3(proLaboreMensal, f);
      final FaixaSimples faixa = faixaSimplesDe(rbt12, anexo3: anexo3);
      return ImpostoDetalhe(
        regime: regime,
        faturamento: f,
        imposto: total,
        efetiva: efetiva,
        rbt12: rbt12,
        simplesNominal: faixa.aliquotaNominal,
        simplesDeducao: faixa.deducao,
        simplesAnexo3: anexo3,
        fatorR: fatorR(proLaboreMensal, f),
      );
    case TaxKind.fixoMensal: // MEI: DAS fixo (folha não abre)
    case TaxKind.flat: // intl: regra de bolso (folha não abre)
      return ImpostoDetalhe(
        regime: regime,
        faturamento: f,
        imposto: total,
        efetiva: efetiva,
      );
  }
}

/// As três zonas do teto do MEI (F5, achado da varredura — doc 16 §7.1). Não é
/// uma barra até 81k: passar do teto tem DOIS desfechos, e o medo do MEI é não
/// saber em qual está.
enum ZonaTeto {
  /// Abaixo de R$ 81k — tranquilo.
  verde,

  /// R$ 81k–97,2k — excesso tolerado: DAS complementar + vira ME ano que vem.
  amarela,

  /// Acima de R$ 97,2k — desenquadramento retroativo a 1º de janeiro.
  vermelha,
}

/// Onde o MEI está em relação ao teto do ano, e pra onde caminha (F5). PURO: a
/// projeção é linear simples (ritmo × 12), com selo de estimativa na UI — é
/// planejamento, nunca a conta oficial.
class TetoMei {
  const TetoMei({
    required this.faturado,
    required this.zona,
    required this.restante,
    required this.excedente,
    required this.ritmoMensal,
    required this.projecaoAno,
    required this.mesEncosta,
  });

  final double faturado;
  final ZonaTeto zona;

  /// Quanto falta pra encostar em R$ 81k (0 quando já passou).
  final double restante;

  /// Quanto já passou de R$ 81k (0 quando ainda dentro).
  final double excedente;

  final double ritmoMensal;

  /// Faturamento projetado pro fim do ano, no ritmo atual.
  final double projecaoAno;

  /// Mês (1..12) em que, no ritmo atual, o faturado encosta em R$ 81k — null se
  /// já encostou, se o ritmo é zero, ou se não encosta dentro do ano.
  final int? mesEncosta;
}

/// Avalia o teto do MEI a partir do [faturado] no ano e do [mesAtual] (1..12,
/// os meses decorridos — base do ritmo linear).
TetoMei avaliarTetoMei({required double faturado, required int mesAtual}) {
  final double f = math.max(0, faturado);
  final ZonaTeto zona = f <= kTetoAnualMei
      ? ZonaTeto.verde
      : (f <= kTetoMeiComTolerancia ? ZonaTeto.amarela : ZonaTeto.vermelha);
  final int meses = mesAtual.clamp(1, 12);
  final double ritmo = f / meses;
  int? mesEncosta;
  if (f < kTetoAnualMei && ritmo > 0) {
    final double alvo = meses + (kTetoAnualMei - f) / ritmo;
    if (alvo <= 12.5) mesEncosta = alvo.round().clamp(meses, 12);
  }
  return TetoMei(
    faturado: f,
    zona: zona,
    restante: math.max(0, kTetoAnualMei - f),
    excedente: math.max(0, f - kTetoAnualMei),
    ritmoMensal: ritmo,
    projecaoAno: ritmo * 12,
    mesEncosta: mesEncosta,
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

/// O valor-hora de uma [Area], no [regime] da PESSOA.
///
/// O regime entra por parâmetro (e não dentro da área) porque ele é de quem
/// trabalha, não do tipo de trabalho: duas áreas não geram dois DAS.
ValorHoraResult computeValorHora(Area p, RegimeId regime) {
  final double provisao = p.provisaoOn ? p.provisaoEfetiva : 0;
  final double custos = p.custosTotal;
  final double base = p.renda + custos + provisao;
  // Folha do Fator R (só o Simples usa): o pró-labore declarado como custo.
  final double proLabore = proLaboreDe(p);

  // Gross-up: f = base + imposto(f). Para MEI é soma direta; para taxas
  // progressivas, ponto-fixo (marginal < 50% ⇒ converge rápido; 8 iterações
  // dão erro < 0,3%).
  double faturamento = base;
  for (int i = 0; i < 8; i++) {
    faturamento = base +
        impostoMensal(regime, faturamento, proLaboreMensal: proLabore);
  }
  final double imposto = faturamento - base;
  final double rate = faturamento > 0 ? imposto / faturamento : 0;
  final double valorHora = faturamento / math.max(1, p.horas);
  final bool mei = regime == RegimeId.mei;

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

Divisao divisaoFromArea(Area p, ValorHoraResult c) => Divisao(
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
    required this.separado,
    required this.sobra,
    required this.pct,
    required this.isMei,
    required this.dasMensal,
    this.impostoDoMesQuitado = false,
  });

  final double rate;

  /// Quanto separar deste pagamento pro imposto.
  final int separado;
  final double sobra;
  final int pct;
  final bool isMei;
  final double? dasMensal;

  /// MEI: o DAS deste mês já foi separado inteiro em pagamentos anteriores,
  /// então deste aqui não sai nada. Só o MEI tem esse estado — nos outros
  /// regimes o imposto é fatia de CADA pagamento e nunca "acaba".
  final bool impostoDoMesQuitado;
}

/// [taxaEfetiva] (0..1) vem do perfil ativo quando o regime bate com o dele —
/// a alíquota da RENDA PLANEJADA do mês, não do pagamento avulso. Sem perfil,
/// estima pela efetiva do próprio valor (melhor aproximação disponível).
///
/// [dasJaSeparado] (só MEI) é quanto do DAS deste mês já saiu em pagamentos
/// anteriores. Existe porque o DAS é um boleto ÚNICO do mês, não uma fatia de
/// cada pagamento: sem esse desconto, quem recebe de três clientes no mesmo mês
/// separaria três DAS — e era pra fugir disso que a tela travava depois do
/// primeiro registro, impedindo a pessoa de anotar o segundo pagamento.
///
/// Reservar o DAS INTEIRO no primeiro pagamento (em vez de ratear por
/// percentual) é deliberado: o boleto vence mesmo que o mês seja fraco, e o
/// erro que dói é chegar no vencimento sem o dinheiro separado.
ReservaResult computeReserva(
  double amount,
  RegimeId regime, {
  double? taxaEfetiva,
  double dasJaSeparado = 0,
}) {
  if (regime == RegimeId.mei) {
    final double falta = math.max(0, kDasMensalMei - dasJaSeparado);
    final int separado = math.min(amount, falta).round();
    return ReservaResult(
      rate: amount > 0 ? separado / amount : 0,
      separado: separado,
      sobra: amount - separado,
      pct: 0,
      isMei: true,
      dasMensal: kDasMensalMei,
      impostoDoMesQuitado: falta <= 0,
    );
  }
  final double rate = (taxaEfetiva ?? aliquotaEfetiva(regime, amount)).clamp(
    0,
    1,
  );
  final int separado = (amount * rate).round();
  return ReservaResult(
    rate: rate,
    separado: separado,
    sobra: amount - separado,
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
