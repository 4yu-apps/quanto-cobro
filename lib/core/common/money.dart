import 'package:intl/intl.dart';

/// Formatação de moeda SEMPRE via intl (nunca concatenação manual) — evita erro
/// e é acessível (Blueprint §9). Reais inteiros no herói (o app fala em R$ 92).
final NumberFormat _brl = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
  decimalDigits: 0,
);

String moneyBRL(num value) => _brl.format(value);

/// Com centavos — pra valores oficiais exatos (ex.: DAS R$ 86,05), onde
/// arredondar seria mentir.
final NumberFormat _brlCents = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
  decimalDigits: 2,
);

String moneyBRLCents(num value) => _brlCents.format(value);
