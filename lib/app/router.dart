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
        (BuildContext context, Animation<double> a, Animation<double> _, Widget child) {
      if (reduceMotionOf(context)) return child;
      final CurvedAnimation curved = CurvedAnimation(parent: a, curve: MotionCurves.standard);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
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
        (BuildContext context, Animation<double> a, Animation<double> _, Widget child) {
      if (reduceMotionOf(context)) return child;
      return FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: MotionCurves.standard),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: MotionCurves.emphasizedDecel)),
          child: child,
        ),
      );
    },
  );
}

/// Navegação hub-and-spoke centrada no Painel (Blueprint §4.2). A tela inicial
/// depende do primeiro uso: onboarding uma vez, depois o Painel.
GoRouter createAppRouter({String initialLocation = Routes.painel}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      // Raízes: default (a chegada do Painel já tem o stagger próprio).
      GoRoute(path: Routes.painel, builder: (_, _) => const PainelScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      // Fluxos (mudança de modo): sobem do rodapé.
      GoRoute(
          path: Routes.calc,
          pageBuilder: (_, GoRouterState s) => _flowPage(s, const CalcScreen())),
      GoRoute(
        path: Routes.resultado,
        pageBuilder: (_, GoRouterState s) =>
            _flowPage(s, ResultadoScreen(perfil: s.extra as Perfil?)),
      ),
      GoRoute(
          path: Routes.pro,
          pageBuilder: (_, GoRouterState s) => _flowPage(s, const ProScreen())),
      // Tools/consulta: gaveta lateral rápida.
      GoRoute(
          path: Routes.detalhe,
          pageBuilder: (_, GoRouterState s) => _toolPage(s, const DetalheScreen())),
      GoRoute(
          path: Routes.reserva,
          pageBuilder: (_, GoRouterState s) => _toolPage(s, const ReservaScreen())),
      GoRoute(
          path: Routes.simulador,
          pageBuilder: (_, GoRouterState s) => _toolPage(s, const SimuladorScreen())),
      GoRoute(
          path: Routes.perfis,
          pageBuilder: (_, GoRouterState s) => _toolPage(s, const PerfisScreen())),
      GoRoute(
          path: Routes.config,
          pageBuilder: (_, GoRouterState s) => _toolPage(s, const ConfigScreen())),
      GoRoute(
          path: Routes.legal,
          pageBuilder: (_, GoRouterState s) => _toolPage(s, const LegalScreen())),
      GoRoute(
          path: Routes.historico,
          pageBuilder: (_, GoRouterState s) => _toolPage(s, const HistoricoScreen())),
    ],
  );
}
