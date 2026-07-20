import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/data/trabalho_repository.dart';
import 'package:quantocobro/core/model/trabalho.dart';

/// O objeto novo da gestão — e o que ele deliberadamente NÃO tem.
void main() {
  Trabalho t({
    String id = 't1',
    String nome = 'Augusto',
    bool encerrado = false,
    DateTime? criadoEm,
  }) => Trabalho(
    id: id,
    areaId: 'a1',
    nome: nome,
    criadoEm: criadoEm ?? DateTime(2026, 1, 1),
    encerrado: encerrado,
  );

  group('JSON', () {
    test('ida e volta preserva tudo', () {
      final Trabalho original = Trabalho(
        id: 't9',
        areaId: 'design',
        nome: 'Padaria',
        criadoEm: DateTime(2026, 3, 4),
        valorCombinado: 2500,
        encerrado: true,
        observacoes: 'entrega em duas etapas',
      );
      final Trabalho volta = Trabalho.fromJson(original.toJson());
      expect(volta.id, 't9');
      expect(volta.areaId, 'design');
      expect(volta.nome, 'Padaria');
      expect(volta.valorCombinado, 2500);
      expect(volta.encerrado, isTrue);
      expect(volta.observacoes, 'entrega em duas etapas');
      expect(volta.criadoEm, DateTime(2026, 3, 4));
    });

    test('JSON incompleto não derruba a lista', () {
      final Trabalho volta = Trabalho.fromJson(<String, dynamic>{'id': 'x'});
      expect(volta.nome, 'Trabalho');
      expect(volta.valorCombinado, 0);
      expect(volta.encerrado, isFalse);
    });
  });

  group('ordenarTrabalhos', () {
    test('quem pagou por último vem primeiro', () {
      // A pessoa abre a aba pra ver o que está vivo — e vivo é o que teve
      // movimento recente, não o que foi cadastrado primeiro.
      final List<Trabalho> ordenado = ordenarTrabalhos(
        <Trabalho>[t(id: 'antigo'), t(id: 'recente')],
        <String, DateTime>{
          'antigo': DateTime(2026, 1, 5),
          'recente': DateTime(2026, 6, 5),
        },
      );
      expect(ordenado.map((Trabalho x) => x.id).toList(), <String>[
        'recente',
        'antigo',
      ]);
    });

    test('quem nunca recebeu fica depois de quem já recebeu', () {
      final List<Trabalho> ordenado = ordenarTrabalhos(
        <Trabalho>[t(id: 'novo'), t(id: 'pagou')],
        <String, DateTime>{'pagou': DateTime(2026, 1, 5)},
      );
      expect(ordenado.first.id, 'pagou');
    });

    test('encerrado afunda, mesmo tendo pago recentemente', () {
      final List<Trabalho> ordenado = ordenarTrabalhos(
        <Trabalho>[t(id: 'encerrado', encerrado: true), t(id: 'ativo')],
        <String, DateTime>{
          'encerrado': DateTime(2026, 6, 30),
          'ativo': DateTime(2026, 1, 1),
        },
      );
      expect(ordenado.first.id, 'ativo');
    });
  });

  group('a fronteira do produto', () {
    test('o Trabalho não carrega nada que exija alimentação semanal', () {
      // Este teste é uma TRAVA DE PRODUTO, não de código. Data de vencimento,
      // status de 4 estados e recorrência configurável já existiram aqui e
      // foram cortados: todos exigiam que a pessoa mantivesse o app atualizado
      // pra ter valor, e isso é gestão — não é o que este app é.
      //
      // A régua: lembrar o que a pessoa disse uma vez = calculadora com
      // memória ✅ · exigir que ela alimente toda semana = gestão ❌
      final Map<String, dynamic> json = t().toJson();
      for (final String proibido in <String>[
        'proximoRecebimento',
        'recorrencia',
        'intervaloMeses',
        'status',
        'diaVencimento',
      ]) {
        expect(
          json.containsKey(proibido),
          isFalse,
          reason:
              'O Trabalho voltou a ter "$proibido". Se ele só tem valor quando '
              'a pessoa mantém o app atualizado, é gestão — e gestão não é '
              'nosso. Ver docs/planning/08-PLANO-OFICIAL.md §1.',
        );
      }
    });
  });
}
