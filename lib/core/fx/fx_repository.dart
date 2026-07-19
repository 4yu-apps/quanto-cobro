import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'fx_rate.dart';

/// Cache local de cotações — offline-first: a tela sempre tem uma taxa pra
/// mostrar (ainda que `stale`), nunca espera rede pra abrir.
///
/// Override manual tem prioridade: uma vez que o usuário digita a taxa na
/// mão ([setManual]), uma busca automática seguinte ([put] com
/// `manual: false`) não pisa em cima — só outro `setManual` substitui.
class FxRepository {
  FxRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _prefix = 'fx_rate_v1_';

  static String _key(String par) => '$_prefix$par';

  FxRate? get(String par) {
    final String? raw = _prefs.getString(_key(par));
    if (raw == null) return null;
    return FxRate.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> put(FxRate rate) async {
    if (!rate.manual) {
      final FxRate? atual = get(rate.par);
      if (atual != null && atual.manual) {
        return; // override manual tem prioridade sobre busca automática
      }
    }
    await _prefs.setString(_key(rate.par), jsonEncode(rate.toJson()));
  }

  /// Override manual: o usuário digitou a taxa. Fica marcada `manual: true`
  /// e sobrevive a buscas automáticas seguintes (ver [put]).
  Future<void> setManual(String par, double taxa, DateTime at) {
    return put(FxRate(par: par, taxa: taxa, at: at, manual: true));
  }
}
