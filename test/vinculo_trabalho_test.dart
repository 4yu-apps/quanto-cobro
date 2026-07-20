import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/entrada.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O vínculo entrada↔trabalho DEPOIS do fato: ligar uma entrada avulsa a um
/// trabalho no histórico, sem redigitar nada. O modelo já guardava `trabalhoId`;
/// o que faltava era o gesto — e este teste cobre a mecânica dele.
void main() {
  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  Entrada entrada({
    double valor = 400,
    int separado = 60,
    DateTime? at,
    String? trabalhoId,
  }) => Entrada(
    valor: valor,
    separado: separado,
    regimeTag: 'MEI',
    at: at ?? DateTime(2026, 7, 1, 10, 30),
    areaId: 'a1',
    trabalhoId: trabalhoId,
  );

  group('Entrada.copyWith', () {
    test('só sobrescreve o que recebe; o resto fica', () {
      final Entrada l = entrada().copyWith(trabalhoId: 't9');
      expect(l.trabalhoId, 't9');
      expect(l.valor, 400);
      expect(l.separado, 60);
      expect(l.areaId, 'a1');
      expect(l.at, DateTime(2026, 7, 1, 10, 30));
    });

    test('null mantém o valor atual — nunca limpa', () {
      final Entrada l = entrada(trabalhoId: 'tX').copyWith();
      expect(l.trabalhoId, 'tX');
    });
  });

  group('EntradasNotifier.setTrabalho', () {
    test('liga uma entrada avulsa a um trabalho', () async {
      final ProviderContainer c = await container();
      final EntradasNotifier n = c.read(entradasProvider.notifier);
      await n.add(entrada(valor: 400));

      await n.setTrabalho(entrada(valor: 400), 'tNovo');

      expect(c.read(entradasProvider).single.trabalhoId, 'tNovo');
    });

    test('não toca numa entrada que já estava ligada', () async {
      final ProviderContainer c = await container();
      final EntradasNotifier n = c.read(entradasProvider.notifier);
      final Entrada jaLigada = entrada(
        valor: 200,
        at: DateTime(2026, 7, 2, 9, 0),
        trabalhoId: 'tExistente',
      );
      await n.add(jaLigada);

      // Mesmo pedindo pra ligar, uma entrada que já tem dono não muda de dono.
      await n.setTrabalho(jaLigada, 'tOutro');

      expect(c.read(entradasProvider).single.trabalhoId, 'tExistente');
    });

    test('só a entrada certa muda; as outras ficam', () async {
      final ProviderContainer c = await container();
      final EntradasNotifier n = c.read(entradasProvider.notifier);
      await n.add(entrada(valor: 400, at: DateTime(2026, 7, 1, 10, 30)));
      await n.add(entrada(valor: 250, at: DateTime(2026, 7, 3, 15, 0)));

      await n.setTrabalho(
        entrada(valor: 400, at: DateTime(2026, 7, 1, 10, 30)),
        'tAugusto',
      );

      final List<Entrada> todas = c.read(entradasProvider);
      expect(
        todas.firstWhere((Entrada e) => e.valor == 400).trabalhoId,
        'tAugusto',
      );
      expect(
        todas.firstWhere((Entrada e) => e.valor == 250).trabalhoId,
        isNull,
      );
    });
  });
}
