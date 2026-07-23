import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// O ID da assinatura Pro na Play (criado no console, irreversível). O plano
/// base (`mensal`) vive dentro dele; a compra é feita pelo productId.
const String kProProductId = 'pro_mensal';

/// O que a loja respondeu, traduzido pro que a TELA precisa dizer. Existe
/// porque o resultado real de uma compra não volta pelo `comprar()` — ele chega
/// depois, pelo `purchaseStream`. Sem isto, "pagamento em análise" e "erro da
/// loja" ficavam invisíveis: a pessoa tocava em Assinar e a tela não mudava.
enum BillingEvento {
  /// Compra confirmada. O Pro já foi ligado quando isto chega.
  comprado,

  /// Pagamento em análise (boleto, Pix, aprovação dos pais). NÃO é erro e NÃO
  /// libera o Pro — a loja avisa depois. A tela tem que dizer "estamos
  /// esperando", senão a pessoa acha que pagou à toa e pede reembolso.
  pendente,

  /// A pessoa fechou a folha de pagamento. Silencioso de propósito na tela.
  cancelado,

  /// A loja recusou. Inclui "item already owned" — a conta já assina, mas o
  /// direito local se perdeu (reinstalou, trocou de aparelho). Nesse caso o
  /// caminho é Restaurar compras, e a tela precisa dizer isso.
  erro,
}

/// A ponte com o Play Billing. Fica entre a loja e o [EntitlementRepository]:
/// quando uma compra de [kProProductId] é confirmada (comprada ou restaurada),
/// chama [onEntitled] — que liga o Pro. Nenhuma tela fala com o Billing direto.
///
/// Sem backend (o app é local-first): a verificação é a que a própria loja dá.
/// Por isso o serviço **concede** ao ver uma compra ativa e só **revoga** quando
/// a loja responde, de forma conclusiva, que não existe assinatura. Revogação
/// real de renovação falha exige as notificações em tempo real da Play +
/// servidor, que não temos ainda.
class BillingService {
  BillingService({
    required this.onEntitled,
    this.onNotEntitled,
    InAppPurchase? iap,
    Duration? timeoutRestauracao,
  }) : _iap = iap ?? InAppPurchase.instance,
       _timeoutRestauracao =
           timeoutRestauracao ?? const Duration(seconds: 12);

  final InAppPurchase _iap;

  /// Chamado quando uma compra válida de [kProProductId] é vista.
  final Future<void> Function() onEntitled;

  /// Chamado quando a loja CONFIRMA (online, sem erro) que não há assinatura
  /// ativa — pra revogar o Pro de quem cancelou. Null = nunca revoga.
  final Future<void> Function()? onNotEntitled;

  /// Quanto esperar a loja responder a uma restauração. Estourar isto é
  /// INCONCLUSIVO, não é "não tem assinatura" — ver [_sincronizar].
  final Duration _timeoutRestauracao;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _disponivel = false;
  bool get disponivel => _disponivel;

  /// Eventos pra tela reagir ao que chega DEPOIS do toque em Assinar.
  final StreamController<BillingEvento> _eventos =
      StreamController<BillingEvento>.broadcast();
  Stream<BillingEvento> get eventos => _eventos.stream;

  /// Marca, durante uma sincronização, se alguma assinatura ativa apareceu.
  bool _ativoNaSync = false;

  /// Completa quando a loja RESPONDE a uma restauração em curso. É o que
  /// substituiu o `Future.delayed` de 2 segundos: agora esperamos o sinal real,
  /// e a ausência dele é tratada como dúvida, não como resposta negativa.
  Completer<void>? _restauracao;

