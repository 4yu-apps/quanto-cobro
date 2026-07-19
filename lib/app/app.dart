import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import '../features/splash/splash_overlay.dart';
import 'router.dart';
import 'routes.dart';

/// Shell do app: MaterialApp.router com os dois temas (ESCURO é o padrão, DS §3).
/// Decide a tela inicial uma vez, pelo primeiro uso (onboarding).
/// Localizado em pt-BR de ponta a ponta: os controles do sistema (voltar, menus
/// de texto, dialogs) falam a língua do app — inclusive no TalkBack.
class QuantoCobroApp extends ConsumerStatefulWidget {
  const QuantoCobroApp({super.key});

  @override
  ConsumerState<QuantoCobroApp> createState() => _QuantoCobroAppState();
}

class _QuantoCobroAppState extends ConsumerState<QuantoCobroApp> {
  late final GoRouter _router;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    final bool onboardingDone = ref
        .read(settingsRepositoryProvider)
        .onboardingDone();
    _router = createAppRouter(
      initialLocation: onboardingDone ? Routes.painel : Routes.onboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    // Reduce-motion também vale pro cross-fade de troca de tema (a fresta que
    // faltava pro gate cobrir 100%). Lido direto do sistema: aqui ainda não
    // existe MediaQuery (ele nasce dentro do MaterialApp).
    final bool reduce = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      themeAnimationStyle: reduce ? AnimationStyle.noAnimation : null,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
      // Brand reveal por cima do app já pronto (não é loading). Sai sozinho.
      builder: (BuildContext context, Widget? child) => Stack(
        children: <Widget>[
          child ?? const SizedBox.shrink(),
          if (!_splashDone)
            SplashOverlay(onDone: () => setState(() => _splashDone = true)),
        ],
      ),
    );
  }
}
