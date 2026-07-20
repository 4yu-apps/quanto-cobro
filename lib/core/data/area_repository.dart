import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/area.dart';

/// Conjunto persistido: todas as áreas + qual está ativa.
class AreasData {
  const AreasData({required this.areas, required this.activeId});

  final List<Area> areas;
  final String? activeId;

  Area? get active {
    if (areas.isEmpty) return null;
    return areas.firstWhere(
      (Area a) => a.id == activeId,
      orElse: () => areas.first,
    );
  }

  /// Quem tem uma área só nunca lê a palavra "área" no app — a hierarquia
  /// existe nos dados e não na navegação.
  bool get hierarquiaVisivel => areas.length > 1;
}

/// Persistência das áreas — local-first, sem servidor, sem login.
abstract interface class AreaRepository {
  AreasData loadSync();
  Future<void> saveAll(AreasData data);
  Future<void> clear();
}

class PrefsAreaRepository implements AreaRepository {
  PrefsAreaRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Chave nova: o app não estava publicado quando os conceitos foram
  /// renomeados (19/07/2026), então não há dado de usuário pra migrar — e
  /// carregar código de migração que nunca vai rodar é dívida de graça.
  static const String _key = 'areas_v1';

  @override
  AreasData loadSync() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return const AreasData(areas: <Area>[], activeId: null);
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    final List<Area> areas = (map['areas'] as List<dynamic>)
        .map((dynamic e) => Area.fromJson(e as Map<String, dynamic>))
        .toList();
    return AreasData(areas: areas, activeId: map['activeId'] as String?);
  }

  @override
  Future<void> saveAll(AreasData data) => _prefs.setString(
    _key,
    jsonEncode(<String, dynamic>{
      'activeId': data.activeId,
      'areas': data.areas.map((Area a) => a.toJson()).toList(),
    }),
  );

  @override
  Future<void> clear() => _prefs.remove(_key);
}
