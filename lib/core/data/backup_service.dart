import 'dart:convert';

import '../model/area.dart';
import '../model/entrada.dart';
import '../model/marca.dart';
import '../model/trabalho.dart';
import 'area_repository.dart';
import 'entrada_repository.dart';
import 'marca_repository.dart';
import 'trabalho_repository.dart';

/// Backup por arquivo/texto — SEM nuvem, SEM conta. Leva áreas, entradas,
/// trabalhos e marca.
///
/// Toda gaveta de dado nova PRECISA entrar aqui. Backup que esquece um pedaço é
/// pior que backup nenhum: a pessoa troca de aparelho confiando nele e descobre
/// a falta quando já não tem como voltar.
class BackupService {
  BackupService(this._areas, this._entradas, this._trabalhos, this._marca);

  final AreaRepository _areas;
  final EntradaRepository _entradas;
  final TrabalhoRepository _trabalhos;
  final MarcaRepository _marca;
  static const String _magic = 'quanto-cobro';

  /// Serializa tudo num JSON legível. `null` = nada pra exportar.
  String? exportJson() {
    final AreasData data = _areas.loadSync();
    if (data.areas.isEmpty) return null;
    final Marca marca = _marca.load();
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': _magic,
      'version': 4,
      'activeId': data.activeId,
      'areas': data.areas.map((Area a) => a.toJson()).toList(),
      'entradas': _entradas.loadAll().map((Entrada e) => e.toJson()).toList(),
      'trabalhos': _trabalhos
          .loadAll()
          .map((Trabalho t) => t.toJson())
          .toList(),
      // A logo é um arquivo no aparelho, não texto: o caminho viaja mas a
      // imagem não. Restaurar em outro aparelho traz nome e contato, e a logo é
      // escolhida de novo — melhor que inchar o backup com base64.
      if (!marca.vazia) 'marca': marca.toJson(),
    });
  }

  /// Restaura de um JSON exportado. Lança se não for um backup válido.
  Future<void> importJson(String raw) async {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['app'] != _magic) {
      throw const FormatException('Esse texto não parece um backup do app.');
    }

    final Object? areas = decoded['areas'];
    if (areas is! List<dynamic> || areas.isEmpty) {
      throw const FormatException(
        'Não achei nenhum cálculo nesse backup. Confere se o texto foi colado inteiro.',
      );
    }
    await _areas.saveAll(
      AreasData(
        areas: areas
            .map((dynamic e) => Area.fromJson(e as Map<String, dynamic>))
            .toList(),
        activeId: decoded['activeId'] as String?,
      ),
    );

    final Object? entradas = decoded['entradas'];
    if (entradas is List<dynamic>) {
      await _entradas.replaceAll(
        entradas
            .map((dynamic e) => Entrada.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    final Object? trabalhos = decoded['trabalhos'];
    if (trabalhos is List<dynamic>) {
      await _trabalhos.replaceAll(
        trabalhos
            .map((dynamic e) => Trabalho.fromJson(e as Map<String, dynamic>))
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
