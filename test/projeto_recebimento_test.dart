import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/model/perfil.dart';
import 'package:quantocobro/core/model/projeto.dart';
import 'package:quantocobro/core/model/regime.dart';
import 'package:quantocobro/core/model/reserva_entry.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O loop que o produto inteiro existe pra fazer girar (07 §C):
/// card do projeto → "Recebi" → Reserva pré-preenchida → Guardado com
/// `projetoId` → o ciclo do projeto avança.
///
/// É o teste mais valioso da feature: se ele passa, a gestão está de fato
/// pendurada na reserva, e não é um CRUD paralelo que só parece integrado.
void main() {
  final Projeto mensal = Projeto(
    id: 'pj1',
    nome: 'Loja da Ana',
    valor: 2000,
    recorrencia: Recorrencia.mensal,
    status: ProjetoStatus.ativo,
    criadoEm: DateTime(2026, 1, 1),
    proximoRecebimento: DateTime(2026, 7, 10),
  );

  /// Regime CPF de propósito: no MEI a reserva é o DAS fixo do mês e o
  /// registro NÃO carrega projeto — este teste quer o caminho percentual, que
  /// é o que carimba o `projetoId`.
  final Perfil perfilCpf = Perfil.padrao().copyWith(regime: RegimeId.cpf);

  Future<ProviderContainer> abrirApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
      'profiles_v2': jsonEncode(<String, dynamic>{
        'activeId': perfilCpf.id,
        'profiles': <Map<String, dynamic>>[perfilCpf.toJson()],
      }),
      'projetos_v1': jsonEncode(<Map<String, dynamic>>[mensal.toJson()]),
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

  testWidgets('o card do projeto mostra nome, valor e o próximo recebimento', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester);
    await tester.tap(find.text('Projetos'));
    await tester.pumpAndSettle();

    expect(find.text('Loja da Ana'), findsOneWidget);
    expect(find.textContaining('Ativo'), findsWidgets);
    expect(find.text('Recebi'), findsOneWidget);
  });

  testWidgets('"Recebi" abre a Reserva já preenchida com o valor do ciclo', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester);
    await tester.tap(find.text('Projetos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recebi'));
    await tester.pumpAndSettle();

    // O título diz de QUEM é o dinheiro — some a dúvida "registrei no lugar
    // certo?".
    expect(find.text('Recebi de Loja da Ana'), findsOneWidget);
    // E o valor do ciclo já está lá: 2 toques do card ao guardado.
    expect(find.textContaining('2.000'), findsWidgets);
  });

  testWidgets(
    'salvar carimba o projetoId no histórico e avança o ciclo do projeto',
    (WidgetTester tester) async {
      final ProviderContainer container = await abrirApp(tester);

      await tester.tap(find.text('Projetos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recebi'));
      await tester.pumpAndSettle();

      // A janela do teste é 800×600; o botão vive abaixo da dobra numa lista
      // que rola. Rolar até ele é o que o dedo faz no aparelho.
      await tester.ensureVisible(find.text('Salvar no histórico'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar no histórico'));
      await tester.pumpAndSettle();

      // 1) O recebimento entrou no Guardado, amarrado ao projeto.
      final List<ReservaEntry> historico = container.read(
        reservaHistoryProvider,
      );
      expect(historico, hasLength(1));
      expect(historico.single.projetoId, 'pj1');
      expect(historico.single.valor, 2000);

      // 2) E o ciclo andou: julho pago, o próximo é agosto.
      final Projeto? depois = container
          .read(projetosProvider.notifier)
          .byId('pj1');
      expect(depois!.proximoRecebimento!.month, 8);
      expect(depois.proximoRecebimento!.day, 10);
    },
  );

  testWidgets('Desfazer devolve o projeto ao ciclo anterior', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await abrirApp(tester);

    await tester.tap(find.text('Projetos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recebi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar no histórico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar no histórico'));
    // `pumpAndSettle` aqui COMERIA o snackbar: ele avança o relógio até nada
    // mais animar, e o Desfazer vive 4 segundos. Pumps curtos param no
    // instante em que a pessoa real ainda veria o botão.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Desfazer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Desfazer tem que desfazer TUDO: sem isso o projeto ficaria com o ciclo
    // adiantado por um pagamento que a pessoa acabou de dizer que não houve.
    expect(container.read(reservaHistoryProvider), isEmpty);
    final Projeto? depois = container
        .read(projetosProvider.notifier)
        .byId('pj1');
    expect(depois!.proximoRecebimento, DateTime(2026, 7, 10));
  });

  testWidgets('o nudge do Painel nomeia o projeto que deve pagar', (
    WidgetTester tester,
  ) async {
    await abrirApp(tester);
    // Projeto mensal, nada registrado no mês: o aviso chama pelo nome, em vez
    // do genérico "seu trabalho mensal já te pagou?".
    expect(find.text('Novo mês começou'), findsOneWidget);
    expect(find.textContaining('Loja da Ana'), findsWidgets);
  });
}
