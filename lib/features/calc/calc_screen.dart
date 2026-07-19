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
import '../../core/ui/help_dot.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/money_field.dart';

/// Calculadora guiada (Blueprint §5.2): UMA pergunta por tela, com default e um
/// momento didático. v0.5 — a régua é o LEIGO: quem abre o app já não sabe
/// cobrar. Nenhuma pergunta pode presumir conhecimento (nada de "horas
/// faturáveis" ou "provisionar"). O passo 2 pergunta a ROTINA e o app faz a conta.
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

  // Passo 2 — rotina.
  late int _dias;
  late int _horasDia;
  late bool _horasManual; // expert digitou o número na mão

  final TextEditingController _renda = TextEditingController();
  final FocusNode _rendaFocus = FocusNode();

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
      final bool intl = ref.read(settingsRepositoryProvider).modo() == 'intl';
      _draft = Perfil.padrao().copyWith(
        regime: intl ? RegimeId.intl : RegimeId.mei,
      );
    }
    _dias = _draft.diasSemana ?? 5;
    _horasDia = _draft.horasDia ?? 6;
    // Perfil legado (sem rotina) mas com horas salvo → abre em "digitar na mão".
    _horasManual = _draft.diasSemana == null;
    _renda.text = _draft.renda.round().toString();
  }

  @override
  void dispose() {
    _renda.dispose();
    _rendaFocus.dispose();
    super.dispose();
  }

  void _focusStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(Motion.base, () {
        if (!mounted) return;
        if (_step == 0) _rendaFocus.requestFocus();
      });
    });
  }

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// Recalcula as horas cobráveis pela rotina e grava tudo no draft.
  void _recalcHorasPorRotina() {
    final int horas = horasFaturaveisPorRotina(
      diasSemana: _dias,
      horasDia: _horasDia,
    );
    setState(() {
      _horasManual = false;
      _draft = _draft.copyWith(
        horas: horas,
        diasSemana: _dias,
        horasDia: _horasDia,
      );
    });
  }

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
      if (_step == 0) {
        announce(context, 'Me diz um valor pra eu começar a conta.');
        _rendaFocus.requestFocus();
      }
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

  Widget _subtitle(String s) => Padding(
    padding: const EdgeInsets.only(top: Space.x2),
    child: Text(
      s,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  String _stepTitle(int step) => switch (step) {
    0 => 'Quanto você quer ganhar por mês?',
    1 => 'Quanto você trabalha por semana?',
    2 => 'O que você gasta pra trabalhar?',
    3 => 'E o imposto, como é pra você?',
    _ => 'Quer guardar um dinheiro pra férias e 13º?',
  };

  // ---------------------------------------------------------------- passo 1
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
              'Comecei com os números do seu trabalho ativo. Ajuste o que for diferente.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: Space.x4),
        ],
        _title('Quanto você quer ganhar por mês?'),
        const SizedBox(height: Space.x4),
        MoneyField(
          controller: _renda,
          focusNode: _rendaFocus,
          autofocus: true,
          label: 'Seu salário, no bolso',
          prefix: r'R$ ',
          helper:
              'O que você quer que sobre pra você, já livre de imposto e das contas do trabalho. Não é o quanto você cobra do cliente — isso a gente calcula.',
          errorText: erro ? 'Me diz um valor pra eu começar a conta.' : null,
          onChanged: (String v) => setState(
            () => _draft = _draft.copyWith(renda: _digits(v).toDouble()),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- passo 2
  Widget _stepHoras() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int horasMostradas = _draft.horas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Quanto você trabalha por semana?'),
        _subtitle(
          'Não precisa saber "horas faturáveis". Me conta sua rotina que eu faço a conta.',
        ),
        const SizedBox(height: Space.x6),
        _stepper(
          label: 'Dias por semana',
          value: _dias,
          min: 1,
          max: 7,
          suffix: _dias == 1 ? 'dia' : 'dias',
          onChanged: (int v) {
            _dias = v;
            _recalcHorasPorRotina();
          },
        ),
        const SizedBox(height: Space.x5),
        _stepper(
          label: 'Horas num dia normal',
          helper: 'Conta só o tempo sentado pra trabalhar.',
          value: _horasDia,
          min: 1,
          max: 16,
          suffix: _horasDia == 1 ? 'hora' : 'horas',
          onChanged: (int v) {
            _horasDia = v;
            _recalcHorasPorRotina();
          },
        ),
        const SizedBox(height: Space.x6),
        // Resultado ao vivo.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Space.x5),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: const BorderRadius.all(Radii.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'VOCÊ COBRA POR MÊS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSecondaryContainer,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: Space.x1),
              MoneyCountUp(
                horasMostradas,
                suffix: ' h',
                duration: Motion.quick,
                style: AppType.valueMd.copyWith(color: cs.onSecondaryContainer),
                semanticLabel: 'Aproximadamente $horasMostradas horas por mês',
              ),
              const SizedBox(height: Space.x2),
              Text(
                _horasManual
                    ? 'Você digitou esse número. Toque nos + / − acima pra voltar pra sua rotina.'
                    : 'Já tirei o tempo que não é pago — e-mail, proposta, imprevisto, férias e feriados. Quase ninguém cobra o dia inteiro, todo dia.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.x2),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _digitarHorasNaMao,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Já sei meu número — digitar na mão'),
          ),
        ),
      ],
    );
  }

  /// Stepper −/+ com valor grande no meio. Alvo ≥48dp nos botões.
  Widget _stepper({
    required String label,
    String? helper,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) => IconButton.filledTonal(
      onPressed: enabled
          ? () {
              Haptics.select();
              onTap();
            }
          : null,
      icon: Icon(icon),
      iconSize: 24,
      style: IconButton.styleFrom(
        minimumSize: const Size(52, 52),
        backgroundColor: cs.surfaceContainerHigh,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.titleMedium),
        if (helper != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            helper,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: Space.x3),
        Semantics(
          label: '$label: $value $suffix',
          child: ExcludeSemantics(
            child: Row(
              children: <Widget>[
                btn(
                  Icons.remove,
                  value > min,
                  () => onChanged(value - 1),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$value $suffix',
                      style: AppType.valueMd.copyWith(color: cs.onSurface),
                    ),
                  ),
                ),
                btn(
                  Icons.add,
                  value < max,
                  () => onChanged(value + 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _digitarHorasNaMao() async {
    final TextEditingController controller = TextEditingController(
      text: _draft.horas.toString(),
    );
    final int? horas = await showModalBottomSheet<int>(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Suas horas por mês', style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: Space.x2),
            const Text('Se você já calculou isso antes, é só colocar aqui.'),
            const SizedBox(height: Space.x4),
            MoneyField(
              controller: controller,
              label: 'Horas que você cobra por mês',
              suffix: 'h/mês',
              autofocus: true,
            ),
            const SizedBox(height: Space.x4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(sheet, _digits(controller.text)),
                child: const Text('Usar este número'),
              ),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);
    if (horas == null || horas <= 0 || !mounted) return;
    setState(() {
      _horasManual = true;
      // Número na mão: esquece a rotina (o horas passa a ser a fonte da verdade).
      _draft = Perfil(
        id: _draft.id,
        nome: _draft.nome,
        renda: _draft.renda,
        horas: horas,
        provisao: _draft.provisao,
        provisaoOn: _draft.provisaoOn,
        provisaoCustom: _draft.provisaoCustom,
        diasSemana: null,
        horasDia: null,
        regime: _draft.regime,
        custos: _draft.custos,
      );
    });
  }

  // ---------------------------------------------------------------- passo 3
  Widget _stepCustos() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final List<Custo> custos = _draft.custos;
    final Set<String> jaTem = custos.map((Custo c) => c.id).toSet();
    final List<CostChip> faltam = CostChip.chips
        .where((CostChip c) => !jaTem.contains(c.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('O que você gasta pra trabalhar?'),
        _subtitle(
          'Tudo que sai do seu bolso todo mês por causa do trabalho. A gente soma aqui pra nada ficar escondido.',
        ),
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
                    color: cs.primary,
                  ),
                  title: Text(c.label),
                  subtitle: Text(
                    'Toque pra editar o valor',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => _editarCusto(c),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: Space.x2),
                      Text(
                        moneyBRL(c.valor),
                        style: theme.textTheme.labelLarge?.copyWith(
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
                  Text('Total: ', style: theme.textTheme.titleMedium),
                  MoneyCountUp(
                    _draft.custosTotal,
                    duration: Motion.quick,
                    style: theme.textTheme.titleMedium ?? const TextStyle(),
                    semanticLabel:
                        'Total de custos: ${moneyBRL(_draft.custosTotal)} por mês',
                  ),
                  Text('/mês', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: Space.x5),
              if (faltam.isNotEmpty) ...<Widget>[
                Text('Você também paga?', style: theme.textTheme.bodyMedium),
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
                  ],
                ),
                const SizedBox(height: Space.x5),
              ],
              // "Adicionar um custo meu": AÇÃO de criar do zero — hierarquia
              // separada dos chips de sugestão (não some no meio deles).
              Text(
                'Algum gasto que não está na lista?',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.x2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _editarCusto(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar um custo meu'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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

  // ---------------------------------------------------------------- passo 4
  Widget _stepRegime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('E o imposto, como é pra você?'),
        _subtitle(
          'Se você não faz ideia, tem uma opção pra isso logo abaixo. Sem estresse.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showHelpSheet(context, 'qual_regime'),
            icon: const Icon(Icons.help_outline, size: 18),
            label: const Text('Não sei qual sou eu'),
          ),
        ),
        const SizedBox(height: Space.x3),
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

  // ---------------------------------------------------------------- passo 5
  Widget _stepProvisao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Quer guardar um dinheiro pra férias e 13º?'),
        _subtitle(
          'Quem trabalha por conta não recebe férias nem 13º de ninguém. Dá pra separar um pouco todo mês e ter os seus.',
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
            title: Text(_draft.provisaoOn ? 'Sim, quero guardar' : 'Agora não'),
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
                    '${moneyBRL(_draft.provisaoEfetiva)} por mês a mais no seu preço',
              ),
              Flexible(
                child: Text(
                  ' /mês a mais no seu preço',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Quanto guardar por mês', style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: Space.x2),
            const Text(
              'Uma conta boa: 1 mês do seu salário por ano, dividido em 12. Mas quem manda é você.',
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
}
