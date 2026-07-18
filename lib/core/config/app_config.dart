/// ÚNICO lugar do nome de exibição e flags globais.
///
/// O nome é PROVISÓRIO e trocável: nunca hardcodar "Quanto Cobro?" espalhado.
/// Trocar [appName] aqui reflete no app inteiro, de uma vez. O identificador
/// técnico (bundle id `com.fouryuapps.quantocobro`) é FIXO, vive no Android/iOS
/// e é desacoplado deste nome — trocar o nome comercial depois não quebra nada.
abstract final class AppConfig {
  /// Nome exibido ao usuário. Trocar aqui reflete no app inteiro.
  static const String appName = 'Quanto Cobro?';

  /// Nome curto (header/espaços apertados).
  static const String appNameShort = 'Quanto Cobro?';

  /// Tagline principal (espelha as 3 respostas).
  static const String tagline = 'Quanto cobrar, quanto guardar, quanto sobra.';

  /// Selo da marca-mãe (só tela Sobre/marketing — nunca na UI funcional).
  static const String parentBrand = '4YU';

  /// Contato público de suporte/privacidade (alias que cai em contato@).
  static const String contactEmail = 'sac@4yu.com.br';

  /// Id do app na Play Store (deep link de avaliar/compartilhar). FIXO.
  static const String androidPackage = 'com.fouryuapps.quantocobro';

  /// Host das páginas públicas (política, termos).
  static const String webHost = '4yu.com.br';
  static const String webBasePath = '/quanto-cobro';
}
