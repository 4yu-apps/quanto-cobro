import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/custo.dart';
import '../../core/model/area.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
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
  const CalcScreen({super.key, this.novaArea, this.initialDraft});

  /// Quando presente, cria uma ÁREA nova com esse nome (em vez de editar a ativa).
  final String? novaArea;
  final Area? initialDraft;

  @override
  ConsumerState<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends ConsumerState<CalcScreen> {
  /// Quatro passos, não cinco. O 5º perguntava sobre provisão de férias/13º —
  /// planejamento de longo prazo feito a quem ainda não sabe quanto cobra por
  /// hora. Virou toggle no Detalhamento, onde já existe o contexto pra entender
  /// o que é, e continua LIGADO por default.
  static const int _lastStep = 3;

  late Area _draft;
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
    final AreaState st = ref.read(areaAtivaProvider);
    final String? novo = widget.novaArea;
    if (widget.initialDraft != null) {
      _draft = widget.initialDraft!;
    } else if (novo != null) {
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      if (st is AreaPronta) {
        _draft = st.area.copyWith(id: id, nome: novo);
      } else {
        _draft = Area.padrao(id: id, nome: novo);
      }
    } else if (st is AreaPronta) {
      _draft = st.area;
    } else {
      _draft = Area.padrao();
    }
    _dias = _draft.diasSemana ?? 5;
    _horasDia = _draft.horasDia ?? 6;
    // Area legado (sem rotina) mas com horas salvo → abre em "digitar na mão".
    _horasManual = _draft.diasSemana == null;
    _renda.text = _draft.renda.round().toString();

    // O denominador do sinal nº 1: quantos começam, pra saber quantos chegam.
    telemetry.evento(Evento.calcIniciada);
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
      // Sinal nº 1 do roadmap: onde a pessoa desiste. Só o índice do passo —
      // nenhum valor digitado sai daqui.
      telemetry.evento(
        Evento.calcPasso,
        params: <String, Object?>{'passo': _step + 1},
      );
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
      telemetry.evento(Evento.calcConcluida);
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

            // O número VIVO, do passo 3 em diante.
            //
            // Antes eram cinco telas de investimento com zero retorno antes do
            // Resultado — o que transformava os passos finais numa prova. Do
            // passo 3 o valor-hora já é calculável, então ele aparece e muda
            // enquanto a pessoa mexe: os passos viram AJUSTE de uma coisa que
            // já é dela, e a diferença entre "responder" e "ajustar" é a
            // diferença entre abandonar e terminar.
            if (_step >= 2) _PreviaValorHora(area: _draft),

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
      default:
        return _stepRegime();
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
    _ => 'E o imposto, como é pra você?',
  };

  // ---------------------------------------------------------------- passo 1
  Widget _stepRenda() {
    final bool erro = _triedContinue && _draft.renda <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.novaArea != null) ...<Widget>[
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
        _subtitle('Me conta sua rotina que eu faço a conta pra você.'),
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
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) =>
        IconButton.filledTonal(
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
                btn(Icons.remove, value > min, () => onChanged(value - 1)),
                Expanded(
                  child: Center(
                    child: Text(
                      '$value $suffix',
                      style: AppType.valueMd.copyWith(color: cs.onSurface),
                    ),
                  ),
                ),
                btn(Icons.add, value < max, () => onChanged(value + 1)),
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
            Text(
              'Suas horas por mês',
              style: Theme.of(sheet).textTheme.titleLarge,
            ),
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
                onPressed: () => Navigator.pop(sheet, _digits(controller.text)),
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
      _draft = Area(
        id: _draft.id,
        nome: _draft.nome,
        renda: _draft.renda,
        horas: horas,
        provisao: _draft.provisao,
        provisaoOn: _draft.provisaoOn,
        provisaoCustom: _draft.provisaoCustom,
        diasSemana: null,
        horasDia: null,
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
                  leading: Icon(Icons.check_circle_outline, color: cs.primary),
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
              // O total é o número que a pessoa veio conferir. Sem o FittedBox
              // ele vaza pela direita — 2,6px num celular de 320dp com fonte
              // normal, e muito mais em fonte grande. Encolhe, nunca sai.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
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
    final bool selected = ref.watch(regimeProvider) == r.id;
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
              // Um só: o `shape` carrega o raio E a borda. `borderRadius` junto
              // de `shape` estoura assert do Material — e como um regime está
              // sempre selecionado (MEI é o default), o passo 4 morria em
              // debug SEMPRE. Em release o assert some e ninguém vê; mas
              // nenhum widget test conseguia chegar aqui, e é por isso que
              // nenhum existia.
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radii.md),
                side: selected
                    ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                    : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: const BorderRadius.all(Radii.md),
                onTap: () {
                  Haptics.select();
                  // O regime é da PESSOA, não desta área: salvar aqui vale
                  // pro app inteiro, e é o que impede duas áreas gerarem dois
                  // DAS pro mesmo CNPJ.
                  ref.read(regimeProvider.notifier).set(r.id);
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

/// A prévia do valor-hora durante o preenchimento. Discreta de propósito: é a
/// promessa do que vem, não o clímax — roubar o peso do Resultado aqui apagaria
/// o único momento de alívio que o app tem pra oferecer.
class _PreviaValorHora extends ConsumerWidget {
  const _PreviaValorHora({required this.area});

  final Area area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int vh = computeValorHora(area, ref.watch(regimeProvider)).valorHora;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x3,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: const BorderRadius.all(Radii.md),
        ),
        // Uma parada de leitura, uma frase falável — em vez de três nós
        // ("até aqui:", o número, "/hora") que virariam três swipes pra ler
        // quatro palavras, com "/hora" saindo como "barra hora".
        //
        // O `semanticLabel: ''` que estava no número não silenciava nada: ele
        // TIRAVA o valor da árvore. E o medo que motivou aquilo — tagarelice a
        // cada dígito — não se realiza: `Text` não fala sozinho quando muda, só
        // quando recebe foco. Quem enxerga tinha a promessa no topo da tela;
        // quem não enxerga tinha nada, justamente quem mais precisa saber que
        // os ajustes estão surtindo efeito.
        child: Semantics(
          container: true,
          label: 'Até aqui, sua hora vale ${moneyBRL(vh)}',
          child: ExcludeSemantics(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: <Widget>[
                  Text(
                    'até aqui:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: Space.x2),
                  MoneyCountUp(
                    vh,
                    duration: Motion.quick,
                    style: AppType.valueMd.copyWith(color: cs.primary),
                  ),
                  Text(
                    '/hora',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
