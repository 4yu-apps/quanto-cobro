import 'custo.dart';

/// Uma **área de trabalho**: "Design", "Consultoria", "Fotografia".
///
/// É onde o CÁLCULO mora — quanto você quer ganhar, quantas horas consegue
/// vender, o que gasta pra trabalhar — e portanto de onde sai o seu valor-hora.
/// Uma área nasce de um cálculo salvo, nunca de um formulário vazio: a pessoa
/// só sabe nomear depois de ver o número (`docs/planning/08-PLANO-OFICIAL.md §4.4`).
///
/// Quem tem uma área só nunca lê a palavra "área" em lugar nenhum do app — a
/// hierarquia existe nos dados e não na navegação. O segundo nível só se revela
/// pra quem cria a segunda.
///
/// **O que NÃO mora aqui, e por quê:** o `regime` (MEI, CPF, Simples…) subiu
/// pra pessoa, em Configurações. Regime por área produzia número **errado** —
/// duas áreas geravam dois DAS para o mesmo CNPJ, enquanto o próprio app dizia
/// em texto que "o imposto do mês é um só". Ninguém é MEI só às terças.
class Area {
  const Area({
    required this.id,
    required this.nome,
    required this.renda,
    required this.horas,
    required this.provisao,
    required this.provisaoOn,
    this.provisaoCustom = false,
    this.diasSemana,
    this.horasDia,
    required this.custos,
  });

  final String id;
  final String nome;

  /// O que você quer que sobre, no bolso.
  final double renda;

  /// Horas cobráveis/mês (realista, não 160h) — a fonte da verdade.
  final int horas;

  /// Valor manual da provisão — só vale quando [provisaoCustom].
  final double provisao;
  final bool provisaoOn;

  /// Falso = provisão acompanha a renda (1 mês por ano = renda/12).
  /// Vira true quando o usuário edita o valor na mão.
  final bool provisaoCustom;

  /// Rotina que GEROU [horas]. Nullable: dado antigo não tem — nesse caso o
  /// passo abre em "digitar na mão" com o `horas` salvo.
  final int? diasSemana;
  final int? horasDia;

  final List<Custo> custos;

  double get custosTotal => custos.fold(0, (double s, Custo c) => s + c.valor);

  /// Provisão que entra na conta: manual quando o usuário editou; senão escala
  /// com a renda ("1 mês seu por ano, pra férias e 13º").
  double get provisaoEfetiva => provisaoCustom ? provisao : renda / 12;

  /// Área canônica (defaults honestos; rotina 5×6 → ~85h cobráveis).
  factory Area.padrao({String id = 'a1', String nome = 'Meu trabalho'}) => Area(
    id: id,
    nome: nome,
    renda: 5000,
    horas: 85,
    provisao: 0,
    provisaoOn: true,
    provisaoCustom: false,
    diasSemana: 5,
    horasDia: 6,
    custos: const <Custo>[
      Custo(id: 'software', label: 'Software/ferramentas', valor: 120),
      Custo(id: 'internet', label: 'Internet/telefone', valor: 100),
      Custo(id: 'equip', label: 'Equipamento (parcela no mês)', valor: 150),
      Custo(id: 'contador', label: 'Contador', valor: 200),
      Custo(id: 'coworking', label: 'Coworking', valor: 280),
    ],
  );

  Area copyWith({
    String? id,
    String? nome,
    double? renda,
    int? horas,
    double? provisao,
    bool? provisaoOn,
    bool? provisaoCustom,
    int? diasSemana,
    int? horasDia,
    List<Custo>? custos,
  }) {
    return Area(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      renda: renda ?? this.renda,
      horas: horas ?? this.horas,
      provisao: provisao ?? this.provisao,
      provisaoOn: provisaoOn ?? this.provisaoOn,
      provisaoCustom: provisaoCustom ?? this.provisaoCustom,
      diasSemana: diasSemana ?? this.diasSemana,
      horasDia: horasDia ?? this.horasDia,
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
    if (diasSemana != null) 'diasSemana': diasSemana,
    if (horasDia != null) 'horasDia': horasDia,
    'custos': custos.map((Custo c) => c.toJson()).toList(),
  };

  factory Area.fromJson(Map<String, dynamic> json) => Area(
    id: json['id'] as String? ?? 'a1',
    nome: json['nome'] as String? ?? 'Meu trabalho',
    renda: (json['renda'] as num).toDouble(),
    horas: (json['horas'] as num).toInt(),
    provisao: (json['provisao'] as num).toDouble(),
    provisaoOn: json['provisaoOn'] as bool? ?? true,
    provisaoCustom: json['provisaoCustom'] as bool? ?? false,
    diasSemana: (json['diasSemana'] as num?)?.toInt(),
    horasDia: (json['horasDia'] as num?)?.toInt(),
    custos: (json['custos'] as List<dynamic>)
        .map((dynamic e) => Custo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
