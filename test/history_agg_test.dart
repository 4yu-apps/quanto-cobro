import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quantocobro/core/data/entrada_repository.dart';
import 'package:quantocobro/core/model/entrada.dart';

/// As agregações do histórico: "quanto entrou no mês", "quanto cada trabalho
/// já pagou", "que meses têm registro".
///
/// Viraram funções PURAS sobre a lista de entradas (antes eram métodos do
/// repositório, que reliam o disco a cada chamada). Puras dão pra testar sem
/// mock e são o que as telas consomem.
void main() {
  late EntradaRepository repo;

  final DateTime jan10 = DateTime(2026, 1, 10);
  final DateTime jan20 = DateTime(2026, 1, 20);
  final DateTime fev5 = DateTime(2026, 2, 5);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    repo = EntradaRepository(prefs);
    await repo.replaceAll(<Entrada>[
      Entrada(
        valor: 1000,
        separado: 150,
        regimeTag: 'MEI',
        at: jan10,
        areaId: 'a',
        trabalhoId: 'augusto',
      ),
      Entrada(
        valor: 500,
        separado: 75,
        regimeTag: 'MEI',
        at: jan20,
        areaId: 'b',
        trabalhoId: 'padaria',
      ),
      Entrada(
        valor: 300,
        separado: 45,
        regimeTag: 'MEI',
        at: jan20,
        areaId: 'a',
        trabalhoId: 'augusto',
      ),
      // Entrada avulsa: dinheiro que entrou sem estar ligado a um trabalho.
      Entrada(
        valor: 200,
        separado: 30,
        regimeTag: 'MEI',
        at: fev5,
        areaId: 'a',
      ),
    ]);
  });

  test('entrouNoMes soma só o valor do mês pedido', () {
    expect(entrouNoMes(repo.loadAll(), DateTime(2026, 1)), 1800);
    expect(entrouNoMes(repo.loadAll(), DateTime(2026, 2)), 200);
  });

  test('entrouNoMes filtra por área quando informada', () {
    expect(entrouNoMes(repo.loadAll(), DateTime(2026, 1), areaId: 'a'), 1300);
    expect(entrouNoMes(repo.loadAll(), DateTime(2026, 1), areaId: 'b'), 500);
  });

  test('separadoNoMes soma o imposto do mês', () {
    expect(separadoNoMes(repo.loadAll(), DateTime(2026, 1)), 270);
    expect(separadoNoMes(repo.loadAll(), DateTime(2026, 2)), 30);
  });

  test('recebidoPorTrabalho agrupa por trabalho e ignora o avulso', () {
    final Map<String, double> porTrabalho = recebidoPorTrabalho(repo.loadAll());
    expect(porTrabalho['augusto'], 1300);
    expect(porTrabalho['padaria'], 500);
    // A entrada de fevereiro não tem trabalho: não pode inventar uma chave.
    expect(porTrabalho.length, 2);
  });

  test('ultimaEntradaPorTrabalho pega a mais recente de cada um', () {
    final Map<String, DateTime> ultima = ultimaEntradaPorTrabalho(
      repo.loadAll(),
    );
    expect(ultima['augusto'], jan20);
    expect(ultima['padaria'], jan20);
  });

  test('entradasPorMes agrupa o extrato de um trabalho, mês a mês', () {
    // É a estrutura da tela do Augusto: "400 num mês, 600 no outro".
    final Map<DateTime, List<Entrada>> porMes = entradasPorMes(
      repo.loadAll(),
      'augusto',
    );
    expect(porMes.keys.single, DateTime(2026, 1));
    expect(porMes[DateTime(2026, 1)], hasLength(2));
  });

  test('mesesComEntrada retorna meses distintos, mais recente primeiro', () {
    expect(mesesComEntrada(repo.loadAll()), <DateTime>[
      DateTime(2026, 2),
      DateTime(2026, 1),
    ]);
  });
}
