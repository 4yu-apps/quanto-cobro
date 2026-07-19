import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/divisao_bar.dart';

void main() {
  testWidgets('DivisaoBar não estoura em textScaler 2.0 e largura estreita', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SizedBox(
              width: 320,
              child: DivisaoBar(lucro: 1234, reserva: 567, custo: 890),
            ),
          ),
        ),
      ),
    );
    // Se estourar, o pump lança um FlutterError e o teste falha aqui.
    expect(tester.takeException(), isNull);
  });
}
