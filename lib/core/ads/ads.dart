import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../theme/divisao_colors.dart';
import '../theme/tokens.dart';

/// Monetização por anúncio — RESERVADA e não-irritante (Blueprint §11).
///
/// ESTRATÉGIA de onde o anúncio pode ficar (e onde JAMAIS):
/// - SIM: só nas superfícies de "estar à toa" — as abas Início · Histórico ·
///   Trabalhos. Um banner ancorado no rodapé, ACIMA da nav bar, fora do fluxo
///   de leitura (via [AdSlot] na casca de navegação). Some sozinho em toda
///   ferramenta/fluxo (calc, resultado, reserva, simulador) porque elas cobrem
///   a casca — ou seja, nunca há anúncio durante uma decisão ou o clímax.
/// - SIM (reservado): 1 intersticial no ÚNICO corte seguro — ao salvar um
///   trabalho e voltar pro Painel (fim de tarefa). Com trava de frequência.
/// - JAMAIS: no Resultado (o print, o "olha que app foda"), no meio da
///   calculadora (decisão), na Reserva/Simulador (o momento de valor). Anúncio
///   nesses lugares é ansiedade — e ansiedade num app de dinheiro é ★1.
/// - NUNCA para quem é Pro. NUNCA antes do 1º cálculo (não monetiza quem ainda
///   não recebeu valor).
///
/// O SDK real (google_mobile_ads) NÃO entra aqui ainda: sem o
/// `com.google.android.gms.ads.APPLICATION_ID` no AndroidManifest, ele DERRUBA
/// o boot (aprendido em produção — ver pubspec). Preencha [AdConfig] com as
/// chaves + coloque o meta-data no manifest, e troque o placeholder do [AdSlot]
/// pelo `AdWidget` real. Toda a lógica de ONDE/QUANDO já está pronta.
abstract final class AdConfig {
  /// AdMob APPLICATION_ID (vai no AndroidManifest, não aqui — anotado pra achar).
  static const String androidAppId = '';

  /// Unit id do banner do hub (abas). Vazio = mostra o espaço reservado.
  static const String bannerHubUnitId = '';

  /// Unit id do intersticial (retorno pós-salvar). Vazio = desligado.
  static const String interstitialUnitId = '';

  static bool get bannerConfigurado => bannerHubUnitId.isNotEmpty;
  static bool get interstitialConfigurado => interstitialUnitId.isNotEmpty;
}

/// Banner ancorado do hub. Renderiza:
/// - nada, se o usuário é Pro ou ainda não tem cálculo (não irrita quem chegou);
/// - o anúncio real, quando [AdConfig.bannerConfigurado] (futuro);
/// - o espaço reservado (placeholder com o footprint exato), enquanto não há
///   chave — pra você VER onde vai entrar.
class AdSlot extends ConsumerWidget {
  const AdSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPro = ref.watch(proProvider);
    final ProfileState profile = ref.watch(profileProvider);
    // Pro não vê anúncio; e não monetiza quem ainda não fez o 1º cálculo.
    if (isPro || profile is! ProfileReady) return const SizedBox.shrink();

    // TODO(ads): quando AdConfig.bannerConfigurado, retornar aqui o
    // `AdWidget(ad: BannerAd(...))` dentro do mesmo container (mesma altura).
    return const _AdPlaceholder();
  }
}

/// O espaço reservado do banner (altura de banner adaptativo ~56dp). Usa os
/// tokens `adSurface`/`adLabel` que o Design System já reservou pra anúncio.
class _AdPlaceholder extends StatelessWidget {
  const _AdPlaceholder();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    return Semantics(
      label: 'Espaço de anúncio',
      child: Container(
        height: 56,
        margin: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x2),
        decoration: BoxDecoration(
          color: d.adSurface,
          borderRadius: const BorderRadius.all(Radii.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: Space.x2,
              top: Space.x1,
              child: Text(
                'PUBLICIDADE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: d.adLabel,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.campaign_outlined, size: 18, color: d.adLabel),
                  const SizedBox(width: Space.x2),
                  Text(
                    'Espaço reservado para anúncio',
                    style: theme.textTheme.labelMedium?.copyWith(color: d.adLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Intersticial reservado — o único corte seguro é o retorno pós-salvar (fim de
/// tarefa). No-op enquanto não há SDK/chave; a chamada já vive no ponto certo
/// (resultado_screen, ao salvar). Trava de frequência entra junto com o SDK.
abstract final class AdInterstitial {
  /// Chamado ao concluir "Salvar este trabalho". Retorna se mostrou algo.
  static Future<bool> maybeShowOnSave(bool isPro) async {
    if (isPro || !AdConfig.interstitialConfigurado) return false;
    // TODO(ads): carregar/exibir InterstitialAd aqui, com trava de frequência
    // (ex.: 1 a cada 3 salvamentos). Nunca entre calc e Resultado.
    return false;
  }
}
