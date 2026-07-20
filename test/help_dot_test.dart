import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/help_dot.dart';

void main() {
  testWidgets('tocar no HelpDot abre o balão com o verbete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(child: HelpDot(verbeteId: 'regime')),
        ),
      ),
    );

    // Antes de tocar, o texto do verbete não está na tela.
    expect(find.textContaining('aos olhos do imposto'), findsNothing);

    await tester.tap(find.byType(HelpDot));
    await tester.pumpAndSettle();

    // O balão abriu com título e explicação.
    expect(find.text('O que é "regime"?'), findsOneWidget);
    expect(find.textContaining('aos olhos do imposto'), findsOneWidget);
    expect(find.text('Entendi'), findsOneWidget);
  });

  testWidgets('o HelpDot tem alvo de toque de pelo menos 48dp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(child: HelpDot(verbeteId: 'leao')),
        ),
      ),
    );

    final Size size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
