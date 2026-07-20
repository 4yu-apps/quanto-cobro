import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/billing/billing_service.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O billing fecha o buraco que o handoff apontou: o entitlement era um bool
/// local e dava pra virar Pro sem pagar. Agora o Pro só nasce de uma compra
/// confirmada pela loja — e, sem loja (aqui no teste), nada liga.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sem loja, init é seguro: nao concede E nao revoga', () async {
    bool concedeu = false;
    bool revogou = false;
    final BillingService b = BillingService(
      onEntitled: () async => concedeu = true,
      onNotEntitled: () async => revogou = true,
    );

    // Sem plataforma de billing (ambiente de teste): nada lança no boot.
    await b.init();

    expect(b.disponivel, isFalse);
    expect(await b.comprar(), isFalse); // nao abre compra
    expect(await b.precoFormatado(), isNull); // sem preco da loja
    expect(concedeu, isFalse); // nada concede sozinho
    // A garantia critica: checagem inconclusiva (offline/sem loja) NUNCA revoga
    // — senao trancaria quem pagou num boot sem rede.
    expect(revogou, isFalse);
    b.dispose();
  });

  test('sem compra, o Pro continua DESLIGADO (fim do "Pro sem pagar")', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    await c.read(billingServiceProvider).init();

    // O caminho antigo (grant no toque do botao) morreu; sem compra, false.
    expect(c.read(proProvider), isFalse);
  });
}
