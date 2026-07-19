import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/data/projeto_repository.dart';
import 'package:quantocobro/core/model/projeto.dart';

/// O objeto novo da gestão (07 §B.3) e a matemática de datas dele. Somar mês
/// é onde bug de calendário mora — 31/jan + 1 mês não é 03/mar.
void main() {
  Projeto projeto({
    String id = 'p1',
    Recorrencia recorrencia = Recorrencia.mensal,
    int intervaloMeses = 2,
    ProjetoStatus status = ProjetoStatus.ativo,
    DateTime? proximo,
    double valor = 2000,
  }) => Projeto(
    id: id,
    nome: 'Loja da Ana',
    valor: valor,
    recorrencia: recorrencia,
    intervaloMeses: intervaloMeses,
    status: status,
    criadoEm: DateTime(2026, 1, 1),
    proximoRecebimento: proximo,
  );

  group('proximoApos — somar mês respeitando o calendário', () {
    test('mensal anda um mês', () {
      expect(
        projeto().proximoApos(DateTime(2026, 3, 10)),
        DateTime(2026, 4, 10),
      );
    });

    test('trimestral anda três meses', () {
      expect(
        projeto(
          recorrencia: Recorrencia.trimestral,
        ).proximoApos(DateTime(2026, 3, 10)),
        DateTime(2026, 6, 10),
      );
    });

    test('vira o ano', () {
      expect(
        projeto().proximoApos(DateTime(2026, 12, 5)),
        DateTime(2027, 1, 5),
      );
    });

    test('dia 31 cai no último dia do mês curto (não vaza pro seguinte)', () {
      // O bug clássico: DateTime(2026, 2, 31) vira 03/mar sozinho.
      expect(
        projeto().proximoApos(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
    });

    test('dia 31 em ano bissexto respeita 29 de fevereiro', () {
      expect(
        projeto().proximoApos(DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29),
      );
    });

    test('avulso não tem próximo', () {
      expect(
        projeto(
          recorrencia: Recorrencia.avulso,
        ).proximoApos(DateTime(2026, 3, 10)),
        isNull,
      );
    });

    test('custom usa o intervalo escolhido', () {
      expect(
        projeto(
          recorrencia: Recorrencia.custom,
          intervaloMeses: 4,
        ).proximoApos(DateTime(2026, 1, 10)),
        DateTime(2026, 5, 10),
      );
    });
  });

  group('avancarCiclo — depois de registrar um recebimento', () {
    test('a base é a data AGENDADA, não a do pagamento', () {
      // Pagou no dia 12 um boleto do dia 10: o ciclo continua no dia 10.
      // Se a base fosse o pagamento, o vencimento andaria pra frente todo mês.
      final Projeto p = projeto(proximo: DateTime(2026, 3, 10));
      expect(
        avancarCiclo(p, pagoEm: DateTime(2026, 3, 12)),
        DateTime(2026, 4, 10),
      );
    });

    test('meses sem registrar: avança até sair do passado', () {
      final Projeto p = projeto(proximo: DateTime(2026, 1, 10));
      // Sem o laço, devolveria 10/fev — uma data velha, e o card nasceria
      // "atrasado" no mesmo instante em que a pessoa registrou o pagamento.
      expect(
        avancarCiclo(p, pagoEm: DateTime(2026, 5, 20)),
        DateTime(2026, 6, 10),
      );
    });

    test('sem data marcada, parte da data do pagamento', () {
      expect(
        avancarCiclo(projeto(), pagoEm: DateTime(2026, 3, 15)),
        DateTime(2026, 4, 15),
      );
    });

    test('avulso não agenda nada depois de receber', () {
      expect(
        avancarCiclo(
          projeto(recorrencia: Recorrencia.avulso),
          pagoEm: DateTime(2026, 3, 15),
        ),
        isNull,
      );
    });
  });

  group('JSON', () {
    test('ida e volta preserva tudo', () {
      final Projeto p = projeto(
        recorrencia: Recorrencia.custom,
        intervaloMeses: 5,
        status: ProjetoStatus.orcamento,
        proximo: DateTime(2026, 8, 10),
      );
      final Projeto volta = Projeto.fromJson(p.toJson());
      expect(volta.id, p.id);
      expect(volta.nome, p.nome);
      expect(volta.valor, p.valor);
      expect(volta.recorrencia, Recorrencia.custom);
      expect(volta.intervaloMeses, 5);
      expect(volta.status, ProjetoStatus.orcamento);
      expect(volta.proximoRecebimento, DateTime(2026, 8, 10));
    });

    test('enum desconhecido não derruba a lista — cai no default', () {
      final Projeto volta = Projeto.fromJson(<String, dynamic>{
        'id': 'x',
        'nome': 'Vindo do futuro',
        'valor': 100,
        'recorrencia': 'semanal', // não existe (ainda)
        'status': 'arquivado', // idem
        'criadoEm': '2026-01-01T00:00:00.000',
      });
      expect(volta.recorrencia, Recorrencia.avulso);
      expect(volta.status, ProjetoStatus.ativo);
    });
  });

  group('ordenarPorProximoRecebimento', () {
    test('ativo com data mais próxima vem primeiro; concluído afunda', () {
      final List<Projeto> ordenado = ordenarPorProximoRecebimento(<Projeto>[
        projeto(
          id: 'concluido',
          status: ProjetoStatus.concluido,
          proximo: DateTime(2026, 1, 1),
        ),
        projeto(id: 'longe', proximo: DateTime(2026, 9, 1)),
        projeto(id: 'perto', proximo: DateTime(2026, 3, 1)),
        projeto(
          id: 'orcamento',
          status: ProjetoStatus.orcamento,
          proximo: DateTime(2026, 2, 1),
        ),
      ]);
      expect(ordenado.map((Projeto p) => p.id).toList(), <String>[
        'perto',
        'longe',
        'orcamento',
        'concluido',
      ]);
    });

    test('sem data vem depois de quem tem data', () {
      final List<Projeto> ordenado = ordenarPorProximoRecebimento(<Projeto>[
        projeto(id: 'sem-data'),
        projeto(id: 'com-data', proximo: DateTime(2026, 9, 1)),
      ]);
      expect(ordenado.first.id, 'com-data');
    });
  });
}
