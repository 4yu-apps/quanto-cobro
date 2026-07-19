import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/marca.dart';
import 'package:quantocobro/core/model/proposta.dart';
import 'package:quantocobro/features/proposta/proposta_papel.dart';

/// A regra de ouro (07 §A.6): o documento é do CLIENTE, e a cozinha do
/// freelancer — divisão, reserva, imposto, custo, lucro — NUNCA aparece nele.
///
/// Este teste existe porque essa regra é fácil de quebrar sem querer: basta
/// alguém reaproveitar um card do app dentro do papel. Quem quebrar isso vai
/// ver este teste vermelho e ler o porquê.
void main() {
  const Marca marca = Marca(
    nome: 'Estúdio Corvo',
    contato: 'ana@estudiocorvo.com.br',
  );

  Future<void> render(WidgetTester tester, Proposta p) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PropostaPapel(
              proposta: p,
              marca: marca,
              emitidaEm: DateTime(2026, 7, 19),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('o papel mostra o que o cliente precisa', (
    WidgetTester tester,
  ) async {
    await render(
      tester,
      const Proposta(
        servico: 'Identidade visual completa',
        valor: 3500,
        prazo: '15 dias úteis',
        cliente: 'Padaria do Zé',
      ),
    );

    expect(find.text('Estúdio Corvo'), findsOneWidget);
    expect(find.text('Identidade visual completa'), findsOneWidget);
    expect(find.text('Padaria do Zé'), findsOneWidget);
    // `textContaining` e não `text`: o intl separa símbolo e número com espaço
    // NÃO-QUEBRÁVEL (U+00A0), que não bate com um espaço digitado aqui.
    expect(find.textContaining('3.500'), findsOneWidget);
    expect(find.text('15 dias úteis'), findsOneWidget);
    expect(find.text('7 dias'), findsOneWidget);
    expect(
      find.textContaining('Proposta gerada em 19/07/2026'),
      findsOneWidget,
    );
  });

  testWidgets('NUNCA mostra a cozinha do freelancer', (
    WidgetTester tester,
  ) async {
    await render(
      tester,
      const Proposta(
        servico: 'Identidade visual completa',
        valor: 3500,
        horas: 40,
        valorHora: 87,
      ),
    );

    for (final String proibido in <String>[
      'reserva',
      'Reserva',
      'imposto',
      'Imposto',
      'Leão',
      'lucro',
      'Lucro',
      'custo',
      'Custo',
      'Divisão',
      'MEI',
      'DAS',
    ]) {
      expect(
        find.textContaining(proibido),
        findsNothing,
        reason: '"$proibido" não pode aparecer no documento do cliente (§A.6)',
      );
    }
  });

  testWidgets('sem marca d\'água e sem citar o app', (
    WidgetTester tester,
  ) async {
    await render(tester, const Proposta(servico: 'Consultoria', valor: 1200));
    // Um "feito com Quanto Cobro?" no documento envergonha a marca DELE — é o
    // oposto do que a feature vende (§A.5/§D.4).
    expect(find.textContaining('Quanto Cobro'), findsNothing);
    expect(find.textContaining('quantocobro'), findsNothing);
  });

  testWidgets('as horas ficam ocultas por default e só aparecem no toggle', (
    WidgetTester tester,
  ) async {
    const Proposta base = Proposta(
      servico: 'Site institucional',
      valor: 4000,
      horas: 40,
      valorHora: 100,
    );

    // Default OFF: cliente que vê "40h × R$ 100" ancora na hora e pechincha a
    // hora, não o trabalho entregue.
    await render(tester, base);
    expect(find.textContaining('40 horas'), findsNothing);

    await render(tester, base.copyWith(mostrarHoras: true));
    expect(find.textContaining('40 horas'), findsOneWidget);
  });

  testWidgets('campos opcionais vazios não deixam rótulo órfão', (
    WidgetTester tester,
  ) async {
    await render(tester, const Proposta(servico: 'Consultoria', valor: 1200));
    expect(find.text('PARA'), findsNothing);
    expect(find.text('OBSERVAÇÕES'), findsNothing);
    expect(find.text('Prazo de entrega'), findsNothing);
    // A validade sempre aparece: é ela que protege o freelancer.
    expect(find.text('Validade da proposta'), findsOneWidget);
  });
}
