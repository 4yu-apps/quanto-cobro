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

    final EntradasNotifier entradasN = ref.read(entradasProvider.notifier);
    await entradasN.add(entrada);

    telemetry.evento(
      Evento.entradaRegistrada,
      params: <String, Object?>{
        'origem': trabalho == null ? 'avulso' : 'trabalho',
        'regime': regime.name,
      },
    );

    if (!mounted) return;
    // O gesto mais importante do app VIBRA e agora também FALA: a SnackBar não
    // é anunciada de forma confiável pelo leitor de tela.
    announce(
      context,
      trabalho == null
          ? 'Guardado. ${moneyBRL(res.separado)} separados pro imposto.'
          : 'Guardado. ${moneyBRL(res.separado)} separados do pagamento de ${trabalho.nome}.',
    );
    setState(() => _saved = true);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            trabalho == null
                ? '${moneyBRL(res.separado)} separados pro imposto'
                : '${moneyBRL(res.separado)} separados — "${trabalho.nome}" em dia',
          ),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              entradasN.remove(entrada);
              if (mounted) setState(() => _saved = false);
            },
          ),
        ),
      );
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
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          MoneyField(
            controller: _valor,
            label: 'Quanto você recebeu?',
            prefix: r'R$ ',
            autofocus: true,
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
                            Text(
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
                                res.impostoDoMesQuitado ? valor : res.separado,
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
                            EntradaBar(
                              total: valor,
                              separado: res.separado,
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
                                  'Imposto',
                                  res.separado.toDouble(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.x4),
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
                              onPressed: () => setState(() {
                                _valor.clear();
                                if (widget.trabalhoId == null) _deQuem.clear();
                                _saved = false;
                              }),
                              child: const Text('Registrar outro'),
                            ),
                          ],
                        )
                      else
                        FilledButton.tonal(
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
      Text(
        '$label ${moneyBRL(valor)}',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontFeatures: AppType.tnum),
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
