import 'package:flutter/material.dart';

/// "A Divisão" e tokens fora do ColorScheme padrão (Design System §2.3, §9.3).
/// A barra que reparte qualquer valor em Lucro (é seu) · Reserva (do imposto) ·
/// Custos — a mesma legenda em toda tela. Regra cromática: âmbar ≠ imposto; a
/// Reserva é Azul-Cofre (seguro), o âmbar é só atenção sem alarme.
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

  final Color lucro; // é seu
  final Color reserva; // guardado pro leão, seguro
  final Color custo; // mantém você trabalhando
  final Color track; // trilho vazio da barra
  final Color alerta; // "abaixo do alvo" (âmbar = atenção, não erro)
  final Color alertaContainer;
  final Color onAlertaContainer;
  final Color sealBg; // selo "estimativa de planejamento" (nunca vermelho/âmbar)
  final Color sealFg;
  final Color staleBg; // "valores base de 2025" (azul calmo = info, não erro)
  final Color staleFg;
  final Color adSurface; // container de anúncio
  final Color adLabel;
  final Color brand4yu; // só selo "by 4YU"/Sobre

  static const DivisaoColors dark = DivisaoColors(
    lucro: Color(0xFF6FDEB5),
    reserva: Color(0xFFB8C4FF),
    custo: Color(0xFFA4ADA5),
    track: Color(0xFF2F3633),
    alerta: Color(0xFFFBBE48),
    alertaContainer: Color(0xFF5C4200),
    onAlertaContainer: Color(0xFFFFDEAD),
    sealBg: Color(0xFF252B28),
    sealFg: Color(0xFFC0C9C0),
    staleBg: Color(0xFF0B409F),
    staleFg: Color(0xFFDCE1FF),
    adSurface: Color(0xFF171D1A),
    adLabel: Color(0xFFC0C9C0),
    brand4yu: Color(0xFF6C4BD6),
  );

  static const DivisaoColors light = DivisaoColors(
    lucro: Color(0xFF006C50),
    reserva: Color(0xFF2C57B8),
    custo: Color(0xFF586259),
    track: Color(0xFFDCE5DB),
    alerta: Color(0xFF7C5800),
    alertaContainer: Color(0xFFFFDEAD),
    onAlertaContainer: Color(0xFF261900),
    sealBg: Color(0xFFE4EAE2),
    sealFg: Color(0xFF404943),
    staleBg: Color(0xFFDCE1FF),
    staleFg: Color(0xFF00174B),
    adSurface: Color(0xFFEFF5ED),
    adLabel: Color(0xFF404943),
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
      onAlertaContainer: Color.lerp(onAlertaContainer, other.onAlertaContainer, t)!,
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
