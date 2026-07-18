import 'dart:convert';

import '../model/perfil.dart';
import '../model/reserva_entry.dart';
import 'profile_repository.dart';
import 'reserva_history_repository.dart';

/// Backup por arquivo/texto — SEM nuvem, SEM conta (planning/06 §4). Resolve o
/// "vou trocar de celular" que o mercado sofre, mantendo o usuário dono do dado.
class BackupService {
  BackupService(this._repo, this._history);

  final ProfileRepository _repo;
  final ReservaHistoryRepository _history;
  static const String _magic = 'quanto-cobro';

  /// Serializa o perfil salvo num JSON legível. `null` = nada pra exportar.
  String? exportJson() {
    final Perfil? p = _repo.loadSync();
    if (p == null) return null;
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': _magic,
      'version': 1,
      'profile': p.toJson(),
      'history': _history.loadAll().map((ReservaEntry e) => e.toJson()).toList(),
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
    // Histórico: retro-compatível (backup antigo sem a chave é ignorado).
    final Object? hist = decoded['history'];
    if (hist is List<dynamic>) {
      await _history.replaceAll(hist
          .map((dynamic e) => ReservaEntry.fromJson(e as Map<String, dynamic>))
          .toList());
    }
  }
}
