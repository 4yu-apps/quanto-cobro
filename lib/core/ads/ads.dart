/// Monetização por anúncio — **decidido em 01/09/2026: entra DEPOIS, não agora.**
///
/// Até 01/09 a decisão era "nunca" (o raciocínio dos reviews está abaixo e
/// continua verdadeiro). O Gabriel decidiu que a versão grátis vai ter anúncio
/// numa versão futura e que o Pro vende "sem anúncios" desde já. Os termos já
/// dizem isso. Antes de ligar qualquer SDK, ler o Apêndice A do
/// `docs/planning/18-PLANO-FLUXO-FOLGA-E-VISUAL.md` (Data Safety, AD_ID, R6).
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
