/// Cotação de câmbio cacheada localmente (offline-first). Só o par de moedas
/// ('USD->BRL') viaja pra API pública — nenhum dado do usuário sai do device.
class FxRate {
  const FxRate({
    required this.par,
    required this.taxa,
    required this.at,
    this.manual = false,
    this.stale = false,
    this.fonte,
  });

  final String par; // 'USD->BRL'
  final double taxa;

  /// Data de REFERÊNCIA da cotação: pra PTAX é o dia útil do boletim (que é
  /// anterior a hoje, de propósito); pra mercado é o momento da busca.
  final DateTime at;

  /// O usuário digitou essa taxa na mão (não veio da API).
  final bool manual;

  /// A busca falhou/está offline; essa é a última cotação conhecida.
  final bool stale;

  /// De onde veio a taxa: `'ptax'` (oficial do Banco Central, a primária) ou
  /// `'mercado'` (open.er-api, o fallback). Null em registro antigo/manual.
  final String? fonte;

  bool get ehPtax => fonte == 'ptax';

  FxRate copyWith({
    String? par,
    double? taxa,
    DateTime? at,
    bool? manual,
    bool? stale,
    String? fonte,
  }) {
    return FxRate(
      par: par ?? this.par,
      taxa: taxa ?? this.taxa,
      at: at ?? this.at,
      manual: manual ?? this.manual,
      stale: stale ?? this.stale,
      fonte: fonte ?? this.fonte,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'par': par,
    'taxa': taxa,
    'at': at.toIso8601String(),
    'manual': manual,
    'stale': stale,
    if (fonte != null) 'fonte': fonte,
  };

  factory FxRate.fromJson(Map<String, dynamic> json) => FxRate(
    par: json['par'] as String,
    taxa: (json['taxa'] as num).toDouble(),
    at: DateTime.parse(json['at'] as String),
    manual: json['manual'] as bool? ?? false,
    stale: json['stale'] as bool? ?? false,
    fonte: json['fonte'] as String?,
  );
}
