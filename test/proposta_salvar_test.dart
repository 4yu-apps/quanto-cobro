import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/proposta.dart';
import 'package:quantocobro/core/model/trabalho.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/features/proposta/proposta_preview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Salvar o cliente da própria pessoa não é Pro.**
///
/// O furo: a oferta de "salvar como trabalho" só nascia no fim da geração do
/// PDF, que estava atrás do paywall. Usuário grátis montava a proposta e nunca
/// conseguia guardar o freela. Isso contradiz a regra que o app jura em
/// historico_screen.dart ("prender o dado dela atrás de pagamento é o crime que
/// derrubou o MEI Fácil pra 1,92★"). Este teste tranca a porta pra ele voltar.
void main() {
  final Area area = Area.padrao();

  Future<ProviderContainer> abrir(
    WidgetTester tester,
    Proposta proposta, {
    String? trabalhoId,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
      'areas_v1': jsonEncode(<String, dynamic>{
        'activeId': area.id,
        'areas': <Map<String, dynamic>>[area.toJson()],
      }),
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PropostaPreviewScreen(
            proposta: proposta,
            trabalhoId: trabalhoId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  const Proposta proposta = Proposta(
    servico: 'Site',
    valor: 3000,
    cliente: 'Padaria',
    valorHora: 100,
    horas: 30,
  );

  testWidgets('quem NÃO é Pro consegue salvar a proposta como trabalho', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await abrir(tester, proposta);
    expect(container.read(proProvider), isFalse);

    await tester.tap(find.text('Salvar como trabalho'));
    await tester.pumpAndSettle();

    final List<Trabalho> trabalhos = container.read(trabalhosProvider);
    expect(trabalhos, hasLength(1));
    // Nasce com o nome do cliente e o valor combinado da proposta.
    expect(trabalhos.single.nome, 'Padaria');
    expect(trabalhos.single.valorCombinado, 3000);
  });

  testWidgets('salvar duas vezes não cria dois trabalhos', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await abrir(tester, proposta);

    await tester.tap(find.text('Salvar como trabalho'));
    await tester.pumpAndSettle();
    // Depois de salvar, o botão some — não dá pra salvar de novo por engano.
    expect(find.text('Salvar como trabalho'), findsNothing);
    expect(container.read(trabalhosProvider), hasLength(1));
  });

  testWidgets('proposta que já veio de um trabalho não reoferece salvar', (
    WidgetTester tester,
  ) async {
    await abrir(tester, proposta, trabalhoId: 'tExistente');
    expect(find.text('Salvar como trabalho'), findsNothing);
  });
}
