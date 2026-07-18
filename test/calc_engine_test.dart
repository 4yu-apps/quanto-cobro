import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/calc/calc_engine.dart';
import 'package:quantocobro/core/model/perfil.dart';
import 'package:quantocobro/core/model/regime.dart';

void main() {
  group('computeValorHora', () {
    test('perfil padrão dá R\$ 92/hora e reserva 16%', () {
      final ValorHoraResult r = computeValorHora(Perfil.padrao());
      expect(r.valorHora, 92);
      expect(r.reservaPct, 16);
    });

    test('horas 0 não estoura (usa mínimo 1, sem divisão por zero)', () {
      final ValorHoraResult r = computeValorHora(Perfil.padrao().copyWith(horas: 0));
      expect(r.valorHora, greaterThan(0));
    });
  });

  group('computeReserva', () {
    test('MEI reserva 16% de R\$ 2.000 = R\$ 320', () {
      final ReservaResult r = computeReserva(2000, RegimeId.mei);
      expect(r.reserva, 320);
      expect(r.sobra, 1680);
    });
  });

  group('computeSimulador', () {
    test('detecta projeto abaixo do alvo e sugere preço maior', () {
      final SimuladorResult s = computeSimulador(3000, 30, 200, RegimeId.mei, 92);
      expect(s.abaixo, isTrue);
      expect(s.sugestao, greaterThan(3000));
    });
  });
}
