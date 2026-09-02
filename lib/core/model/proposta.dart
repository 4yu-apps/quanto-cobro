/// O conteúdo da proposta que o CLIENTE vê (07 §A.6 — a regra de ouro).
///
/// Repare no que NÃO existe aqui: divisão, reserva, imposto, custo, lucro.
/// Não é esquecimento — é a regra. Esses números são a confiança interna do
/// freelancer; expor eles no documento entrega a cozinha pro cliente
/// pechinchar. Se um dia alguém for adicionar um campo `lucro` neste arquivo,
/// a resposta é não.
class Proposta {
  const Proposta({
    required this.servico,
    required this.valor,
    this.descricao = '',
    this.prazo = '',
    this.validadeDias = 7,
    this.formaPagamento = kFormaPagamentoPadrao,
    this.cliente = '',
    this.observacoes = '',
    this.mostrarHoras = false,
    this.horas,
    this.valorHora,
  });

  /// Default de mercado (PeqArt): sinal protege o freelancer de sumiço.
  static const String kFormaPagamentoPadrao =
      'PIX · 50% de sinal, 50% na entrega';

  static const List<String> kMeios = <String>[
    'PIX',
    'Transferência',
    'Cartão',
    'Boleto',
  ];

  /// A primeira é o default: sinal protege o freelancer de sumiço.
  static const List<String> kCondicoes = <String>[
    '50% de sinal, 50% na entrega',
    'À vista na entrega',
    'Parcelado',
  ];

  static String prazoDe(int dias, {bool uteis = true}) {
    final String unidade = dias == 1 ? 'dia' : 'dias';
    final String tipo = uteis
        ? (dias == 1 ? 'útil' : 'úteis')
        : (dias == 1 ? 'corrido' : 'corridos');
    return '$dias $unidade $tipo';
  }

  static (int?, bool) prazoParse(String s) {
    final RegExpMatch? m = RegExp(
      r'^\s*(\d+)\s*dias?\s*(úteis|útil|uteis|util|corridos?)?\s*$',
      caseSensitive: false,
    ).firstMatch(s);
    if (m == null) return (null, true);
    final String tipo = (m.group(2) ?? 'úteis').toLowerCase();
    return (int.parse(m.group(1)!), !tipo.startsWith('corrid'));
  }

  static String formaPagamentoDe({
    required List<String> meios,
    required String condicao,
    String extra = '',
  }) {
    final List<String> partes = <String>[
      if (meios.isNotEmpty) meios.join(' ou '),
      condicao,
      if (extra.trim().isNotEmpty) extra.trim(),
    ];
    return partes.join(' · ');
  }

  static ({List<String> meios, String condicao, String extra})
  formaPagamentoParse(String s) {
    final String baixo = s.toLowerCase();
    final List<String> meios = kMeios
        .where((String m) => baixo.contains(m.toLowerCase()))
        .toList();
    final String condicao = kCondicoes.firstWhere(
      (String c) => baixo.contains(c.toLowerCase()),
      orElse: () => kCondicoes.first,
    );
    final bool reconhecido =
        meios.isNotEmpty ||
        kCondicoes.any((String c) => baixo.contains(c.toLowerCase()));
    return (
      meios: meios,
      condicao: condicao,
      extra: reconhecido || s.trim().isEmpty ? '' : s.trim(),
    );
  }

  final String servico;
  final String descricao;

  /// Em reais. O número que veio do Simulador/Calculadora, editável.
  final double valor;

  final String prazo;

  /// Default 7 dias: protege o freelancer de honrar preço velho e cria uma
  /// urgência leve, sem pressão agressiva.
  final int validadeDias;

  final String formaPagamento;
  final String cliente;
  final String observacoes;

  /// DESLIGADO por default de propósito (07 §A.6): cliente que vê "40h × R$92"
  /// ancora na hora e pechincha a hora. Preço se vende por valor entregue.
  final bool mostrarHoras;

  final int? horas;
  final double? valorHora;

  /// Só faz sentido mostrar o detalhamento se os dois números existirem.
  bool get temDetalheHoras =>
      mostrarHoras && horas != null && horas! > 0 && valorHora != null;

  Proposta copyWith({
    String? servico,
    String? descricao,
    double? valor,
    String? prazo,
    int? validadeDias,
    String? formaPagamento,
    String? cliente,
    String? observacoes,
    bool? mostrarHoras,
    int? horas,
    double? valorHora,
  }) => Proposta(
    servico: servico ?? this.servico,
    descricao: descricao ?? this.descricao,
    valor: valor ?? this.valor,
    prazo: prazo ?? this.prazo,
    validadeDias: validadeDias ?? this.validadeDias,
    formaPagamento: formaPagamento ?? this.formaPagamento,
    cliente: cliente ?? this.cliente,
    observacoes: observacoes ?? this.observacoes,
    mostrarHoras: mostrarHoras ?? this.mostrarHoras,
    horas: horas ?? this.horas,
    valorHora: valorHora ?? this.valorHora,
  );
}
