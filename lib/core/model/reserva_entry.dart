/// Um recebimento registrado no histórico de reservas (IA §2.12) — o gancho de
/// hábito: "quanto já guardei pro imposto este mês?".
class ReservaEntry {
  const ReservaEntry({
    required this.valor,
    required this.reserva,
    required this.regimeTag,
    required this.at,
    this.perfilId,
    this.tipo = 'pct',
  });

  final double valor; // quanto recebeu
  final int reserva; // quanto separar
  final String regimeTag; // MEI / Autônomo / Simples / Internacional
  final DateTime at;

  /// Trabalho a que o registro pertence (null em registros antigos).
  final String? perfilId;

  /// 'pct' = reserva percentual por pagamento · 'das' = DAS do mês separado (MEI).
  final String tipo;

  bool get isDas => tipo == 'das';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'valor': valor,
    'reserva': reserva,
    'regimeTag': regimeTag,
    'at': at.toIso8601String(),
    if (perfilId != null) 'perfilId': perfilId,
    'tipo': tipo,
  };

  factory ReservaEntry.fromJson(Map<String, dynamic> json) => ReservaEntry(
    valor: (json['valor'] as num).toDouble(),
    reserva: (json['reserva'] as num).toInt(),
    regimeTag: json['regimeTag'] as String,
    at: DateTime.parse(json['at'] as String),
    perfilId: json['perfilId'] as String?,
    tipo: json['tipo'] as String? ?? 'pct',
  );
}
