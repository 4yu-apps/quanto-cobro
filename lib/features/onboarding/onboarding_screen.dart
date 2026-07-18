import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';

/// Onboarding (Blueprint §2.3): curto. Fisga a dor e promete privacidade. Não é
/// tutorial. Mostrado uma vez; depois o Painel é a casa.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  static const List<(String, String, IconData)> _pages = <(String, String, IconData)>[
    (
      'Pare de trabalhar de graça.',
      'Descubra quanto cobrar por hora, quanto guardar pro imposto e quanto realmente sobra.',
      Icons.savings_outlined,
    ),
    (
      '100% no seu aparelho.',
      'Sem cadastro, sem login, sem enviar seus dados pra ninguém. É só abrir e usar, mesmo offline.',
      Icons.lock_outline,
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pages.length - 1;

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).setOnboardingDone();
    if (mounted) context.go(Routes.painel);
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Pular')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (int i) => setState(() => _page = i),
                itemBuilder: (BuildContext context, int i) {
                  final (String title, String body, IconData icon) = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(icon, size: 48, color: theme.colorScheme.primary),
                        const SizedBox(height: 24),
                        Text(title, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        Text(body, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < _pages.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? 'Começar' : 'Continuar'),
                ),
              ),
            ),
            Text('${AppConfig.appName} · ${AppConfig.parentBrand}',
                style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
