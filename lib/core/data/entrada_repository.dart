import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/entrada.dart';

/// Entradas — local, no aparelho (sem nuvem/login).
class EntradaRepository {
  EntradaRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'entradas_v1';

  List<Entrada> loadAll() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return <Entrada>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => Entrada.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Entrada>[]; // dado corrompido não deve travar o app
    }
  }

  Future<void> add(Entrada entrada) {
    final List<Entrada> all = loadAll()..insert(0, entrada);
    return replaceAll(all);
  }

  Future<void> replaceAll(List<Entrada> all) => _prefs.setString(
    _key,
    jsonEncode(all.map((Entrada e) => e.toJson()).toList()),
  );

  Future<void> clear() => _prefs.remove(_key);
}

/// Quanto entrou no mês (bruto), opcionalmente só de uma área.
double entrouNoMes(List<Entrada> todas, DateTime mes, {String? areaId}) => todas
    .where(
      (Entrada e) =>
          e.at.year == mes.year &&
          e.at.month == mes.month &&
          (areaId == null || e.areaId == areaId),
    )
    .fold(0.0, (double s, Entrada e) => s + e.valor);

/// Quanto foi separado de imposto no mês.
int separadoNoMes(List<Entrada> todas, DateTime mes, {String? areaId}) => todas
    .where(
      (Entrada e) =>
          e.at.year == mes.year &&
          e.at.month == mes.month &&
          (areaId == null || e.areaId == areaId),
    )
    .fold(0, (int s, Entrada e) => s + e.separado);

/// Meses com pelo menos uma entrada, mais recente primeiro.
List<DateTime> mesesComEntrada(List<Entrada> todas) {
  final Set<DateTime> meses = <DateTime>{
    for (final Entrada e in todas) DateTime(e.at.year, e.at.month),
  };
  return meses.toList()..sort((DateTime a, DateTime b) => b.compareTo(a));
}

/// Quanto cada trabalho já pagou no total.
Map<String, double> recebidoPorTrabalho(List<Entrada> todas) {
  final Map<String, double> out = <String, double>{};
  for (final Entrada e in todas) {
    final String? id = e.trabalhoId;
    if (id == null) continue;
    out[id] = (out[id] ?? 0) + e.valor;
  }
  return out;
}

/// A data da última entrada de cada trabalho — é o que ordena a lista.
Map<String, DateTime> ultimaEntradaPorTrabalho(List<Entrada> todas) {
  final Map<String, DateTime> out = <String, DateTime>{};
  for (final Entrada e in todas) {
    final String? id = e.trabalhoId;
    if (id == null) continue;
    final DateTime? atual = out[id];
    if (atual == null || e.at.isAfter(atual)) out[id] = e.at;
  }
  return out;
}

/// As entradas de um trabalho, agrupadas por mês, mais recente primeiro.
///
/// É a estrutura da tela que o dono descreveu literalmente: *"o Augusto me
/// pagou 400 num mês, 600 no outro, 200 no outro — e quanto eu separei de
/// cada"*.
Map<DateTime, List<Entrada>> entradasPorMes(
  List<Entrada> todas,
  String trabalhoId,
) {
  final Map<DateTime, List<Entrada>> out = <DateTime, List<Entrada>>{};
  for (final Entrada e in todas) {
    if (e.trabalhoId != trabalhoId) continue;
    final DateTime mes = DateTime(e.at.year, e.at.month);
    (out[mes] ??= <Entrada>[]).add(e);
  }
  for (final List<Entrada> lista in out.values) {
    lista.sort((Entrada a, Entrada b) => b.at.compareTo(a.at));
  }
  return Map<DateTime, List<Entrada>>.fromEntries(
    out.entries.toList()..sort(
      (
        MapEntry<DateTime, List<Entrada>> a,
        MapEntry<DateTime, List<Entrada>> b,
      ) => b.key.compareTo(a.key),
    ),
  );
}
