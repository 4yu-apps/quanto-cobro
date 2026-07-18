import 'custo.dart';
import 'regime.dart';

/// Perfil de cálculo (permanente/estratégico). Alimenta de defaults os tools
/// recorrentes (reserva, simulador). No MVP: 1 perfil; no Pro: vários.
class Perfil {
  const Perfil({
    required this.nome,
    required this.renda,
    required this.horas,
    required this.provisao,
    required this.provisaoOn,
    required this.regime,
    required this.custos,
  });

  final String nome;
  final double renda; // o que você quer que sobre, no bolso
  final int horas; // horas faturáveis/mês (realista, não 160h)
  final double provisao; // férias + 13º
  final bool provisaoOn;
  final RegimeId regime;
  final List<Custo> custos;

  double get custosTotal => custos.fold(0, (double s, Custo c) => s + c.valor);

  /// Perfil canônico do protótipo (resultado coerente: ~R$ 92/hora).
  factory Perfil.padrao() => const Perfil(
        nome: 'Padrão',
        renda: 5000,
        horas: 82,
        provisao: 458,
        provisaoOn: true,
        regime: RegimeId.mei,
        custos: <Custo>[
          Custo(id: 'software', label: 'Software/ferramentas', valor: 120),
          Custo(id: 'internet', label: 'Internet/telefone', valor: 100),
          Custo(id: 'equip', label: 'Equipamento (rateio)', valor: 150),
          Custo(id: 'contador', label: 'Contador', valor: 200),
          Custo(id: 'coworking', label: 'Coworking', valor: 280),
        ],
      );

  Perfil copyWith({
    String? nome,
    double? renda,
    int? horas,
    double? provisao,
    bool? provisaoOn,
    RegimeId? regime,
    List<Custo>? custos,
  }) {
    return Perfil(
      nome: nome ?? this.nome,
      renda: renda ?? this.renda,
      horas: horas ?? this.horas,
      provisao: provisao ?? this.provisao,
      provisaoOn: provisaoOn ?? this.provisaoOn,
      regime: regime ?? this.regime,
      custos: custos ?? this.custos,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nome': nome,
        'renda': renda,
        'horas': horas,
        'provisao': provisao,
        'provisaoOn': provisaoOn,
        'regime': regime.name,
        'custos': custos.map((Custo c) => c.toJson()).toList(),
      };

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        nome: json['nome'] as String? ?? 'Padrão',
        renda: (json['renda'] as num).toDouble(),
        horas: (json['horas'] as num).toInt(),
        provisao: (json['provisao'] as num).toDouble(),
        provisaoOn: json['provisaoOn'] as bool? ?? true,
        regime: RegimeId.values.byName(json['regime'] as String),
        custos: (json['custos'] as List<dynamic>)
            .map((dynamic e) => Custo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
