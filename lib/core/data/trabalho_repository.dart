import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/trabalho.dart';

/// Trabalhos — local, no aparelho. Lista simples em JSON: são dezenas, não
/// milhares.
class TrabalhoRepository {
  TrabalhoRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'trabalhos_v1';

  List<Trabalho> loadAll() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return <Trabalho>[];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => Trabalho.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Trabalho>[]; // dado corrompido não deve travar o app
    }
  }

  Future<void> replaceAll(List<Trabalho> all) => _prefs.setString(
    _key,
    jsonEncode(all.map((Trabalho t) => t.toJson()).toList()),
  );

  Future<void> clear() => _prefs.remove(_key);
}

/// Ordem da lista: **quem pagou por último aparece primeiro.**
///
/// Não é ordem alfabética nem por data de cadastro: a pessoa abre a aba pra
/// olhar o que está vivo, e o que está vivo é o que teve movimento recente.
/// Trabalho encerrado afunda — não compete com quem ainda paga.
List<Trabalho> ordenarTrabalhos(
  List<Trabalho> trabalhos,
  Map<String, DateTime> ultimaEntradaPorTrabalho,
) {
  final List<Trabalho> out = List<Trabalho>.of(trabalhos);
  out.sort((Trabalho a, Trabalho b) {
    if (a.encerrado != b.encerrado) return a.encerrado ? 1 : -1;
    final DateTime? ua = ultimaEntradaPorTrabalho[a.id];
    final DateTime? ub = ultimaEntradaPorTrabalho[b.id];
    if (ua != null && ub != null) return ub.compareTo(ua);
    // Quem nunca recebeu vem depois de quem já recebeu, mas antes dos
    // encerrados: é trabalho novo esperando a primeira entrada.
    if (ua != null) return -1;
    if (ub != null) return 1;
    return b.criadoEm.compareTo(a.criadoEm);
  });
  return out;
}
