import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/fx/fx_rate.dart';
import 'package:quantocobro/core/fx/fx_service.dart';
import 'package:quantocobro/core/model/entrada.dart';
import 'package:quantocobro/core/model/moeda.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// F3 — o fosso: recebeu em dólar, o app converte pela cotação e reserva sobre
/// o valor em reais. Ninguém no mundo une "USD que entrou" + "imposto BR".
void main() {
  test('Entrada guarda moeda de origem e taxa no round-trip', () {
    final Entrada e = Entrada(
      valor: 550,
      separado: 90,
      regimeTag: 'CPF exterior',
      at: DateTime(2026, 7, 20),
      moedaOrigem: 'USD',
      taxa: 5.5,
    );
    final Entrada volta = Entrada.fromJson(
      jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>,
    );
    expect(volta.valor, 550);
    expect(volta.moedaOrigem, 'USD');
    expect(volta.taxa, 5.5);
  });

  test('Entrada em real não grava moeda/taxa (retrocompat)', () {
    final Entrada e = Entrada(
      valor: 2000,
      separado: 340,
      regimeTag: 'MEI',
      at: DateTime(2026, 7, 20),
    );
    final Map<String, dynamic> j = e.toJson();
    expect(j.containsKey('moedaOrigem'), isFalse);
    expect(j.containsKey('taxa'), isFalse);
    final Entrada volta = Entrada.fromJson(j);
    expect(volta.moedaOrigem, isNull);
    expect(volta.taxa, isNull);
  });

  testWidgets('recebi em dólar → converte pela cotação e reserva em real', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      final ProviderContainer container = await _abrir(tester);

      await tester.tap(find.text('Recebi um pagamento'));
      await tester.pumpAndSettle();

      // Abre o seletor de moeda e escolhe dólar.
      await tester.tap(find.text('Recebi em outra moeda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dólar americano (US\$)'));
      await tester.pumpAndSettle();

      // US$ 100 pela cotação fake (5,50) = R$ 550.
      await tester.enterText(find.byType(TextField).first, '100');
      await tester.pumpAndSettle();

      // A conversão aparece — cotação de hoje, taxa visível.
      expect(find.textContaining('cotação de hoje'), findsOneWidget);

      final Finder guardar = find.widgetWithText(FilledButton, 'Guardar');
      await tester.ensureVisible(guardar);
      await tester.pumpAndSettle();
      await tester.tap(guardar);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final List<Entrada> entradas = container.read(entradasProvider);
      expect(entradas, hasLength(1));
      // O valor foi CONVERTIDO pra reais; a origem ficou rastreada.
      expect(entradas.single.valor, 550);
      expect(entradas.single.moedaOrigem, 'USD');
      expect(entradas.single.taxa, 5.5);
    });
  });
}

Future<ProviderContainer> _abrir(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    'areas_v1': _umaArea,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      fxServiceProvider.overrideWith(
        (Ref ref) => _FxFake(ref.watch(fxRepositoryProvider)),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const QuantoCobroApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Cotação fixa, sem rede — 1 US$ = R$ 5,50.
class _FxFake extends FxService {
  _FxFake(super.repo);

  @override
  Future<FxRate> cotacao(
    Moeda de,
    Moeda para, {
    required DateTime agora,
  }) async => FxRate(par: '${de.codigo}->${para.codigo}', taxa: 5.5, at: agora);
}

const String _umaArea =
    '{"activeId":"a1","areas":[{"id":"a1","nome":"Design","renda":5000,'
    '"horas":85,"provisao":0,"provisaoOn":true,"provisaoCustom":false,'
    '"diasSemana":5,"horasDia":6,"custos":[]}]}';
