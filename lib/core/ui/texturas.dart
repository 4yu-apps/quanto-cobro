/// **Cor nunca sozinha.** Os segmentos das barras se distinguem por FORMA, não
/// só por matiz: Custos leva hachura, Reserva leva pontilhado.
///
/// Não é enfeite — é defesa contra deuteranopia e protanopia, onde o par
/// esmeralda×ouro colapsa. E é o tipo de decisão que se perde sozinha: estes
/// painters nasceram privados dentro da `DivisaoBar`, e foi exatamente por
/// isso que a `EntradaBar` — a barra da tela MAIS USADA do app — nasceu sem
/// eles, com dois blocos chapados a 1,16:1 de contraste entre si no tema
/// claro. Públicos, num arquivo só, eles são difíceis de não usar.
library;

import 'package:flutter/material.dart';

/// Hachura diagonal sutil — o sinal não-cromático do segmento de **Custos**.
class HatchPainter extends CustomPainter {
  const HatchPainter(this.color);

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
  bool shouldRepaint(HatchPainter oldDelegate) => oldDelegate.color != color;
}

/// Pontilhado fino — o sinal não-cromático do segmento de **Reserva**.
class DotPainter extends CustomPainter {
  const DotPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = color;
    const double step = 6;
    int row = 0;
    for (double y = 3; y < size.height; y += step, row++) {
      final double x0 = row.isOdd ? 3 + step / 2 : 3;
      for (double x = x0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(DotPainter oldDelegate) => oldDelegate.color != color;
}
