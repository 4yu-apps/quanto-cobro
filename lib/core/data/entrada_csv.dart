import '../model/entrada.dart';

/// CSV do histórico "Guardado" — export Pro, puro Dart (zero dependência
/// nova). Cabeçalho fixo + uma linha por registro, RFC-4180 (campo com
/// vírgula/aspas/quebra de linha vai entre aspas, aspas internas dobradas).
const String entradasCsvHeader = 'data,recebeu,guardou,regime,trabalho';

String entradasCsv(List<Entrada> entries) {
  final StringBuffer buffer = StringBuffer()..writeln(entradasCsvHeader);
  for (final Entrada e in entries) {
    final List<String> campos = <String>[
      e.at.toIso8601String(),
      e.valor.toString(),
      e.separado.toString(),
      e.regimeTag,
      e.areaId ?? '',
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
