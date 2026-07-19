import 'package:flutter/material.dart';

/// "A Divisão" e tokens fora do ColorScheme padrão — identidade "Cofre Aberto".
/// A barra que reparte qualquer valor em Lucro (é seu) · Reserva (do imposto) ·
/// Custos — a mesma legenda em toda tela. Virada semântica v0.4: a Reserva é
/// OURO (tesouro guardado no cofre, não perda); o aço-azul rebaixa pra
/// informação; a atenção é terracota (pra não colidir com o ouro); o custo é
/// neutro (é a hachura, não a joia).
@immutable
class DivisaoColors extends ThemeExtension<DivisaoColors> {
  const DivisaoColors({
    required this.lucro,
    required this.reserva,
    required this.custo,
    required this.track,
    required this.alerta,
    required this.alertaContainer,
    required this.onAlertaContainer,
    required this.sealBg,
    required this.sealFg,
    required this.staleBg,
    required this.staleFg,
    required this.adSurface,
    required this.adLabel,
    required this.brand4yu,
  });

  final Color lucro; // é seu — esmeralda
  final Color reserva; // guardado pro imposto — OURO
  final Color custo; // mantém você trabalhando — neutro
  final Color track; // trilho vazio da barra
  final Color alerta; // "abaixo do alvo" (terracota = atenção, não erro)
  final Color alertaContainer;
  final Color onAlertaContainer;
  final Color
  sealBg; // selo "estimativa de planejamento" (nunca vermelho/âmbar)
  final Color sealFg;
  final Color staleBg; // "valores base de [ano]" (aço calmo = info, não erro)
  final Color staleFg;
  final Color adSurface; // container de anúncio
  final Color adLabel;
  final Color brand4yu; // só selo "by 4YU"/Sobre (variante clara no escuro)

  static const DivisaoColors dark = DivisaoColors(
    lucro: Color(0xFF57E5A9),
    reserva: Color(0xFFEFCE6F),
    custo: Color(0xFF96A298),
    // Superfícies re-neutralizadas p/ acompanhar o charcoal "Cofre de Aço"
    // (os acentos lucro/reserva/custo/alerta permanecem).
    track: Color(0xFF222524),
    alerta: Color(0xFFF2A26A),
    alertaContainer: Color(0xFF542C13),
    onAlertaContainer: Color(0xFFFEE2CC),
    sealBg: Color(0xFF272B29),
    sealFg: Color(0xFFACB4B1),
    staleBg: Color(0xFF213D56),
    staleFg: Color(0xFFCAE2F3),
    adSurface: Color(0xFF171A19),
    adLabel: Color(0xFFACB4B1),
    brand4yu: Color(0xFFAA95E8),
  );

  static const DivisaoColors light = DivisaoColors(
    lucro: Color(0xFF007D54),
    reserva: Color(0xFF8E6700),
    custo: Color(0xFF5D665B),
    track: Color(0xFFDEDFD6),
    alerta: Color(0xFFA1532E),
    alertaContainer: Color(0xFFFFE1CE),
    onAlertaContainer: Color(0xFF562001),
    sealBg: Color(0xFFEBECE4),
    sealFg: Color(0xFF455048),
    staleBg: Color(0xFFD4E9FD),
    staleFg: Color(0xFF0D2F4F),
    adSurface: Color(0xFFEDEDE7),
    adLabel: Color(0xFF455048),
    brand4yu: Color(0xFF6C4BD6),
  );

  @override
  DivisaoColors copyWith({
    Color? lucro,
    Color? reserva,
    Color? custo,
    Color? track,
    Color? alerta,
    Color? alertaContainer,
    Color? onAlertaContainer,
    Color? sealBg,
    Color? sealFg,
    Color? staleBg,
    Color? staleFg,
    Color? adSurface,
    Color? adLabel,
    Color? brand4yu,
  }) {
    return DivisaoColors(
      lucro: lucro ?? this.lucro,
      reserva: reserva ?? this.reserva,
      custo: custo ?? this.custo,
      track: track ?? this.track,
      alerta: alerta ?? this.alerta,
      alertaContainer: alertaContainer ?? this.alertaContainer,
      onAlertaContainer: onAlertaContainer ?? this.onAlertaContainer,
      sealBg: sealBg ?? this.sealBg,
      sealFg: sealFg ?? this.sealFg,
      staleBg: staleBg ?? this.staleBg,
      staleFg: staleFg ?? this.staleFg,
      adSurface: adSurface ?? this.adSurface,
      adLabel: adLabel ?? this.adLabel,
      brand4yu: brand4yu ?? this.brand4yu,
    );
  }

  @override
  DivisaoColors lerp(ThemeExtension<DivisaoColors>? other, double t) {
    if (other is! DivisaoColors) return this;
    return DivisaoColors(
      lucro: Color.lerp(lucro, other.lucro, t)!,
      reserva: Color.lerp(reserva, other.reserva, t)!,
      custo: Color.lerp(custo, other.custo, t)!,
      track: Color.lerp(track, other.track, t)!,
      alerta: Color.lerp(alerta, other.alerta, t)!,
      alertaContainer: Color.lerp(alertaContainer, other.alertaContainer, t)!,
      onAlertaContainer: Color.lerp(
        onAlertaContainer,
        other.onAlertaContainer,
        t,
      )!,
      sealBg: Color.lerp(sealBg, other.sealBg, t)!,
      sealFg: Color.lerp(sealFg, other.sealFg, t)!,
      staleBg: Color.lerp(staleBg, other.staleBg, t)!,
      staleFg: Color.lerp(staleFg, other.staleFg, t)!,
      adSurface: Color.lerp(adSurface, other.adSurface, t)!,
      adLabel: Color.lerp(adLabel, other.adLabel, t)!,
      brand4yu: Color.lerp(brand4yu, other.brand4yu, t)!,
    );
  }
}
