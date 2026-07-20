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

  /// Três páginas: a dor, a privacidade (+ modo), e o consentimento de
  /// telemetria — nesta ordem. O consentimento é a ÚLTIMA tela de propósito:
  /// pedir permissão de dado como primeira coisa que a pessoa vê seria o retrato
  /// do app que cobra antes de dar. Depois de ela entender que é local-first e
  /// que os números dela ficam no aparelho, o pedido faz sentido — e é honesto,
  /// porque a telemetria é estabilidade anônima, não os dados dela.
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

  /// A escolha da última página. Grava o consentimento (que já liga/desliga a
  /// coleta no lado nativo, via telemetryProvider) e fecha o onboarding. "Pular"
  /// e sair sem escolher = fica desligado, o default seguro.
  Future<void> _finishComConsent(bool aceitou) async {
    await ref.read(telemetryProvider.notifier).set(aceitou);
    if (mounted) {
      announce(
        context,
        aceitou
            ? 'Obrigado. Dá pra desligar quando quiser em Ajustes.'
            : 'Sem problema. Nada será enviado.',
      );
    }
    await _finish();
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
                children: <Widget>[
                  _page1(theme),
                  _page3(theme),
                  _pageConsent(theme),
                ],
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
              child: _page == _last
                  // Consentimento: confirmar é o caminho fácil (preenchido,
                  // domina a largura); recusar é um texto à esquerda — discreto,
                  // mas botão de VERDADE (48dp, alcançável por leitor de tela),
                  // nunca texto morto. Assimetria de ênfase, não de acesso.
                  ? Row(
                      children: <Widget>[
                        TextButton(
                          onPressed: () => _finishComConsent(false),
                          child: const Text('Agora não'),
                        ),
                        const SizedBox(width: Space.x2),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _finishComConsent(true),
                            child: const Text('Sim, pode ajudar'),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        child: const Text('Continuar'),
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
    1 => '100 por cento no seu aparelho.',
    _ => 'Me ajuda a melhorar?',
  };

  Widget _page3(ThemeData theme) => _pageBody(
    theme,
    icon: Icons.lock_outline,
    title: '100% no seu aparelho.',
    // A promessa fala do que É da pessoa — e isso é verdade absoluta: renda,
    // clientes e valores nunca saem do aparelho. Antes dizia "sem enviar dados
    // pra ninguém", o que colidiria com o pedido de telemetria da tela seguinte;
    // agora é preciso, e a próxima tela pede só estabilidade anônima, que é
    // outra coisa.
    body:
        'Sem cadastro, sem login. Sua renda, seus clientes e seus valores ficam só aqui no aparelho, e funciona offline.',
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

  /// A última tela: o pedido de consentimento. Honesto e específico — diz o que
  /// vai e o que NUNCA vai, e que só acontece se a pessoa deixar (LGPD). As
  /// ações vivem na barra inferior (ver build): confirmar preenchido, recusar
  /// como texto.
  Widget _pageConsent(ThemeData theme) => _pageBody(
    theme,
    icon: Icons.favorite_outline,
    title: 'Me ajuda a melhorar?',
    body:
        'Se o app travar ou der erro, ele pode me avisar sozinho: só '
        'estabilidade e uso, de forma anônima. Seus números nunca entram '
        'nisso, e só se você deixar.',
    extra: Text(
      'Dá pra ligar ou desligar quando quiser em Ajustes.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
