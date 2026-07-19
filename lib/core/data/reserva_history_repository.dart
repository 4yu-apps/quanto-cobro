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

  Future<void> _save(List<ReservaEntry> all) => _prefs.setString(
    _key,
    jsonEncode(all.map((ReservaEntry e) => e.toJson()).toList()),
  );
}
