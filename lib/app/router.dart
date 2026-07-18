import 'package:go_router/go_router.dart';

import '../core/model/perfil.dart';
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

/// Navegação hub-and-spoke centrada no Painel (Blueprint §4.2). A tela inicial
/// depende do primeiro uso: onboarding uma vez, depois o Painel.
GoRouter createAppRouter({String initialLocation = Routes.painel}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(path: Routes.painel, builder: (_, _) => const PainelScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.calc, builder: (_, _) => const CalcScreen()),
      GoRoute(
        path: Routes.resultado,
        builder: (_, GoRouterState state) => ResultadoScreen(perfil: state.extra as Perfil?),
      ),
      GoRoute(path: Routes.detalhe, builder: (_, _) => const DetalheScreen()),
      GoRoute(path: Routes.reserva, builder: (_, _) => const ReservaScreen()),
      GoRoute(path: Routes.simulador, builder: (_, _) => const SimuladorScreen()),
      GoRoute(path: Routes.perfis, builder: (_, _) => const PerfisScreen()),
      GoRoute(path: Routes.config, builder: (_, _) => const ConfigScreen()),
      GoRoute(path: Routes.pro, builder: (_, _) => const ProScreen()),
      GoRoute(path: Routes.legal, builder: (_, _) => const LegalScreen()),
      GoRoute(path: Routes.historico, builder: (_, _) => const HistoricoScreen()),
    ],
  );
}
