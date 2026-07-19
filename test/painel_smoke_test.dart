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

  testWidgets('nav bar de 3 abas troca entre Início, Histórico e Trabalhos', (
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

    // A casca de navegação existe, com as 3 abas.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Trabalhos'), findsOneWidget);

    // Troca pra Histórico → estado vazio da tela renderiza sem crash.
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem reservas'), findsOneWidget);

    // Troca pra Trabalhos → estado vazio dos perfis renderiza.
    await tester.tap(find.text('Trabalhos'));
    await tester.pumpAndSettle();
    expect(find.text('Meus trabalhos'), findsOneWidget);
  });
}
