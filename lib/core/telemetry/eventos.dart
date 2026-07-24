/// Os eventos que o app registra — e SÓ eles.
///
/// Esta lista não é "tudo que dá pra medir": é o de-para exato dos **cinco
/// sinais de sucesso** definidos em `docs/planning/05-ESCOPO-E-ROADMAP.md §7`.
/// Evento que não responde a um desses sinais não entra, porque telemetria sem
/// pergunta vira lixo que ninguém olha e dado pessoal que ninguém precisava ter.
///
/// ## A regra de privacidade (dura, e vale mais que qualquer métrica)
///
/// **Nenhum evento carrega dinheiro, nome, cliente ou texto digitado.** Nem o
/// valor-hora, nem o valor de uma entrada, nem "Augusto". O app promete no
/// onboarding que os dados ficam no aparelho; medir *que* a pessoa registrou
/// uma entrada é legítimo, medir *quanto* ela recebeu é quebrar a promessa.
///
/// Os parâmetros permitidos são categóricos e de baixa cardinalidade (um passo,
/// um regime, um gatilho). Se algum dia alguém precisar mandar um número de
/// dinheiro daqui, a resposta é não.
abstract final class Evento {
  // ---- Sinal 1: conclusão do fluxo guiado ----
  /// A pessoa começou a calculadora.
  static const String calcIniciada = 'calc_iniciada';

  /// Avançou pro passo N. Param: `passo` (int). É o que revela ONDE ela desiste.
  static const String calcPasso = 'calc_passo';

  /// Chegou no Resultado. A razão `calc_concluida / calc_iniciada` é o sinal.
  static const String calcConcluida = 'calc_concluida';

  /// Salvou o cálculo (nasceu uma Área).
  static const String areaSalva = 'area_salva';

  // ---- Sinal 2: uso da reserva (proxy nº1 de hábito) ----
  /// Registrou uma entrada. Param: `origem` (`trabalho` | `avulso`),
  /// `regime` (mei|cpf|simples|intl|carne_leao).
  static const String entradaRegistrada = 'entrada_registrada';

  // ---- Sinal 3: o conceito difícil foi resolvido? ----
  /// Usou uma ajuda/estimativa em vez de digitar na mão. Param: `campo`.
  static const String estimativaUsada = 'estimativa_usada';

  /// Abriu um verbete do glossário. Param: `verbete`. Diz QUAL palavra confunde.
  static const String glossarioAberto = 'glossario_aberto';

  // ---- Sinal 4: conversão Pro por gatilho ----
  /// A parede Pro apareceu. Param: `gatilho` (ver [GatilhoPro]).
  static const String proParedeVista = 'pro_parede_vista';

  /// O Pro foi ativado. Param: `gatilho` — é o que diz QUAL recurso puxa a compra.
  static const String proAtivado = 'pro_ativado';

  // ---- Sinal 5: crash-free ----
  /// Erro não tratado capturado pelo app. Param: `fatal` (bool).
  /// Vai pro Crashlytics quando ele estiver ligado; hoje só conta.
  static const String erroNaoTratado = 'erro_nao_tratado';
}

/// De onde a parede Pro foi vista. Sem isso, "conversão" é um número só e não
/// responde a pergunta que interessa: **qual recurso puxa a compra?**
abstract final class GatilhoPro {
  static const String propostaPdf = 'proposta_pdf';
  static const String segundaArea = 'segunda_area';
  static const String moedaEstrangeira = 'moeda_estrangeira';
  static const String detalhamentoImposto = 'detalhamento_imposto';
  static const String config = 'config';
}
