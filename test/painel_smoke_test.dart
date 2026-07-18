import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sem perfil: Painel mostra o estado vazio com "Começar"', (WidgetTester tester) async {
    // onboarding já visto → cai direto no Painel (que está vazio, sem perfil).
    SharedPreferences.setMockInitialValues(<String, Object>{'onboarding_done': true});
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
