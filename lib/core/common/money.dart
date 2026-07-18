import 'package:intl/intl.dart';

/// Formatação de moeda SEMPRE via intl (nunca concatenação manual) — evita erro
/// e é acessível (Blueprint §9). Reais inteiros no herói (o app fala em R$ 92).
final NumberFormat _brl =
    NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 0);

String moneyBRL(num value) => _brl.format(value);
