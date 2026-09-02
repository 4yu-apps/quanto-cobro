import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/theme/materials.dart';
import '../core/theme/motion.dart';
import '../core/theme/tokens.dart';
import '../core/ui/a11y.dart';
import '../core/ui/breakpoints.dart';
import 'routes.dart';

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

/// O gesto mais frequente do app, alcançável de QUALQUER aba: um círculo
/// esmeralda colado na pílula, com rótulo (público leigo: rótulo é o mapa).
/// Some enquanto não existe preço calculado: sem valor-hora não há reserva a
/// fazer, e um botão que abre uma tela que pede pra "calcular primeiro" é
/// promessa quebrada no primeiro toque.
///
/// A checagem de visibilidade mora só AQUI, não em quem chama: `_GlassRail`
/// não tem `Consumer` nenhum, então já dependia deste retorno vazio; duplicar
/// a mesma condição lá fora (como no bruto do plano) é duas cópias que
/// divergem na primeira mudança. O vão de 12dp antes do círculo também mora
/// aqui dentro — sem preço, sem botão e sem vão.
class _BotaoRecebi extends ConsumerWidget {
  const _BotaoRecebi({this.compacto = false});

  /// No trilho lateral não cabe o rótulo embaixo: só o círculo, com tooltip.
  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(areaAtivaProvider) is! AreaPronta) {
      return const SizedBox.shrink();
    }

    void aoTocar() {
      Haptics.select();
      context.push(Routes.entrada);
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    // Puramente decorativo: quem escuta o toque é o único `InkWell` abaixo,
    // que cobre o círculo E o rótulo. Antes o círculo era um `FilledButton`
    // com `onPressed` próprio, dentro de um `GestureDetector` externo — dois
    // donos de toque na mesma geometria, e só funcionava porque a arena de
    // gestos escolhe um vencedor. `cs.primary` é o mesmo valor que o
    // `FilledButton` já resolvia por padrão: nenhuma cor nova na paleta.
    final Widget circulo = Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
      child: Icon(Icons.payments_outlined, size: 26, color: cs.onPrimary),
    );
    final Widget miolo = compacto
        ? circulo
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              circulo,
              const SizedBox(height: Space.x1),
              Text(
                'Recebi',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
    // Um `InkWell` só, do tamanho do círculo + rótulo: mesmo padrão de
    // `_AnelReserva` (`painel_screen.dart`) e `ToolActionCard`
    // (`tool_action_card.dart`) — visual puramente decorativo, um único
    // widget interativo por baixo, `SemanticButton` por cima. Dá ripple no
    // rótulo também, que um `GestureDetector` cru não dava.
    final Widget interativo = Tooltip(
      message: 'Recebi um pagamento',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: aoTocar,
          borderRadius: const BorderRadius.all(Radii.lg),
          child: miolo,
        ),
      ),
    );
    // `SemanticButton` é a casa (ver `core/ui/a11y.dart`): a ação de toque é
    // obrigatória por assinatura, ao contrário de um `Semantics(button:) +
    // ExcludeSemantics` cru, que apagaria a `SemanticsAction.tap` de dentro e
    // deixaria um nó que diz "é botão" sem oferecer ação nenhuma — invisível
    // pro Switch Access, mudo pro VoiceOver.
    final Widget botao = SemanticButton(
      label: 'Recebi um pagamento',
      onTap: aoTocar,
      child: interativo,
    );
    // O vão/padding mora aqui, não em quem chama: um botão escondido
    // (`SizedBox.shrink()` acima) não pode deixar vão nenhum pra trás, nem na
    // barra de baixo (Ruling E) nem no trilho lateral.
    return compacto
        ? Padding(
            padding: const EdgeInsets.only(top: Space.x2, bottom: Space.x2),
            child: botao,
          )
        : Padding(
            padding: const EdgeInsets.only(left: Space.x3, bottom: 2),
            child: botao,
          );
  }
}

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: _pilula(
                context,
                child: _vidro(
                  context,
                  solido: _solido(context, ref),
                  child: bar,
                ),
              ),
            ),
            const _BotaoRecebi(),
          ],
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
      leading: const _BotaoRecebi(compacto: true),
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
