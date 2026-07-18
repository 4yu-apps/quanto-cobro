/// Um custo fixo de trabalhar. Os chips de lembrança materializam o "custo
/// invisível" (Blueprint §5.5 / §7.1) — o que a calculadora rasa não faz.
class Custo {
  const Custo({required this.id, required this.label, required this.valor});

  final String id;
  final String label;
  final double valor; // em reais/mês

  Custo copyWith({String? id, String? label, double? valor}) =>
      Custo(id: id ?? this.id, label: label ?? this.label, valor: valor ?? this.valor);
}

/// Chip de custo sugerido ("não esqueça"): contador, coworking, cursos...
class CostChip {
  const CostChip({required this.id, required this.label, required this.icon, required this.sugg});

  final String id;
  final String label;
  final String icon; // nome do Material Symbol
  final double sugg;

  static const List<CostChip> chips = <CostChip>[
    CostChip(id: 'contador', label: 'Contador', icon: 'calculate', sugg: 200),
    CostChip(id: 'coworking', label: 'Coworking', icon: 'chair', sugg: 280),
    CostChip(id: 'cursos', label: 'Cursos', icon: 'school', sugg: 120),
    CostChip(id: 'energia', label: 'Energia', icon: 'bolt', sugg: 90),
    CostChip(id: 'internet', label: 'Internet/telefone', icon: 'wifi', sugg: 100),
    CostChip(id: 'equip', label: 'Equipamento', icon: 'devices', sugg: 150),
    CostChip(id: 'prolabore', label: 'Pró-labore', icon: 'account_balance', sugg: 0),
    CostChip(id: 'saude', label: 'Plano de saúde', icon: 'health_and_safety', sugg: 350),
    CostChip(id: 'software', label: 'Software', icon: 'apps', sugg: 120),
    CostChip(id: 'marketing', label: 'Marketing', icon: 'campaign', sugg: 80),
    CostChip(id: 'transporte', label: 'Transporte', icon: 'directions_car', sugg: 120),
  ];
}
