import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

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

  // v0.7: as três abas viraram **Início · Trabalhos · Ajustes**.
  //
  // "Guardado" saiu porque era o mesmo balde do card do mês no Início, num
  // zoom maior — e slot de aba é caro demais pra um zoom. "Recebidos" foi
  // recusado de propósito: o nome da aba ensina o modelo mental, e ele
  // anunciaria um app de ficar marcando recebimento, que é o que este app NÃO
  // é. Continuam TRÊS — este teste é o que impede uma 4ª aparecer sem decisão.
  //
  // Em celular EM PÉ a casca é a barra de baixo. De `medium` pra cima ela vira
  // trilho lateral — o teste logo abaixo cobre esse caso. Fixar a tela aqui é
  // o que torna a distinção testável: sem isso este teste rodava em 800×600,
  // que não é celular nenhum.
  testWidgets(
    'celular em pé: nav bar de 3 abas — Início · Trabalhos · Ajustes',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_done': true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await comTela(tester, Tela.celularEmPe, () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const QuantoCobroApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
        expect(
          tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
          hasLength(3),
        );
        expect(find.text('Início'), findsOneWidget);
        expect(find.text('Trabalhos'), findsOneWidget);
        expect(find.text('Ajustes'), findsOneWidget);

        expect(find.text('Guardado'), findsNothing);
        expect(find.text('Projetos'), findsNothing);
        expect(find.text('Recebidos'), findsNothing);

        await tester.tap(find.text('Trabalhos'));
        await tester.pumpAndSettle();
        expect(find.text('Seus trabalhos, num lugar só.'), findsOneWidget);

        await tester.tap(find.text('Ajustes'));
        await tester.pumpAndSettle();
        // A aba e a tela têm que dizer o MESMO nome: quem navega por fala
        // confere o título pra saber que chegou no lugar certo (WCAG 3.2.4).
        // Antes a aba dizia "Ajustes" e a tela se anunciava "Configurações".
        expect(find.text('Configurações'), findsNothing);
        expect(find.widgetWithText(AppBar, 'Ajustes'), findsOneWidget);
      });
    },
  );

  // A partir de `medium` (600dp) a casca vira trilho. Vale pro tablet e vale —
  // principalmente — pro celular DEITADO: lá a pílula + os 88dp de reserva
  // comiam quase um quarto de uma tela de 360dp de altura.
  //
  // O que este teste protege é que a troca seja de FORMA, não de conteúdo: os
  // mesmos três destinos, na mesma ordem, com os mesmos rótulos.
  for (final Tela tela in <Tela>[Tela.celularDeitado, Tela.tabletDeitado]) {
    testWidgets('${tela.name}: a casca vira trilho, com as mesmas 3 abas', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_done': true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await comTela(tester, tela, () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const QuantoCobroApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(
          tester
              .widget<NavigationRail>(find.byType(NavigationRail))
              .destinations,
          hasLength(3),
        );

        await tester.tap(find.byIcon(Icons.work_outline));
        await tester.pumpAndSettle();
        expect(find.text('Seus trabalhos, num lugar só.'), findsOneWidget);
      });
    });
  }
}
