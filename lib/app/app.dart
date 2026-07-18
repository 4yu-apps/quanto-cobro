import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';
import 'routes.dart';

/// Shell do app: MaterialApp.router com os dois temas (ESCURO é o padrão, DS §3).
/// Decide a tela inicial uma vez, pelo primeiro uso (onboarding).
class QuantoCobroApp extends ConsumerStatefulWidget {
  const QuantoCobroApp({super.key});

  @override
  ConsumerState<QuantoCobroApp> createState() => _QuantoCobroAppState();
}

class _QuantoCobroAppState extends ConsumerState<QuantoCobroApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final bool onboardingDone = ref.read(settingsRepositoryProvider).onboardingDone();
    _router = createAppRouter(
      initialLocation: onboardingDone ? Routes.painel : Routes.onboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: _router,
    );
  }
}