  /// A última restauração teve resposta de verdade da loja? `false` cobre
  /// timeout, erro do stream e dispose no meio. Fica separado do Completer de
  /// propósito: completar com erro um future que ninguém está esperando (o
  /// caso do `dispose`) vira erro assíncrono não tratado.
  bool _restauracaoConclusiva = false;

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
    _sub = _iap.purchaseStream.listen(_aoAtualizar, onError: _aoFalhar);
    await _sincronizar();
  }

  /// Erro no próprio stream (a loja caiu no meio). Antes isto era `(_) {}` —
  /// o erro sumia e, pior, uma restauração em curso ficava pendurada até o
  /// timeout e podia ser lida como "não tem assinatura".
  void _aoFalhar(Object erro) {
    _encerrarRestauracao(conclusiva: false);
    if (!_eventos.isClosed) _eventos.add(BillingEvento.erro);
  }

  /// Fecha a espera da restauração. `conclusiva: false` marca que a loja NÃO
  /// respondeu direito — e quem espera vai preferir não mexer no estado.
  void _encerrarRestauracao({required bool conclusiva}) {
    _restauracaoConclusiva = conclusiva;
    final Completer<void>? c = _restauracao;
    _restauracao = null;
    if (c == null || c.isCompleted) return;
    c.complete();
  }

  /// Restaura o estado real da loja e RECONCILIA: liga o Pro se a assinatura
  /// está ativa, revoga se a loja confirma que não está.
  ///
  /// **A regra que não pode quebrar: só revoga com resposta da loja na mão.**
  /// A versão anterior esperava 2 segundos fixos e revogava se nada tivesse
  /// chegado — num boot com rede ruim ou aparelho lento, isso derrubava o Pro
  /// de quem tinha pagado. Agora a espera é pelo evento do `purchaseStream`
  /// (o plugin sempre emite a lista da restauração, mesmo vazia); se ele não
  /// vier dentro de [_timeoutRestauracao], a checagem é inconclusiva e o estado
  /// atual fica como está.
  Future<void> _sincronizar() async {
    if (!_disponivel) return;
    _ativoNaSync = false;
    _restauracaoConclusiva = false;
    final Completer<void> espera = Completer<void>();
    _restauracao = espera;
    try {
      await _iap.restorePurchases();
      // A lista chega pelo stream, de forma assíncrona. Esperamos ELA.
      await espera.future.timeout(_timeoutRestauracao);
    } catch (_) {
      // Falha do restore ou timeout: inconclusivo. Não concede e,
      // principalmente, NÃO revoga.
      _restauracao = null;
      return;
    }
    _restauracao = null;
    // O stream respondeu, mas pode ter sido um erro dele (`_aoFalhar`).
    // Revogar exige uma lista de verdade — inclusive vazia.
    if (!_restauracaoConclusiva) return;
    if (!_ativoNaSync) await onNotEntitled?.call();
  }

  Future<void> _aoAtualizar(List<PurchaseDetails> compras) async {
    for (final PurchaseDetails p in compras) {
      if (p.productID != kProProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _ativoNaSync = true;
          await onEntitled();
          if (!_eventos.isClosed) _eventos.add(BillingEvento.comprado);
        case PurchaseStatus.pending:
          // Pagamento em análise: não libera nada, mas a tela avisa.
          if (!_eventos.isClosed) _eventos.add(BillingEvento.pendente);
        case PurchaseStatus.error:
          if (!_eventos.isClosed) _eventos.add(BillingEvento.erro);
        case PurchaseStatus.canceled:
          if (!_eventos.isClosed) _eventos.add(BillingEvento.cancelado);
      }
      // A loja exige confirmar o consumo/entrega, senão ela reembolsa em ~3
      // dias. Vale pra compra e pra restauração; nunca pra pendente (a compra
      // ainda não existe).
      if (p.pendingCompletePurchase && p.status != PurchaseStatus.pending) {
        await _iap.completePurchase(p);
      }
    }
    // A lista chegou — inclusive se veio vazia, que é a resposta "não há
    // assinatura". ISSO é conclusivo, e é o único caminho pra revogar.
    _encerrarRestauracao(conclusiva: true);
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
  /// pelo [eventos], não por aqui.
  Future<bool> comprar() async {
    if (!_disponivel) return false;
    final ProductDetails? pd = await _produto();
    if (pd == null) return false;
    try {
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: pd),
      );
    } catch (_) {
      // Ex.: "item already owned" — a conta já assina e o direito local sumiu.
      // A tela transforma isso no convite pra Restaurar compras.
      if (!_eventos.isClosed) _eventos.add(BillingEvento.erro);
      return false;
    }
  }

  /// Preço formatado pela loja (na moeda do usuário), pra tela mostrar o valor
  /// REAL — não um "R$ 6,90" chumbado que mente pra quem está no exterior.
  Future<String?> precoFormatado() async => (await _produto())?.price;

  /// "Restaurar compras" da tela Pro — reconcilia igual ao boot (liga se ativa,
  /// revoga se a loja disser que não está).
  Future<void> restaurar() async => _sincronizar();

  void dispose() {
    _encerrarRestauracao(conclusiva: false);
    _sub?.cancel();
    _sub = null;
    _eventos.close();
  }
}
