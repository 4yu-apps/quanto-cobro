/// Cotação de câmbio cacheada localmente (offline-first). Só o par de moedas
/// ('USD->BRL') viaja pra API pública — nenhum dado do usuário sai do device.
class FxRate {
  const FxRate({
    required this.par,
    required this.taxa,
    required this.at,
    this.manual = false,
    this.stale = false,
  });

  final String par; // 'USD->BRL'
  final double taxa;
  final DateTime at;

  /// O usuário digitou essa taxa na mão (não veio da API).
  final bool manual;

  /// A busca falhou/está offline; essa é a última cotação conhecida.
  final bool stale;

  FxRate copyWith({
    String? par,
    double? taxa,
    DateTime? at,
    bool? manual,
    bool? stale,
  }) {
    return FxRate(
      par: par ?? this.par,
      taxa: taxa ?? this.taxa,
      at: at ?? this.at,
      manual: manual ?? this.manual,
      stale: stale ?? this.stale,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'par': par,
    'taxa': taxa,
    'at': at.toIso8601String(),
    'manual': manual,
    'stale': stale,
  };

  factory FxRate.fromJson(Map<String, dynamic> json) => FxRate(
    par: json['par'] as String,
    taxa: (json['taxa'] as num).toDouble(),
    at: DateTime.parse(json['at'] as String),
    manual: json['manual'] as bool? ?? false,
    stale: json['stale'] as bool? ?? false,
  );
}
