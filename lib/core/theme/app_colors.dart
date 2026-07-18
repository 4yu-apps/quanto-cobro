import 'package:flutter/painting.dart';

/// Cores-semente da marca (Design System §2.1). A cor da UI é o Verde-Justo,
/// escolhido pela categoria (finanças, sem frieza de banco). O roxo 4YU é
/// assinatura discreta — só selo "by 4YU"/Sobre, NUNCA a cor da interface.
abstract final class BrandColors {
  static const Color verdeJusto = Color(0xFF0E8C6B); // primária — "é seu/positivo"
  static const Color azulCofre = Color(0xFF4A72D6); // reserva — "guardado/seguro"
  static const Color ambarAtencao = Color(0xFF9C6F00); // atenção sem alarme
  static const Color carmim = Color(0xFFBA1A1A); // erro (imposto nunca é vermelho)
  static const Color roxo4yu = Color(0xFF6C4BD6); // marca-mãe (só selo/Sobre)
}
