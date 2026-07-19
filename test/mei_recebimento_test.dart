import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/calc/calc_engine.dart';
import 'package:quantocobro/core/calc/tax_tables.dart';
import 'package:quantocobro/core/model/perfil.dart';
import 'package:quantocobro/core/model/projeto.dart';
import 'package:quantocobro/core/model/regime.dart';
import 'package:quantocobro/core/model/reserva_entry.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O bug do MEI — que é o regime PADRÃO do app (`Perfil.padrao`).
///
/// Dois sintomas, uma raiz: o app tratava o registro do MEI como "separei o
/// DAS do mês" em vez de "recebi um pagamento". Como consequência (1) o
/// dinheiro nunca se ligava ao freela que pagou e (2) depois do primeiro
/// registro do mês a tela travava, sem caminho pra anotar o segundo pagamento.
///
/// A raiz era o modelo: a reserva de imposto era a protagonista e o
/// recebimento, o acompanhante. Quando o regime é um em que o imposto NÃO é
/// fatia do pagamento, o protagonista sumia e levava o acompanhante junto.
void main() {
  group('computeReserva no MEI — o DAS é um boleto só do mês', () {
    test('o primeiro pagamento do mês separa o DAS inteiro', () {
      final ReservaResult r = computeReserva(1000, RegimeId.mei);
      expect(r.reserva, kDasMensalMei.round());
      expect(r.impostoDoMesQuitado, isFalse);
    });

    test('o segundo pagamento do mês não separa nada de novo', () {
      // Era aqui que o app dobrava o imposto — e por isso travava a tela.
      final ReservaResult r = computeReserva(
        1000,
        RegimeId.mei,
        dasJaSeparado: kDasMensalMei,
      );
      expect(r.reserva, 0);
      expect(r.sobra, 1000);
      expect(r.impostoDoMesQuitado, isTrue);
    });

    test(
      'pagamento pequeno separa só o que dá, e o resto fica pro próximo',
      () {
        final ReservaResult primeiro = computeReserva(50, RegimeId.mei);
        expect(primeiro.reserva, 50);
        expect(primeiro.impostoDoMesQuitado, isFalse);

        final ReservaResult segundo = computeReserva(
          1000,
          RegimeId.mei,
          dasJaSeparado: 50,
        );
        expect(segundo.reserva, (kDasMensalMei - 50).round());
      },
    );

    test('somando o mês inteiro, separou exatamente um DAS', () {
      final ReservaResult a = computeReserva(400, RegimeId.mei);
      final ReservaResult b = computeReserva(
        600,
        RegimeId.mei,
        dasJaSeparado: a.reserva.toDouble(),
      );
      final ReservaResult c = computeReserva(
        200,
        RegimeId.mei,
        dasJaSeparado: (a.reserva + b.reserva).toDouble(),
      );
      expect(a.reserva + b.reserva + c.reserva, kDasMensalMei.round());
    });

    test(
      'os outros regimes não têm imposto "quitado" — é fatia de cada um',
      () {
        final ReservaResult r = computeReserva(
          1000,
          RegimeId.cpf,
          dasJaSeparado: 9999,
        );
        expect(r.impostoDoMesQuitado, isFalse);
        expect(r.reserva, greaterThan(0));
      },
    );
  });

  group('a tela, ponta a ponta, no regime padrão (MEI)', () {
    final Projeto gustavo = Projeto(
      id: 'pj1',
      nome: 'Gustavo',
      valor: 400,
      recorrencia: Recorrencia.mensal,
      status: ProjetoStatus.ativo,
      criadoEm: DateTime(2026, 1, 1),
    );

    Future<ProviderContainer> abrirApp(WidgetTester tester) async {
      final Perfil mei = Perfil.padrao(); // regime MEI é o default
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_done': true,
        'profiles_v2': jsonEncode(<String, dynamic>{
          'activeId': mei.id,
          'profiles': <Map<String, dynamic>>[mei.toJson()],
        }),
        'projetos_v1': jsonEncode(<Map<String, dynamic>>[gustavo.toJson()]),
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

    Future<void> registrar(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Salvar no histórico'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar no histórico'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('o recebimento do MEI se liga ao freela que pagou', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await abrirApp(tester);

      await tester.tap(find.text('Projetos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recebi'));
      await tester.pumpAndSettle();
      await registrar(tester);

      final List<ReservaEntry> historico = container.read(
        reservaHistoryProvider,
      );
      expect(historico, hasLength(1));
      // ANTES: era null — o dinheiro do Gustavo sumia do Gustavo.
      expect(historico.single.projetoId, 'pj1');
      expect(historico.single.valor, 400);
    });

    testWidgets('o MEI registra um SEGUNDO pagamento no mesmo mês', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = await abrirApp(tester);

      await tester.tap(find.text('Projetos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recebi'));
      await tester.pumpAndSettle();
      await registrar(tester);

      // ANTES: o botão virava "DAS separado" desabilitado, e "Registrar outro"
      // não saía desse estado — não existia caminho pro 2º pagamento do mês.
      await tester.tap(find.text('Registrar outro'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '600');
      await tester.pumpAndSettle();
      await registrar(tester);

      final List<ReservaEntry> historico = container.read(
        reservaHistoryProvider,
      );
      expect(historico, hasLength(2));
      // E o imposto do mês continua sendo UM DAS, não dois.
      final int separado = historico.fold<int>(
        0,
        (int s, ReservaEntry e) => s + e.reserva,
      );
      expect(separado, kDasMensalMei.round());
    });
  });
}
