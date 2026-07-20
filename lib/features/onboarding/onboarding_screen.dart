import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/providers.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/breakpoints.dart';

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

  /// Duas páginas, não três. A do meio era uma AULA sobre a Divisão dada a
  /// quem ainda não tinha visto número nenhum — e a pergunta "Brasil x
  /// exterior" saiu junto: ela é feita de novo, melhor e no contexto certo, no
  /// passo do regime. Fazer a mesma pergunta duas vezes, a primeira antes de
  /// entregar qualquer valor, é o retrato do app que cobra antes de dar.
  static const int _last = 1;

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
                children: <Widget>[_page1(theme), _page3(theme)],
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
    // Este corpo era uma Column NÃO-ROLÁVEL entre um "Pular" fixo e um botão
    // fixo. Contas: 360dp de altura menos a moldura deixavam ~170dp pra um
    // círculo de 96 mais dois blocos de texto. Estourava 148px no celular
    // deitado — e 972px com fonte 200%, que é o público que mais precisa
    // desta tela. Em 320×640 com fonte normal já estourava 24px.
    //
    // A rolagem resolve sem tirar nada. O `minHeight` da altura do viewport é
    // o que preserva o enquadramento: em tela alta a Column continua centrada
    // como antes, e em tela baixa ela cresce além do viewport e a pessoa rola
    // — em vez de perder conteúdo pra sempre.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) =>
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: ContentWidth(
                child: _pageColumn(theme, icon, title, body, extra),
              ),
            ),
          ),
    );
  }

  Widget _pageColumn(
    ThemeData theme,
    IconData? icon,
    String title,
    String body,
    Widget? extra,
  ) {
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
    _ => '100 por cento no seu aparelho.',
  };

  Widget _page3(ThemeData theme) => _pageBody(
    theme,
    icon: Icons.lock_outline,
    title: '100% no seu aparelho.',
    body:
        'Sem cadastro, sem login, sem enviar seus dados pra ninguém. É só abrir e usar, mesmo offline.',
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
