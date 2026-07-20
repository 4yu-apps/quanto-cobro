import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/text_scale.dart';
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
  late final bool _primeiraAbertura;

  @override
  void initState() {
    super.initState();
    final bool onboardingDone = ref
        .read(settingsRepositoryProvider)
        .onboardingDone();
    _primeiraAbertura = !onboardingDone;
    _router = createAppRouter(
      initialLocation: onboardingDone ? Routes.painel : Routes.onboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    final double appMult = ref.watch(textScaleProvider);
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
      // A escala de texto (multiplicador do app sobre o fator do sistema)
      // envolve SÓ o child — o splash fica fora pra não distorcer a marca.
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mq = MediaQuery.of(context);
        final double sysFactor = mq.textScaler.scale(14) / 14;
        final double eff = effectiveTextScale(sysFactor, appMult);
        final Widget scaled = MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(eff)),
          child: child ?? const SizedBox.shrink(),
        );
        return Stack(
          children: <Widget>[
            scaled,
            if (!_splashDone)
              SplashOverlay(
                primeiraAbertura: _primeiraAbertura,
                onDone: () => setState(() => _splashDone = true),
              ),
          ],
        );
      },
    );
  }
}
