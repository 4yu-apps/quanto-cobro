import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/projeto.dart';

/// Projetos — local, no aparelho (sem nuvem/login), igual ao resto do app.
/// Lista simples em JSON: são dezenas de projetos, não milhares; Drift aqui
/// seria peso sem ganho (a interface deixa a troca indolor se um dia virar).
class ProjetoRepository {
  ProjetoRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'projetos_v1';

  List<Projeto> loadAll() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return <Projeto>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => Projeto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Projeto>[]; // dado corrompido não deve travar o app
    }
  }

  Future<void> replaceAll(List<Projeto> all) => _prefs.setString(
    _key,
    jsonEncode(all.map((Projeto p) => p.toJson()).toList()),
  );

  Future<void> clear() => _prefs.remove(_key);
}

/// Ordem da lista: o que importa primeiro é QUANDO entra dinheiro (07 §B.4).
/// Quem tem recebimento marcado vem antes, do mais próximo pro mais distante;
/// depois os sem data, por criação (mais novo primeiro). Concluído e pausado
/// afundam — não competem com o que ainda paga.
List<Projeto> ordenarPorProximoRecebimento(List<Projeto> projetos) {
  final List<Projeto> out = List<Projeto>.of(projetos);
  out.sort((Projeto a, Projeto b) {
    final int pesoA = _peso(a);
    final int pesoB = _peso(b);
    if (pesoA != pesoB) return pesoA.compareTo(pesoB);

    final DateTime? da = a.proximoRecebimento;
    final DateTime? db = b.proximoRecebimento;
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return b.criadoEm.compareTo(a.criadoEm);
  });
  return out;
}

int _peso(Projeto p) => switch (p.status) {
  ProjetoStatus.ativo => 0,
  ProjetoStatus.orcamento => 1,
  ProjetoStatus.pausado => 2,
  ProjetoStatus.concluido => 3,
};
