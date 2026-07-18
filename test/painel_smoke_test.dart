import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('primeiro uso: Painel mostra o estado vazio com "Começar"', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const QuantoCobroApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Começar'), findsOneWidget);
    expect(find.text('Você provavelmente cobra menos do que deveria.'), findsOneWidget);
  });
}
