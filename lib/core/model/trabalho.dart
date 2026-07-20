/// Um **trabalho**: o freela com o Augusto, o site da Padaria, o cliente fixo.
///
/// Mora dentro de uma [Area] e guarda as **entradas** — o que entrou, quando, e
/// quanto disso foi separado de imposto.
///
/// ## O que este objeto NÃO tem, e é a parte importante
///
/// Não tem data de vencimento, status de quatro estados, recorrência
/// configurável nem previsão de caixa. Tudo isso existiu e foi cortado em
/// 19/07/2026, porque cada um exigia que a pessoa **alimentasse o app toda
/// semana** pra ter valor — e essa é exatamente a fronteira do produto:
///
/// > Lembrar o que a pessoa disse uma vez = calculadora com memória. ✅
/// > Exigir que ela alimente o app toda semana = gestão. ❌
///
/// O gatilho pra voltar ao app é o dinheiro cair, não o app cutucar. Cadastrar
/// a entrada É o registro; ninguém fica marcando "recebi, recebi, recebi".
class Trabalho {
  const Trabalho({
    required this.id,
    required this.areaId,
    required this.nome,
    required this.criadoEm,
    this.valorCombinado = 0,
    this.encerrado = false,
    this.observacoes,
  });

  final String id;

  /// A área a que este trabalho pertence — é dela que sai o valor-hora.
  final String areaId;

  /// Como a pessoa chama: "Augusto", "Padaria", "Loja da Ana".
  final String nome;

  final DateTime criadoEm;

  /// O combinado, quando existe. Opcional de propósito: muita gente fecha
  /// trabalho sem valor fixo, e exigir o número aqui seria inventar uma
  /// certeza que a pessoa não tem. Serve pra pré-preencher a entrada.
  final double valorCombinado;

  /// Acabou. Um booleano, não quatro estados: "Orçamento / Ativo / Concluído /
  /// Pausado" é vocabulário de board de kanban, e obriga a pessoa a manter um
  /// status atualizado que ninguém lê depois.
  final bool encerrado;

  final String? observacoes;

  Trabalho copyWith({
    String? areaId,
    String? nome,
    double? valorCombinado,
    bool? encerrado,
    String? observacoes,
  }) => Trabalho(
    id: id,
    areaId: areaId ?? this.areaId,
    nome: nome ?? this.nome,
    criadoEm: criadoEm,
    valorCombinado: valorCombinado ?? this.valorCombinado,
    encerrado: encerrado ?? this.encerrado,
    observacoes: observacoes ?? this.observacoes,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'areaId': areaId,
    'nome': nome,
    'criadoEm': criadoEm.toIso8601String(),
    'valorCombinado': valorCombinado,
    'encerrado': encerrado,
    if (observacoes != null) 'observacoes': observacoes,
  };

  factory Trabalho.fromJson(Map<String, dynamic> json) => Trabalho(
    id: json['id'] as String,
    areaId: json['areaId'] as String? ?? '',
    nome: json['nome'] as String? ?? 'Trabalho',
    criadoEm:
        DateTime.tryParse(json['criadoEm'] as String? ?? '') ?? DateTime(2024),
    valorCombinado: (json['valorCombinado'] as num?)?.toDouble() ?? 0,
    encerrado: json['encerrado'] as bool? ?? false,
    observacoes: json['observacoes'] as String?,
  );
}
