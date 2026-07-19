/// "Como você trabalha?" → modelo de imposto nos bastidores (Blueprint §6.9 / §7.2).
/// O usuário nunca escolhe "Anexo III" ou "carnê-leão"; escolhe como recebe.
///
/// Cada regime tem um MODELO, não uma alíquota chapada (v0.4):
/// - MEI: DAS fixo mensal (não é % do faturamento) + teto anual.
/// - CPF: carnê-leão progressivo (IRPF 2026 com redutor) + INSS individual.
/// - Simples: alíquota efetiva por faixa do Anexo III.
/// - Internacional: regra de bolso flat (reserva de segurança).
/// As tabelas vivem em `tax_tables.dart` (ano-base lá; revisar ~1x/ano, regra R5).
enum RegimeId { mei, cpf, simples, intl }

/// Como o imposto do regime é calculado.
enum TaxKind { fixoMensal, progressivo, faixasSimples, flat }

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
      sub: 'DAS fixo mensal — não é % do que você fatura',
      kind: TaxKind.fixoMensal,
      tag: 'MEI',
    ),
    RegimeId.cpf: Regime(
      id: RegimeId.cpf,
      label: 'Autônomo (CPF)',
      sub: 'Carnê-leão + INSS, pela sua faixa de renda',
      kind: TaxKind.progressivo,
      tag: 'Autônomo',
    ),
    RegimeId.simples: Regime(
      id: RegimeId.simples,
      label: 'Tenho empresa no Simples',
      sub: 'Alíquota efetiva pela sua faixa',
      kind: TaxKind.faixasSimples,
      tag: 'Simples',
    ),
    RegimeId.intl: Regime(
      id: RegimeId.intl,
      label: 'Não sei / cliente no exterior',
      sub: 'Reserva de segurança de 25% a 30%',
      kind: TaxKind.flat,
      tag: 'Internacional',
    ),
  };

  static Regime of(RegimeId id) => all[id]!;
}
