import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/theme/materials.dart';
import '../core/theme/motion.dart';
import '../core/theme/tokens.dart';
import '../core/ui/breakpoints.dart';

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
///
/// v0.8 (tablet): de `medium` pra cima a pílula vira **trilho lateral**. Não é
/// enfeite de tablet — resolve dois problemas de uma vez:
///
/// 1. numa tela de 1000dp, três destinos espalhados na largura toda ficam feios
///    e longe do polegar;
/// 2. no **celular deitado** (640×360, que também é `medium`), a pílula mais os
///    88dp de `kFloatingNavReserve` comiam ~24% de uma tela que já tem 360dp de
///    altura. Em pé essa reserva é barata; deitado ela é a tela inteira.
///
/// O trilho usa o mesmo vidro, o mesmo fallback sólido e o `NavigationRail`
/// **nativo** — a semântica de aba do leitor de tela continua vindo do
/// framework, como já vinha na barra.
class NavShell extends StatelessWidget {
  const NavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    if (WindowClass.of(context).usaTrilho) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            _GlassRail(navigationShell: navigationShell),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    return Scaffold(
      extendBody: true, // conteúdo rola POR BAIXO da barra flutuante
      body: navigationShell,
      bottomNavigationBar: _GlassBottomBar(navigationShell: navigationShell),
    );
  }
}

/// Os três destinos, em ordem — casa por índice com `branches` em `router.dart`.
///
/// Uma lista só pras duas formas de navegação: barra e trilho não podem
/// divergir, e divergir é o que acontece quando a lista é escrita duas vezes.
const List<({IconData icone, IconData iconeAtivo, String label})> _destinos =
    <({IconData icone, IconData iconeAtivo, String label})>[
      (icone: Icons.home_outlined, iconeAtivo: Icons.home, label: 'Início'),
      (icone: Icons.work_outline, iconeAtivo: Icons.work, label: 'Trabalhos'),
      (
        icone: Icons.settings_outlined,
        iconeAtivo: Icons.settings,
        label: 'Ajustes',
      ),
    ];

/// Troca de aba. Igual nos dois layouts, inclusive o "re-tocar a aba ativa
/// volta pra raiz dela".
void _irPara(StatefulNavigationShell shell, int i) {
  Haptics.select();
  shell.goBranch(i, initialLocation: i == shell.currentIndex);
}

/// Envolve [child] no vidro da casa (blur + fill translúcido), ou no fallback
/// sólido quando "Reduzir transparência" ou leitor de tela estão ativos.
///
/// Um só ramo cria `BackdropFilter` — é o que `nav_glass_test.dart` verifica.
Widget _vidro(
  BuildContext context, {
  required bool solido,
  required Widget child,
}) {
  final Materials m = Theme.of(context).extension<Materials>()!;
  return solido
      ? ColoredBox(color: m.glassFill.withValues(alpha: 1), child: child)
      : BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: m.glassBlurSigma,
            sigmaY: m.glassBlurSigma,
          ),
          child: ColoredBox(color: m.glassFill, child: child),
        );
}

/// A moldura da pílula: sombra, halo esmeralda, borda e o recorte do raio.
Widget _pilula(BuildContext context, {required Widget child}) {
  final Materials m = Theme.of(context).extension<Materials>()!;
  return RepaintBoundary(
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
          child: child,
        ),
      ),
    ),
  );
}

bool _solido(BuildContext context, WidgetRef ref) =>
    MediaQuery.of(context).accessibleNavigation ||
    ref.watch(reduceTransparencyProvider);

/// A pílula de vidro que envolve a `NavigationBar` nativa — o layout de
/// celular em pé.
class _GlassBottomBar extends ConsumerWidget {
  const _GlassBottomBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget bar = NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (int i) => _irPara(navigationShell, i),
      destinations: <NavigationDestination>[
        for (final ({IconData icone, IconData iconeAtivo, String label}) d
            in _destinos)
          NavigationDestination(
            icon: Icon(d.icone),
            selectedIcon: Icon(d.iconeAtivo),
            label: d.label,
          ),
      ],
    );

    // Aqui morava um banner de anúncio ancorado. Saiu em 19/07/2026: no nosso
    // nicho, anúncio dói 2,48× mais que a média do mercado, por eCPM de
    // centavos — ver `core/ads/ads.dart` pro número e o raciocínio.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x3),
        child: _pilula(
          context,
          child: _vidro(context, solido: _solido(context, ref), child: bar),
        ),
      ),
    );
  }
}

/// O trilho de vidro — `medium` pra cima. Mesma gramática visual da pílula,
/// deitada de lado.
class _GlassRail extends ConsumerWidget {
  const _GlassRail({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WindowClass w = WindowClass.of(context);
    final Widget rail = NavigationRail(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (int i) => _irPara(navigationShell, i),
      backgroundColor: Colors.transparent,
      // Em `expanded` sobra largura: o rótulo fica sempre visível, que é uma
      // parada de leitura a menos. Em `medium` — inclusive o celular deitado —
      // o rótulo só aparece no selecionado, pra não roubar largura do conteúdo.
      labelType: w.isExpanded
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
      extended: w.isExpanded,
      destinations: <NavigationRailDestination>[
        for (final ({IconData icone, IconData iconeAtivo, String label}) d
            in _destinos)
          NavigationRailDestination(
            icon: Icon(d.icone),
            selectedIcon: Icon(d.iconeAtivo),
            label: Text(d.label),
          ),
      ],
    );

    // A pílula ABRAÇA os três destinos, ancorada no topo — ela não estica pela
    // altura da tela. Um trilho de 1250px com três ícones deixa um vão que
    // parece erro de layout, e centrar os destinos só move o vão pra cima, que
    // é onde o olho vai primeiro. A barra de baixo já é uma pílula que abraça
    // o conteúdo; o trilho é a mesma pílula, de pé.
    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.x3, Space.x3, 0, Space.x3),
        child: Align(
          alignment: Alignment.topCenter,
          child: IntrinsicHeight(
            child: _pilula(
              context,
              child: _vidro(
                context,
                solido: _solido(context, ref),
                child: rail,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
