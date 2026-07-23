import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/calc/tax_tables.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/entrada.dart';
import 'package:quantocobro/core/model/trabalho.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// **O trabalho nasce do primeiro pagamento.**
///
/// É a inversão que resolveu a nota 4 do teste de personas: ninguém preenche
/// formulário vazio pra começar. A pessoa diz quanto recebeu e de quem, e o
/// Augusto passa a existir — no momento em que a resposta é óbvia.
///
/// Também cobre o bug do MEI (o regime PADRÃO): antes o registro dele não se
/// ligava ao trabalho e só cabia um por mês.
void main() {
  final Area area = Area.padrao();

  Future<ProviderContainer> abrirApp(
    WidgetTester tester, {
    List<Trabalho> trabalhos = const <Trabalho>[],
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
      'areas_v1': jsonEncode(<String, dynamic>{
        'activeId': area.id,
        'areas': <Map<String, dynamic>>[area.toJson()],
      }),
      'trabalhos_v1': jsonEncode(
        trabalhos.map((Trabalho t) => t.toJson()).toList(),
      ),
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const QuantoCobroApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> irPraEntrada(WidgetTester tester) async {
    await tester.tap(find.text('Recebi um pagamento'));
    await tester.pumpAndSettle();
  }

  /// Salvar SAI da Reserva e vai pra Meus Trabalhos (onde o pagamento aparece).
  Future<void> guardar(WidgetTester tester) async {
    final Finder g = find.widgetWithText(FilledButton, 'Guardar');
    await tester.ensureVisible(g);
    await tester.pumpAndSettle();
    await tester.tap(g);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  /// Depois de salvar, a pessoa está em Meus Trabalhos. Pra registrar OUTRO
  /// pagamento ela volta ao Início e toca "Recebi um pagamento" de novo — que é
  /// o fluxo real, no lugar do antigo "registrar outro" na mesma tela.
  Future<void> registrarDeNovo(WidgetTester tester) async {
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    await irPraEntrada(tester);
  }

  testWidgets('o trabalho nasce do nome digitado na entrada', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await abrirApp(tester);
    await irPraEntrada(tester);

    await tester.enterText(find.byType(TextField).first, '400');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Augusto');
    await tester.pumpAndSettle();
    await guardar(tester);

    final List<Trabalho> trabalhos = container.read(trabalhosProvider);
    expect(trabalhos, hasLength(1));
    expect(trabalhos.single.nome, 'Augusto');

    final List<Entrada> entradas = container.read(entradasProvider);
    expect(entradas, hasLength(1));
    expect(entradas.single.valor, 400);
    // O dinheiro fica ligado a quem pagou — inclusive no MEI, que é o padrão.
    expect(entradas.single.trabalhoId, trabalhos.single.id);
  });

  testWidgets('digitar o mesmo nome de novo NÃO cria um segundo Augusto', (
    WidgetTester tester,
  ) async {
    // celularEmPe: nav de baixo com os rótulos visíveis, pra tocar "Início".
    await comTela(tester, Tela.celularEmPe, () async {
      final ProviderContainer container = await abrirApp(tester);
      await irPraEntrada(tester);

      await tester.enterText(find.byType(TextField).first, '400');
      await tester.enterText(find.byType(TextField).at(1), 'Augusto');
      await tester.pumpAndSettle();
      await guardar(tester);

      await registrarDeNovo(tester);
      await tester.enterText(find.byType(TextField).first, '600');
      await tester.enterText(find.byType(TextField).at(1), 'augusto');
      await tester.pumpAndSettle();
      await guardar(tester);

      expect(container.read(trabalhosProvider), hasLength(1));
      expect(container.read(entradasProvider), hasLength(2));
    });
  });

  testWidgets('entrada sem nome é avulsa — não inventa um cliente', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await abrirApp(tester);
    await irPraEntrada(tester);

    await tester.enterText(find.byType(TextField).first, '250');
    await tester.pumpAndSettle();
    await guardar(tester);

    expect(container.read(trabalhosProvider), isEmpty);
    expect(container.read(entradasProvider).single.trabalhoId, isNull);
  });

  testWidgets('o MEI registra mais de um pagamento no mês, e separa UM DAS', (
    WidgetTester tester,
  ) async {
    // O bug antigo: depois do primeiro registro do mês a tela travava, e não
    // existia caminho pro segundo pagamento.
    await comTela(tester, Tela.celularEmPe, () async {
      final ProviderContainer container = await abrirApp(tester);
      await irPraEntrada(tester);

      await tester.enterText(find.byType(TextField).first, '400');
      await tester.pumpAndSettle();
      await guardar(tester);

      await registrarDeNovo(tester);
      await tester.enterText(find.byType(TextField).first, '600');
      await tester.pumpAndSettle();
      await guardar(tester);

      final List<Entrada> entradas = container.read(entradasProvider);
      expect(entradas, hasLength(2));
      final int separado = entradas.fold(
        0,
        (int s, Entrada e) => s + e.separado,
      );
      expect(separado, kDasMensalMei.round());
    });
  });

  testWidgets(
    'escolher um trabalho existente liga sem criar outro e traz o combinado',
    (WidgetTester tester) async {
      // O furo que o dono sentiu: na entrada avulsa dava pra redigitar, não pra
      // ESCOLHER. Agora o "Augusto" que já existe aparece — e escolhê-lo liga a
      // entrada a ele (sem criar um segundo) e traz o valor combinado.
      final Trabalho augusto = Trabalho(
        id: 't1',
        areaId: area.id,
        nome: 'Augusto',
        criadoEm: DateTime(2026, 1, 1),
        valorCombinado: 400,
      );
      final ProviderContainer container = await abrirApp(
        tester,
        trabalhos: <Trabalho>[augusto],
      );
      await irPraEntrada(tester);

      // Digitar abre o autocompletar; a opção "Augusto" está lá pra escolher.
      await tester.enterText(find.byType(TextField).at(1), 'Aug');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Augusto').last);
      await tester.pumpAndSettle();

      await guardar(tester);

      // Não criou um segundo Augusto, e a entrada ficou ligada a ele.
      expect(container.read(trabalhosProvider), hasLength(1));
      final List<Entrada> entradas = container.read(entradasProvider);
      expect(entradas.single.trabalhoId, 't1');
      // O valor combinado veio junto — não precisou digitar.
      expect(entradas.single.valor, 400);
    },
  );
}
