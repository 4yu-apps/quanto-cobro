/// Uma **entrada**: dinheiro que caiu, e quanto dele foi separado pro imposto.
///
/// É o objeto do hábito — o único que a pessoa cria toda semana. Cadastrar a
/// entrada É o registro do recebimento: não existe um segundo passo de
/// "confirmar que recebi".
class Entrada {
  const Entrada({
    required this.valor,
    required this.separado,
    required this.regimeTag,
    required this.at,
    this.areaId,
    this.trabalhoId,
    this.moedaOrigem,
    this.taxa,
  });

  /// Quanto entrou (já em reais, convertido se veio em outra moeda).
  final double valor;

  /// Código ISO da moeda ORIGINAL do recebimento ('USD', 'EUR'…), quando não
  /// foi em real. Null = recebido em BRL. Guardado só pra rastreabilidade e
  /// histórico; o [valor] já está convertido pra reais.
  final String? moedaOrigem;

  /// A taxa de câmbio usada na conversão (ex.: 5,50 pra USD→BRL). Null quando
  /// foi em real. Junto de [moedaOrigem] deixa a conta auditável depois.
  final double? taxa;

  /// Quanto foi separado pro imposto.
  final int separado;

  /// MEI / Autônomo / Simples / Internacional — o regime **no momento do
  /// registro**. Guardado junto de propósito: se a pessoa mudar de regime, o
  /// histórico continua contando a verdade de quando aconteceu.
  final String regimeTag;

  final DateTime at;

  /// Área a que a entrada pertence (null em registro antigo).
  final String? areaId;

  /// Trabalho que pagou. Null quando foi um recebimento avulso, que não está
  /// ligado a nenhum trabalho da lista.
  final String? trabalhoId;

  /// Só serve pra LIGAR depois uma entrada avulsa a um trabalho (histórico):
  /// os campos só sobrescrevem, nunca limpam — passar null mantém o valor.
  Entrada copyWith({String? areaId, String? trabalhoId}) => Entrada(
    valor: valor,
    separado: separado,
    regimeTag: regimeTag,
    at: at,
    areaId: areaId ?? this.areaId,
    trabalhoId: trabalhoId ?? this.trabalhoId,
    moedaOrigem: moedaOrigem,
    taxa: taxa,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'valor': valor,
    'separado': separado,
    'regimeTag': regimeTag,
    'at': at.toIso8601String(),
    if (areaId != null) 'areaId': areaId,
    if (trabalhoId != null) 'trabalhoId': trabalhoId,
    if (moedaOrigem != null) 'moedaOrigem': moedaOrigem,
    if (taxa != null) 'taxa': taxa,
  };

  factory Entrada.fromJson(Map<String, dynamic> json) => Entrada(
    valor: (json['valor'] as num).toDouble(),
    // `reserva` é o nome antigo do campo — lido pra não perder histórico de
    // quem já usava o app antes do renome.
    separado: ((json['separado'] ?? json['reserva']) as num).toInt(),
    regimeTag: json['regimeTag'] as String? ?? '',
    at: DateTime.parse(json['at'] as String),
    areaId: (json['areaId'] ?? json['perfilId']) as String?,
    trabalhoId: (json['trabalhoId'] ?? json['projetoId']) as String?,
    moedaOrigem: json['moedaOrigem'] as String?,
    taxa: (json['taxa'] as num?)?.toDouble(),
  );
}
