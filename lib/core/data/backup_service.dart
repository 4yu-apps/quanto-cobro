import 'dart:convert';

import '../model/perfil.dart';
import 'profile_repository.dart';

/// Backup por arquivo/texto — SEM nuvem, SEM conta (planning/06 §4). Resolve o
/// "vou trocar de celular" que o mercado sofre, mantendo o usuário dono do dado.
class BackupService {
  BackupService(this._repo);

  final ProfileRepository _repo;
  static const String _magic = 'quanto-cobro';

  /// Serializa o perfil salvo num JSON legível. `null` = nada pra exportar.
  String? exportJson() {
    final Perfil? p = _repo.loadSync();
    if (p == null) return null;
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': _magic,
      'version': 1,
      'profile': p.toJson(),
    });
  }

  /// Restaura de um JSON exportado. Lança se o conteúdo não for um backup válido.
  Future<void> importJson(String raw) async {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['app'] != _magic) {
      throw const FormatException('Esse texto não parece um backup do app.');
    }
    final Perfil perfil = Perfil.fromJson(decoded['profile'] as Map<String, dynamic>);
    await _repo.save(perfil);
  }
}
