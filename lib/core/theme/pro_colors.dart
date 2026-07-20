import 'package:flutter/material.dart';

/// Cor do **Pro** — um eixo próprio, separado de [DivisaoColors] de propósito.
///
/// A tensão que este arquivo resolve: o dono pediu um selo "dourado", mas OURO
/// já significa RESERVA DE IMPOSTO no app (`DivisaoColors.reserva`). Num selo de
/// 11–13px, um champanhe fica a ~2° de matiz do ouro-reserva em OKLCH — o olho
/// não separa, e o selo Pro seria lido como "imposto". Então o Pro fala a cor
/// da **marca-mãe**: o roxo 4YU (`BrandColors.roxo4yu`), a ~154° do ouro (o
/// oposto na roda), o único matiz ainda livre no sistema semântico.
///
/// Narrativa, não só espaço vago: Pro = a pessoa entrou pro 4YU. O `proSolid`
/// claro é EXATAMENTE o `brand4yu` do selo "by 4YU" — o Pro é literalmente a
/// marca-mãe. O "premium alegre" vem do MATERIAL (sheen + faísca), não de mais
/// cor. Manter isto fora de `DivisaoColors` deixa o firewall ouro-vs-roxo
/// visível no próprio código. Hexes e contraste WCAG derivados em OKLCH.
@immutable
class ProColors extends ThemeExtension<ProColors> {
  const ProColors({
    required this.pro,
    required this.proSolid,
    required this.onProSolid,
    required this.proContainer,
    required this.onProContainer,
  });

  final Color pro; // tinta: texto/ícone/hairline Pro sobre superfície normal
  final Color proSolid; // fundo preenchido do selo (pílula/círculo)
  final Color onProSolid; // texto/ícone sobre proSolid
  final Color proContainer; // wash suave (círculo do ícone, convite)
  final Color onProContainer; // texto sobre proContainer

  static const ProColors dark = ProColors(
    pro: Color(0xFFC6B2F7), // lilás claro — AAA sobre o charcoal
    proSolid: Color(0xFF7A5AE6), // sobe de L no escuro pra brilhar no charcoal
    onProSolid: Color(0xFFFFFFFF), // branco puro (o quente cai <4.5 no escuro)
    proContainer: Color(0xFF2C2150),
    onProContainer: Color(0xFFE7DEFF),
  );

  static const ProColors light = ProColors(
    pro: Color(0xFF5B39C4),
    proSolid: Color(0xFF6C4BD6), // = brand4yu exato: o selo É a marca-mãe
    onProSolid: Color(0xFFFFF6EC), // branco-QUENTE: o toque champanhe, só aqui
    proContainer: Color(0xFFECE3FF),
    onProContainer: Color(0xFF2A1170),
  );

  @override
  ProColors copyWith({
    Color? pro,
    Color? proSolid,
    Color? onProSolid,
    Color? proContainer,
    Color? onProContainer,
  }) => ProColors(
    pro: pro ?? this.pro,
    proSolid: proSolid ?? this.proSolid,
    onProSolid: onProSolid ?? this.onProSolid,
    proContainer: proContainer ?? this.proContainer,
    onProContainer: onProContainer ?? this.onProContainer,
  );

  @override
  ProColors lerp(ThemeExtension<ProColors>? other, double t) {
    if (other is! ProColors) return this;
    return ProColors(
      pro: Color.lerp(pro, other.pro, t)!,
      proSolid: Color.lerp(proSolid, other.proSolid, t)!,
      onProSolid: Color.lerp(onProSolid, other.onProSolid, t)!,
      proContainer: Color.lerp(proContainer, other.proContainer, t)!,
      onProContainer: Color.lerp(onProContainer, other.onProContainer, t)!,
    );
  }
}
