/// "Como você trabalha?" → alíquota nos bastidores (Blueprint §6.9 / §7.2).
/// O usuário nunca escolhe "Anexo III" ou "carnê-leão"; escolhe como recebe.
///
/// ATENÇÃO: as alíquotas abaixo são ILUSTRATIVAS de planejamento. Precisam ser
/// validadas nas fontes oficiais da Receita antes de publicar (regra R5) e
/// revisadas ~1x/ano. O número é "estimativa/piso", nunca boleto.
enum RegimeId { mei, cpf, simples, intl }

class Regime {
  const Regime({
    required this.id,
    required this.label,
    required this.sub,
    required this.reserveRate,
    required this.tag,
  });

  final RegimeId id;
  final String label;
  final String sub;
  final double reserveRate;
  final String tag;

  static const Map<RegimeId, Regime> all = <RegimeId, Regime>{
    RegimeId.mei: Regime(
      id: RegimeId.mei,
      label: 'Sou MEI',
      sub: 'DAS fixo mensal, imposto baixo',
      reserveRate: 0.16,
      tag: 'MEI',
    ),
    RegimeId.cpf: Regime(
      id: RegimeId.cpf,
      label: 'Autônomo (CPF)',
      sub: 'Carnê-leão + INSS',
      reserveRate: 0.275,
      tag: 'Autônomo',
    ),
    RegimeId.simples: Regime(
      id: RegimeId.simples,
      label: 'Tenho empresa no Simples',
      sub: 'Alíquota por faixa',
      reserveRate: 0.12,
      tag: 'Simples',
    ),
    RegimeId.intl: Regime(
      id: RegimeId.intl,
      label: 'Não sei / cliente no exterior',
      sub: 'Reserva padrão de 25% a 30%',
      reserveRate: 0.27,
      tag: 'Internacional',
    ),
  };

  static Regime of(RegimeId id) => all[id]!;
}
