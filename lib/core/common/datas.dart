/// Datas na fala do app, em pt-BR.
///
/// Tabela à mão de propósito: `DateFormat` com locale 'pt_BR' exige
/// `initializeDateFormatting` no boot e carrega os símbolos de data de TODOS
/// os locales — peso e um ponto de falha em runtime pra um app que fala uma
/// língua só e mostra doze palavras. O app já vinha escrevendo os meses assim.
const List<String> kMesesAbrev = <String>[
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

const List<String> kMeses = <String>[
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String mesNome(DateTime data) => kMeses[data.month - 1];

String _dois(int n) => n.toString().padLeft(2, '0');

/// "10/ago" — e "10/ago/25" quando não é o ano corrente. O ano só aparece
/// quando muda o sentido; senão é ruído em cima do que importa (o dia).
String dataCurta(DateTime data, {DateTime? hoje}) {
  final int anoRef = (hoje ?? DateTime.now()).year;
  final String base = '${_dois(data.day)}/${kMesesAbrev[data.month - 1]}';
  return data.year == anoRef ? base : '$base/${_dois(data.year % 100)}';
}

/// "10 de agosto" — pra leitor de tela e frases corridas, onde "10/ago" é lido
/// como "dez barra ago".
String dataPorExtenso(DateTime data) =>
    '${data.day} de ${mesNome(data)}${data.year == DateTime.now().year ? '' : ' de ${data.year}'}';

/// "19/07/2026" — data cheia, pro documento que vai pro cliente.
String dataNumerica(DateTime data) =>
    '${_dois(data.day)}/${_dois(data.month)}/${data.year}';

/// "este mês" / "agosto de 2025" — cabeçalho de agrupamento.
String mesAno(DateTime data, {DateTime? hoje}) {
  final DateTime ref = hoje ?? DateTime.now();
  final String nome = mesNome(data);
  return data.year == ref.year ? nome : '$nome de ${data.year}';
}
