import 'package:flutter/material.dart';

import '../common/money.dart';
import '../theme/divisao_colors.dart';

/// "A Divisão" (DS §2.3 / §6.2) — a assinatura do produto. Reparte um valor em
/// Lucro (é seu) · Reserva (do imposto) · Custos, com legenda fixa. A mesma
/// leitura em toda tela: o usuário aprende uma vez. Cor NUNCA sozinha — cada
/// segmento tem rótulo + R$ + % (acessível a daltônicos e à leitura à pressa).
class DivisaoBar extends StatelessWidget {
  const DivisaoBar({
    super.key,
    required this.lucro,
    required this.reserva,
    required this.custo,
  });

  final double lucro;
  final double reserva;
  final double custo;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    final double total = lucro + reserva + custo;
    final double t = total <= 0 ? 1 : total;
    int flex(double v) => (v / t * 1000).round();
    int pct(double v) => (v / t * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Barra é decorativa: os valores/percentuais são lidos na legenda abaixo.
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 18,
              child: total <= 0
                  ? ColoredBox(color: d.track)
                  : Row(
                      children: <Widget>[
                        Expanded(flex: flex(lucro), child: ColoredBox(color: d.lucro)),
                        Expanded(flex: flex(reserva), child: ColoredBox(color: d.reserva)),
                        Expanded(flex: flex(custo), child: ColoredBox(color: d.custo)),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend(context, d.lucro, 'Lucro (é seu)', lucro, pct(lucro)),
        _legend(context, d.reserva, 'Reserva (imposto)', reserva, pct(reserva)),
        _legend(context, d.custo, 'Custos', custo, pct(custo)),
      ],
    );
  }

  Widget _legend(BuildContext context, Color color, String label, double value, int pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            '${moneyBRL(value)}  ·  $pct%',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
