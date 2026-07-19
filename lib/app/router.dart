import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/model/perfil.dart';
import '../core/model/projeto.dart';
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
import '../features/projetos/projeto_detalhe_screen.dart';
import '../features/projetos/projeto_form_screen.dart';
import '../features/projetos/projetos_screen.dart';
import '../features/proposta/marca_screen.dart';
import '../features/proposta/proposta_flow.dart';
import '../features/proposta/proposta_screen.dart';
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
        // `extra` = id do projeto que pagou, quando veio de um card "Recebi".
        pageBuilder: (_, GoRouterState s) => _toolPage(
          s,
          ReservaScreen(
            projetoId: s.extra is String ? s.extra as String : null,
          ),
        ),
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
      // Presets de preço: saíram da aba (v0.6), viraram destino de ferramenta.
      GoRoute(
        path: Routes.perfis,
        pageBuilder: (_, GoRouterState s) => _toolPage(s, const PerfisScreen()),
      ),
      // Gestão de projetos (07 §B). Detalhe/edição empilham acima da aba.
      GoRoute(
        path: Routes.projetoDetalhe,
        pageBuilder: (_, GoRouterState s) => _toolPage(
          s,
          ProjetoDetalheScreen(projetoId: s.extra as String? ?? ''),
        ),
      ),
      GoRoute(
        path: Routes.projetoForm,
        // Espelha o padrão da Calculadora: `String` = editar o de tal id,
        // `Projeto` = rascunho pré-preenchido (nasceu de uma proposta).
        pageBuilder: (_, GoRouterState s) {
          final Object? extra = s.extra;
          return _flowPage(
            s,
            ProjetoFormScreen(
              projetoId: extra is String ? extra : null,
              draft: extra is Projeto ? extra : null,
            ),
          );
        },
      ),
      // Proposta (07 §A): é FLUXO, não destino — sobe do rodapé como a
      // Calculadora, porque é uma mudança de modo ("agora eu falo com o
      // cliente"), não uma gaveta de consulta.
      GoRoute(
        path: Routes.proposta,
        pageBuilder: (_, GoRouterState s) =>
            _flowPage(s, PropostaScreen(args: s.extra as PropostaArgs)),
      ),
      GoRoute(
        path: Routes.marca,
        pageBuilder: (_, GoRouterState s) =>
            _toolPage(s, MarcaScreen(primeiraVez: s.extra == true)),
      ),
      // Casca de 3 abas (IndexedStack preserva o estado de cada uma).
      // A ORDEM aqui é a ordem dos destinos em `nav_shell.dart` — elas são
      // casadas por índice; mexer numa sem a outra troca as abas de lugar.
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
                path: Routes.projetos,
                builder: (_, _) => const ProjetosScreen(),
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
        ],
      ),
    ],
  );
}
