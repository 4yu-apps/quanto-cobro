/// Um recebimento registrado no histórico de reservas (IA §2.12) — o gancho de
/// hábito: "quanto já guardei pro imposto este mês?".
class ReservaEntry {
  const ReservaEntry({
    required this.valor,
    required this.reserva,
    required this.regimeTag,
    required this.at,
    this.perfilId,
    this.projetoId,
    this.tipo = 'pct',
  });

  final double valor; // quanto recebeu
  final int reserva; // quanto separar
  final String regimeTag; // MEI / Autônomo / Simples / Internacional
  final DateTime at;

  /// Trabalho a que o registro pertence (null em registros antigos).
  final String? perfilId;

  /// Projeto/cliente que pagou (07 §C). É o que faz "já recebeu R$ X" e o selo
  /// "imposto separado" saírem do histórico que JÁ existe, sem tabela nova. Null em
  /// registro avulso (a pessoa recebeu algo que não está na lista de projetos)
  /// e em tudo que foi salvo antes desta versão.
  final String? projetoId;

  /// LEGADO. Sempre `'pct'` no que se grava a partir da v0.6.
  ///
  /// O `'das'` existia quando o registro do MEI não era um pagamento e sim uma
  /// separação de imposto avulsa — o modelo que impedia o MEI de ligar o
  /// dinheiro ao cliente e de anotar mais de um recebimento por mês. Continua
  /// sendo LIDO porque o histórico de quem já usava o app tem esses registros,
  /// e eles de fato não são faturamento de ninguém.
  final String tipo;

  bool get isDas => tipo == 'das';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'valor': valor,
    'reserva': reserva,
    'regimeTag': regimeTag,
    'at': at.toIso8601String(),
    if (perfilId != null) 'perfilId': perfilId,
    if (projetoId != null) 'projetoId': projetoId,
    'tipo': tipo,
  };

  factory ReservaEntry.fromJson(Map<String, dynamic> json) => ReservaEntry(
    valor: (json['valor'] as num).toDouble(),
    reserva: (json['reserva'] as num).toInt(),
    regimeTag: json['regimeTag'] as String,
    at: DateTime.parse(json['at'] as String),
    perfilId: json['perfilId'] as String?,
    projetoId: json['projetoId'] as String?,
    tipo: json['tipo'] as String? ?? 'pct',
  );
}
