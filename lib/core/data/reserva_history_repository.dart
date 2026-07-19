import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/reserva_entry.dart';

/// Histórico de reservas — local, no aparelho (sem nuvem/login). Lista simples;
/// se crescer muito, migra pra Drift (a interface deixa a troca indolor).
class ReservaHistoryRepository {
  ReservaHistoryRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'reserva_history_v1';

  List<ReservaEntry> loadAll() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return <ReservaEntry>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => ReservaEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <ReservaEntry>[]; // dado corrompido não deve travar o app
    }
  }

  Future<void> add(ReservaEntry entry) {
    final List<ReservaEntry> all = loadAll()..insert(0, entry);
    return _save(all);
  }

  Future<void> clear() => _prefs.remove(_key);

  Future<void> replaceAll(List<ReservaEntry> all) => _save(all);

  /// Soma de `valor` (bruto) no mês (ano+mês de `mes`), opcionalmente
  /// filtrado por `perfilId`. `perfilId == null` soma todos os trabalhos.
  double brutoDoMes(DateTime mes, {String? perfilId}) => loadAll()
      .where(
        (ReservaEntry e) =>
            e.at.year == mes.year &&
            e.at.month == mes.month &&
            (perfilId == null || e.perfilId == perfilId),
      )
      .fold(0.0, (double soma, ReservaEntry e) => soma + e.valor);

  /// Soma de `valor` no mês, agrupada por `perfilId` (chave `''` pra
  /// registros sem trabalho associado).
  Map<String, double> brutoPorTrabalhoNoMes(DateTime mes) {
    final Map<String, double> byPerfil = <String, double>{};
    for (final ReservaEntry e in loadAll()) {
      if (e.at.year != mes.year || e.at.month != mes.month) continue;
      final String chave = e.perfilId ?? '';
      byPerfil[chave] = (byPerfil[chave] ?? 0) + e.valor;
    }
    return byPerfil;
  }

  /// Meses distintos (ano+mês) com pelo menos um registro, mais recente
  /// primeiro — base pra agrupar o histórico por mês.
  List<DateTime> mesesComReserva() {
    final Set<DateTime> meses = <DateTime>{};
    for (final ReservaEntry e in loadAll()) {
      meses.add(DateTime(e.at.year, e.at.month));
    }
    final List<DateTime> ordenado = meses.toList()
      ..sort((DateTime a, DateTime b) => b.compareTo(a));
    return ordenado;
  }

  Future<void> _save(List<ReservaEntry> all) => _prefs.setString(
    _key,
    jsonEncode(all.map((ReservaEntry e) => e.toJson()).toList()),
  );
}
