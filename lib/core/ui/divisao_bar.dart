import 'package:flutter/material.dart';

import '../common/money.dart';
import '../theme/app_typography.dart';
import '../theme/divisao_colors.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'texturas.dart';

/// Qual segmento é o herói na tela (muda o peso do rótulo, nunca a ordem).
enum DivisaoEmphasis { none, lucro, reserva, custo }

/// "A Divisão" (DS §2.3 / §6.2) — a assinatura do produto. Reparte um valor em
/// Lucro (é seu) · Reserva (do imposto) · Custos, com legenda fixa. A mesma
/// leitura em toda tela: o usuário aprende uma vez.
///
/// Cor NUNCA sozinha: cada parte tem ícone + rótulo + R$ + %, e os segmentos se
/// distinguem por FORMA — Custos leva hachura diagonal, Reserva leva pontilhado
/// (defesa deutan: esmeralda×ouro é mais arriscado que verde×azul).
///
/// [bornDelay] atrasa o "nascer" da barra pra ela preencher DEPOIS do véu do
/// StaggerIn do card-pai — o usuário precisa VER o dinheiro se repartir
/// (calibração: com delay de 120ms a barra assenta em ~570ms e o número-herói
/// em 600ms; o dinheiro continua sendo o último pixel a parar).
class DivisaoBar extends StatelessWidget {
  const DivisaoBar({
    super.key,
    required this.lucro,
    required this.reserva,
    required this.custo,
    this.emphasis = DivisaoEmphasis.none,
    this.bornDelay = Duration.zero,
  });

  final double lucro;
  final double reserva;
  final double custo;
  final DivisaoEmphasis emphasis;
  final Duration bornDelay;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    final Color hatch = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.24);
    final double total = lucro + reserva + custo;
    final double t = total <= 0 ? 1 : total;
    int pct(double v) => (v / t * 100).round();

    final String semantica =
        'Lucro ${moneyBRL(lucro)}, ${pct(lucro)} por cento. '
        'Reserva ${moneyBRL(reserva)}, ${pct(reserva)} por cento. '
        'Custos ${moneyBRL(custo)}, ${pct(custo)} por cento.';

    return Semantics(
      container: true,
      label: semantica,
      // Uma parada só no leitor de tela: o label acima já conta tudo; a barra
      // e as legendas são apresentação visual (evita ouvir tudo 2x).
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.all(Radii.sm),
              child: SizedBox(
                height: 20,
                child: total <= 0
                    ? ColoredBox(color: d.track)
                    : _AnimatedSegments(
                        track: d.track,
                        lucroColor: d.lucro,
                        reservaColor: d.reserva,
                        custoColor: d.custo,
                        hatch: hatch,
                        fLucro: lucro / t,
                        fReserva: reserva / t,
                        fCusto: custo / t,
                        bornDelay: bornDelay,
                      ),
              ),
            ),
            const SizedBox(height: Space.x3),
            _legend(
              context,
              d.lucro,
              Icons.account_balance_wallet,
              'Lucro (é seu)',
              lucro,
              pct(lucro),
              emphasis == DivisaoEmphasis.lucro,
            ),
            _legend(
              context,
              d.reserva,
              Icons.lock_outline,
              'Reserva (imposto)',
              reserva,
              pct(reserva),
              emphasis == DivisaoEmphasis.reserva,
            ),
            _legend(
              context,
              d.custo,
              Icons.build_outlined,
              'Custos',
              custo,
              pct(custo),
              emphasis == DivisaoEmphasis.custo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(
    BuildContext context,
    Color color,
    IconData icon,
    String label,
    double value,
    int pct,
    bool forte,
  ) {
    final TextTheme t = Theme.of(context).textTheme;
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x1),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              // O segmento-heroi ganha sinal por FORMA, nao so por peso.
              border: forte
                  ? Border.all(color: cs.onSurface.withValues(alpha: 0.35))
                  : null,
            ),
          ),
          const SizedBox(width: Space.x2),
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: Space.x2),
          Expanded(
            child: Text(
              label,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${moneyBRL(value)}  ·  $pct%',
                style:
                    (forte
                            ? t.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              )
                            : t.labelLarge)
                        ?.copyWith(
                          fontFeatures: AppType.tnum,
                          color: cs.onSurface,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra em dois modos num mecanismo só (MOTION-SPEC §1.3):
/// - NASCE: progresso p 0→1 escala os três segmentos juntos — a barra cresce
///   da esquerda já repartida (Motion.fill, emphasizedDecel), opcionalmente
///   após [bornDelay] (K1: nascer DEPOIS do véu do stagger).
/// - AO VIVO: com p=1, mudanças de fração animam via AnimatedContainer
///   (Motion.quick) — a barra "respira" atrás da digitação.
/// Em reduce-motion, pinta o estado final no primeiro frame.
class _AnimatedSegments extends StatelessWidget {
  const _AnimatedSegments({
    required this.track,
    required this.lucroColor,
    required this.reservaColor,
    required this.custoColor,
    required this.hatch,
    required this.fLucro,
    required this.fReserva,
    required this.fCusto,
    required this.bornDelay,
  });

  final Color track;
  final Color lucroColor;
  final Color reservaColor;
  final Color custoColor;
  final Color hatch;
  final double fLucro;
  final double fReserva;
  final double fCusto;
  final Duration bornDelay;

  @override
  Widget build(BuildContext context) {
    final bool reduce = reduceMotionOf(context);
    final int delayMs = bornDelay.inMilliseconds;
    final int totalMs = Motion.fill.inMilliseconds + delayMs;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double gap = 2;
        final double w = (c.maxWidth - 2 * gap).clamp(0, double.infinity);
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: reduce ? 1 : 0, end: 1),
          duration: reduce ? Duration.zero : Duration(milliseconds: totalMs),
          curve: delayMs == 0
              ? MotionCurves.emphasizedDecel
              : Interval(
                  delayMs / totalMs,
                  1,
                  curve: MotionCurves.emphasizedDecel,
                ),
          builder: (BuildContext context, double p, Widget? _) => Stack(
            children: <Widget>[
              Positioned.fill(child: ColoredBox(color: track)),
              Row(
                children: <Widget>[
                  AnimatedContainer(
                    duration: reduce ? Duration.zero : Motion.quick,
                    curve: MotionCurves.standard,
                    width: w * fLucro * p,
                    color: lucroColor,
                  ),
                  const SizedBox(width: gap),
                  // Reserva: pontilhado fino — sinal por forma pro par
                  // esmeralda×ouro (visão deutan/protan).
                  AnimatedContainer(
                    duration: reduce ? Duration.zero : Motion.quick,
                    curve: MotionCurves.standard,
                    width: w * fReserva * p,
                    color: reservaColor,
                    child: CustomPaint(painter: DotPainter(hatch)),
                  ),
                  const SizedBox(width: gap),
                  AnimatedContainer(
                    duration: reduce ? Duration.zero : Motion.quick,
                    curve: MotionCurves.standard,
                    width: w * fCusto * p,
                    color: custoColor,
                    child: CustomPaint(painter: HatchPainter(hatch)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
