/// De quanto em quanto tempo esse cliente paga (07 §B.3). São QUATRO opções e
/// não um motor de cron: o leigo não configura RRULE, e cada opção a mais é
/// uma pergunta a mais na cara de quem só quer saber quando entra dinheiro.
enum Recorrencia {
  avulso, // uma vez só (o freela de sempre)
  mensal, // cliente fixo — o caso da Camila
  trimestral,
  custom, // a cada N meses (o "aquele a cada 4 meses")
}

/// Ciclo de vida do projeto. Quatro estados, ponto — é o que impede a lista de
/// virar um kanban de 12 colunas (07 §D.1).
enum ProjetoStatus { orcamento, ativo, concluido, pausado }

extension RecorrenciaLabel on Recorrencia {
  /// Como o usuário lê. `intervalo` só é usado por [Recorrencia.custom].
  String label({int intervaloMeses = 2}) => switch (this) {
    Recorrencia.avulso => 'Uma vez',
    Recorrencia.mensal => 'Todo mês',
    Recorrencia.trimestral => 'A cada 3 meses',
    Recorrencia.custom => 'A cada $intervaloMeses meses',
  };

  /// Quantos meses até o próximo recebimento — `null` quando não repete.
  int? get meses => switch (this) {
    Recorrencia.avulso => null,
    Recorrencia.mensal => 1,
    Recorrencia.trimestral => 3,
    Recorrencia.custom => null, // vem de Projeto.intervaloMeses
  };
}

extension ProjetoStatusLabel on ProjetoStatus {
  String get label => switch (this) {
    ProjetoStatus.orcamento => 'Orçamento',
    ProjetoStatus.ativo => 'Ativo',
    ProjetoStatus.concluido => 'Concluído',
    ProjetoStatus.pausado => 'Pausado',
  };

  /// Projeto "vivo" = ainda espera dinheiro. Orçamento não conta: a proposta
  /// pode nunca ser aceita, e prometer caixa que talvez não venha é pior que
  /// não prometer nada.
  bool get esperaRecebimento => this == ProjetoStatus.ativo;
}

/// Um cliente/engajamento (07 §B.3). NÃO é uma tarefa nem um card de board:
/// cada campo aqui existe porque responde "quanto vem, quando, e quanto disso
/// é do Leão?". Essa é a régua pra aceitar ou recusar qualquer campo futuro.
class Projeto {
  const Projeto({
    required this.id,
    required this.nome,
    required this.valor,
    required this.recorrencia,
    required this.status,
    required this.criadoEm,
    this.intervaloMeses = 2,
    this.cliente,
    this.proximoRecebimento,
    this.perfilId,
    this.observacoes,
  });

  final String id;

  /// Nome do cliente ou do projeto: "Loja da Ana", "Site Padaria".
  final String nome;

  /// Valor combinado POR CICLO (não o total do contrato) — é o número que
  /// entra na Reserva quando ele diz "recebi".
  final double valor;

  final Recorrencia recorrencia;

  /// Só vale quando [recorrencia] é [Recorrencia.custom].
  final int intervaloMeses;

  final ProjetoStatus status;
  final DateTime criadoEm;

  /// Nome de quem paga, quando é diferente do nome do projeto. Opcional: pedir
  /// dois nomes pra cadastrar um cliente é atrito à toa.
  final String? cliente;

  /// A data que mata a ansiedade do power user ("quem me paga quando").
  final DateTime? proximoRecebimento;

  /// Preço/regime que este projeto usa (`Perfil`). Daí sai a % de reserva.
  /// O imposto continua POR PESSOA, não por projeto — isto aqui só diz qual
  /// preço foi combinado, não cria uma caixinha de imposto separada.
  final String? perfilId;

  final String? observacoes;

  /// Meses entre um recebimento e o próximo — `null` quando não repete.
  int? get intervalo =>
      recorrencia == Recorrencia.custom ? intervaloMeses : recorrencia.meses;

  bool get recorrente => intervalo != null;

  String get recorrenciaLabel =>
      recorrencia.label(intervaloMeses: intervaloMeses);

