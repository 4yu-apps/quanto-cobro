import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/perfil.dart';

/// Persistência do Perfil — local-first, sem servidor, sem login. JSON via
/// shared_preferences (o dado é um documento só; backup/export vira trivial).
/// Atrás de interface: trocável por Drift quando o histórico crescer.
abstract interface class ProfileRepository {
  /// Lê o perfil salvo. `null` = nunca houve. Lança se o dado estiver
  /// corrompido (para o app distinguir "vazio" de "erro" — ver ProfileState).
  Perfil? loadSync();
  Future<void> save(Perfil perfil);
  Future<void> clear();
}

class PrefsProfileRepository implements ProfileRepository {
  PrefsProfileRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'profile_v1';

  @override
  Perfil? loadSync() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return null;
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    return Perfil.fromJson(map);
  }

  @override
  Future<void> save(Perfil perfil) => _prefs.setString(_key, jsonEncode(perfil.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}
