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

/// Busca de câmbio — offline-first. A ÚNICA chamada de rede do app, disparada
/// por ação explícita do usuário. Nenhum dado do usuário viaja — só o código
/// ISO da moeda de origem.
///
/// Fonte PRIMÁRIA: PTAX do Banco Central (olinda.bcb.gov.br) — a cotação
/// OFICIAL, a mesma que o carnê-leão usa (dia útil anterior). FALLBACK: taxa de
/// mercado (open.er-api.com), quando a PTAX não vem (fim de semana antes do
/// primeiro boletim, API fora do ar, moeda sem PTAX). Cada resultado carrega a
/// [FxRate.fonte] pra a tela dizer, com verdade, de onde veio o número.
///
/// Sucesso: cacheia e devolve fresca. Tudo falha: cai pra última cotação salva,
/// flagada `stale`. Sem cache nenhum: lança [FxUnavailable].
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

    // 1) PTAX do BCB — a oficial. Só faz sentido convertendo PRA real.
    if (para.codigo == 'BRL') {
      try {
        final FxRate ptax = await _ptax(de, par, agora);
        await _repo.put(ptax, force: true);
        return ptax;
      } catch (_) {
        // segue pro fallback
      }
    }

    // 2) Fallback: taxa de mercado (open.er-api).
    try {
      final FxRate mercado = await _mercado(de, para, par, agora);
      await _repo.put(mercado, force: true);
      return mercado;
    } catch (_) {
      // segue pro cache
    }

    // 3) Sem rede: a última cotação salva, honestamente flagada stale.
    final FxRate? cached = _repo.get(par);
    if (cached != null) return cached.copyWith(stale: true);
    throw FxUnavailable('sem cotação em cache pra $par e busca falhou');
  }

  /// PTAX de fechamento do último dia útil disponível (janela de 8 dias até
  /// ontem, pra pular fim de semana e feriado). Usa a cotação de COMPRA — é a
  /// que a Receita aplica sobre RENDIMENTO recebido em moeda estrangeira.
  Future<FxRate> _ptax(Moeda de, String par, DateTime agora) async {
    final DateTime fim = agora.subtract(const Duration(days: 1));
    final DateTime ini = agora.subtract(const Duration(days: 8));
    final Uri uri = Uri.https(
      'olinda.bcb.gov.br',
      '/olinda/servico/PTAX/versao/v1/odata/'
          'CotacaoMoedaPeriodo(moeda=@moeda,dataInicial=@dataInicial,dataFinalCotacao=@dataFinalCotacao)',
      <String, String>{
        '@moeda': "'${de.codigo}'",
        '@dataInicial': "'${_dataUS(ini)}'",
        '@dataFinalCotacao': "'${_dataUS(fim)}'",
        r'$top': '1',
        r'$orderby': 'dataHoraCotacao desc',
        r'$format': 'json',
      },
    );
    final http.Response resp = await _client.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw FxUnavailable('PTAX status ${resp.statusCode}');
    }
    final Map<String, dynamic> body =
        jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic>? valores = body['value'] as List<dynamic>?;
    if (valores == null || valores.isEmpty) {
      throw FxUnavailable('PTAX sem cotação na janela pra ${de.codigo}');
    }
    final Map<String, dynamic> v = valores.first as Map<String, dynamic>;
    final num? compra = v['cotacaoCompra'] as num?;
    if (compra == null) throw FxUnavailable('PTAX sem cotação de compra');
    final DateTime at =
        DateTime.tryParse((v['dataHoraCotacao'] as String?) ?? '') ?? agora;
    return FxRate(
      par: par,
      taxa: compra.toDouble(),
      at: at,
      fonte: 'ptax',
    );
  }

  /// Taxa de mercado (open.er-api) — o fallback quando a PTAX não vem.
  Future<FxRate> _mercado(
    Moeda de,
    Moeda para,
    String par,
    DateTime agora,
  ) async {
    final Uri uri = Uri.https('open.er-api.com', '/v6/latest/${de.codigo}');
    final http.Response resp = await _client.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw FxUnavailable('status ${resp.statusCode}');
    }
    final Map<String, dynamic> body =
        jsonDecode(resp.body) as Map<String, dynamic>;
    final Map<String, dynamic>? rates = body['rates'] as Map<String, dynamic>?;
    final num? taxaRaw = rates?[para.codigo] as num?;
    if (body['result'] != 'success' || taxaRaw == null) {
      throw FxUnavailable('resposta sem taxa pra ${para.codigo}');
    }
    return FxRate(par: par, taxa: taxaRaw.toDouble(), at: agora, fonte: 'mercado');
  }

  /// Data no formato MM-DD-YYYY que a API OData da PTAX exige.
  static String _dataUS(DateTime d) {
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '$mm-$dd-${d.year}';
  }
}
