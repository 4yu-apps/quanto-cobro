import 'dart:convert';

import '../model/perfil.dart';
import '../model/reserva_entry.dart';
import 'profile_repository.dart';
import 'reserva_history_repository.dart';

/// Backup por arquivo/texto — SEM nuvem, SEM conta (planning/06 §4). Leva TODOS
/// os perfis + o histórico de reservas. Retro-compatível com backups v1.
class BackupService {
  BackupService(this._repo, this._history);

  final ProfileRepository _repo;
  final ReservaHistoryRepository _history;
  static const String _magic = 'quanto-cobro';

  /// Serializa tudo num JSON legível. `null` = nada pra exportar.
  String? exportJson() {
    final ProfilesData data = _repo.loadSync();
    if (data.perfis.isEmpty) return null;
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': _magic,
      'version': 2,
      'activeId': data.activeId,
      'profiles': data.perfis.map((Perfil p) => p.toJson()).toList(),
      'history': _history
          .loadAll()
          .map((ReservaEntry e) => e.toJson())
          .toList(),
    });
  }

  /// Restaura de um JSON exportado (v1 ou v2). Lança se não for um backup válido.
  Future<void> importJson(String raw) async {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['app'] != _magic) {
      throw const FormatException('Esse texto não parece um backup do app.');
    }
    // v2: lista de perfis. v1: perfil único na chave 'profile'.
    if (decoded['profiles'] is List<dynamic> &&
        (decoded['profiles'] as List<dynamic>).isNotEmpty) {
      final List<Perfil> perfis = (decoded['profiles'] as List<dynamic>)
          .map((dynamic e) => Perfil.fromJson(e as Map<String, dynamic>))
          .toList();
      await _repo.saveAll(
        ProfilesData(perfis: perfis, activeId: decoded['activeId'] as String?),
      );
    } else if (decoded['profile'] is Map<String, dynamic>) {
      final Perfil p = Perfil.fromJson(
        decoded['profile'] as Map<String, dynamic>,
      );
      await _repo.saveAll(ProfilesData(perfis: <Perfil>[p], activeId: p.id));
    } else {
      throw const FormatException(
        'Não achei nenhum cálculo nesse backup. Confere se o texto foi colado inteiro.',
      );
    }
    final Object? hist = decoded['history'];
    if (hist is List<dynamic>) {
      await _history.replaceAll(
        hist
            .map(
              (dynamic e) => ReservaEntry.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
    }
  }
}