  /// A data do recebimento seguinte a [base], respeitando a recorrência.
  /// `null` em projeto avulso (recebeu, acabou).
  ///
  /// Somar mês não é somar 30 dias: 31/jan + 1 mês tem que cair em 28/fev, não
  /// em 03/mar. O `DateTime` do Dart estoura sozinho pro mês seguinte, então
  /// o dia é grampeado no último dia do mês de destino.
  DateTime? proximoApos(DateTime base) {
    final int? meses = intervalo;
    if (meses == null) return null;
    final int totalMes = base.month - 1 + meses;
    final int ano = base.year + totalMes ~/ 12;
    final int mes = totalMes % 12 + 1;
    final int ultimoDia = DateTime(ano, mes + 1, 0).day;
    return DateTime(ano, mes, base.day > ultimoDia ? ultimoDia : base.day);
  }

  Projeto copyWith({
    String? nome,
    double? valor,
    Recorrencia? recorrencia,
    int? intervaloMeses,
    ProjetoStatus? status,
    String? cliente,
    DateTime? proximoRecebimento,
    bool limparProximoRecebimento = false,
    String? perfilId,
    String? observacoes,
  }) {
    return Projeto(
      id: id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      recorrencia: recorrencia ?? this.recorrencia,
      intervaloMeses: intervaloMeses ?? this.intervaloMeses,
      status: status ?? this.status,
      criadoEm: criadoEm,
      cliente: cliente ?? this.cliente,
      proximoRecebimento: limparProximoRecebimento
          ? null
          : (proximoRecebimento ?? this.proximoRecebimento),
      perfilId: perfilId ?? this.perfilId,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nome': nome,
    'valor': valor,
    'recorrencia': recorrencia.name,
    'intervaloMeses': intervaloMeses,
    'status': status.name,
    'criadoEm': criadoEm.toIso8601String(),
    if (cliente != null) 'cliente': cliente,
    if (proximoRecebimento != null)
      'proximoRecebimento': proximoRecebimento!.toIso8601String(),
    if (perfilId != null) 'perfilId': perfilId,
    if (observacoes != null) 'observacoes': observacoes,
  };

  /// Tolerante a dado de versão futura/antiga: um enum desconhecido cai no
  /// default em vez de derrubar a lista inteira de projetos.
  factory Projeto.fromJson(Map<String, dynamic> json) => Projeto(
    id: json['id'] as String,
    nome: json['nome'] as String? ?? 'Projeto',
    valor: (json['valor'] as num?)?.toDouble() ?? 0,
    recorrencia: _enumOr(
      Recorrencia.values,
      json['recorrencia'] as String?,
      Recorrencia.avulso,
    ),
    intervaloMeses: (json['intervaloMeses'] as num?)?.toInt() ?? 2,
    status: _enumOr(
      ProjetoStatus.values,
      json['status'] as String?,
      ProjetoStatus.ativo,
    ),
    criadoEm:
        DateTime.tryParse(json['criadoEm'] as String? ?? '') ?? DateTime(2024),
    cliente: json['cliente'] as String?,
    proximoRecebimento: json['proximoRecebimento'] == null
        ? null
        : DateTime.tryParse(json['proximoRecebimento'] as String),
    perfilId: json['perfilId'] as String?,
    observacoes: json['observacoes'] as String?,
  );
}

/// Pra onde a data do próximo recebimento anda depois de um pagamento
/// registrado em [pagoEm]. Pura de propósito: é regra de negócio com data,
/// exatamente o tipo de coisa que precisa de teste sem widget no meio.
///
/// A base é a data AGENDADA (não a data do pagamento): quem paga no dia 12 um
/// boleto do dia 10 não deve empurrar o ciclo inteiro pra frente mês a mês.
/// E se a pessoa passou meses sem registrar, o ciclo avança até sair do
/// passado — devolver uma data velha faria o card nascer "atrasado".
DateTime? avancarCiclo(Projeto projeto, {required DateTime pagoEm}) {
  if (!projeto.recorrente) return null;
  DateTime? proximo = projeto.proximoApos(projeto.proximoRecebimento ?? pagoEm);
  int voltas = 0;
  while (proximo != null && proximo.isBefore(pagoEm) && voltas++ < 240) {
    proximo = projeto.proximoApos(proximo);
  }
  return proximo;
}

T _enumOr<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
