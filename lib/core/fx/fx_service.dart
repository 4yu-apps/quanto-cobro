import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/moeda.dart';
import 'fx_rate.dart';
import 'fx_repository.dart';

/// Lançada quando não há cotação disponível: a busca falhou (rede/erro/
/// timeout) e não existe nenhuma cotação em cache pra cair como stale.
class FxUnavailable implements Exception {
  const FxUnavailable(this.message);

  final String message;

  @override
  String toString() => 'FxUnavailable: $message';
}

/// Busca de câmbio — offline-first. A ÚNICA chamada de rede do app: uma API
/// pública sem chave (open.er-api.com), disparada por ação explícita do
/// usuário. Nenhum dado do usuário viaja nessa chamada — só o código ISO da
/// moeda de origem.
///
/// Sucesso: cacheia e devolve a cotação fresca. Erro/offline: cai pra última
/// cotação salva, flagada `stale`. Sem cache nenhum: lança [FxUnavailable].
class FxService {
  FxService(this._repo, {http.Client? client})
    : _client = client ?? http.Client();

  final FxRepository _repo;
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 8);

  static String _par(Moeda de, Moeda para) => '${de.codigo}->${para.codigo}';

  /// [agora] é injetado (não usa `DateTime.now()` aqui) pra ficar testável.
  Future<FxRate> cotacao(
    Moeda de,
    Moeda para, {
    required DateTime agora,
  }) async {
    final String par = _par(de, para);
    try {
      final Uri uri = Uri.https('open.er-api.com', '/v6/latest/${de.codigo}');
      final http.Response resp = await _client.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) {
        throw FxUnavailable('status ${resp.statusCode}');
      }
      final Map<String, dynamic> body =
          jsonDecode(resp.body) as Map<String, dynamic>;
      final Map<String, dynamic>? rates =
          body['rates'] as Map<String, dynamic>?;
      final num? taxaRaw = rates?[para.codigo] as num?;
      if (body['result'] != 'success' || taxaRaw == null) {
        throw FxUnavailable('resposta sem taxa pra ${para.codigo}');
      }
      final FxRate rate = FxRate(par: par, taxa: taxaRaw.toDouble(), at: agora);
      await _repo.put(rate);
      return rate;
    } catch (_) {
      final FxRate? cached = _repo.get(par);
      if (cached != null) {
        return cached.copyWith(stale: true);
      }
      throw FxUnavailable('sem cotação em cache pra $par e busca falhou');
    }
  }
}
