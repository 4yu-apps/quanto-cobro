import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quantocobro/core/fx/fx_rate.dart';
import 'package:quantocobro/core/fx/fx_repository.dart';
import 'package:quantocobro/core/fx/fx_service.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/reserva/reserva_screen.dart';

/// Fase 3 Task 4 — seletor de moeda + câmbio transparente na Reserva.
/// A tela é offline-first: nunca busca cotação sozinha ao abrir, só lê o
/// cache local — mas escolher uma moeda estrangeira sem cotação em cache
/// É uma ação explícita da pessoa, então dispara a busca na hora. Nesses
/// casos os testes sobrescrevem `fxServiceProvider` com um [FxService]
/// ligado a um `MockClient` — nenhuma chamada de rede real acontece aqui.
void main() {
  final DateTime hoje = DateTime(2026, 7, 19);

  Future<SharedPreferences> prefsComCotacaoUsd() async {
    final FxRate rate = FxRate(par: 'USD->BRL', taxa: 5.0, at: hoje);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
      'fx_rate_v1_USD->BRL': jsonEncode(rate.toJson()),
    });
    return SharedPreferences.getInstance();
  }

  Future<SharedPreferences> prefsSemCotacao() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
    });
    return SharedPreferences.getInstance();
  }

  Future<void> pumpReserva(
    WidgetTester tester,
    SharedPreferences prefs, {
    FxService? fxService,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          if (fxService != null)
            fxServiceProvider.overrideWithValue(fxService),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const ReservaScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('BRL (padrão): sem linha de câmbio nenhuma', (
    WidgetTester tester,
  ) async {
    final SharedPreferences prefs = await prefsComCotacaoUsd();
    await pumpReserva(tester, prefs);

    expect(find.textContaining('Cotação de'), findsNothing);
    expect(find.text('Digitar a minha'), findsNothing);
    expect(find.text('Atualizar'), findsNothing);
  });

  testWidgets('selecionar USD revela a linha de câmbio com a cotação em cache', (
    WidgetTester tester,
  ) async {
    final SharedPreferences prefs = await prefsComCotacaoUsd();
    await pumpReserva(tester, prefs);

    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();

    // Cotação de 19/07 (a `at` seedada), 1 USD = R$ 5,00, com os dois botões
    // de transparência: reconsultar ou digitar a taxa da pessoa na mão.
    expect(find.textContaining('Cotação de 19/07'), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget);
    expect(find.text('Digitar a minha'), findsOneWidget);
  });

  testWidgets(
    'sem cache pra EUR: a busca automática falha (offline) e cai na '
    'mensagem calma (não-alarme) + Digitar a minha, sem spinner preso',
    (WidgetTester tester) async {
      final SharedPreferences prefs = await prefsComCotacaoUsd();
      final FxRepository repo = FxRepository(prefs);
      final MockClient client = MockClient((http.Request request) async {
        throw Exception('sem conexão');
      });
      await pumpReserva(
        tester,
        prefs,
        fxService: FxService(repo, client: client),
      );

      await tester.tap(find.text('EUR'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ligue a internet uma vez pra puxar a cotação, ou digite a sua.'),
        findsOneWidget,
      );
      expect(find.text('Digitar a minha'), findsOneWidget);
      expect(find.text('Atualizar'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'selecionar USD sem cotação em cache dispara a busca automática — a '
    'cotação buscada aparece sem precisar tocar em "Atualizar"',
    (WidgetTester tester) async {
      final SharedPreferences prefs = await prefsSemCotacao();
      final FxRepository repo = FxRepository(prefs);
      final MockClient client = MockClient((http.Request request) async {
        return http.Response('{"result":"success","rates":{"BRL":5.0}}', 200);
      });
      await pumpReserva(
        tester,
        prefs,
        fxService: FxService(repo, client: client),
      );

      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();

      // Ninguém tocou em "Atualizar" — a cotação buscada já aparece.
      expect(find.textContaining('Cotação de'), findsOneWidget);
      expect(find.textContaining('5,00'), findsOneWidget);
      expect(find.text('Atualizar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'valor digitado em USD converte pra BRL antes de calcular a reserva',
    (WidgetTester tester) async {
      final SharedPreferences prefs = await prefsComCotacaoUsd();
      await pumpReserva(tester, prefs);

      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '100');
      await tester.pumpAndSettle();

      // 100 USD * 5,0 = R$ 500 (sem perfil ativo → regime padrão MEI): DAS
      // fixo de R$ 86,05 é separado, o resto (R$ 414) já é livre — os dois
      // números só batem se o valor foi convertido pra BRL antes da conta.
      expect(find.textContaining('86,05'), findsWidgets);

      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp(r'Esse dinheiro é seu.*500')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Pra usar.*414.*Reserva.*86')),
        findsOneWidget,
      );
      handle.dispose();
    },
  );
}
