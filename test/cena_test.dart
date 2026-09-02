import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/cena.dart';
import 'package:quantocobro/core/ui/cofre_mark.dart';

/// L4 — a ilustração assinatura. O que ela precisa garantir: a marca da casa
/// aparece nos dois tipos (é ela que separa "app de IA" de "app com dono"), e
/// nada disso chega ao leitor de tela, que é decoração pura.
void main() {
  for (final CenaTipo tipo in CenaTipo.values) {
    testWidgets(
      'cena $tipo desenha a marca e é decorativa pro leitor de tela',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(body: Center(child: Cena(tipo: tipo))),
          ),
        );
        expect(find.byType(CofreMark), findsOneWidget);
        expect(find.byType(ExcludeSemantics), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
