import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/billing/billing_service.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/pro_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/breakpoints.dart';
import '../../core/ui/panel_card.dart';
import '../../core/ui/pro_selo.dart';

/// Tela Pro (Blueprint §11): oferta transparente, no momento de valor. Preço e
/// o que é Pro aparecem ANTES de o usuário investir trabalho (anti-★1 R2). O
/// núcleo do app é sempre grátis; um único CTA primário fecha a escolha.
class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key, this.gatilho = GatilhoPro.config});

  /// De ONDE a pessoa chegou aqui. Sem isso, "conversão" é um número só e não
  /// responde a pergunta que decide o roadmap: qual recurso puxa a compra?
  final String gatilho;

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  bool _comprando = false;

  /// O preço REAL da loja, na moeda do usuário (BRL 6,90 aqui, USD/EUR 1,49 lá
  /// fora). Fica null até a loja responder — o texto cai no fallback em reais.
  String? _preco;

  /// O que a loja responde DEPOIS do toque em Assinar chega por aqui — a compra
  /// é assíncrona, o `comprar()` só diz se a folha abriu.
  StreamSubscription<BillingEvento>? _eventosBilling;

  @override
  void initState() {
    super.initState();
    _carregarPreco();
    _eventosBilling = ref
        .read(billingServiceProvider)
        .eventos
        .listen(_aoEventoDaLoja);
  }

  @override
  void dispose() {
    _eventosBilling?.cancel();
    super.dispose();
  }

  Future<void> _carregarPreco() async {
    final String? p = await ref.read(billingServiceProvider).precoFormatado();
    if (mounted && p != null) setState(() => _preco = p);
  }

  /// Sem isto, "pagamento em análise" e "a loja recusou" eram silêncio: a pessoa
  /// tocava em Assinar, a folha fechava e a tela ficava idêntica. Silêncio
  /// depois de pagar é o caminho curto pro ★1 e pro pedido de reembolso.
  void _aoEventoDaLoja(BillingEvento e) {
    if (!mounted) return;
    // A compra confirmada não precisa de aviso: a tela troca sozinha pro
    // recibo (isPro no build). E cancelar foi escolha da pessoa — avisar que
    // ela cancelou é ruído.
    if (e == BillingEvento.comprado || e == BillingEvento.cancelado) {
      if (_comprando) setState(() => _comprando = false);
      return;
    }
    final String msg = switch (e) {
      BillingEvento.pendente =>
        'Pagamento em análise. Assim que a loja confirmar, o Pro liga sozinho.',
      // "Item already owned" cai aqui: a conta já assina e o direito local se
      // perdeu (reinstalou, trocou de aparelho). Por isso a saída oferecida é
      // Restaurar compras, e não "tente pagar de novo".
      BillingEvento.erro =>
        'A loja não concluiu a compra. Se você já assina, toque em "Restaurar compras".',
      BillingEvento.comprado || BillingEvento.cancelado => '',
    };
    if (msg.isEmpty) return;
    setState(() => _comprando = false);
    announce(context, msg);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
      );
  }

  static const List<(IconData, String)> _hoje = <(IconData, String)>[
    (
      Icons.switch_account_outlined,
      'Vários trabalhos (cliente recorrente x avulso)',
    ),
    // A proposta em PDF ficou listada como "chegando" DEPOIS de estar pronta e
    // já gated por Pro (proposta_preview_screen). Vender como promessa o que já
    // se entrega é o pior dos dois mundos: parece que o Pro tem menos do que
    // tem, e a pessoa que assina esperando "algo que vem" já recebe.
    (Icons.picture_as_pdf_outlined, 'Orçamento em PDF pra mandar ao cliente'),
    (Icons.block, 'Sem anúncios: quando eles chegarem, você nunca os verá'),
  ];

  static const List<(IconData, String)> _chegando = <(IconData, String)>[
    (Icons.tune, 'Modo avançado por regime (faixas, INSS, deduções)'),
    (Icons.public, 'Módulo freela pra gringo (USD)'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isPro = ref.watch(proProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final ProColors pc = theme.extension<ProColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Pro')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            if (isPro)
              // O recibo: cartão de membro, não aviso de sistema. Selo circular
              // preenchido (aqui a medalha cabe), glow roxo do PanelCard, e a
              // mesma pílula "PRO" da home fechando a rima.
              PanelCard(
                accent: pc.pro,
                padding: const EdgeInsets.all(Space.x5),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color.alphaBlend(
                              Colors.white.withValues(alpha: 0.06),
                              pc.proSolid,
                            ),
                            pc.proSolid,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        color: pc.onProSolid,
                      ),
                    ),
                    const SizedBox(width: Space.x4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Pro ativo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: pc.pro,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Todos os recursos liberados. Obrigado por apoiar o 4YU.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.x3),
                    const ProSelo(animar: false),
                  ],
                ),
              )
            else ...<Widget>[
              // Header de venda: presença, não recibo. Convite roxo suave — a
              // faísca da marca, não a medalha corporativa.
              Center(
                child: AnimatedScale(
                  duration: reduceMotionOf(context)
                      ? Duration.zero
                      : Motion.emphasized,
                  scale: _comprando ? 1.06 : 1,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: pc.proContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: pc.proSolid, width: 2),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 36,
                      color: pc.pro,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.x4),
              Text(
                'Faça mais com o Pro',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: Space.x1),
              Text(
                'O cálculo, a reserva e o simulador são grátis pra sempre.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: Space.x6),
            Text('O que o Pro libera hoje', style: theme.textTheme.titleMedium),
            const SizedBox(height: Space.x3),
            for (final (IconData icon, String label) in _hoje)
              _beneficio(context, icon, label),
            const SizedBox(height: Space.x3),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Chegando: já incluso no seu Pro',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  'em desenvolvimento',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x3),
            for (final (IconData icon, String label) in _chegando)
              _beneficio(context, icon, label),
            if (!isPro) ...<Widget>[
              const SizedBox(height: Space.x4),
              // Um plano só (decisão de 19/07/2026). Três opções obrigavam a
              // pessoa a comparar antes de entender o que compra — e a comparação
              // acontecia justamente no instante em que ela ainda estava
              // decidindo SE quer, não COMO paga.
              _plano_(
                context,
                'Pro',
                // "Renova automaticamente" não é jargão jurídico enfiado na
                // tela: a Play EXIGE que a recorrência apareça antes da compra,
                // e omitir isso é metade das reclamações de "me cobraram de
                // novo". Dizer junto com "cancela quando quiser" mantém a
                // frase honesta sem virar aviso de letra miúda.
                '${_preco ?? 'R\$ 6,90'} por mês · renova automaticamente · cancela quando quiser',
                destaque: true,
              ),
              const SizedBox(height: Space.x4),
              FilledButton(
                // Roxo = "a coisa Pro". No app inteiro, a compra é roxa e as
                // ações grátis são verdes — o botão diz de que lado ele está.
                style: FilledButton.styleFrom(
                  backgroundColor: pc.proSolid,
                  foregroundColor: pc.onProSolid,
                ),
                // Abre a compra da LOJA. O Pro não liga aqui: liga quando a loja
                // CONFIRMA (billing_service -> grant), e aí a tela troca pro
                // recibo sozinha (isPro no build). Fim do "Pro sem pagar".
                onPressed: _comprando
                    ? null
                    : () async {
                        Haptics.commit();
                        telemetry.evento(
                          Evento.proAtivado,
                          params: <String, Object?>{'gatilho': widget.gatilho},
                        );
                        setState(() => _comprando = true);
                        final bool abriu = await ref
                            .read(billingServiceProvider)
                            .comprar();
                        if (!context.mounted) return;
                        setState(() => _comprando = false);
                        if (!abriu) {
                          announce(
                            context,
                            'A loja não está disponível agora. Tenta de novo em instantes.',
                          );
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Loja indisponível agora. Tenta de novo.',
                                ),
                              ),
                            );
                        }
                      },
                child: _comprando
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: pc.onProSolid,
                        ),
                      )
                    : const Text('Assinar'),
              ),
              const SizedBox(height: Space.x2),
              Text(
                'Cobrado pela Google Play e renovado a cada mês até você '
                'cancelar. O cancelamento é na sua conta da Play, e o Pro '
                'continua até o fim do período já pago.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(billingServiceProvider).restaurar();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Procurando sua assinatura…'),
                      ),
                    );
                },
                child: const Text('Restaurar compras'),
              ),
            ] else
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Voltar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _beneficio(BuildContext context, IconData icon, String label) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: const BorderRadius.all(Radii.sm),
            ),
            child: Icon(icon, size: 22, color: cs.primary),
          ),
          const SizedBox(width: Space.x3),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }

  /// O card do preço. Com um plano só ele não é uma ESCOLHA — é uma
  /// informação. Por isso não tem rádio (não há o que selecionar) nem selo
  /// "melhor valor" (não há com o que comparar): os dois convidariam a pessoa
  /// a procurar a opção que não existe.
  Widget _plano_(
    BuildContext context,
    String titulo,
    String valor, {
    bool destaque = false,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: MergeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: const BorderRadius.all(Radii.md),
            border: destaque ? Border.all(color: cs.primary, width: 1.5) : null,
          ),
          padding: const EdgeInsets.all(Space.x4),
          child: Row(
            children: <Widget>[
              Icon(Icons.workspace_premium_outlined, color: cs.primary),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(titulo, style: theme.textTheme.titleMedium),
                    Text(
                      valor,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
