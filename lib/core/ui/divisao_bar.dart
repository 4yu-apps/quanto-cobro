import 'package:flutter/material.dart';

import '../common/money.dart';
import '../theme/divisao_colors.dart';
import '../theme/tokens.dart';

/// Qual segmento é o herói na tela (muda o peso do rótulo, nunca a ordem).
enum DivisaoEmphasis { none, lucro, reserva, custo }

/// "A Divisão" (DS §2.3 / §6.2) — a assinatura do produto. Reparte um valor em
/// Lucro (é seu) · Reserva (do imposto) · Custos, com legenda fixa. A mesma
/// leitura em toda tela: o usuário aprende uma vez.
///
/// Cor NUNCA sozinha (os segmentos têm contraste quase nulo entre si, medido):
/// cada parte tem ícone + rótulo + R$ + %, e o segmento de Custos leva hachura.
class DivisaoBar extends StatelessWidget {
  const DivisaoBar({
    super.key,
    required this.lucro,
    required this.reserva,
    required this.custo,
    this.emphasis = DivisaoEmphasis.none,
  });

  final double lucro;
  final double reserva;
  final double custo;
  final DivisaoEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    final Color hatch = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.24);
    final double total = lucro + reserva + custo;
    final double t = total <= 0 ? 1 : total;
    int flex(double v) => (v / t * 1000).round();
    int pct(double v) => (v / t * 100).round();

    final String semantica =
        'Lucro ${moneyBRL(lucro)}, ${pct(lucro)} por cento. '
        'Reserva ${moneyBRL(reserva)}, ${pct(reserva)} por cento. '
        'Custos ${moneyBRL(custo)}, ${pct(custo)} por cento.';

    return Semantics(
      container: true,
      label: semantica,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radii.sm),
              child: SizedBox(
                height: 20,
                child: total <= 0
                    ? ColoredBox(color: d.track)
                    : Row(
                        children: <Widget>[
                          Expanded(flex: flex(lucro), child: ColoredBox(color: d.lucro)),
                          const SizedBox(width: 2),
                          Expanded(flex: flex(reserva), child: ColoredBox(color: d.reserva)),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: flex(custo),
                            child: CustomPaint(
                              painter: _HatchPainter(hatch),
                              child: ColoredBox(color: d.custo),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: Space.x3),
          _legend(context, d.lucro, Icons.account_balance_wallet, 'Lucro (é seu)', lucro,
              pct(lucro), emphasis == DivisaoEmphasis.lucro),
          _legend(context, d.reserva, Icons.lock_outline, 'Reserva (imposto)', reserva,
              pct(reserva), emphasis == DivisaoEmphasis.reserva),
          _legend(context, d.custo, Icons.build_outlined, 'Custos', custo, pct(custo),
              emphasis == DivisaoEmphasis.custo),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, IconData icon, String label, double value,
      int pct, bool forte) {
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x1),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: Space.x2),
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: Space.x2),
          Expanded(child: Text(label, style: t.bodyMedium)),
          Text(
            '${moneyBRL(value)}  ·  $pct%',
            style: forte ? t.labelLarge?.copyWith(fontWeight: FontWeight.w700) : t.labelLarge,
          ),
        ],
      ),
    );
  }
}

/// Hachura diagonal sutil (sinal não-cromático do segmento de Custos, DS §6.2).
class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const double step = 6;
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) => oldDelegate.color != color;
}
