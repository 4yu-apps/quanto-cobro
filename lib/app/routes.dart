/// Caminhos das telas. Só constantes — sem dependência de widgets, para as
/// telas importarem sem ciclo.
abstract final class Routes {
  // ---- As três abas ----
  static const String painel = '/';
  static const String trabalhos = '/trabalhos';
  static const String config = '/config';

  // ---- Fluxos e ferramentas (empilham acima da casca) ----
  static const String onboarding = '/onboarding';
  static const String calc = '/calc';
  static const String resultado = '/resultado';
  static const String detalhe = '/detalhe';

  /// Registrar uma entrada — o caminho de ouro.
  static const String entrada = '/entrada';

  static const String simulador = '/simulador';
  static const String trabalhoForm = '/trabalho/editar';
  static const String trabalhoDetalhe = '/trabalho';

  /// O histórico do mês. Deixou de ser aba: é o mesmo balde do card do
  /// Início, num zoom maior.
  static const String historico = '/historico';

  /// As áreas de trabalho (multi-área é Pro). Alcançada por Configurações.
  static const String areas = '/areas';

  static const String pro = '/pro';
  static const String legal = '/legal';

  // ---- Proposta pro cliente ----
  static const String proposta = '/proposta';
  static const String marca = '/marca';
}
