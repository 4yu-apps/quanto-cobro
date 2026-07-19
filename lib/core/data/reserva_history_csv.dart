import '../model/reserva_entry.dart';

/// CSV do histórico "Guardado" — export Pro, puro Dart (zero dependência
/// nova). Cabeçalho fixo + uma linha por registro, RFC-4180 (campo com
/// vírgula/aspas/quebra de linha vai entre aspas, aspas internas dobradas).
const String reservaHistoryCsvHeader = 'data,recebeu,guardou,regime,trabalho';

String reservaHistoryCsv(List<ReservaEntry> entries) {
  final StringBuffer buffer = StringBuffer()..writeln(reservaHistoryCsvHeader);
  for (final ReservaEntry e in entries) {
    final List<String> campos = <String>[
      e.at.toIso8601String(),
      e.valor.toString(),
      e.reserva.toString(),
      e.regimeTag,
      e.perfilId ?? '',
    ];
    buffer.writeln(campos.map(_csvField).join(','));
  }
  return buffer.toString();
}

String _csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
