import 'package:flutter/material.dart';

import '../../core/common/money.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/texturas.dart';

/// Barra "Pra usar × Reserva" da tela de Reserva (auditoria Joana/cega). Mesma
/// regra da [DivisaoBar]: um rótulo semântico conta tudo numa parada só de
/// leitor de tela; a pintura (que é apresentação) vai sob [ExcludeSemantics]
/// pra o TalkBack não ler nada duas vezes — nem passar batido pela barra.
///
/// A camada VISUAL (cores, altura, motion) é intencionalmente idêntica ao que
/// já existia — a trilha visual cuida de escala/estética. Aqui só nasce a voz.
class EntradaBar extends StatelessWidget {
  const EntradaBar({
    super.key,
    required this.total,
    required this.separado,
    required this.sobra,
  });

  /// Quanto a pessoa recebeu (denominador da barra).
  final num total;

  /// Quanto separar pro imposto.
  final num separado;

  /// Quanto sobra pra usar (o que a legenda mostra em "Pra usar").
  final num sobra;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    // Mesma tinta de textura da DivisaoBar: visível o bastante pra dar forma,
    // discreta o bastante pra não virar ruído sobre a cor.
    final Color hatch = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.24);
    final double fR = total <= 0 ? 0 : separado / total;
    final String semantica =
        'Pra usar ${moneyBRL(sobra)}. Reserva ${moneyBRL(separado)}.';

    return Semantics(
      container: true,
      label: semantica,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radii.sm),
          child: SizedBox(
            height: 20,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final bool reduce = reduceMotionOf(context);
                final double w = c.maxWidth - 2;
                return Row(
                  children: <Widget>[
                    // "Pra usar" estava pintado de `d.custo` — a cor que
                    // significa CUSTO em todas as outras telas —, enquanto
                    // `d.lucro` (esmeralda, "é seu") não aparecia. A mesma
                    // ideia tinha duas cores em duas telas.
                    AnimatedContainer(
                      duration: reduce ? Duration.zero : Motion.quick,
                      curve: MotionCurves.standard,
                      width: w * (1 - fR),
                      color: d.lucro,
                    ),
                    const SizedBox(width: 2),
                    // Reserva leva pontilhado, como na DivisaoBar. Sem forma,
                    // os dois segmentos ficavam a 1,16:1 de contraste entre si
                    // no tema claro — na prática, um bloco só.
                    AnimatedContainer(
                      duration: reduce ? Duration.zero : Motion.quick,
                      curve: MotionCurves.standard,
                      width: w * fR,
                      color: d.reserva,
                      child: CustomPaint(painter: DotPainter(hatch)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
