// test/resultado_copy_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/resultado/resultado_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('resultado não diz "faturados"; diz o que precisa cobrar', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
      'regime': 'mei',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: ResultadoScreen(area: Area.padrao()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('faturados'), findsNothing);
    expect(find.textContaining('precisa cobrar'), findsOneWidget);
  });
}
