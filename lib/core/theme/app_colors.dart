import 'package:flutter/painting.dart';

/// Cores-âncora da identidade "Cofre Aberto" (proposta Lúa, 2026-07):
/// esmeralda = o que é seu; ouro = reserva guardada (imposto vira tesouro);
/// aço = informação/interação secundária; terracota = atenção sem alarme.
/// O roxo 4YU é assinatura discreta — só selo "by 4YU"/Sobre, NUNCA a cor da
/// interface. Derivadas em OKLCH; contraste WCAG calculado (zero FAIL).
abstract final class BrandColors {
  static const Color verdeJusto = Color(
    0xFF007D54,
  ); // Esmeralda-Cédula — "é seu"
  static const Color azulCofre = Color(0xFF2E5C8A); // Aço-Cofre — informação
  static const Color ambarAtencao = Color(0xFFA1532E); // Terracota — atenção
  static const Color carmim = Color(
    0xFFB91D1A,
  ); // erro (imposto nunca é vermelho)
  static const Color roxo4yu = Color(0xFF6C4BD6); // marca-mãe (só selo/Sobre)
}
