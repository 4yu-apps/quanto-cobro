/// Caminhos das telas (hub-and-spoke). Só constantes — sem dependência de
/// widgets, para as telas importarem sem ciclo.
abstract final class Routes {
  static const String painel = '/';
  static const String onboarding = '/onboarding';
  static const String calc = '/calc';
  static const String resultado = '/resultado';
  static const String detalhe = '/detalhe';
  static const String reserva = '/reserva';
  static const String simulador = '/simulador';

  /// Presets de preço (multi-`Perfil`, Pro). Saiu do slot de aba em v0.6: é
  /// baixa frequência (você define seu preço raramente) e ocupava um lugar
  /// nobre. Agora se chega por ele pelo switcher do herói e por Configurações.
  static const String perfis = '/perfis';

  static const String config = '/config';
  static const String pro = '/pro';
  static const String legal = '/legal';
  static const String historico = '/historico';

  // ---- Gestão de projetos (07 §B) ----
  static const String projetos = '/projetos';
  static const String projetoForm = '/projeto/editar';
  static const String projetoDetalhe = '/projeto';

  // ---- Proposta pro cliente (07 §A) ----
  static const String proposta = '/proposta';
  static const String marca = '/marca';
}
