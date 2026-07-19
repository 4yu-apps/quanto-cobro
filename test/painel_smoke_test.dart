import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sem perfil: Painel mostra o estado vazio com "Começar"', (
    WidgetTester tester,
  ) async {
    // onboarding já visto → cai direto no Painel (que está vazio, sem perfil).
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const QuantoCobroApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Começar'), findsOneWidget);
    expect(
      find.text('Você provavelmente cobra menos do que deveria.'),
      findsOneWidget,
    );
  });

  // v0.6 (07 §B.2): o slot do meio deixou de ser "Trabalhos" (presets de preço)
  // e virou "Projetos" (os clientes). Continuam TRÊS abas — foi troca, não
  // adição: este teste é o que impede uma 4ª de aparecer sem decisão.
  testWidgets('nav bar de 3 abas troca entre Início, Projetos e Guardado', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const QuantoCobroApp(),
      ),
    );
    await tester.pumpAndSettle();

    // A casca de navegação existe, com as 3 abas — e nenhuma a mais.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(3),
    );
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Projetos'), findsOneWidget);
    expect(find.text('Guardado'), findsOneWidget);
    expect(find.text('Trabalhos'), findsNothing);

    // Troca pra Guardado → estado vazio da tela renderiza sem crash.
    await tester.tap(find.text('Guardado'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem reservas'), findsOneWidget);

    // Troca pra Projetos → estado vazio da gestão renderiza.
    await tester.tap(find.text('Projetos'));
    await tester.pumpAndSettle();
    expect(find.text('Seus projetos, num lugar só.'), findsOneWidget);
  });
}
