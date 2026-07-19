/// "Como você trabalha?" → modelo de imposto nos bastidores (Blueprint §6.9 / §7.2).
/// O usuário nunca escolhe "Anexo III" ou "carnê-leão"; escolhe como recebe.
///
/// Cada regime tem um MODELO, não uma alíquota chapada (v0.4):
/// - MEI: DAS fixo mensal (não é % do faturamento) + teto anual.
/// - CPF: carnê-leão progressivo (IRPF 2026 com redutor) + INSS individual.
/// - Simples: alíquota efetiva por faixa do Anexo III.
/// - Internacional: regra de bolso flat (reserva de segurança).
/// - Carnê-leão puro: mesmo IRPF progressivo (tabela + redutor) do CPF, mas
///   SEM INSS — CPF que recebe de cliente no exterior e não contribui como
///   autônomo (Fase 3).
/// As tabelas vivem em `tax_tables.dart` (ano-base lá; revisar ~1x/ano, regra R5).
enum RegimeId { mei, cpf, simples, intl, carneLeao }

/// Como o imposto do regime é calculado.
enum TaxKind { fixoMensal, progressivo, faixasSimples, flat, progressivoSemInss }

class Regime {
  const Regime({
    required this.id,
    required this.label,
    required this.sub,
    required this.kind,
    required this.tag,
  });

  final RegimeId id;
  final String label;
  final String sub;
  final TaxKind kind;
  final String tag;

  static const Map<RegimeId, Regime> all = <RegimeId, Regime>{
    RegimeId.mei: Regime(
      id: RegimeId.mei,
      label: 'Sou MEI',
      sub: 'Você abriu MEI: paga o DAS (boleto fixo mensal), não uma % do que fatura.',
      kind: TaxKind.fixoMensal,
      tag: 'MEI',
    ),
    RegimeId.cpf: Regime(
      id: RegimeId.cpf,
      label: 'Autônomo (CPF)',
      sub: 'Você trabalha por conta, sem abrir empresa. Imposto pela sua faixa de renda + INSS.',
      kind: TaxKind.progressivo,
      tag: 'Autônomo',
    ),
    RegimeId.simples: Regime(
      id: RegimeId.simples,
      label: 'Tenho empresa no Simples',
      sub: 'Você tem empresa no Simples Nacional. Alíquota efetiva pela sua faixa.',
      kind: TaxKind.faixasSimples,
      tag: 'Simples',
    ),
    RegimeId.intl: Regime(
      id: RegimeId.intl,
      label: 'Não sei / cliente no exterior',
      sub: 'Não faz ideia, ou recebe de fora? Guarda uma reserva de segurança de 25% a 30%.',
      kind: TaxKind.flat,
      tag: 'Internacional',
    ),
    RegimeId.carneLeao: Regime(
      id: RegimeId.carneLeao,
      label: 'Recebo de fora, sei que sou CPF',
      sub: 'Freelancer com cliente no exterior, como pessoa física. Paga só o IRPF pela sua faixa (carnê-leão) — sem INSS, porque não contribui como autônomo.',
      kind: TaxKind.progressivoSemInss,
      tag: 'CPF exterior',
    ),
  };

  static Regime of(RegimeId id) => all[id]!;
}
