import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// O ID da assinatura Pro na Play (criado no console, irreversível). O plano
/// base (`mensal`) vive dentro dele; a compra é feita pelo productId.
const String kProProductId = 'pro_mensal';

/// A ponte com o Play Billing. Fica entre a loja e o [EntitlementRepository]:
/// quando uma compra de [kProProductId] é confirmada (comprada ou restaurada),
/// chama [onEntitled] — que liga o Pro. Nenhuma tela fala com o Billing direto.
///
/// Sem backend (o app é local-first): a verificação é a que a própria loja dá.
/// Por isso o serviço **concede** ao ver uma compra ativa, mas **não revoga**
/// sozinho na ausência dela — offline ou com `restorePurchases` incompleto,
/// revogar trancaria um assinante que pagou. Revogação real de renovação falha
/// exige as notificações em tempo real da Play + servidor, que não temos ainda.
class BillingService {
  BillingService({required this.onEntitled, InAppPurchase? iap})
    : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  /// Chamado quando uma compra válida de [kProProductId] é vista.
  final Future<void> Function() onEntitled;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _disponivel = false;
  bool get disponivel => _disponivel;

  /// Liga o ouvinte de compras e restaura no boot (best-effort — precisa de
  /// rede). Idempotente. Blindado: sem plataforma de billing (loja ausente,
  /// ambiente de teste), NADA lança — o app segue sem Pro, nunca crasha no boot.
  Future<void> init() async {
    if (_sub != null) return;
    try {
      _disponivel = await _iap.isAvailable();
    } catch (_) {
      _disponivel = false;
    }
    if (!_disponivel) return;
    _sub = _iap.purchaseStream.listen(_aoAtualizar, onError: (_) {});
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  Future<void> _aoAtualizar(List<PurchaseDetails> compras) async {
    for (final PurchaseDetails p in compras) {
      if (p.productID != kProProductId) continue;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await onEntitled();
      }
      // A loja exige confirmar o consumo/entrega, senão ela reembolsa em ~3 dias.
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<ProductDetails?> _produto() async {
    if (!_disponivel) return null;
    try {
      final ProductDetailsResponse r = await _iap.queryProductDetails(
        <String>{kProProductId},
      );
      if (r.productDetails.isEmpty) return null;
      return r.productDetails.first;
    } catch (_) {
      return null;
    }
  }

  /// Abre o fluxo de compra da loja. `false` = loja indisponível ou produto não
  /// encontrado (ex.: build sem a assinatura publicada). O resultado real chega
  /// pelo purchaseStream, não por aqui.
  Future<bool> comprar() async {
    if (!_disponivel) return false;
    final ProductDetails? pd = await _produto();
    if (pd == null) return false;
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: pd),
    );
  }

  /// Preço formatado pela loja (na moeda do usuário), pra tela mostrar o valor
  /// REAL — não um "R$ 6,90" chumbado que mente pra quem está no exterior.
  Future<String?> precoFormatado() async => (await _produto())?.price;

  Future<void> restaurar() async {
    if (_disponivel) await _iap.restorePurchases();
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
