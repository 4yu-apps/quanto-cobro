import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/model/area.dart';
import '../core/telemetry/eventos.dart';
import '../core/theme/motion.dart';
import '../core/theme/tokens.dart';
import '../features/areas/areas_screen.dart';
import '../features/calc/calc_screen.dart';
import '../features/config/config_screen.dart';
import '../features/detalhe/detalhe_screen.dart';
import '../features/entrada/entrada_screen.dart';
import '../features/historico/historico_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/painel/painel_screen.dart';
import '../features/pro/pro_screen.dart';
import '../features/proposta/marca_screen.dart';
import '../features/proposta/proposta_flow.dart';
import '../features/proposta/proposta_screen.dart';
import '../features/resultado/resultado_screen.dart';
import '../features/simulador/simulador_screen.dart';
import '../features/trabalhos/trabalho_detalhe_screen.dart';
import '../features/trabalhos/trabalho_form_screen.dart';
import '../features/trabalhos/trabalhos_screen.dart';
import 'nav_shell.dart';
import 'routes.dart';

/// Dois sabores de transição (MOTION-SPEC §2):
/// - tool: rápida, desliza 6% da direita ("abri uma gaveta ao lado do hub").
/// - flow: sobe 8% do rodapé, mais pesada ("entrei num modo focado").
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

/// Navegação v0.7: casca de 3 abas — **Início · Trabalhos · Configurações**.
///
/// "Guardado" deixou de ser aba: era o mesmo balde do card do Início, num zoom
/// maior. E "Recebidos" foi recusado de propósito — o nome da aba ensina o
/// modelo mental, e ele anunciaria um app de ficar marcando recebimento, que é
/// exatamente o que este app NÃO é.
GoRouter createAppRouter({String initialLocation = Routes.painel}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),

      // ---- Fluxos (mudança de modo): sobem do rodapé ----
      GoRoute(
        path: Routes.calc,
        pageBuilder: (_, GoRouterState s) {
          final Object? extra = s.extra;
          return _flowPage(
            s,
            CalcScreen(
              novaArea: extra is String ? extra : null,
              initialDraft: extra is Area ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.resultado,
        pageBuilder: (_, GoRouterState s) =>
            _flowPage(s, ResultadoScreen(area: s.extra as Area?)),
      ),
      GoRoute(
        path: Routes.pro,
        // `extra` = o gatilho que trouxe a pessoa até aqui (GatilhoPro.*).
        pageBuilder: (_, GoRouterState s) => _flowPage(
          s,
          ProScreen(
            gatilho: s.extra is String ? s.extra! as String : GatilhoPro.config,
          ),
        ),
      ),
      GoRoute(
        path: Routes.proposta,
        pageBuilder: (_, GoRouterState s) =>
            _flowPage(s, PropostaScreen(args: s.extra as PropostaArgs)),
      ),
      GoRoute(
        path: Routes.trabalhoForm,
        pageBuilder: (_, GoRouterState s) =>
            _flowPage(s, TrabalhoFormScreen(trabalhoId: s.extra as String?)),
      ),

      // ---- Ferramentas/consulta: gaveta lateral rápida ----
      // Registrar uma entrada é FLUXO, não gaveta: é o gesto mais importante
      // do app e uma mudança de modo ("agora eu vou guardar dinheiro"). Abria
      // com a mesma transição das Configurações.
      GoRoute(
        path: Routes.entrada,
        // `extra` = id do trabalho, quando veio do detalhe dele.
        pageBuilder: (_, GoRouterState s) =>
            _flowPage(s, EntradaScreen(trabalhoId: s.extra as String?)),
      ),
      GoRoute(
        path: Routes.detalhe,
        pageBuilder: (_, GoRouterState s) =>
            _toolPage(s, const DetalheScreen()),
      ),
      GoRoute(
        path: Routes.simulador,
        pageBuilder: (_, GoRouterState s) =>
            _toolPage(s, const SimuladorScreen()),
      ),
      GoRoute(
        path: Routes.trabalhoDetalhe,
        pageBuilder: (_, GoRouterState s) => _toolPage(
          s,
          TrabalhoDetalheScreen(trabalhoId: s.extra as String? ?? ''),
        ),
      ),
      GoRoute(
        path: Routes.historico,
        pageBuilder: (_, GoRouterState s) =>
            _toolPage(s, const HistoricoScreen()),
      ),
      GoRoute(
        path: Routes.areas,
        pageBuilder: (_, GoRouterState s) => _toolPage(s, const AreasScreen()),
      ),
      GoRoute(
        path: Routes.legal,
        pageBuilder: (_, GoRouterState s) => _toolPage(s, const LegalScreen()),
      ),
      GoRoute(
        path: Routes.marca,
        pageBuilder: (_, GoRouterState s) =>
            _toolPage(s, MarcaScreen(primeiraVez: s.extra == true)),
      ),

      // ---- A casca de 3 abas (IndexedStack preserva o estado de cada uma) ----
      // A ORDEM aqui casa por índice com `destinations` em `nav_shell.dart`.
      StatefulShellRoute.indexedStack(
        builder: (_, _, StatefulNavigationShell shell) =>
            NavShell(navigationShell: shell),
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
                path: Routes.trabalhos,
                builder: (_, _) => const TrabalhosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.config,
                builder: (_, _) => const ConfigScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
