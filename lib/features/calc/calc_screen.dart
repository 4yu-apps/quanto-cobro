import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/custo.dart';
import '../../core/model/perfil.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/money_field.dart';

/// Calculadora guiada (Blueprint §5.2): UMA pergunta por tela, com default e um
/// momento didático. Cada passo tem sua validação (erro humano). O caminho free
/// entrega um número credível em 5 passos.
class CalcScreen extends ConsumerStatefulWidget {
  const CalcScreen({super.key, this.novoTrabalho, this.initialDraft});

  /// Quando presente, cria um NOVO perfil com esse nome (em vez de editar o ativo).
  final String? novoTrabalho;
  final Perfil? initialDraft;

  @override
  ConsumerState<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends ConsumerState<CalcScreen> {
  static const int _lastStep = 4;

  late Perfil _draft;
  int _step = 0;
  int _prevStep = 0;
  bool _triedContinue = false;
  final TextEditingController _renda = TextEditingController();
  final TextEditingController _horas = TextEditingController();
  final FocusNode _rendaFocus = FocusNode();
  final FocusNode _horasFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final ProfileState st = ref.read(profileProvider);
    final String? novo = widget.novoTrabalho;
    if (widget.initialDraft != null) {
      _draft = widget.initialDraft!;
    } else if (novo != null) {
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      if (st is ProfileReady) {
        _draft = st.perfil.copyWith(id: id, nome: novo);
      } else {
        final bool intl = ref.read(settingsRepositoryProvider).modo() == 'intl';
        _draft = Perfil.padrao(
          id: id,
          nome: novo,
        ).copyWith(regime: intl ? RegimeId.intl : RegimeId.mei);
      }
    } else if (st is ProfileReady) {
      _draft = st.perfil;
    } else {
      // Primeiro uso: defaults honestos + regime pré-selecionado pelo modo BR/intl.
      final bool intl = ref.read(settingsRepositoryProvider).modo() == 'intl';
      _draft = Perfil.padrao().copyWith(
        regime: intl ? RegimeId.intl : RegimeId.mei,
      );
    }
    _renda.text = _draft.renda.round().toString();
    _horas.text = _draft.horas.toString();
  }

  @override
  void dispose() {
    _renda.dispose();
    _horas.dispose();
    _rendaFocus.dispose();
    _horasFocus.dispose();
    super.dispose();
  }

