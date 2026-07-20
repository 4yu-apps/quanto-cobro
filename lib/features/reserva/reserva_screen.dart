import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/money.dart';
import '../../core/fx/fx_rate.dart';
import '../../core/fx/fx_service.dart';
import '../../core/model/moeda.dart';
import '../../core/model/projeto.dart';
import '../../core/model/regime.dart';
import '../../core/model/reserva_entry.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/money_field.dart';
import '../../core/ui/stale_banner.dart';
import '../../core/ui/vitrine_card.dart';
import 'reserva_bar.dart';

/// Reserva por pagamento (Blueprint §5.5) — o CAMINHO DE OURO (uso recorrente).
/// Resultado ao vivo dentro de um "cofre" visual; salvar fecha o loop
/// (Guardado + Desfazer + Registrar outro), sem duplicata acidental.
class ReservaScreen extends ConsumerStatefulWidget {
  const ReservaScreen({super.key, this.projetoId});

  /// Projeto que pagou, quando a tela veio de um "Recebi" (07 §B.4). Muda três
  /// coisas: o valor já chega preenchido, o registro nasce com `projetoId`, e
  /// salvar avança o ciclo do projeto.
  final String? projetoId;

  @override
  ConsumerState<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends ConsumerState<ReservaScreen> {
  final TextEditingController _valor = TextEditingController();
  RegimeId? _regime;
  bool _saved = false;
  Timer? _announceTimer;

  // ---- Câmbio (Fase 3 — cliente estrangeiro) ----
  // Offline-first: nunca busca sozinho ao abrir a tela. Sai pra rede só por
  // ação explícita da pessoa — escolher uma moeda estrangeira sem cotação em
  // cache, ou tocar em "Atualizar".
  Moeda _moeda = Moeda.brl;
  FxRate? _rate;
  bool _buscandoCotacao = false;

  /// 'USD->BRL' etc. — o par que o repo/serviço de câmbio usam como chave.
  String get _par => '${_moeda.codigo}->${Moeda.brl.codigo}';

  /// Quanto vale 1 unidade de [_moeda] em BRL agora — `1.0` quando já é BRL
  /// (sem câmbio nenhum), `null` quando é moeda estrangeira sem cotação.
  double? get _taxaConversao => _moeda == Moeda.brl ? 1.0 : _rate?.taxa;

  /// O projeto que pagou (quando veio de um "Recebi"). Lido uma vez no init:
  /// a tela representa UM pagamento, e trocar o projeto por baixo dela no meio
  /// do preenchimento não é um cenário real.
  Projeto? _projeto;

  @override
  void initState() {
    super.initState();
    final ProfileState state = ref.read(profileProvider);
    if (state is ProfileReady) {
      final String? saved = ref
          .read(settingsRepositoryProvider)
          .reservaRegime(state.perfil.id, state.perfil.regime.name);
      if (saved != null) _regime = RegimeId.values.byName(saved);
    }

    _projeto = ref.read(projetosProvider.notifier).byId(widget.projetoId);
    final Projeto? p = _projeto;
    // Pré-preenche o valor do ciclo, mas deixa EDITÁVEL: cliente que paga
    // metade, paga adiantado ou paga a mais é o caso comum, não a exceção.
    if (p != null) _valor.text = moneyFieldText(p.valor);
  }

  @override
  void dispose() {
    _valor.dispose();
    _announceTimer?.cancel();
    super.dispose();
  }

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _announceResult(ReservaResult? result) {
    _announceTimer?.cancel();
    if (result == null) return;
    _announceTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final String message = result.isMei
          ? 'Esse dinheiro é seu. O DAS do mês é ${moneyBRLCents(result.dasMensal!)}.'
          : 'Reserve ${moneyBRL(result.reserva)}. Sobra pra usar ${moneyBRL(result.sobra)}.';
      announce(context, message);
    });
  }

  /// Converte [amountInput] (digitado em [_moeda]) pra BRL e calcula a
  /// reserva em cima do valor já convertido — o imposto é sempre pago em
  /// BRL. Sem cotação disponível pra moeda estrangeira, não dá pra calcular
  /// nada (devolve null: a tela cai no estado "digite o valor").
  ReservaResult? _reservaPara(
    int amountInput,
    RegimeId regime,
    double? taxaEfetiva,
  ) {
    final double? taxa = _taxaConversao;
    if (amountInput <= 0 || taxa == null) return null;
    return computeReserva(
      amountInput * taxa,
      regime,
      taxaEfetiva: taxaEfetiva,
      dasJaSeparado: _impostoJaSeparadoNoMes(),
    );
  }

  /// Soma do que já foi separado de imposto no mês corrente, neste trabalho.
  /// É o que permite ao MEI registrar o 2º, 3º e 4º pagamento do mês sem
  /// separar o DAS de novo — e sem a tela travar.
  double _impostoJaSeparadoNoMes() {
    final ProfileState st = ref.read(profileProvider);
    final String? perfilId = st is ProfileReady ? st.perfil.id : null;
    final DateTime now = DateTime.now();
    return ref
        .read(reservaHistoryProvider)
        .where(
          (ReservaEntry e) =>
              e.perfilId == perfilId &&
              e.at.year == now.year &&
              e.at.month == now.month,
        )
        .fold<double>(0, (double s, ReservaEntry e) => s + e.reserva);
  }

  void _onMoedaChanged(Moeda m) {
    if (m == _moeda) return;
    Haptics.select();
    setState(() {
      _moeda = m;
      _saved = false;
      // Lê o cache local (síncrono) primeiro — sem custo de rede nenhum.
      _rate = m == Moeda.brl ? null : ref.read(fxRepositoryProvider).get(_par);
    });
    // Escolher a moeda é ação explícita da pessoa: sem cotação usável em
    // cache, busca na hora (sem exigir um toque extra em "Atualizar").
    if (m != Moeda.brl && _rate == null) {
      _atualizarCotacao();
    }
  }

  Future<void> _atualizarCotacao() async {
    setState(() => _buscandoCotacao = true);
    try {
      final FxRate rate = await ref
          .read(fxServiceProvider)
          .cotacao(_moeda, Moeda.brl, agora: DateTime.now());
      if (!mounted) return;
      setState(() {
        _rate = rate;
        _saved = false;
      });
      announce(
        context,
        'Cotação de hoje: ${money(1, _moeda)} = ${moneyBRLCents(rate.taxa)}.',
      );
    } on FxUnavailable {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não consegui buscar agora. Tenta de novo com internet, ou digite a sua.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _buscandoCotacao = false);
    }
  }

  Future<void> _abrirDialogTaxaManual() async {
    final TextEditingController controller = TextEditingController(
      text: _rate == null ? '' : _rate!.taxa.toString().replaceAll('.', ','),
    );
    final String? digitado = await showDialog<String>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text('Quanto vale 1 ${_moeda.codigo} em reais?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Ex.: 5,35'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);
    if (digitado == null) return;
    final double? taxa = double.tryParse(digitado.trim().replaceAll(',', '.'));
    if (taxa == null || taxa <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Não entendi esse número.')),
        );
      return;
    }
    await ref.read(fxRepositoryProvider).setManual(_par, taxa, DateTime.now());
    if (!mounted) return;
    setState(() {
      _rate = ref.read(fxRepositoryProvider).get(_par);
      _saved = false;
    });
    announce(
      context,
      'Cotação salva: ${money(1, _moeda)} = ${moneyBRLCents(taxa)}.',
    );
  }

  Widget _linhaCambio(BuildContext context, ThemeData theme, ColorScheme cs) {
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
    );
    if (_buscandoCotacao) {
      return Padding(
        padding: const EdgeInsets.only(top: Space.x1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Space.x2),
            Text('Buscando cotação…', style: style),
          ],
        ),
      );
    }
    final FxRate? rate = _rate;
    if (rate == null) {
      return Padding(
        padding: const EdgeInsets.only(top: Space.x1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Ligue a internet uma vez pra puxar a cotação, ou digite a sua.',
              style: style,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _abrirDialogTaxaManual,
                child: const Text('Digitar a minha'),
              ),
            ),
          ],
        ),
      );
    }
    final String data = DateFormat('dd/MM').format(rate.at);
    final String texto =
        'Cotação de $data: ${money(1, _moeda)} = ${moneyBRLCents(rate.taxa)}'
        '${rate.stale ? ' (desatualizada)' : ''}';
    return Padding(
      padding: const EdgeInsets.only(top: Space.x1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(texto, style: style),
          Wrap(
            children: <Widget>[
              TextButton(
                onPressed: _atualizarCotacao,
                child: const Text('Atualizar'),
              ),
              TextButton(
                onPressed: _abrirDialogTaxaManual,
                child: const Text('Digitar a minha'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final ProfileState st = ref.watch(profileProvider);
    final RegimeId regimeBase = st is ProfileReady
        ? st.perfil.regime
        : RegimeId.mei;
    final RegimeId regime = _regime ?? regimeBase;
    final double? taxaEfetiva = st is ProfileReady && regime == st.perfil.regime
        ? computeValorHora(st.perfil).rate
        : null;

    final String? perfilId = st is ProfileReady ? st.perfil.id : null;
    final DateTime now = DateTime.now();

    // Quanto do imposto deste mês já foi separado. Só o MEI usa (o DAS é um
    // boleto único), mas a soma é a mesma pra todo mundo — inclusive os
    // registros antigos com `tipo: 'das'`, que eram exatamente isso.
    final double impostoJaSeparadoNoMes = ref
        .watch(reservaHistoryProvider)
        .where(
          (ReservaEntry e) =>
              e.perfilId == perfilId &&
              e.at.year == now.year &&
              e.at.month == now.month,
        )
        .fold<double>(0, (double s, ReservaEntry e) => s + e.reserva);

    final int amountInput = _digits(_valor.text);
    final double? taxaConversao = _taxaConversao;
    final bool temValor = amountInput > 0 && taxaConversao != null;
    final double amountBRL = temValor ? amountInput * taxaConversao : 0;
    final ReservaResult? res = temValor
        ? computeReserva(
            amountBRL,
            regime,
            taxaEfetiva: taxaEfetiva,
            dasJaSeparado: impostoJaSeparadoNoMes,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        // Vindo de um projeto, o título diz de QUEM é o dinheiro: some a
        // dúvida "será que estou registrando no lugar certo?".
        title: Text(
          _projeto == null
              ? 'Recebi um pagamento'
              : 'Recebi de ${_projeto!.nome}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Guardado',
            onPressed: () => context.push(Routes.historico),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          MoneyField(
            controller: _valor,
            label: 'Quanto você recebeu?',
            prefix: '${_moeda.simbolo} ',
            autofocus: true,
            onChanged: (_) {
              setState(() => _saved = false);
              final int value = _digits(_valor.text);
              _announceResult(_reservaPara(value, regime, taxaEfetiva));
            },
          ),
          const SizedBox(height: Space.x2),
          // Moeda: compacta, do lado do valor — Fase 3 (cliente estrangeiro).
          Row(
            children: <Widget>[
              Text(
                'Moeda',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Space.x3),
              SegmentedButton<Moeda>(
                segments: <ButtonSegment<Moeda>>[
                  for (final Moeda m in Moeda.curadas)
                    ButtonSegment<Moeda>(value: m, label: Text(m.codigo)),
                ],
                selected: <Moeda>{_moeda},
                showSelectedIcon: false,
                onSelectionChanged: (Set<Moeda> s) => _onMoedaChanged(s.first),
              ),
            ],
          ),
          if (_moeda != Moeda.brl) _linhaCambio(context, theme, cs),
          const SizedBox(height: Space.x3),
          // Regime: chips na linguagem do app (alvo generoso, sem dropdown 2014).
          Wrap(
            spacing: Space.x2,
            children: <Widget>[
              for (final Regime r in Regime.all.values)
                ChoiceChip(
                  label: Text(r.tag),
                  selected: regime == r.id,
                  backgroundColor: cs.surfaceContainerLow,
                  selectedColor: cs.secondaryContainer,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: regime == r.id
                        ? cs.onSecondaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  side: regime == r.id
                      ? BorderSide(color: cs.primary, width: 1.5)
                      : BorderSide(color: cs.outlineVariant),
                  onSelected: (_) async {
                    Haptics.select();
                    setState(() {
                      _regime = r.id;
                      _saved = false;
                    });
                    // Trocar o regime recalcula o valor debaixo dos dedos — o
                    // leitor de tela precisa ouvir o novo número (auditoria
                    // Joana), igual a Calculadora já faz ao mudar de regime.
                    final double? taxaNova =
                        st is ProfileReady && r.id == st.perfil.regime
                        ? computeValorHora(st.perfil).rate
                        : null;
                    _announceResult(_reservaPara(amountInput, r.id, taxaNova));
                    if (st is ProfileReady) {
                      await ref
                          .read(settingsRepositoryProvider)
                          .setReservaRegime(
                            st.perfil.id,
                            st.perfil.regime.name,
                            r.id.name,
                          );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: Space.x6),
          AnimatedSwitcher(
            duration: reduceMotionOf(context) ? Duration.zero : Motion.base,
            child: res == null
                ? Padding(
                    key: const ValueKey<bool>(true),
                    padding: const EdgeInsets.only(top: Space.x8),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.payments_outlined,
                          size: 40,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: Space.x3),
                        Text(
                          'Digite o valor que caiu pra ver quanto guardar.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: const ValueKey<bool>(false),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      VitrineCard(
                        // O cofre "tranca" (borda fio-de-ouro) em QUALQUER save
                        // — a batida emocional de "guardei o imposto".
                        highlight: _saved,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              // O MEI só ouve "esse dinheiro é seu" quando o
                              // imposto do mês JÁ está separado. Antes disso
                              // ele separa igual a todo mundo — era essa a
                              // mentira que travava a tela no 1º pagamento.
                              res.impostoDoMesQuitado
                                  ? 'ESSE DINHEIRO É TODO SEU'
                                  : 'SEPARE PRO IMPOSTO',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: Space.x1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: MoneyCountUp(
                                res.impostoDoMesQuitado
                                    ? amountBRL
                                    : res.reserva,
                                duration: Motion.quick,
                                endTint: res.impostoDoMesQuitado
                                    ? d.lucro
                                    : d.reserva,
                                style: AppType.valueHero.copyWith(
                                  color: res.impostoDoMesQuitado
                                      ? d.lucro
                                      : d.reserva,
                                ),
                                semanticLabel: res.impostoDoMesQuitado
                                    ? 'Esse dinheiro é todo seu: ${moneyBRL(amountBRL)}'
                                    : 'Separe ${moneyBRL(res.reserva)} deste pagamento pro imposto',
                              ),
                            ),
                            const SizedBox(height: Space.x1),
                            Text(
                              res.isMei
                                  ? res.impostoDoMesQuitado
                                        ? 'Seu imposto de ${_mesNome(now)} já está separado. O que entrar agora é todo seu.'
                                        : 'Como MEI, seu imposto do mês é um boleto só: ${moneyBRLCents(res.dasMensal!)}. Separando ele já de uma vez.'
                                  : '~${res.pct}% — já é a sua faixa real de imposto, não a cheia.',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: Space.x4),
                            ReservaBar(
                              amount: amountBRL,
                              reserva: res.reserva,
                              sobra: res.sobra,
                            ),
                            const SizedBox(height: Space.x2),
                            Wrap(
                              spacing: Space.x4,
                              runSpacing: Space.x2,
                              children: <Widget>[
                                _legenda(
                                  context,
                                  d.custo,
                                  'Pra usar',
                                  res.sobra,
                                ),
                                _legenda(
                                  context,
                                  d.reserva,
                                  'Reserva',
                                  res.reserva.toDouble(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.x4),
                      // Só o registro DESTA sessão trava o botão. Antes o MEI
                      // caía aqui por ter separado o DAS em QUALQUER dia do
                      // mês — e como isso vinha do histórico salvo, "Registrar
                      // outro" não conseguia sair do estado. Era o caminho sem
                      // saída que impedia anotar o 2º pagamento do mês.
                      if (_saved)
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: null,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(Icons.check, size: 20),
                                    SizedBox(width: Space.x2),
                                    Text('Guardado'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.x3),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _valor.clear();
                                  _saved = false;
                                });
                              },
                              child: const Text('Registrar outro'),
                            ),
                          ],
                        )
                      else
                        FilledButton.tonal(
                          onPressed: () {
                            Haptics.commit();
                            final DateTime pagoEm = DateTime.now();
                            // Cada registro é um PAGAMENTO — inclusive no MEI.
                            // Antes, o registro do MEI virava um lançamento de
                            // "DAS" solto, sem dono: o dinheiro do cliente não
                            // aparecia no freela dele, "já recebeu" ficava
                            // zerado pra sempre e o ciclo nunca andava. O que
                            // muda entre regimes é QUANTO se separa, nunca de
                            // quem o dinheiro veio.
                            final ReservaEntry entry = ReservaEntry(
                              valor: amountBRL,
                              reserva: res.reserva,
                              regimeTag: Regime.of(regime).tag,
                              at: pagoEm,
                              perfilId: perfilId,
                              projetoId: _projeto?.id,
                            );
                            final ReservaHistoryNotifier historyN = ref.read(
                              reservaHistoryProvider.notifier,
                            );
                            historyN.add(entry);

                            final Projeto? projeto = _projeto;
                            if (projeto != null) {
                              ref
                                  .read(projetosProvider.notifier)
                                  .registrarRecebimento(
                                    projeto.id,
                                    pagoEm: pagoEm,
                                  );
                            }

                            // Sinal nº 2 do roadmap: usos de reserva por mês é
                            // o proxy nº 1 de hábito. Sem valor nenhum junto —
                            // só QUE aconteceu, de que origem e em que regime.
                            telemetry.evento(
                              Evento.entradaRegistrada,
                              params: <String, Object?>{
                                'origem': projeto == null
                                    ? 'avulso'
                                    : 'trabalho',
                                'regime': regime.name,
                              },
                            );

                            // O momento mais importante do app vibrava sem
                            // falar: a SnackBar não é anunciada de forma
                            // confiável pelo TalkBack, e a regra da casa é que
                            // todo gesto que VIBRA também FALA.
                            announce(
                              context,
                              projeto == null
                                  ? 'Guardado. ${moneyBRL(res.reserva)} separados pro imposto.'
                                  : 'Guardado. ${moneyBRL(res.reserva)} separados pro imposto de ${projeto.nome}.',
                            );
                            setState(() => _saved = true);
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    projeto != null
                                        ? '${moneyBRL(res.reserva)} guardado — "${projeto.nome}" em dia'
                                        : '${moneyBRL(res.reserva)} guardado no histórico',
                                  ),
                                  action: SnackBarAction(
                                    label: 'Desfazer',
                                    onPressed: () {
                                      historyN.remove(entry);
                                      // Desfazer tem que desfazer TUDO: sem
                                      // isto o projeto ficaria com o ciclo
                                      // adiantado por um pagamento que a
                                      // pessoa acabou de dizer que não houve.
                                      if (projeto != null) {
                                        ref
                                            .read(projetosProvider.notifier)
                                            .save(projeto);
                                      }
                                      if (mounted) {
                                        setState(() => _saved = false);
                                      }
                                    },
                                  ),
                                ),
                              );
                          },
                          child: const Text('Salvar no histórico'),
                        ),
                      const SizedBox(height: Space.x4),
                      if (tabelasDefasadas(DateTime.now())) ...<Widget>[
                        StaleBanner(ano: kTabelasAno),
                        const SizedBox(height: Space.x3),
                      ],
                      const EstimativaSeal(short: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legenda(
    BuildContext context,
    Color color,
    String label,
    double valor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: Space.x2),
        Text(
          '$label ${moneyBRL(valor)}',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontFeatures: AppType.tnum),
        ),
      ],
    );
  }

  String _mesNome(DateTime date) {
    const List<String> nomes = <String>[
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return nomes[date.month - 1];
  }
}
