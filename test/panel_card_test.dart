import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/panel_card.dart';

void main() {
  testWidgets(
    'PanelCard renderiza o filho e não usa BackdropFilter (é faux-glass)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: PanelCard(child: Text('conteúdo'))),
        ),
      );
      expect(find.text('conteúdo'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing); // vidro real só na nav
    },
  );
}
