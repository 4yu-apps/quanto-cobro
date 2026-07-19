import 'package:flutter/material.dart';

import '../../core/common/money.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';

/// Barra "Pra usar × Reserva" da tela de Reserva (auditoria Joana/cega). Mesma
/// regra da [DivisaoBar]: um rótulo semântico conta tudo numa parada só de
/// leitor de tela; a pintura (que é apresentação) vai sob [ExcludeSemantics]
/// pra o TalkBack não ler nada duas vezes — nem passar batido pela barra.
///
/// A camada VISUAL (cores, altura, motion) é intencionalmente idêntica ao que
/// já existia — a trilha visual cuida de escala/estética. Aqui só nasce a voz.
class ReservaBar extends StatelessWidget {
  const ReservaBar({
    super.key,
    required this.amount,
    required this.reserva,
    required this.sobra,
  });

  /// Quanto a pessoa recebeu (denominador da barra).
  final num amount;

  /// Quanto separar pro imposto.
  final num reserva;

  /// Quanto sobra pra usar (o que a legenda mostra em "Pra usar").
  final num sobra;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    final double fR = amount <= 0 ? 0 : reserva / amount;
    final String semantica =
        'Pra usar ${moneyBRL(sobra)}. Reserva ${moneyBRL(reserva)}.';

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
                    AnimatedContainer(
                      duration: reduce ? Duration.zero : Motion.quick,
                      curve: MotionCurves.standard,
                      width: w * (1 - fR),
                      color: d.custo,
                    ),
                    const SizedBox(width: 2),
                    AnimatedContainer(
                      duration: reduce ? Duration.zero : Motion.quick,
                      curve: MotionCurves.standard,
                      width: w * fR,
                      color: d.reserva,
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
