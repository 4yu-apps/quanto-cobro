import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

/// Shell do app: MaterialApp.router com os dois temas. O ESCURO é o padrão
/// (Design System §3); respeita o sistema quando o usuário escolher.
class QuantoCobroApp extends StatelessWidget {
  const QuantoCobroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