  /// Foca o campo do passo corrente APOS o slide (teclado nao pula no meio
  /// da transicao). Passos sem campo nao roubam foco.
  void _focusStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(Motion.base, () {
        if (!mounted) return;
        if (_step == 0) _rendaFocus.requestFocus();
        if (_step == 1) _horasFocus.requestFocus();
      });
    });
  }

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool get _stepValid {
    switch (_step) {
      case 0:
        return _draft.renda > 0;
      case 1:
        return _draft.horas > 0;
      default:
        return true;
    }
  }

  void _next() {
    if (!_stepValid) {
      setState(() => _triedContinue = true);
      final bool renda = _step == 0;
      announce(
        context,
        renda
            ? 'Coloque quanto você quer ganhar pra eu calcular.'
            : 'Preciso de pelo menos 1 hora faturável pra fazer a conta.',
      );
      (renda ? _rendaFocus : _horasFocus).requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    if (_step < _lastStep) {
      Haptics.select();
      setState(() {
        _prevStep = _step;
        _step++;
        _triedContinue = false;
      });
      _focusStep();
      Future<void>.delayed(Motion.base, () {
        if (mounted) {
          announce(
            context,
            'Passo ${_step + 1} de ${_lastStep + 1}. ${_stepTitle(_step)}',
          );
        }
      });
    } else {
      context.push(Routes.resultado, extra: _draft);
    }
  }

  void _back() {
    if (_step > 0) {
      FocusScope.of(context).unfocus();
      setState(() {
        _prevStep = _step;
        _step--;
        _triedContinue = false;
      });
      _focusStep();
      Future<void>.delayed(Motion.base, () {
        if (mounted) {
          announce(
            context,
            'Passo ${_step + 1} de ${_lastStep + 1}. ${_stepTitle(_step)}',
          );
        }
      });
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: Text('Passo ${_step + 1} de ${_lastStep + 1}'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x4,
                vertical: Space.x2,
              ),
              child: Row(
                children: <Widget>[
                  for (int i = 0; i <= _lastStep; i++)
                    AnimatedContainer(
                      duration: reduceMotionOf(context)
                          ? Duration.zero
                          : Motion.base,
                      curve: MotionCurves.standard,
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _step ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radii.full),
                        color: i <= _step ? cs.primary : cs.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotionOf(context) ? Duration.zero : Motion.base,
                switchInCurve: MotionCurves.standard,
                switchOutCurve: MotionCurves.standard,
                transitionBuilder: (Widget child, Animation<double> anim) {
                  final bool forward = _step >= _prevStep;
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(forward ? 0.12 : -0.12, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  );
                },
                layoutBuilder: (Widget? current, List<Widget> previous) =>
                    Stack(
                      alignment: Alignment.topLeft,
                      children: <Widget>[...previous, ?current],
                    ),
                child: SingleChildScrollView(
                  key: ValueKey<int>(_step),
                  padding: const EdgeInsets.all(Space.x6),
                  child: _buildStep(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.x4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: AnimatedSwitcher(
                    duration: reduceMotionOf(context)
                        ? Duration.zero
                        : Motion.base,
                    child: Text(
                      _step == _lastStep ? 'Ver resultado' : 'Continuar',
                      key: ValueKey<int>(_step == _lastStep ? 1 : 0),
                    ),
                  ),
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

  Widget _title(String q) =>
      Text(q, style: Theme.of(context).textTheme.headlineSmall);

  String _stepTitle(int step) => switch (step) {
    0 => 'Quanto você quer ganhar por mês?',
    1 => 'Quantas horas você realmente fatura por mês?',
    2 => 'Seus custos pra trabalhar?',
    3 => 'Como você recebe hoje?',
    _ => 'Quer provisionar férias e décimo terceiro?',
  };

  Widget _stepRenda() {
    final bool erro = _triedContinue && _draft.renda <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.novoTrabalho != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(Space.x3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.all(Radii.md),
            ),
            child: Text(
              "Comecei com os números do seu trabalho ativo. Ajuste o que for diferente.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: Space.x4),
        ],
        _title('Quanto você quer GANHAR por mês?'),
        const SizedBox(height: Space.x4),
        MoneyField(
          controller: _renda,
          focusNode: _rendaFocus,
          autofocus: true,
          label: 'Renda no bolso',
          prefix: r'R$ ',
          helper: 'É o que você quer que sobre pra você, não o faturamento.',
          errorText: erro
              ? 'Coloque quanto você quer ganhar pra eu calcular.'
              : null,
          onChanged: (String v) => setState(
            () => _draft = _draft.copyWith(renda: _digits(v).toDouble()),
          ),
        ),
      ],
    );
  }

  Widget _stepHoras() {
    final ThemeData theme = Theme.of(context);
    final bool erro = _triedContinue && _draft.horas <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Quantas horas você realmente FATURA por mês?'),
        const SizedBox(height: Space.x4),
        MoneyField(
          controller: _horas,
          focusNode: _horasFocus,
          label: 'Horas faturáveis',
          suffix: 'h/mês',
          errorText: erro
              ? 'Preciso de pelo menos 1 hora faturável pra fazer a conta.'
              : null,
          onChanged: (String v) =>
              setState(() => _draft = _draft.copyWith(horas: _digits(v))),
        ),
        const SizedBox(height: Space.x4),
        Container(
          padding: const EdgeInsets.all(Space.x3),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: const BorderRadius.all(Radii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.schedule,
                size: 20,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: Space.x2),
              Expanded(
                child: Text(
                  'Não são 160h. Tire férias, feriados e o tempo sem cliente (vendas, e-mail, estudo). Quase ninguém fatura mais que ~70%.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.x2),
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
    final List<CostChip> faltam = CostChip.chips
        .where((CostChip c) => !jaTem.contains(c.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Seus custos pra trabalhar?'),
        const SizedBox(height: Space.x4),
        AnimatedSize(
          duration: reduceMotionOf(context) ? Duration.zero : Motion.base,
          curve: MotionCurves.standard,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final Custo c in custos)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(c.label),
                  subtitle: Text(
                    'Toque pra editar o valor',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => _editarCusto(c),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        moneyBRL(c.valor),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontFeatures: AppType.tnum,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Remover',
                        onPressed: () {
                          Haptics.select();
                          setState(() {
                            _draft = _draft.copyWith(
                              custos: custos
                                  .where((Custo x) => x.id != c.id)
                                  .toList(),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Space.x2),
              Row(
                children: <Widget>[
                  Text(
                    'Total: ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  MoneyCountUp(
                    _draft.custosTotal,
                    duration: Motion.quick,
                    style:
                        Theme.of(context).textTheme.titleMedium ??
                        const TextStyle(),
                    semanticLabel:
                        'Total de custos: ${moneyBRL(_draft.custosTotal)} por mês',
                  ),
                  Text('/mês', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: Space.x4),
              Text(
                'Não esqueça:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.x2),
              Wrap(
                spacing: Space.x2,
                runSpacing: Space.x2,
                children: <Widget>[
                  for (final CostChip chip in faltam)
                    ActionChip(
                      avatar: Icon(_iconFor(chip.icon), size: 18),
                      label: Text(chip.label),
                      onPressed: () {
                        Haptics.select();
                        setState(() {
                          _draft = _draft.copyWith(
                            custos: <Custo>[
                              ...custos,
                              Custo(
                                id: chip.id,
                                label: chip.label,
                                valor: chip.sugg,
                              ),
                            ],
                          );
                        });
                      },
                    ),
                  // O SEU custo, com o SEU valor: ninguém disse que só existem os pré-setados.
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Outro custo'),
                    onPressed: () => _editarCusto(null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Sheet de custo: adiciona um custo PRÓPRIO (nome + valor) ou edita um
  /// existente. Ninguém fica preso aos pré-setados.
  Future<void> _editarCusto(Custo? existente) async {
    final TextEditingController nomeC = TextEditingController(
      text: existente?.label ?? '',
    );
    final TextEditingController valorC = TextEditingController(
      text: existente == null ? '' : existente.valor.round().toString(),
    );
    final bool novo = existente == null;

    final Custo? result = await showModalBottomSheet<Custo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext c) {
        String? erro;
        return StatefulBuilder(
          builder: (BuildContext c, void Function(void Function()) setSheet) =>
              Padding(
                padding: EdgeInsets.only(
                  left: Space.x6,
                  right: Space.x6,
                  top: Space.x2,
                  bottom: Space.x6 + MediaQuery.of(c).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      novo ? 'Seu custo' : 'Editar ${existente.label}',
                      style: Theme.of(c).textTheme.titleLarge,
                    ),
                    const SizedBox(height: Space.x4),
                    if (novo) ...<Widget>[
                      TextField(
                        controller: nomeC,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          hintText: 'Ex.: Estacionamento, Domínio...',
                        ),
                      ),
                      const SizedBox(height: Space.x4),
                    ],
                    MoneyField(
                      controller: valorC,
                      label: 'Valor por mês',
                      prefix: r'R$ ',
                      autofocus: !novo,
                    ),
                    const SizedBox(height: Space.x4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final int v =
                              int.tryParse(
                                valorC.text.replaceAll(RegExp(r'[^0-9]'), ''),
                              ) ??
                              0;
                          final String nome = novo
                              ? nomeC.text.trim()
                              : existente.label;
                          if (nome.isEmpty || v <= 0) {
                            final String mensagem = nome.isEmpty
                                ? 'Dá um nome pro custo pra eu guardar.'
                                : 'Coloca o valor por mês.';
                            setSheet(() => erro = mensagem);
                            announce(c, mensagem);
                            return;
                          }
                          Navigator.pop(
                            c,
                            Custo(
                              id:
                                  existente?.id ??
                                  'custom-${DateTime.now().millisecondsSinceEpoch}',
                              label: nome,
                              valor: v.toDouble(),
                            ),
                          );
                        },
                        child: Text(novo ? 'Adicionar' : 'Salvar'),
                      ),
                    ),
                    if (erro != null) ...<Widget>[
                      const SizedBox(height: Space.x2),
                      Text(
                        erro!,
                        style: TextStyle(color: Theme.of(c).colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
        );
      },
    );
    // Dispose atrasado: o sheet ainda anima a saída (viewInsets rebuilda os
    // TextFields); descartar agora crasharia.
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      nomeC.dispose();
      valorC.dispose();
    });
    if (result == null || !mounted) return;
    Haptics.select();
    setState(() {
      final List<Custo> list = List<Custo>.of(_draft.custos);
      final int i = list.indexWhere((Custo x) => x.id == result.id);
      if (i >= 0) {
        list[i] = result;
      } else {
        list.add(result);
      }
      _draft = _draft.copyWith(custos: list);
    });
  }

  Widget _stepRegime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Como você recebe hoje?'),
        const SizedBox(height: Space.x4),
        for (final Regime r in Regime.all.values) _regimeOption(r),
      ],
    );
  }

  Widget _regimeOption(Regime r) {
    final bool selected = _draft.regime == r.id;
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: MergeSemantics(
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: selected,
          child: PressableScale(
            child: Material(
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.all(Radii.md),
              shape: selected
                  ? RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(Radii.md),
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    )
                  : null,
              child: InkWell(
                borderRadius: const BorderRadius.all(Radii.md),
                onTap: () {
                  Haptics.select();
                  setState(() => _draft = _draft.copyWith(regime: r.id));
                  announce(context, '${r.label} selecionado.');
                },
                child: Padding(
                  padding: const EdgeInsets.all(Space.x3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: Space.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(r.label, style: theme.textTheme.titleMedium),
                            Text(
                              r.sub,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepProvisao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Quer provisionar férias e 13º?'),
        const SizedBox(height: Space.x2),
        Text(
          'Autônomo não ganha de graça.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Space.x4),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: SwitchListTile(
            value: _draft.provisaoOn,
            onChanged: (bool v) {
              Haptics.select();
              setState(() => _draft = _draft.copyWith(provisaoOn: v));
            },
            title: Text(_draft.provisaoOn ? 'Sim, provisionar' : 'Agora não'),
          ),
        ),
        if (_draft.provisaoOn) ...<Widget>[
          const SizedBox(height: Space.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              MoneyCountUp(
                _draft.provisaoEfetiva,
                duration: Motion.quick,
                style: AppType.valueMd.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                semanticLabel:
                    '${moneyBRL(_draft.provisaoEfetiva)} por mês entram na conta',
              ),
              Text(
                '/mês entram na conta',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.x2),
          TextButton.icon(
            onPressed: _editarProvisao,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Ajustar valor'),
          ),
        ],
      ],
    );
  }

  Future<void> _editarProvisao() async {
    final TextEditingController controller = TextEditingController(
      text: _draft.provisaoEfetiva.round().toString(),
    );
    final double? valor = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          Space.x6,
          Space.x2,
          Space.x6,
          Space.x6 + MediaQuery.of(sheet).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Sua provisão mensal',
              style: Theme.of(sheet).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.x2),
            const Text(
              '1 mês da sua renda por ano, pra férias e 13º. Ajuste se quiser.',
            ),
            const SizedBox(height: Space.x4),
            MoneyField(
              controller: controller,
              label: 'Valor por mês',
              prefix: r'R$ ',
              autofocus: true,
            ),
            const SizedBox(height: Space.x4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(sheet, _digits(controller.text).toDouble()),
                child: const Text('Usar este valor'),
              ),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);
    if (valor == null || !mounted) return;
    setState(
      () => _draft = _draft.copyWith(provisao: valor, provisaoCustom: true),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'calculate':
        return Icons.calculate;
      case 'chair':
        return Icons.chair;
      case 'school':
        return Icons.school;
      case 'bolt':
        return Icons.bolt;
      case 'wifi':
        return Icons.wifi;
      case 'devices':
        return Icons.devices;
      case 'account_balance':
        return Icons.account_balance;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'apps':
        return Icons.apps;
      case 'campaign':
        return Icons.campaign;
      case 'directions_car':
        return Icons.directions_car;
      default:
        return Icons.attach_money;
    }
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
            final int estimado = estimarHorasFaturaveis(
              ferias: ferias,
              pct: pct,
              feriados: feriados,
            );
            final TextTheme t = Theme.of(c).textTheme;
            return Padding(
              padding: EdgeInsets.only(
                left: Space.x6,
                right: Space.x6,
                top: Space.x2,
                bottom: Space.x6 + MediaQuery.of(c).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Vamos achar suas horas reais', style: t.titleLarge),
                  const SizedBox(height: Space.x4),
                  Text(
                    'Semanas de férias por ano: $ferias',
                    style: t.bodyMedium,
                  ),
                  Slider(
                    value: ferias.toDouble(),
                    max: 8,
                    divisions: 8,
                    label: '$ferias',
                    semanticFormatterCallback: (double v) =>
                        '${v.round()} semanas de férias por ano',
                    onChanged: (double v) => setSheet(() => ferias = v.round()),
                  ),
                  Text(
                    'Do seu tempo, quanto é trabalho pago: $pct%',
                    style: t.bodyMedium,
                  ),
                  Slider(
                    value: pct.toDouble(),
                    min: 30,
                    max: 90,
                    divisions: 12,
                    label: '$pct%',
                    semanticFormatterCallback: (double v) =>
                        '${v.round()} por cento de trabalho pago',
                    onChanged: (double v) => setSheet(() => pct = v.round()),
                  ),
                  Text('Feriados por ano: $feriados', style: t.bodyMedium),
                  Slider(
                    value: feriados.toDouble(),
                    max: 20,
                    divisions: 20,
                    label: '$feriados',
                    semanticFormatterCallback: (double v) =>
                        '${v.round()} feriados por ano',
                    onChanged: (double v) =>
                        setSheet(() => feriados = v.round()),
                  ),
                  const SizedBox(height: Space.x2),
                  MoneyCountUp(
                    estimado,
                    suffix: ' h/mês',
                    duration: Motion.quick,
                    style: t.headlineSmall ?? const TextStyle(),
                    semanticLabel: 'Aproximadamente $estimado horas por mês',
                  ),
                  const SizedBox(height: Space.x4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Haptics.select();
                        Navigator.pop(c, estimado);
                      },
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
