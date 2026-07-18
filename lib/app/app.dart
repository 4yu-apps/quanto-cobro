import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/providers.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

/// Shell do app: MaterialApp.router com os dois temas. O ESCURO é o padrão
/// (Design System §3); o usuário pode trocar em Configurações.
class QuantoCobroApp extends ConsumerWidget {
  const QuantoCobroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: appRouter,
    );
  }
}
