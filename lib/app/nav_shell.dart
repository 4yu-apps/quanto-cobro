import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/motion.dart';

/// Casca de navegação (v0.5): dá ao app um MAPA visível em 1 olhada — o que um
/// leigo precisa. Três abas (Início · Histórico · Trabalhos). As duas ações
/// recorrentes (Recebi um pagamento / Vou orçar) NÃO são abas — são os cards
/// protagonistas do Painel. Config vive na engrenagem, não gasta slot.
/// Ferramentas e fluxos (calc, reserva, resultado…) empilham ACIMA da casca
/// (cobrem a barra — são modos focados).
class NavShell extends StatelessWidget {
  const NavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int i) {
          Haptics.select();
          navigationShell.goBranch(
            i,
            // Re-tocar a aba ativa volta pra raiz dela.
            initialLocation: i == navigationShell.currentIndex,
          );
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Trabalhos',
          ),
        ],
      ),
    );
  }
}
