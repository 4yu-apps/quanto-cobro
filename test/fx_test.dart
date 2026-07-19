import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quantocobro/core/fx/fx_rate.dart';
import 'package:quantocobro/core/fx/fx_repository.dart';
import 'package:quantocobro/core/fx/fx_service.dart';
import 'package:quantocobro/core/model/moeda.dart';

void main() {
  final DateTime agora = DateTime(2026, 7, 19, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('sucesso: busca a taxa, devolve fresca e cacheia no repo', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FxRepository repo = FxRepository(prefs);
    final MockClient client = MockClient((http.Request request) async {
      return http.Response('{"result":"success","rates":{"BRL":5.0}}', 200);
    });
    final FxService service = FxService(repo, client: client);

    final FxRate rate = await service.cotacao(
      Moeda.usd,
      Moeda.brl,
      agora: agora,
    );

    expect(rate.par, 'USD->BRL');
    expect(rate.taxa, 5.0);
    expect(rate.stale, isFalse);
    expect(rate.manual, isFalse);

    final FxRate? cached = repo.get('USD->BRL');
    expect(cached, isNotNull);
    expect(cached!.taxa, 5.0);
  });

  test('erro na rede: cai pra cotação cacheada, flagada stale', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FxRepository repo = FxRepository(prefs);
    await repo.put(FxRate(par: 'USD->BRL', taxa: 4.8, at: agora));
    final MockClient client = MockClient((http.Request request) async {
      return http.Response('erro interno', 500);
    });
    final FxService service = FxService(repo, client: client);

    final FxRate rate = await service.cotacao(
      Moeda.usd,
      Moeda.brl,
      agora: agora,
    );

    expect(rate.taxa, 4.8);
    expect(rate.stale, isTrue);
  });

  test('offline sem cache: lança FxUnavailable', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FxRepository repo = FxRepository(prefs);
    final MockClient client = MockClient((http.Request request) async {
      throw Exception('sem conexão');
    });
    final FxService service = FxService(repo, client: client);

    expect(
      () => service.cotacao(Moeda.usd, Moeda.brl, agora: agora),
      throwsA(isA<FxUnavailable>()),
    );
  });

  test('repo: override manual sobrevive e fica flagado manual:true', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final FxRepository repo = FxRepository(prefs);

    await repo.setManual('USD->BRL', 5.55, agora);

    final FxRate? rate = repo.get('USD->BRL');
    expect(rate, isNotNull);
    expect(rate!.manual, isTrue);
    expect(rate.taxa, 5.55);

    // Uma cotação automática (não-manual) não deve pisar no override manual.
    await repo.put(FxRate(par: 'USD->BRL', taxa: 6.0, at: agora));
    final FxRate? afterAuto = repo.get('USD->BRL');
    expect(afterAuto!.manual, isTrue);
    expect(afterAuto.taxa, 5.55);
  });

  test(
    'Atualizar cotação (busca automática explícita) sobrescreve override '
    'manual — o refresh gruda',
    () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final FxRepository repo = FxRepository(prefs);

      // Usuário tinha digitado uma taxa na mão.
      await repo.setManual('USD->BRL', 5.55, agora);

      // Toca em "Atualizar": busca automática bem-sucedida.
      final MockClient client = MockClient((http.Request request) async {
        return http.Response('{"result":"success","rates":{"BRL":5.20}}', 200);
      });
      final FxService service = FxService(repo, client: client);

      final FxRate rate = await service.cotacao(
        Moeda.usd,
        Moeda.brl,
        agora: agora,
      );
      expect(rate.taxa, 5.20);
      expect(rate.manual, isFalse);

      // A releitura do cache (o que a tela faz ao trocar de moeda) agora
      // devolve a taxa fresca, não a manual antiga — o override foi limpo.
      final FxRate? afterRefresh = repo.get('USD->BRL');
      expect(afterRefresh, isNotNull);
      expect(afterRefresh!.taxa, 5.20);
      expect(afterRefresh.manual, isFalse);
    },
  );
}
