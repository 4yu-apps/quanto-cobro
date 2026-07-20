import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/model/area.dart';
import '../../core/model/entrada.dart';
import '../../core/model/regime.dart';
import '../../core/model/trabalho.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/money_field.dart';
import '../../core/ui/stale_banner.dart';
import '../../core/ui/vitrine_card.dart';
import 'entrada_bar.dart';
import '../../core/ui/breakpoints.dart';

/// **Registrar uma entrada** — o caminho de ouro, o gesto que se repete.
///
/// Duas mudanças de fundo em relação à tela antiga:
///
/// 1. **O trabalho nasce aqui.** Um campo "De quem?" e pronto — o Augusto passa
///    a existir no momento em que a resposta é óbvia, sem formulário vazio.
/// 2. **Os controles saíram do corpo.** Regime agora é da pessoa (Configurações)
///    e moeda virou um link. A tela abria com até 11 controles antes de mostrar
///    a resposta; agora a resposta vem primeiro.
class EntradaScreen extends ConsumerStatefulWidget {
  const EntradaScreen({super.key, this.trabalhoId});

  /// Trabalho de origem, quando veio do detalhe dele.
  final String? trabalhoId;

  @override
  ConsumerState<EntradaScreen> createState() => _EntradaScreenState();
}

class _EntradaScreenState extends ConsumerState<EntradaScreen> {
  final TextEditingController _valor = TextEditingController();
  final TextEditingController _deQuem = TextEditingController();
  bool _saved = false;
  Timer? _announceTimer;

  /// Trava do salvamento. `_salvar` é `async` e nada impedia dois disparos
  /// durante o `await`: saíam duas entradas e o Desfazer removia uma. Toque
  /// duplo é o normal de quem tem tremor, usa Switch Access, ou de quem o
  /// leitor de tela fez disparar duas vezes.
  bool _salvando = false;

  /// Pra onde o foco pousa quando os botões trocam de identidade. Sem eles, o
  /// nó em que a pessoa estava é destruído debaixo dela e o leitor de tela
  /// recai no topo da tela — com o "Desfazer" virando um botão que ninguém
  /// acha.
  final FocusNode _focoDepoisDoSave = FocusNode();
  final FocusNode _focoGuardar = FocusNode();
  final FocusNode _focoValor = FocusNode();

  /// Quanto já havia no cofre ANTES desta entrada, e quanto ficou depois.
  /// É o par que faz o valor contar de 344 pra 412 em vez de zero pra 412 —
  /// "você cresceu 68", não "você tem 412".
  int? _cofreAntes;
  int? _cofreDepois;

  /// A última entrada salva — o que o "Desfazer" remove.
  Entrada? _ultima;

  Trabalho? _trabalho;

  @override
  void initState() {
    super.initState();
    _trabalho = ref.read(trabalhosProvider.notifier).byId(widget.trabalhoId);
    final Trabalho? t = _trabalho;
    if (t != null) {
      _deQuem.text = t.nome;
      // Pré-preenche o combinado, mas deixa EDITÁVEL: cliente que paga metade,
      // adiantado ou a mais é o caso comum, não a exceção.
      if (t.valorCombinado > 0) _valor.text = moneyFieldText(t.valorCombinado);
    }
  }

  @override
  void dispose() {
    _valor.dispose();
    _deQuem.dispose();
    _focoDepoisDoSave.dispose();
    _focoGuardar.dispose();
    _focoValor.dispose();
    _announceTimer?.cancel();
    super.dispose();
  }

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// Quanto do imposto deste mês já foi separado — é o que permite ao MEI
  /// registrar o 2º e o 3º pagamento do mês sem separar o DAS de novo.
  double _impostoJaSeparadoNoMes() {
    final DateTime now = DateTime.now();
    return ref
        .read(entradasProvider)
        .where((Entrada e) => e.at.year == now.year && e.at.month == now.month)
        .fold<double>(0, (double s, Entrada e) => s + e.separado);
  }

  int _separadoNoMesAtual() {
    final DateTime now = DateTime.now();
    return ref
        .read(entradasProvider)
        .where((Entrada e) => e.at.year == now.year && e.at.month == now.month)
        .fold<int>(0, (int s, Entrada e) => s + e.separado);
  }

