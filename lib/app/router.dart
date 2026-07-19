import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/model/perfil.dart';
import '../core/theme/motion.dart';
import '../core/theme/tokens.dart';
import '../features/calc/calc_screen.dart';
import '../features/config/config_screen.dart';
import '../features/detalhe/detalhe_screen.dart';
import '../features/historico/historico_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/painel/painel_screen.dart';
import '../features/perfis/perfis_screen.dart';
import '../features/pro/pro_screen.dart';
import '../features/reserva/reserva_screen.dart';
import '../features/resultado/resultado_screen.dart';
import '../features/simulador/simulador_screen.dart';
import 'nav_shell.dart';
import 'routes.dart';

/// Dois sabores de transição (MOTION-SPEC §2):
/// - tool: rápida, desliza 6% da direita ("abri uma gaveta ao lado do hub").
/// - flow: sobe 8% do rodapé, mais pesada ("entrei num modo focado / a resposta chega").
/// Em reduce-motion, corte seco.
CustomTransitionPage<void> _toolPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.base,
    reverseTransitionDuration: Motion.base,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> a,
          Animation<double> _,
          Widget child,
        ) {
          if (reduceMotionOf(context)) return child;
          final CurvedAnimation curved = CurvedAnimation(
            parent: a,
            curve: MotionCurves.standard,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
  );
}

CustomTransitionPage<void> _flowPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.emphasized,
    reverseTransitionDuration: Motion.base,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> a,
          Animation<double> _,
          Widget child,
        ) {
          if (reduceMotionOf(context)) return child;
          return FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: MotionCurves.standard),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: a,
                      curve: MotionCurves.emphasizedDecel,
                    ),
                  ),
              child: child,
            ),
          );
        },
  );
}

/// Navegação v0.5: uma casca de 3 abas (Início · Histórico · Trabalhos) via
/// `StatefulShellRoute` — o app ganha um mapa visível. Fluxos e ferramentas
/// (calc, resultado, reserva, simulador, detalhe, config, pro, legal) e o
/// onboarding ficam TOP-LEVEL, acima da casca (cobrem a barra). A tela inicial
/// depende do primeiro uso: onboarding uma vez, depois o Painel (aba Início).
GoRouter createAppRouter({String initialLocation = Routes.painel}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      // Fluxos (mudança de modo): sobem do rodapé.
      GoRoute(
        path: Routes.calc,
        pageBuilder: (_, GoRouterState s) {
          final Object? extra = s.extra;
          return _flowPage(
            s,
            CalcScreen(
              novoTrabalho: extra is String ? extra : null,
              initialDraft: extra is Perfil ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.resultado,
        pageBuilder: (_, GoRouterState s) =>
            _flowPage(s, ResultadoScreen(perfil: s.extra as Perfil?)),
      ),
      GoRoute(
        path: Routes.pro,
        pageBuilder: (_, GoRouterState s) => _flowPage(s, const ProScreen()),
      ),
      // Tools/consulta: gaveta lateral rápida.
      GoRoute(
        path: Routes.detalhe,
        pageBuilder: (_, GoRouterState s) =>
            _toolPage(s, const DetalheScreen()),
      ),
      GoRoute(
        path: Routes.reserva,
        pageBuilder: (_, GoRouterState s) =>
            _toolPage(s, const ReservaScreen()),
      ),
      GoRoute(
        path: Routes.simulador,
        pageBuilder: (_, GoRouterState s) =>
            _toolPage(s, const SimuladorScreen()),
      ),
      GoRoute(
        path: Routes.config,
        pageBuilder: (_, GoRouterState s) => _toolPage(s, const ConfigScreen()),
      ),
      GoRoute(
        path: Routes.legal,
        pageBuilder: (_, GoRouterState s) => _toolPage(s, const LegalScreen()),
      ),
      // Casca de 3 abas (IndexedStack preserva o estado de cada uma).
      StatefulShellRoute.indexedStack(
        builder:
            (_, _, StatefulNavigationShell shell) => NavShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.painel,
                builder: (_, _) => const PainelScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.historico,
                builder: (_, _) => const HistoricoScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.perfis,
                builder: (_, _) => const PerfisScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
