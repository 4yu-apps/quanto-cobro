import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quantocobro/core/billing/billing_service.dart';

/// Os testes do bug que a auditoria de 23/07 achou no `BillingService`: a versão
/// anterior esperava 2 segundos fixos depois do `restorePurchases()` e revogava
/// o Pro se nada tivesse chegado. Num boot com rede ruim isso derrubava o Pro de
/// quem pagou. Aqui a regra é fixada em teste: **só revoga com resposta da loja
/// na mão; timeout e erro são inconclusivos e não mexem no estado.**
///
/// Também cobre o que a tela passou a precisar: pendente e erro viram eventos,
/// não silêncio.

/// Fake da loja. Implementa só o que o serviço chama; o resto lança, de
/// propósito — se o serviço passar a usar um método novo, o teste avisa.
class _FakeIap implements InAppPurchase {
  _FakeIap({
    List<ProductDetails>? produtos,
  }) : produtos = produtos ??
            <ProductDetails>[
              ProductDetails(
                id: kProProductId,
                title: 'Pro',
                description: 'Assinatura',
                price: 'R\$ 6,90',
                rawPrice: 6.90,
                currencyCode: 'BRL',
              ),
            ];

  final List<ProductDetails> produtos;

  final StreamController<List<PurchaseDetails>> _ctrl =
      StreamController<List<PurchaseDetails>>.broadcast();

  /// Se != null, é o que `restorePurchases()` empurra no stream (com o atraso
  /// abaixo). null = a loja não responde nada — o caso do timeout.
  List<PurchaseDetails>? respostaDoRestore = <PurchaseDetails>[];
  Duration atrasoDoRestore = const Duration(milliseconds: 10);

  /// Vira true quando o serviço confirma uma compra (o que evita o reembolso).
  final List<PurchaseDetails> completadas = <PurchaseDetails>[];

  void emitir(List<PurchaseDetails> compras) => _ctrl.add(compras);
  void emitirErro(Object e) => _ctrl.addError(e);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _ctrl.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails:
            produtos.where((ProductDetails p) => ids.contains(p.id)).toList(),
        notFoundIDs:
            ids.where((String i) => !produtos.any((p) => p.id == i)).toList(),
      );

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    final List<PurchaseDetails>? r = respostaDoRestore;
    if (r == null) return; // loja muda: nada chega no stream
    Timer(atrasoDoRestore, () {
      if (!_ctrl.isClosed) _ctrl.add(r);
    });
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completadas.add(purchase);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    return true;
  }

  Future<void> fechar() => _ctrl.close();

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('_FakeIap não implementa ${i.memberName}');
}

PurchaseDetails _compra(PurchaseStatus status, {bool pendente = false}) {
  return PurchaseDetails(
    productID: kProProductId,
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: '',
      source: 'test',
    ),
    transactionDate: null,
    status: status,
  )..pendingCompletePurchase = pendente;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('reconciliação — a regra de nunca trancar quem pagou', () {
    test('loja responde SEM assinatura (lista vazia): revoga', () async {
      bool revogou = false;
      final _FakeIap iap = _FakeIap()..respostaDoRestore = <PurchaseDetails>[];
      final BillingService b = BillingService(
        onEntitled: () async {},
        onNotEntitled: () async => revogou = true,
        iap: iap,
      );

      await b.init();

      expect(revogou, isTrue, reason: 'lista vazia é resposta conclusiva');
      b.dispose();
      await iap.fechar();
    });

    test('loja responde COM assinatura ativa: concede, não revoga', () async {
      bool concedeu = false;
      bool revogou = false;
      final _FakeIap iap = _FakeIap()
        ..respostaDoRestore = <PurchaseDetails>[
          _compra(PurchaseStatus.restored),
        ];
      final BillingService b = BillingService(
        onEntitled: () async => concedeu = true,
        onNotEntitled: () async => revogou = true,
        iap: iap,
      );

      await b.init();

      expect(concedeu, isTrue);
      expect(revogou, isFalse);
      b.dispose();
      await iap.fechar();
    });

    test(
      'loja NÃO responde a tempo (timeout): inconclusivo, NÃO revoga',
      () async {
        bool revogou = false;
        // A loja nunca empurra a resposta — simula rede travada no boot.
        final _FakeIap iap = _FakeIap()..respostaDoRestore = null;
        final BillingService b = BillingService(
          onEntitled: () async {},
          onNotEntitled: () async => revogou = true,
          iap: iap,
          // Timeout curto pro teste não esperar os 12s de produção.
          timeoutRestauracao: const Duration(milliseconds: 80),
        );

        await b.init();

        expect(
          revogou,
          isFalse,
          reason: 'sem resposta da loja, o Pro de quem pagou fica de pé',
        );
        b.dispose();
        await iap.fechar();
      },
    );

    test('erro no stream durante o restore: inconclusivo, NÃO revoga', () async {
      bool revogou = false;
      final _FakeIap iap = _FakeIap()..respostaDoRestore = null;
      final BillingService b = BillingService(
        onEntitled: () async {},
        onNotEntitled: () async => revogou = true,
        iap: iap,
        timeoutRestauracao: const Duration(seconds: 5),
      );

      final Future<void> boot = b.init();
      // A loja cai no meio da restauração.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      iap.emitirErro(Exception('loja caiu'));
      await boot;

      expect(revogou, isFalse);
      b.dispose();
      await iap.fechar();
    });
  });

  group('eventos pra tela — pendente e erro não são silêncio', () {
    test('compra confirmada emite `comprado` e confirma (anti-reembolso)',
        () async {
      final _FakeIap iap = _FakeIap()..respostaDoRestore = <PurchaseDetails>[];
      final BillingService b = BillingService(
        onEntitled: () async {},
        iap: iap,
      );
      await b.init();

      final Future<BillingEvento> visto = b.eventos.first;
      iap.emitir(<PurchaseDetails>[
        _compra(PurchaseStatus.purchased, pendente: true),
      ]);

      expect(await visto, BillingEvento.comprado);
      expect(iap.completadas, hasLength(1),
          reason: 'compra confirmada tem que ser completada, senão reembolsa');
      b.dispose();
      await iap.fechar();
    });

    test('pagamento pendente emite `pendente` e NÃO concede nem confirma',
        () async {
      bool concedeu = false;
      final _FakeIap iap = _FakeIap()..respostaDoRestore = <PurchaseDetails>[];
      final BillingService b = BillingService(
        onEntitled: () async => concedeu = true,
        iap: iap,
      );
      await b.init();

      final Future<BillingEvento> visto = b.eventos.first;
      iap.emitir(<PurchaseDetails>[
        _compra(PurchaseStatus.pending, pendente: true),
      ]);

      expect(await visto, BillingEvento.pendente);
      expect(concedeu, isFalse, reason: 'pendente não libera o Pro');
      expect(iap.completadas, isEmpty,
          reason: 'não se completa uma compra que ainda não existe');
      b.dispose();
      await iap.fechar();
    });

    test('erro da loja emite `erro`', () async {
      final _FakeIap iap = _FakeIap()..respostaDoRestore = <PurchaseDetails>[];
      final BillingService b = BillingService(
        onEntitled: () async {},
        iap: iap,
      );
      await b.init();

      final Future<BillingEvento> visto = b.eventos.first;
      iap.emitir(<PurchaseDetails>[_compra(PurchaseStatus.error)]);

      expect(await visto, BillingEvento.erro);
      b.dispose();
      await iap.fechar();
    });
  });
}
