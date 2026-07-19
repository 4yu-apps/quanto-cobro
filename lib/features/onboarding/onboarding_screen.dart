import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/providers.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/divisao_bar.dart';

/// Onboarding (Blueprint §2.3): curto. Fisga a dor, ensina "A Divisão" uma vez,
/// promete privacidade e captura o modo (Brasil x exterior). Mostrado uma vez.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;
  String _modo = 'br';
  static const int _last = 2;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).setModo(_modo);
    await ref.read(settingsRepositoryProvider).setOnboardingDone();
    if (mounted) context.go(Routes.painel);
  }

  void _next() {
    if (_page == _last) {
      _finish();
    } else {
      _pc.nextPage(
        duration: reduceMotionOf(context)
            ? const Duration(milliseconds: 1)
            : Motion.base,
        curve: MotionCurves.standard,
      );
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
              child: PageView(
                controller: _pc,
                onPageChanged: (int i) {
                  setState(() => _page = i);
                  announce(
                    context,
                    'Página ${i + 1} de ${_last + 1}. ${_pageTitle(i)}',
                  );
                },
                children: <Widget>[_page1(theme), _page2(theme), _page3(theme)],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i <= _last; i++)
                  AnimatedContainer(
                    duration: reduceMotionOf(context)
                        ? Duration.zero
                        : Motion.base,
                    curve: MotionCurves.standard,
                    width: i == _page ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radii.full),
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Space.x6),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_page == _last ? 'Começar' : 'Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageBody(
    ThemeData theme, {
    required IconData? icon,
    required String title,
    required String body,
    Widget? extra,
  }) {
    return Padding(
      padding: const EdgeInsets.all(Space.x8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: Space.x6),
          ],
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: Space.x3),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (extra != null) ...<Widget>[
            const SizedBox(height: Space.x6),
            extra,
          ],
        ],
      ),
    );
  }

  Widget _page1(ThemeData theme) => _pageBody(
    theme,
    icon: Icons.savings_outlined,
    title: 'Pare de trabalhar de graça.',
    body:
        'Descubra quanto cobrar por hora, quanto guardar pro imposto e quanto realmente sobra.',
  );

  String _pageTitle(int page) => switch (page) {
    0 => 'Pare de trabalhar de graça.',
    1 => 'Veja pra onde vai cada real.',
    _ => '100 por cento no seu aparelho.',
  };

  Widget _page2(ThemeData theme) => _pageBody(
    theme,
    icon: null,
    title: 'Veja pra onde vai cada real.',
    body:
        'Toda vez que um pagamento cair, o app mostra o que é seu, o que é imposto e o que foi custo.',
    extra: Card(
      color: theme.colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.x5),
        child: ExcludeSemantics(
          child: KeyedSubtree(
            key: ValueKey<bool>(_page == 1),
            child: const DivisaoBar(
              lucro: 5000,
              reserva: 1600,
              custo: 850,
              bornDelay: Motion.quick,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _page3(ThemeData theme) => _pageBody(
    theme,
    icon: Icons.lock_outline,
    title: '100% no seu aparelho.',
    body:
        'Sem cadastro, sem login, sem enviar seus dados pra ninguém. É só abrir e usar, mesmo offline. Isso só deixa pré-escolhido como você trabalha; você confirma depois.',
    extra: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Você trabalha mais pra clientes:',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: Space.x2),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: 'br', label: Text('No Brasil')),
            ButtonSegment<String>(value: 'intl', label: Text('No exterior')),
          ],
          selected: <String>{_modo},
          onSelectionChanged: (Set<String> s) =>
              setState(() => _modo = s.first),
        ),
      ],
    ),
  );
}
