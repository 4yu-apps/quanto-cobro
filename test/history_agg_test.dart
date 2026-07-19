import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quantocobro/core/data/reserva_history_repository.dart';
import 'package:quantocobro/core/model/reserva_entry.dart';

/// Fase 4 Task 6 — agregação "quanto recebi no mês" no histórico de reservas.
/// Base pra agrupar o histórico por mês (Task 7) e responder, sem cálculo
/// mental, "quanto entrou em janeiro?" / "quanto veio de cada trabalho?".
void main() {
  late ReservaHistoryRepository repo;

  final DateTime jan10 = DateTime(2026, 1, 10);
  final DateTime jan20 = DateTime(2026, 1, 20);
  final DateTime fev5 = DateTime(2026, 2, 5);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    repo = ReservaHistoryRepository(prefs);
    await repo.replaceAll(<ReservaEntry>[
      ReservaEntry(
        valor: 1000,
        reserva: 150,
        regimeTag: 'MEI',
        at: jan10,
        perfilId: 'a',
      ),
      ReservaEntry(
        valor: 500,
        reserva: 75,
        regimeTag: 'MEI',
        at: jan20,
        perfilId: 'b',
      ),
      ReservaEntry(
        valor: 300,
        reserva: 45,
        regimeTag: 'MEI',
        at: jan20,
        perfilId: 'a',
      ),
      ReservaEntry(
        valor: 200,
        reserva: 30,
        regimeTag: 'MEI',
        at: fev5,
        perfilId: 'a',
      ),
    ]);
  });

  test('brutoDoMes soma só o valor de janeiro', () async {
    expect(repo.brutoDoMes(DateTime(2026, 1)), 1800);
    expect(repo.brutoDoMes(DateTime(2026, 2)), 200);
  });

  test('brutoDoMes filtra por perfilId quando informado', () async {
    expect(repo.brutoDoMes(DateTime(2026, 1), perfilId: 'a'), 1300);
    expect(repo.brutoDoMes(DateTime(2026, 1), perfilId: 'b'), 500);
  });

  test('brutoPorTrabalhoNoMes agrupa por perfil', () async {
    final Map<String, double> byPerfil = repo.brutoPorTrabalhoNoMes(
      DateTime(2026, 1),
    );
    expect(byPerfil['a'], 1300);
    expect(byPerfil['b'], 500);
    expect(byPerfil.length, 2);
  });

  test('mesesComReserva retorna meses distintos, mais recente primeiro', () {
    final List<DateTime> meses = repo.mesesComReserva();
    expect(meses, <DateTime>[DateTime(2026, 2), DateTime(2026, 1)]);
  });
}
