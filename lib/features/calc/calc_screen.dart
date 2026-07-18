import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/custo.dart';
import '../../core/model/perfil.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';

/// Calculadora guiada (Blueprint §5.2): UMA pergunta por tela, com default e um
/// momento didático. Cada passo tem sua validação (erro humano, nunca "input
/// inválido"). O caminho free entrega um número credível em 5 passos.
class CalcScreen extends ConsumerStatefulWidget {
  const CalcScreen({super.key});

  @override
  ConsumerState<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends ConsumerState<CalcScreen> {
  static const int _lastStep = 4;

  late Perfil _draft;
  int _step = 0;
  final TextEditingController _renda = TextEditingController();
  final TextEditingController _horas = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Recalcular parte do perfil salvo; primeiro uso parte dos defaults honestos.
    final ProfileState st = ref.read(profileProvider);
    _draft = st is ProfileReady ? st.perfil : Perfil.padrao();
    _renda.text = _draft.renda.round().toString();
    _horas.text = _draft.horas.toString();
  }

  @override
  void dispose() {
    _renda.dispose();
    _horas.dispose();
    super.dispose();
  }

  int _digits(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _draft.renda > 0;
      case 1:
        return _draft.horas > 0;
      default:
        return true; // custos (vazio ok), regime (default), provisão (toggle)
    }
  }

  void _next() {
    if (!_stepValid) return;
    if (_step < _lastStep) {
      setState(() => _step++);
    } else {
      context.push(Routes.resultado, extra: _draft);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        title: Text('Passo ${_step + 1} de ${_lastStep + 1}'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            LinearProgressIndicator(value: (_step + 1) / (_lastStep + 1)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _stepValid ? _next : null,
                  child: Text(_step == _lastStep ? 'Ver resultado' : 'Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _stepRenda();
      case 1:
        return _stepHoras();
      case 2:
        return _stepCustos();
      case 3:
        return _stepRegime();
      default:
        return _stepProvisao();
    }
  }

  Widget _title(String q) => Text(q, style: Theme.of(context).textTheme.headlineSmall);

  Widget _stepRenda() {
    final bool erro = _renda.text.isNotEmpty && _draft.renda <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Quanto você quer GANHAR por mês?'),
        const SizedBox(height: 16),
        TextField(
          controller: _renda,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: r'R$ ',
            errorText: erro ? 'Coloque quanto você quer ganhar pra eu calcular.' : null,
          ),
          onChanged: (String v) => setState(() => _draft = _draft.copyWith(renda: _digits(v).toDouble())),
        ),
        const SizedBox(height: 8),
        Text('É o que você quer que sobre pra você, não o faturamento.',
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _stepHoras() {
    final bool erro = _horas.text.isNotEmpty && _draft.horas <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Quantas horas você realmente FATURA por mês?'),
        const SizedBox(height: 16),
        TextField(
          controller: _horas,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            suffixText: 'h/mês',
            errorText: erro ? 'Preciso de pelo menos 1 hora faturável pra fazer a conta.' : null,
          ),
          onChanged: (String v) => setState(() => _draft = _draft.copyWith(horas: _digits(v))),
        ),
        const SizedBox(height: 8),
        Text('Não são 160h. Tire férias, feriados e o tempo sem cliente (vendas, e-mail, '
            'estudo). Quase ninguém fatura mais que ~70%.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _abrirEstimador,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Não sei, estimar pra mim'),
        ),
      ],
    );
  }

  Widget _stepCustos() {
    final List<Custo> custos = _draft.custos;
    final Set<String> jaTem = custos.map((Custo c) => c.id).toSet();
    final List<CostChip> faltam =
        CostChip.chips.where((CostChip c) => !jaTem.contains(c.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Seus custos pra trabalhar?'),
        const SizedBox(height: 16),
        for (final Custo c in custos)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(c.label),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(moneyBRL(c.valor)),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remover',
                  onPressed: () => setState(() {
                    _draft = _draft.copyWith(
                      custos: custos.where((Custo x) => x.id != c.id).toList(),
                    );
                  }),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text('Total: ${moneyBRL(_draft.custosTotal)}/mês',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        if (faltam.isNotEmpty) ...<Widget>[
          Text('Não esqueça:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final CostChip chip in faltam)
                ActionChip(
                  label: Text('${chip.label}  +'),
                  onPressed: () => setState(() {
                    _draft = _draft.copyWith(
                      custos: <Custo>[
                        ...custos,
                        Custo(id: chip.id, label: chip.label, valor: chip.sugg),
                      ],
                    );
                  }),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _stepRegime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Como você recebe hoje?'),
        const SizedBox(height: 16),
        for (final Regime r in Regime.all.values) _regimeOption(r),
      ],
    );
  }

  Widget _regimeOption(Regime r) {
    final bool selected = _draft.regime == r.id;
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _draft = _draft.copyWith(regime: r.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(r.label, style: theme.textTheme.titleMedium),
                  Text(r.sub, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepProvisao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Quer provisionar férias e 13º?'),
        const SizedBox(height: 8),
        Text('Autônomo não ganha de graça.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _draft.provisaoOn,
          onChanged: (bool v) => setState(() => _draft = _draft.copyWith(provisaoOn: v)),
          title: Text(_draft.provisaoOn
              ? 'Sim, reservar ${moneyBRL(_draft.provisao)}/mês'
              : 'Agora não'),
        ),
      ],
    );
  }

  Future<void> _abrirEstimador() async {
    int ferias = 4;
    int pct = 60;
    int feriados = 12;

    final int? horas = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext c) {
        return StatefulBuilder(
          builder: (BuildContext c, void Function(void Function()) setSheet) {
            final int estimado =
                estimarHorasFaturaveis(ferias: ferias, pct: pct, feriados: feriados);
            final TextTheme t = Theme.of(c).textTheme;
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: 24 + MediaQuery.of(c).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Vamos achar suas horas reais', style: t.titleLarge),
                  const SizedBox(height: 16),
                  Text('Semanas de férias por ano: $ferias', style: t.bodyMedium),
                  Slider(
                    value: ferias.toDouble(),
                    max: 8,
                    divisions: 8,
                    label: '$ferias',
                    onChanged: (double v) => setSheet(() => ferias = v.round()),
                  ),
                  Text('Do seu tempo, quanto é trabalho pago: $pct%', style: t.bodyMedium),
                  Slider(
                    value: pct.toDouble(),
                    min: 30,
                    max: 90,
                    divisions: 12,
                    label: '$pct%',
                    onChanged: (double v) => setSheet(() => pct = v.round()),
                  ),
                  Text('Feriados por ano: $feriados', style: t.bodyMedium),
                  Slider(
                    value: feriados.toDouble(),
                    max: 20,
                    divisions: 20,
                    label: '$feriados',
                    onChanged: (double v) => setSheet(() => feriados = v.round()),
                  ),
                  const SizedBox(height: 8),
                  Text('≈ $estimado h/mês', style: t.headlineSmall),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(c, estimado),
                      child: Text('Usar $estimado h/mês'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (horas != null && mounted) {
      setState(() {
        _draft = _draft.copyWith(horas: horas);
        _horas.text = horas.toString();
      });
    }
  }
}
