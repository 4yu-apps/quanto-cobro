import 'dart:convert';

import '../model/marca.dart';
import '../model/perfil.dart';
import '../model/projeto.dart';
import '../model/reserva_entry.dart';
import 'marca_repository.dart';
import 'profile_repository.dart';
import 'projeto_repository.dart';
import 'reserva_history_repository.dart';

/// Backup por arquivo/texto — SEM nuvem, SEM conta (planning/06 §4). Leva TODOS
/// os perfis + o histórico de reservas + os projetos + a marca.
/// Retro-compatível com backups v1 e v2.
///
/// Toda gaveta de dado nova PRECISA entrar aqui. Backup que esquece um pedaço
/// é pior que backup nenhum: a pessoa troca de aparelho confiando nele e
/// descobre a falta quando já não tem como voltar.
class BackupService {
  BackupService(this._repo, this._history, this._projetos, this._marca);

  final ProfileRepository _repo;
  final ReservaHistoryRepository _history;
  final ProjetoRepository _projetos;
  final MarcaRepository _marca;
  static const String _magic = 'quanto-cobro';

  /// Serializa tudo num JSON legível. `null` = nada pra exportar.
  String? exportJson() {
    final ProfilesData data = _repo.loadSync();
    if (data.perfis.isEmpty) return null;
    final Marca marca = _marca.load();
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': _magic,
      'version': 3,
      'activeId': data.activeId,
      'profiles': data.perfis.map((Perfil p) => p.toJson()).toList(),
      'history': _history
          .loadAll()
          .map((ReservaEntry e) => e.toJson())
          .toList(),
      'projetos': _projetos.loadAll().map((Projeto p) => p.toJson()).toList(),
      // A logo é um arquivo no aparelho, não texto: o caminho viaja no backup
      // mas a imagem não. Restaurar em outro aparelho traz nome e contato, e a
      // logo é escolhida de novo — melhor que inchar o backup com base64.
      if (!marca.vazia) 'marca': marca.toJson(),
    });
  }

  /// Restaura de um JSON exportado (v1, v2 ou v3). Lança se não for válido.
  Future<void> importJson(String raw) async {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['app'] != _magic) {
      throw const FormatException('Esse texto não parece um backup do app.');
    }
    // v2+: lista de perfis. v1: perfil único na chave 'profile'.
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

    final Object? projetos = decoded['projetos'];
    if (projetos is List<dynamic>) {
      await _projetos.replaceAll(
        projetos
            .map((dynamic e) => Projeto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    final Object? marca = decoded['marca'];
    if (marca is Map<String, dynamic>) {
      // Sem o logoPath: ele aponta pra um arquivo do aparelho ANTIGO. Manter
      // deixaria a proposta com uma logo fantasma que nunca renderiza.
      await _marca.save(Marca.fromJson(marca).copyWith(limparLogo: true));
    }
  }
}
