import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/projeto.dart';
import 'package:quantocobro/core/model/reserva_entry.dart';
import 'package:quantocobro/core/projetos/agenda.dart';

/// A agenda de recebimentos (07 §B.4/§B.5): previsão de caixa, selo da reserva
/// e a regra do nudge por-projeto — que é onde mora o risco de virar alarme
/// falso e ensinar a pessoa a ignorar o app.
void main() {
  final DateTime hoje = DateTime(2026, 7, 19);

  Projeto projeto({
    required String id,
    Recorrencia recorrencia = Recorrencia.mensal,
    ProjetoStatus status = ProjetoStatus.ativo,
    DateTime? proximo,
    double valor = 1000,
  }) => Projeto(
    id: id,
    nome: id,
    valor: valor,
    recorrencia: recorrencia,
    status: status,
    criadoEm: DateTime(2026, 1, 1),
    proximoRecebimento: proximo,
  );

  ReservaEntry entry({
    required DateTime at,
    String? projetoId,
    double valor = 500,
    String tipo = 'pct',
  }) => ReservaEntry(
    valor: valor,
    reserva: 80,
    regimeTag: 'MEI',
    at: at,
    projetoId: projetoId,
    tipo: tipo,
  );

  group('proximosRecebimentos', () {
    test('pega o que vence dentro da janela e ordena por data', () {
      final List<RecebimentoPrevisto> r = proximosRecebimentos(<Projeto>[
        projeto(id: 'depois', proximo: DateTime(2026, 8, 10)),
        projeto(id: 'antes', proximo: DateTime(2026, 7, 25)),
      ], de: hoje);
      expect(r.map((RecebimentoPrevisto e) => e.projeto.id).toList(), <String>[
        'antes',
        'depois',
      ]);
    });

    test('ignora o que cai depois da janela de 30 dias', () {
      final List<RecebimentoPrevisto> r = proximosRecebimentos(<Projeto>[
        projeto(id: 'longe', proximo: DateTime(2026, 10, 1)),
      ], de: hoje);
      expect(r, isEmpty);
    });

    test('atrasado entra e vem marcado — é o que a pessoa precisa ver', () {
      final List<RecebimentoPrevisto> r = proximosRecebimentos(<Projeto>[
        projeto(id: 'venceu', proximo: DateTime(2026, 6, 10)),
      ], de: hoje);
      expect(r.single.atrasado, isTrue);
    });

    test('orçamento não entra na previsão de caixa', () {
      // Proposta enviada não é dinheiro combinado: prometer caixa que talvez
      // não venha é pior que não prometer nada.
      final List<RecebimentoPrevisto> r = proximosRecebimentos(<Projeto>[
        projeto(
          id: 'talvez',
          status: ProjetoStatus.orcamento,
          proximo: DateTime(2026, 7, 25),
        ),
        projeto(
          id: 'pausado',
          status: ProjetoStatus.pausado,
          proximo: DateTime(2026, 7, 26),
        ),
      ], de: hoje);
      expect(r, isEmpty);
    });
  });

  group('recebidoPorProjeto', () {
    test('soma por projeto e ignora entrada de DAS', () {
      // O DAS é imposto do mês, não faturamento: somá-lo inflaria o "já
      // recebeu" com dinheiro que nunca entrou por aquele cliente.
      final Map<String, double> soma = recebidoPorProjeto(<ReservaEntry>[
        entry(at: hoje, projetoId: 'a', valor: 1000),
        entry(at: hoje, projetoId: 'a', valor: 500),
        entry(at: hoje, projetoId: 'b', valor: 300),
        entry(at: hoje, projetoId: 'a', valor: 90, tipo: 'das'),
        entry(at: hoje, valor: 700), // avulso, sem projeto
      ]);
      expect(soma['a'], 1500);
      expect(soma['b'], 300);
      expect(soma.containsKey(null), isFalse);
    });
  });

  group('projetosParaCutucar — o nudge por-projeto', () {
    test('mensal sem data e sem recebimento no mês: cutuca', () {
      final List<Projeto> r = projetosParaCutucar(
        <Projeto>[projeto(id: 'fixo')],
        <ReservaEntry>[],
        hoje,
      );
      expect(r.single.id, 'fixo');
    });

    test('já recebeu este mês: não cutuca', () {
      final List<Projeto> r = projetosParaCutucar(
        <Projeto>[projeto(id: 'fixo')],
        <ReservaEntry>[entry(at: DateTime(2026, 7, 3), projetoId: 'fixo')],
        hoje,
      );
      expect(r, isEmpty);
    });

    test('trimestral com vencimento longe NÃO vira alarme mensal', () {
      // A regressão que este teste tranca: sem olhar a data, um projeto a cada
      // 3 meses cutucaria todo mês, e a pessoa aprenderia a ignorar o aviso
      // justo quando ele fica verdadeiro.
      final List<Projeto> r = projetosParaCutucar(
        <Projeto>[
          projeto(
            id: 'tri',
            recorrencia: Recorrencia.trimestral,
            proximo: DateTime(2026, 9, 10),
          ),
        ],
        <ReservaEntry>[],
        hoje,
      );
      expect(r, isEmpty);
    });

    test('trimestral vencendo no mês corrente: cutuca', () {
      final List<Projeto> r = projetosParaCutucar(
        <Projeto>[
          projeto(
            id: 'tri',
            recorrencia: Recorrencia.trimestral,
            proximo: DateTime(2026, 7, 28),
          ),
        ],
        <ReservaEntry>[],
        hoje,
      );
      expect(r.single.id, 'tri');
    });

    test('avulso nunca cutuca', () {
      final List<Projeto> r = projetosParaCutucar(
        <Projeto>[projeto(id: 'freela', recorrencia: Recorrencia.avulso)],
        <ReservaEntry>[],
        hoje,
      );
      expect(r, isEmpty);
    });
  });

  group('seloReserva', () {
    test('recebeu no mês: Leão em dia', () {
      expect(
        seloReserva(projeto(id: 'a'), <ReservaEntry>[
          entry(at: DateTime(2026, 7, 2), projetoId: 'a'),
        ], hoje),
        SeloReserva.emDia,
      );
    });

    test('vence este mês e nada registrado: falta separar', () {
      expect(
        seloReserva(
          projeto(id: 'a', proximo: DateTime(2026, 7, 25)),
          <ReservaEntry>[],
          hoje,
        ),
        SeloReserva.faltaSeparar,
      );
    });

    test(
      'vencimento distante: sem selo (silêncio é melhor que selo cinza)',
      () {
        expect(
          seloReserva(
            projeto(id: 'a', proximo: DateTime(2026, 11, 25)),
            <ReservaEntry>[],
            hoje,
          ),
          SeloReserva.nenhum,
        );
      },
    );
  });
}
