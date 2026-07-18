/// Um recebimento registrado no histórico de reservas (IA §2.12) — o gancho de
/// hábito: "quanto já guardei pro imposto este mês?".
class ReservaEntry {
  const ReservaEntry({
    required this.valor,
    required this.reserva,
    required this.regimeTag,
    required this.at,
  });

  final double valor; // quanto recebeu
  final int reserva; // quanto separar
  final String regimeTag; // MEI / Autônomo / Simples / Internacional
  final DateTime at;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'valor': valor,
        'reserva': reserva,
        'regimeTag': regimeTag,
        'at': at.toIso8601String(),
      };

  factory ReservaEntry.fromJson(Map<String, dynamic> json) => ReservaEntry(
        valor: (json['valor'] as num).toDouble(),
        reserva: (json['reserva'] as num).toInt(),
        regimeTag: json['regimeTag'] as String,
        at: DateTime.parse(json['at'] as String),
      );
}
