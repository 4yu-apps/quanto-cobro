import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/marca.dart';

/// A marca do freelancer (nome/logo/contato) — no aparelho, como todo o resto.
class MarcaRepository {
  MarcaRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'marca_v1';

  Marca load() {
    final String? raw = _prefs.getString(_key);
    if (raw == null) return const Marca();
    try {
      return Marca.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const Marca();
    }
  }

  Future<void> save(Marca marca) =>
      _prefs.setString(_key, jsonEncode(marca.toJson()));

  Future<void> clear() async {
    await _apagarLogo(load().logoPath);
    await _prefs.remove(_key);
  }

  /// Copia a logo escolhida pra dentro da pasta do app e devolve o novo
  /// caminho. Guardar o caminho da galeria não funciona: o Android revoga o
  /// acesso e a logo somiria da proposta semanas depois, sem aviso — o pior
  /// tipo de bug, porque quem descobre é o cliente do freelancer.
  Future<String> importarLogo(String origem) async {
    final Directory dir = await getApplicationSupportDirectory();
    final String ext = p.extension(origem).toLowerCase();
    // Nome novo a cada import: se o arquivo tivesse nome fixo, a imagem velha
    // ficaria em cache e a "nova" logo apareceria como a antiga.
    final String destino = p.join(
      dir.path,
      'marca_logo_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(origem).copy(destino);
    await _apagarLogo(load().logoPath); // a anterior vira lixo
    return destino;
  }

  Future<void> _apagarLogo(String? path) async {
    if (path == null) return;
    try {
      final File f = File(path);
      if (f.existsSync()) await f.delete();
    } catch (_) {
      // Falhar em apagar a logo antiga é irrelevante pro usuário: só ocupa
      // alguns KB. Nunca deve borbulhar como erro na cara dele.
    }
  }
}
