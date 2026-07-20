import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/theme/materials.dart';
import '../core/theme/motion.dart';
import '../core/theme/tokens.dart';

/// Casca de navegação (v0.5): dá ao app um MAPA visível em 1 olhada — o que um
/// leigo precisa. Três abas, cada uma um balde mental limpo:
/// **Início = meu preço + ações · Projetos = meus clientes · Guardado = meu
/// imposto.** As duas ações recorrentes (Recebi um pagamento / Vou orçar) NÃO
/// são abas — são os cards protagonistas do Painel. Config vive na engrenagem,
/// não gasta slot. Ferramentas e fluxos (calc, reserva, proposta…) empilham
/// ACIMA da casca (cobrem a barra — são modos focados).
///
/// v0.6 (07 §B.2): o slot do meio era "Trabalhos" e mostrava PRESETS DE PREÇO —
/// um conceito interno num lugar nobre, sendo que quem abre uma aba com esse
/// nome espera ver os clientes dele. Trocamos baixa frequência (você define seu
/// preço raramente) por alta (o power user olha os projetos toda semana). O
/// número de abas não cresceu: foi troca, não adição.
///
/// v0.6 (Lúa, "Cofre Aberto"): a nav bar flutua descolada das bordas, em
/// vidro de verdade (BackdropFilter + fill translúcido + halo esmeralda) —
/// mantém o `NavigationBar` NATIVO (semântica de aba do TalkBack preservada)
/// só envolvendo-o na pílula. Com "Reduzir transparência" ou leitor de tela
/// ativo, cai pro fallback sólido (sem blur) — nunca ilegível, nunca custoso.
class NavShell extends StatelessWidget {
  const NavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // conteúdo rola POR BAIXO da barra flutuante
      body: navigationShell,
      bottomNavigationBar: _GlassBottomBar(navigationShell: navigationShell),
    );
  }
}

/// A pílula de vidro que envolve a `NavigationBar` nativa. Um só ramo (vidro
/// OU sólido) cria `BackdropFilter` — é o que o teste de fallback
/// (`nav_glass_test.dart`) verifica.
class _GlassBottomBar extends ConsumerWidget {
  const _GlassBottomBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Materials m = Theme.of(context).extension<Materials>()!;
    final bool solido =
        MediaQuery.of(context).accessibleNavigation ||
        ref.watch(reduceTransparencyProvider);

    final Widget bar = NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (int i) {
        Haptics.select();
        navigationShell.goBranch(
          i,
          // Re-tocar a aba ativa volta pra raiz dela.
          initialLocation: i == navigationShell.currentIndex,
        );
      },
      // A ordem casa por índice com `branches` em `router.dart`.
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.work_outline),
          selectedIcon: Icon(Icons.work),
          label: 'Trabalhos',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Ajustes',
        ),
      ],
    );

    // Fundo: sólido (fallback) OU vidro (blur + tint >=0.88). Um só ramo cria
    // BackdropFilter.
    final Widget fundo = solido
        ? ColoredBox(color: m.glassFill.withValues(alpha: 1), child: bar)
        : BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: m.glassBlurSigma,
              sigmaY: m.glassBlurSigma,
            ),
            child: ColoredBox(color: m.glassFill, child: bar),
          );

    final Widget pilula = RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radii.xl2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(color: m.navHalo, blurRadius: 32), // halo <=0.12
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radii.xl2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
              borderRadius: const BorderRadius.all(Radii.xl2),
            ),
            child: fundo,
          ),
        ),
      ),
    );

    // Aqui morava um banner de anúncio ancorado. Saiu em 19/07/2026: no nosso
    // nicho, anúncio dói 2,48× mais que a média do mercado, por eCPM de
    // centavos — ver `core/ads/ads.dart` pro número e o raciocínio.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x3),
        child: pilula,
      ),
    );
  }
}
