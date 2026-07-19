import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/perfil.dart';

/// Conjunto persistido: todos os perfis + qual está ativo.
class ProfilesData {
  const ProfilesData({required this.perfis, required this.activeId});

  final List<Perfil> perfis;
  final String? activeId;

  Perfil? get active {
    if (perfis.isEmpty) return null;
    return perfis.firstWhere(
      (Perfil p) => p.id == activeId,
      orElse: () => perfis.first,
    );
  }
}

/// Persistência dos perfis — local-first, sem servidor, sem login. JSON via
/// shared_preferences. v2 = multi-perfil; migra o v1 (perfil único) na leitura.
abstract interface class ProfileRepository {
  ProfilesData loadSync();
  Future<void> saveAll(ProfilesData data);
  Future<void> clear();
}

class PrefsProfileRepository implements ProfileRepository {
  PrefsProfileRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _keyV1 = 'profile_v1';
  static const String _keyV2 = 'profiles_v2';

  @override
  ProfilesData loadSync() {
    final String? rawV2 = _prefs.getString(_keyV2);
    if (rawV2 != null) {
      final Map<String, dynamic> map =
          jsonDecode(rawV2) as Map<String, dynamic>;
      final List<Perfil> perfis = (map['profiles'] as List<dynamic>)
          .map((dynamic e) => Perfil.fromJson(e as Map<String, dynamic>))
          .toList();
      return ProfilesData(perfis: perfis, activeId: map['activeId'] as String?);
    }
    // Migração v1 -> v2 (quem salvou na versão de perfil único não perde nada).
    final String? rawV1 = _prefs.getString(_keyV1);
    if (rawV1 != null) {
      final Perfil p = Perfil.fromJson(
        jsonDecode(rawV1) as Map<String, dynamic>,
      );
      return ProfilesData(perfis: <Perfil>[p], activeId: p.id);
    }
    return const ProfilesData(perfis: <Perfil>[], activeId: null);
  }

  @override
  Future<void> saveAll(ProfilesData data) async {
    await _prefs.setString(
      _keyV2,
      jsonEncode(<String, dynamic>{
        'activeId': data.activeId,
        'profiles': data.perfis.map((Perfil p) => p.toJson()).toList(),
      }),
    );
    await _prefs.remove(_keyV1); // v1 já migrado
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_keyV2);
    await _prefs.remove(_keyV1);
  }
}
