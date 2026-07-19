/// Moeda suportada pra cálculo/exibição (Fase 3 — freelas com cliente
/// estrangeiro, ex. Marina cobrando em USD). Curada, não livre: só as moedas
/// que a 4YU decidiu suportar aparecem em [curadas].
class Moeda {
  const Moeda({
    required this.codigo,
    required this.simbolo,
    required this.casas,
    required this.locale,
  });

  final String codigo; // ISO: 'BRL','USD','EUR','GBP'
  final String simbolo; // 'R$','US$','€','£'
  final int casas; // casas decimais na exibição
  final String locale; // locale do intl: 'pt_BR','en_US',...

  static const Moeda brl = Moeda(
    codigo: 'BRL',
    simbolo: r'R$',
    casas: 0,
    locale: 'pt_BR',
  );
  static const Moeda usd = Moeda(
    codigo: 'USD',
    simbolo: r'US$',
    casas: 2,
    locale: 'en_US',
  );
  static const Moeda eur = Moeda(
    codigo: 'EUR',
    simbolo: '€',
    casas: 2,
    locale: 'en_US',
  );
  static const Moeda gbp = Moeda(
    codigo: 'GBP',
    simbolo: '£',
    casas: 2,
    locale: 'en_GB',
  );

  static const List<Moeda> curadas = <Moeda>[brl, usd, eur, gbp];

  /// Busca por código ISO; cai pra BRL se não achar (nunca quebra a tela).
  static Moeda byCodigo(String codigo) =>
      curadas.firstWhere((Moeda m) => m.codigo == codigo, orElse: () => brl);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'codigo': codigo,
    'simbolo': simbolo,
    'casas': casas,
    'locale': locale,
  };

  factory Moeda.fromJson(Map<String, dynamic> json) => Moeda(
    codigo: json['codigo'] as String? ?? 'BRL',
    simbolo: json['simbolo'] as String? ?? r'R$',
    casas: (json['casas'] as num?)?.toInt() ?? 0,
    locale: json['locale'] as String? ?? 'pt_BR',
  );
}
