import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, {required bool reduce}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    if (reduce) 'reduce_transparency': true,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const QuantoCobroApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('navbar usa vidro (BackdropFilter) por padrão', (
    WidgetTester t,
  ) async {
    await _pump(t, reduce: false);
    expect(find.byType(BackdropFilter), findsWidgets);
  });

  testWidgets(
    'com Reduzir transparência, navbar cai pro fallback opaco (sem blur)',
    (WidgetTester t) async {
      await _pump(t, reduce: true);
      expect(find.byType(BackdropFilter), findsNothing);
    },
  );
}