  void _desfazer() {
    // A fala do "digitando" não pode chegar DEPOIS da fala do desfazer.
    _announceTimer?.cancel();
    final Entrada? e = _ultima;
    if (e == null) return;
    ref.read(entradasProvider.notifier).remove(e);
    announce(context, 'Desfeito. A entrada foi removida.');
    setState(() {
      _saved = false;
      _ultima = null;
      _cofreAntes = null;
      _cofreDepois = null;
    });
    // O botão que ela apertou deixou de existir; o foco volta pro "Guardar".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focoGuardar.requestFocus();
    });
  }

  void _anunciar(ReservaResult? r) {
    _announceTimer?.cancel();
    if (r == null) return;
    _announceTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      announce(
        context,
        r.impostoDoMesQuitado
            ? 'Esse dinheiro é todo seu. O imposto do mês já está separado.'
            : 'Separe ${moneyBRL(r.separado)} pro imposto. Sobra ${moneyBRL(r.sobra)}.',
      );
    });
  }

  Future<void> _salvar(ReservaResult res, RegimeId regime, Area? area) async {
    // Digite o valor, toque em Guardar dentro de 900ms, e a sequência era:
    // "Guardado. R$ 68 separados…" e, 300ms depois, "Separe R$ 68 pro
    // imposto." Pra quem não vê a tela a segunda frase DESFAZ a primeira —
    // soa como se o salvamento não tivesse pego e o app pedisse de novo. No
    // caminho de ouro, no gesto que se repete toda semana.
    _announceTimer?.cancel();
    if (_salvando) return;
    _salvando = true;
    Haptics.commit();
    final DateTime agora = DateTime.now();

    // O trabalho nasce do nome digitado — e reaproveita o existente quando a
    // pessoa escreve o mesmo nome de novo, pra não criar dois "Augusto".
    Trabalho? trabalho = _trabalho;
    final String nome = _deQuem.text.trim();
    if (trabalho == null && nome.isNotEmpty && area != null) {
      final TrabalhosNotifier n = ref.read(trabalhosProvider.notifier);
      trabalho =
          n.porNome(nome, areaId: area.id) ??
          await n.criarPorNome(nome, areaId: area.id);
    }

    final Entrada entrada = Entrada(
      valor: _valorEmReais,
      separado: res.separado,
      regimeTag: Regime.of(regime).tag,
      at: agora,
      areaId: area?.id,
      trabalhoId: trabalho?.id,
    );

    final int antes = _separadoNoMesAtual();
    final EntradasNotifier entradasN = ref.read(entradasProvider.notifier);
    await entradasN.add(entrada);

    telemetry.evento(
      Evento.entradaRegistrada,
      params: <String, Object?>{
        'origem': trabalho == null ? 'avulso' : 'trabalho',
        'regime': regime.name,
      },
    );

    if (!mounted) {
      _salvando = false;
      return;
    }
    // O gesto mais importante do app VIBRA e agora também FALA: a SnackBar não
    // é anunciada de forma confiável pelo leitor de tela.
    announce(
      context,
      'Guardado. ${moneyBRL(res.separado)} separados do imposto'
      '${trabalho == null ? '' : ' do pagamento de ${trabalho.nome}'}. '
      'Você já tem ${moneyBRL(antes + res.separado)} separados este mês.',
    );
    setState(() {
      _saved = true;
      _ultima = entrada;
      _cofreAntes = antes;
      _cofreDepois = antes + res.separado;
      _salvando = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focoDepoisDoSave.requestFocus();
    });
  }

  double get _valorEmReais => _digits(_valor.text).toDouble();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final AreaState st = ref.watch(areaAtivaProvider);
    final Area? area = st is AreaPronta ? st.area : null;
    final RegimeId regime = ref.watch(regimeProvider);
    final double? taxaEfetiva = area == null
        ? null
        : computeValorHora(area, regime).rate;

    final double valor = _valorEmReais;
    final ReservaResult? res = valor > 0
        ? computeReserva(
            valor,
            regime,
            taxaEfetiva: taxaEfetiva,
            dasJaSeparado: _impostoJaSeparadoNoMes(),
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _trabalho == null
              ? 'Recebi um pagamento'
              : 'Recebi de ${_trabalho!.nome}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            MoneyField(
              controller: _valor,
              label: 'Quanto você recebeu?',
              prefix: r'R$ ',
              focusNode: _focoValor,
              // Autofocus é ouro pra quem enxerga — abre o teclado no campo
              // certo. Mas ele rouba o foco antes de o leitor de tela terminar
              // de anunciar o nome da tela, então quem navega por fala perde a
              // orientação. Gateado: dá o ganho sem cobrar o preço.
              autofocus: !MediaQuery.accessibleNavigationOf(context),
              onChanged: (_) {
                setState(() => _saved = false);
                final double v = _valorEmReais;
                _anunciar(
                  v > 0
                      ? computeReserva(
                          v,
                          regime,
                          taxaEfetiva: taxaEfetiva,
                          dasJaSeparado: _impostoJaSeparadoNoMes(),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(height: Space.x4),

            // O campo que faz o trabalho nascer. Opcional de propósito: quem
            // recebeu algo avulso não precisa inventar um cliente pra registrar.
            if (_trabalho == null)
              TextField(
                controller: _deQuem,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'De quem? (opcional)',
                  hintText: 'Ex.: Augusto',
                  helperText:
                      'Se for a primeira vez, eu crio o trabalho pra você.',
                ),
                onChanged: (_) => setState(() {}),
              ),

            const SizedBox(height: Space.x3),
            // Regime como FRASE, não como fileira de chips: é ajuste raro, da
            // pessoa, e ocupava o lugar da resposta.
            _LinhaRegime(regime: regime),

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
                          highlight: _saved,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // O sobrolho é a legenda do número logo abaixo,
                              // e o `semanticLabel` do MoneyCountUp já diz a
                              // frase inteira ("Separe R$ 68 pro imposto").
                              // Sem o Exclude, este card falava a mesma coisa
                              // três vezes: aqui, no número, e na legenda.
                              // Escolha UMA fonte da verdade — e a que fica é
                              // a que carrega o valor.
                              ExcludeSemantics(
                                child: Text(
                                  res.impostoDoMesQuitado
                                      ? 'ESSE DINHEIRO É TODO SEU'
                                      : 'SEPARE PRO IMPOSTO',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: Space.x1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: MoneyCountUp(
                                  res.impostoDoMesQuitado
                                      ? valor
                                      : res.separado,
                                  duration: Motion.quick,
                                  style: AppType.valueHero.copyWith(
                                    color: res.impostoDoMesQuitado
                                        ? d.lucro
                                        : d.reserva,
                                  ),
                                  semanticLabel: res.impostoDoMesQuitado
                                      ? 'Esse dinheiro é todo seu: ${moneyBRL(valor)}'
                                      : 'Separe ${moneyBRL(res.separado)} pro imposto',
                                ),
                              ),
                              const SizedBox(height: Space.x1),
                              Text(
                                _explicacao(res),
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: Space.x4),
                              // A barra e as duas legendas dizem o MESMO par
                              // de números. As legendas são texto de verdade
                              // (e é delas que sai a garantia "cor nunca
                              // sozinha"), então a barra sai da fala.
                              ExcludeSemantics(
                                child: EntradaBar(
                                  total: valor,
                                  separado: res.separado,
                                  sobra: res.sobra,
                                ),
                              ),
                              const SizedBox(height: Space.x2),
                              // O cofre FECHA: a linha nasce dentro do mesmo
                              // card, e o valor conta do total anterior pro
                              // novo. Herói, barra e campo ficam parados — o
                              // cofre não pula, ele fecha.
                              _CofreDoMes(
                                antes: _cofreAntes,
                                depois: _cofreDepois,
                              ),
                              Wrap(
                                spacing: Space.x4,
                                runSpacing: Space.x2,
                                children: <Widget>[
                                  // Acompanha a barra: "Pra usar" é o que É
                                  // SEU, e isso é esmeralda em todo o resto do
                                  // app. `d.custo` aqui fazia a mesma ideia ter
                                  // duas cores em duas telas.
                                  _legenda(
                                    context,
                                    d.lucro,
                                    'Pra usar',
                                    res.sobra,
                                  ),
                                  _legenda(
                                    context,
                                    d.reserva,
                                    'Imposto',
                                    res.separado.toDouble(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Space.x4),
                        // O Desfazer inline (no lugar da SnackBar) foi a
                        // decisão certa: SnackBar some sozinha em ~4s, e isso
                        // é WCAG 2.2.1 na cara — com leitor de tela dá pra
                        // ouvir o anúncio e mais nada. Aqui não tem prazo, e
                        // ele fica na ordem de leitura, logo depois do card
                        // que acabou de mudar. Falta só o foco não cair no
                        // vazio quando os botões trocam de identidade.
                        if (_saved)
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: FilledButton.tonal(
                                  focusNode: _focoDepoisDoSave,
                                  onPressed: () {
                                    setState(() {
                                      _valor.clear();
                                      if (widget.trabalhoId == null) {
                                        _deQuem.clear();
                                      }
                                      _saved = false;
                                      _cofreAntes = null;
                                      _cofreDepois = null;
                                    });
                                    // O campo é limpo; sem isto ninguém avisa
                                    // quem não vê a tela que ele esvaziou.
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) {
                                            _focoValor.requestFocus();
                                          }
                                        });
                                  },
                                  child: const Text('Registrar outro'),
                                ),
                              ),
                              const SizedBox(width: Space.x3),
                              Semantics(
                                // "Desfazer" sozinho é um cheque em branco:
                                // desfazer o quê? O registro? O trabalho que
                                // nasceu? O rótulo diz o que se perde.
                                label: _ultima == null
                                    ? 'Desfazer'
                                    : 'Desfazer o registro de '
                                          '${moneyBRL(_ultima!.valor)}',
                                button: true,
                                onTap: _desfazer,
                                child: ExcludeSemantics(
                                  child: TextButton(
                                    onPressed: _desfazer,
                                    child: const Text('Desfazer'),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          FilledButton.tonal(
                            focusNode: _focoGuardar,
                            onPressed: () => _salvar(res, regime, area),
                            child: const Text('Guardar'),
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
      ),
    );
  }

  String _explicacao(ReservaResult res) {
    if (res.isMei) {
      return res.impostoDoMesQuitado
          ? 'Seu imposto de ${mesNome(DateTime.now())} já está separado. O que entrar agora é todo seu.'
          : 'Como MEI, seu imposto do mês é um boleto só: ${moneyBRLCents(res.dasMensal!)}. Separando ele de uma vez.';
    }
    return '~${res.pct}% — já é a sua faixa real de imposto, não a cheia.';
  }

  Widget _legenda(
    BuildContext context,
    Color color,
    String label,
    double valor,
  ) => Row(
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
      // Sem o Flexible a legenda estoura 70px já em fonte normal num celular
      // de 320dp, e 358px em fonte 200%. O que se perde é o TEXTO — e o texto
      // é o canal que garante a regra "cor nunca sozinha". Em fonte grande
      // sobrava só o quadradinho colorido, sem nada dizendo o que ele é.
      Flexible(
        child: Text(
          '$label ${moneyBRL(valor)}',
          softWrap: true,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontFeatures: AppType.tnum),
        ),
      ),
    ],
  );
}

/// "como MEI · ajustar" — a frase que substituiu cinco chips de regime.
class _LinhaRegime extends StatelessWidget {
  const _LinhaRegime({required this.regime});

  final RegimeId regime;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(
          Icons.account_balance_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Space.x2),
        Expanded(
          child: Text(
            'Calculando como ${Regime.of(regime).tag}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// A linha que nasce quando o cofre fecha: `NO COFRE ESTE MÊS`, com o valor
/// contando **do total anterior pro novo**.
///
/// É a microinteração-assinatura do app. A regra que ela obedece: o último
/// pixel a parar é o dinheiro que FICA, não o que sai.
class _CofreDoMes extends StatelessWidget {
  const _CofreDoMes({required this.antes, required this.depois});

  final int? antes;
  final int? depois;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final int? total = depois;

    return AnimatedSize(
      duration: reduceMotionOf(context) ? Duration.zero : Motion.emphasized,
      curve: MotionCurves.emphasizedDecel,
      alignment: Alignment.topCenter,
      child: total == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: Space.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'NO COFRE ESTE MÊS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyCountUp(
                    total,
                    from: antes,
                    duration: Motion.emphasized,
                    curve: MotionCurves.landing,
                    style: theme.textTheme.titleLarge!.copyWith(
                      color: d.reserva,
                      fontFamily: AppType.numberFamily,
                      fontFeatures: AppType.tnum,
                    ),
                    // Anuncie a TRANSIÇÃO, rotule o ESTADO — nunca deixe o
                    // estado sem nome pra evitar repetir a transição.
                    //
                    // Aqui estava `semanticLabel: ''`, achando que silenciava
                    // uma repetição. Não silencia: tira o valor da árvore. O
                    // `announce` do save é transitório ("você acabou de
                    // crescer 68") e passa; o rótulo é permanente ("no cofre
                    // este mês: 412") e responde toda vez que o dedo passa.
                    // Quem enxerga ouvia o anúncio e podia OLHAR de novo; quem
                    // não enxerga ouvia uma vez e o número deixava de existir
                    // — tendo que ir ao Histórico procurar o próprio acúmulo,
                    // que é justamente a recompensa de voltar mês que vem.
                    semanticLabel: 'No cofre este mês: ${moneyBRL(total)}',
                  ),
                ],
              ),
            ),
    );
  }
}
