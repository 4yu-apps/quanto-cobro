import 'custo.dart';
import 'regime.dart';

/// Perfil de cálculo (permanente/estratégico). Cada CASO do usuário é um
/// perfil: "Freela design", "Consultoria", "Cliente fixo"... Alimenta de
/// defaults os tools recorrentes (reserva, simulador). Na UI o nome é sempre
/// "trabalho"; "perfil" sobrevive só em código e rotas.
class Perfil {
  const Perfil({
    required this.id,
    required this.nome,
    required this.renda,
    required this.horas,
    required this.provisao,
    required this.provisaoOn,
    this.provisaoCustom = false,
    required this.regime,
    required this.custos,
  });

  final String id;
  final String nome;
  final double renda; // o que você quer que sobre, no bolso
  final int horas; // horas faturáveis/mês (realista, não 160h)

  /// Valor manual da provisão — só vale quando [provisaoCustom].
  final double provisao;
  final bool provisaoOn;

  /// Falso = provisão acompanha a renda (1 mês por ano = renda/12).
  /// Vira true quando o usuário edita o valor na mão.
  final bool provisaoCustom;
  final RegimeId regime;
  final List<Custo> custos;

  double get custosTotal => custos.fold(0, (double s, Custo c) => s + c.valor);

  /// Provisão que entra na conta: manual quando o usuário editou; senão
  /// escala com a renda ("1 mês seu por ano, pra férias e 13º").
  double get provisaoEfetiva => provisaoCustom ? provisao : renda / 12;

  /// Perfil canônico (defaults honestos; provisão acompanha a renda).
  factory Perfil.padrao({String id = 'p1', String nome = 'Meu trabalho'}) =>
      Perfil(
        id: id,
        nome: nome,
        renda: 5000,
        horas: 82,
        provisao: 0,
        provisaoOn: true,
        provisaoCustom: false,
        regime: RegimeId.mei,
        custos: const <Custo>[
          Custo(id: 'software', label: 'Software/ferramentas', valor: 120),
          Custo(id: 'internet', label: 'Internet/telefone', valor: 100),
          Custo(id: 'equip', label: 'Equipamento (rateio)', valor: 150),
          Custo(id: 'contador', label: 'Contador', valor: 200),
          Custo(id: 'coworking', label: 'Coworking', valor: 280),
        ],
      );

  Perfil copyWith({
    String? id,
    String? nome,
    double? renda,
    int? horas,
    double? provisao,
    bool? provisaoOn,
    bool? provisaoCustom,
    RegimeId? regime,
    List<Custo>? custos,
  }) {
    return Perfil(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      renda: renda ?? this.renda,
      horas: horas ?? this.horas,
      provisao: provisao ?? this.provisao,
      provisaoOn: provisaoOn ?? this.provisaoOn,
      provisaoCustom: provisaoCustom ?? this.provisaoCustom,
      regime: regime ?? this.regime,
      custos: custos ?? this.custos,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nome': nome,
    'renda': renda,
    'horas': horas,
    'provisao': provisao,
    'provisaoOn': provisaoOn,
    'provisaoCustom': provisaoCustom,
    'regime': regime.name,
    'custos': custos.map((Custo c) => c.toJson()).toList(),
  };

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
    id: json['id'] as String? ?? 'p1',
    nome: json['nome'] as String? ?? 'Meu trabalho',
    renda: (json['renda'] as num).toDouble(),
    horas: (json['horas'] as num).toInt(),
    provisao: (json['provisao'] as num).toDouble(),
    provisaoOn: json['provisaoOn'] as bool? ?? true,
    // Legado (v0.3, R$458 fixo): melhor migração é a provisão que escala.
    provisaoCustom: json['provisaoCustom'] as bool? ?? false,
    regime: RegimeId.values.byName(json['regime'] as String),
    custos: (json['custos'] as List<dynamic>)
        .map((dynamic e) => Custo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
