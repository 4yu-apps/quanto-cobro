/// Monetização por anúncio — **DECIDIDO: não tem.**
///
/// O app foi desenhado com um slot de banner ancorado nas abas e um
/// intersticial no retorno pós-salvar. Ambos saíram em 19/07/2026, e este
/// arquivo continua existindo pra que a decisão não seja desfeita por engano
/// daqui a seis meses "só pra testar uma receitinha".
///
/// **O motivo é dado, não gosto.** Na mineração de 16.961 reviews de
/// concorrentes (`docs/research/ANALISE-QUANTITATIVA-REVIEWS.md`), "anúncio"
/// aparece em 2,7% das reclamações do mercado em geral — mas em **6,7% no
/// nosso nicho de precificação: 2,48× mais**. No mesmo recorte,
/// cobrança/paywall dói MENOS que a média (5,8% contra 14,1%).
///
/// Traduzindo: **no mercado onde vamos jogar, cobrar é seguro e anunciar não
/// é.** Em troca desse risco, um banner num utilitário offline rende eCPM de
/// centavos — e o SDK do AdMob já derrubou este app no boot uma vez, quando o
/// `APPLICATION_ID` faltou no manifest (ver histórico no `pubspec.yaml`).
///
/// Risco alto de ★1 por receita irrelevante, num app cuja promessa é
/// justamente ser limpo, offline e sem pegadinha. A receita vem do Pro.
///
/// Se um dia isso for reaberto, o ônus é de quem reabre: mostre que o número
/// mudou.
library;

/// O intersticial pós-salvar também morreu. Fica como no-op porque a chamada
/// vive no fim do "Salvar este trabalho" (`resultado_screen`) — apagar a
/// chamada junto tornaria a decisão invisível pra quem ler aquela tela depois.
abstract final class AdInterstitial {
  /// Sempre `false`: não existe anúncio neste app.
  static Future<bool> maybeShowOnSave(bool isPro) async => false;
}
