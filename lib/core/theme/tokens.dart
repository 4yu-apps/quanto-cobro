import 'package:flutter/widgets.dart';

/// Tokens de fundamento (Design System §5): espaço, raio, motion.
/// Mesmos nomes do Claude Design → de-para direto.
abstract final class Space {
  static const double x0 = 0;
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;
}

abstract final class Radii {
  static const Radius sm = Radius.circular(12);
  static const Radius md = Radius.circular(16);
  static const Radius lg = Radius.circular(20);
  static const Radius xl = Radius.circular(24);
  static const Radius xl2 = Radius.circular(28);
  static const Radius full = Radius.circular(999);
}

abstract final class Motion {
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration countUp = Duration(milliseconds: 600);
  static const Duration fill = Duration(milliseconds: 450);
}
