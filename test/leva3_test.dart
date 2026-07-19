import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/theme/motion.dart';
import 'package:quantocobro/core/ui/money_count_up.dart';
import 'package:quantocobro/core/ui/vitrine_card.dart';

void main() {
  test('MoneyCountUp usa MotionCurves.landing como curva default', () {
    const MoneyCountUp countUp = MoneyCountUp(42, style: TextStyle());
    expect(countUp.curve, MotionCurves.landing);
  });

  testWidgets('VitrineCard(highlight: true) acende sem exceção', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: VitrineCard(highlight: true, child: Text('x')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('x'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('VitrineCard(highlight: false) renderiza sem exceção', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: VitrineCard(highlight: false, child: Text('x')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('x'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
