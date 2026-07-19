import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/reserva/reserva_bar.dart';

void main() {
  testWidgets('ReservaBar expõe um rótulo de leitor de tela com pra-usar e reserva', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: ReservaBar(amount: 2000, reserva: 320, sobra: 1680),
        ),
      ),
    );

    // A barra deixou de ser muda: o TalkBack agora ouve o valor de cada lado.
    expect(
      find.bySemanticsLabel(RegExp(r'Pra usar.*1\.680.*Reserva.*320')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
