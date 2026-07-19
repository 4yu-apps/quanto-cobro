import 'package:intl/intl.dart';

import '../model/moeda.dart';

/// Formatação de moeda SEMPRE via intl (nunca concatenação manual) — evita erro
/// e é acessível (Blueprint §9). Reais inteiros no herói (o app fala em R$ 92).
///
/// Genérica, base da Fase 3 (multi-moeda — cliente estrangeiro).
String money(num value, Moeda moeda) => NumberFormat.currency(
  locale: moeda.locale,
  symbol: moeda.simbolo,
  decimalDigits: moeda.casas,
).format(value);

String moneyBRL(num value) => money(value, Moeda.brl);

/// Com centavos — pra valores oficiais exatos (ex.: DAS R$ 86,05), onde
/// arredondar seria mentir.
final NumberFormat _brlCents = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
  decimalDigits: 2,
);

String moneyBRLCents(num value) => _brlCents.format(value);
