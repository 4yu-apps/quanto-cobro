import 'package:shared_preferences/shared_preferences.dart';

/// Direito Pro (entitlement) local. Quando a compra real pela loja for ligada
/// com os IDs de produto da Play, ela só grava aqui. O resto do app lê este
/// flag pra liberar os recursos Pro.
class EntitlementRepository {
  EntitlementRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _kPro = 'entitlement_pro';

  bool isPro() => _prefs.getBool(_kPro) ?? false;
  Future<void> setPro(bool value) => _prefs.setBool(_kPro, value);
}
