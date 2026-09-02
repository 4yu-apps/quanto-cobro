import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calc/calc_engine.dart';
import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/model/area.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/breakpoints.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/help_dot.dart';
import '../../core/ui/money_field.dart';
import '../../core/ui/panel_card.dart';

/// Simulador de folga: "pra parar N dias daqui a M meses, minha hora precisa
/// ser quanto?". Férias como decisão de preço (é o nosso job), não como meta
/// de poupança (é o job do app de banco). Sem calendário, sem tracking, sem
/// barra de progresso: três perguntas e uma ação comercial.
class FolgaScreen extends ConsumerStatefulWidget {
  const FolgaScreen({super.key});

  @override
  ConsumerState<FolgaScreen> createState() => _FolgaScreenState();
}

class _FolgaScreenState extends ConsumerState<FolgaScreen> {
  int _dias = 10;
  int _meses = 3;
  final TextEditingController _custo = TextEditingController();

  @override
  void initState() {
    super.initState();
    telemetry.evento(Evento.folgaSimulada);
  }

  @override
  void dispose() {
    _custo.dispose();
    super.dispose();
  }

  int _digits(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final AreaState st = ref.watch(areaAtivaProvider);
    final RegimeId regime = ref.watch(regimeProvider);

    if (st is! AreaPronta) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vou tirar uma folga')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(Space.x6),
            child: Text('Calcule seu valor-hora primeiro. A folga parte dele.'),
          ),
        ),
      );
    }
    final Area area = st.area;
    final FolgaResult f = computeFolga(
      area: area,
      regime: regime,
      diasFolga: _dias,
      mesesAte: _meses,
      custoFolga: _digits(_custo.text).toDouble(),
    );
    final DateTime alvo = DateTime(DateTime.now().year, DateTime.now().month + _meses);
    final String mesAlvo = kMeses[alvo.month - 1];

    return Scaffold(
      appBar: AppBar(title: const Text('Vou tirar uma folga')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            // Cena.folga entra aqui (Task 16)
            _stepper(
              context,
              label: 'Quantos dias você quer parar?',
              value: _dias,
              min: 1,
              max: 60,
              suffix: 'dias',
              unidadeSingular: 'dia',
              verbeteId: 'folga',
              onChanged: (int v) => setState(() => _dias = v),
            ),
            const SizedBox(height: Space.x5),
            _stepper(
              context,
              label: 'Daqui a quantos meses?',
              helper: 'Em $mesAlvo, então.',
              value: _meses,
              min: 1,
              max: 12,
              suffix: _meses == 1 ? 'mês' : 'meses',
              unidadeSingular: 'mês',
              onChanged: (int v) => setState(() => _meses = v),
            ),
            const SizedBox(height: Space.x5),
            MoneyField(
              controller: _custo,
              label: 'Quanto a folga custa? (opcional)',
              prefix: r'R$ ',
              helper: 'Viagem, passagem, o que for. Se for só ficar em casa, deixa em branco.',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.x6),
            _Resposta(f: f, mesAlvo: mesAlvo, ouro: d.reserva),
            const SizedBox(height: Space.x4),
            const EstimativaSeal(),
          ],
        ),
      ),
    );
  }

  /// Stepper −/+ com valor grande no meio. Alvo ≥48dp nos botões.
  ///
  /// Ruling A (Task 10): o par `Semantics(label:) + ExcludeSemantics` cobre
  /// só o VALOR — o mesmo defeito já corrigido em
  /// `trabalho_detalhe_screen.dart` (o Exclude cobria o card inteiro e
  /// engolia a lista de pagamentos). Aqui os botões +/- ficam FORA do
  /// Exclude, cada um com o próprio `tooltip` (o padrão da casa pra rótulo de
  /// leitor de tela em `IconButton`, usado em `calc_screen.dart`,
  /// `help_dot.dart`, `areas_screen.dart` etc.) — senão o TalkBack fala só o
  /// valor e ninguém alcança os controles.
  Widget _stepper(
    BuildContext context, {
    required String label,
    String? helper,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required String unidadeSingular,
    String? verbeteId,
    required ValueChanged<int> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    Widget btn(IconData icon, bool enabled, String tooltip, VoidCallback onTap) =>
        IconButton.filledTonal(
          onPressed: enabled
              ? () {
                  Haptics.select();
                  onTap();
                }
              : null,
          icon: Icon(icon),
          iconSize: 24,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            minimumSize: const Size(52, 52),
            backgroundColor: cs.surfaceContainerHigh,
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
            if (verbeteId != null) HelpDot(verbeteId: verbeteId),
          ],
        ),
        if (helper != null)
          Text(
            helper,
            style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        const SizedBox(height: Space.x3),
        Row(
          children: <Widget>[
            btn(Icons.remove, value > min, 'Um $unidadeSingular a menos', () => onChanged(value - 1)),
            Expanded(
              child: Center(
                child: Semantics(
                  label: '$label: $value $suffix',
                  child: ExcludeSemantics(
                    child: Text(
                      '$value $suffix',
                      style: AppType.valueMd.copyWith(color: cs.onSurface),
                    ),
                  ),
                ),
              ),
            ),
            btn(Icons.add, value < max, 'Um $unidadeSingular a mais', () => onChanged(value + 1)),
          ],
        ),
      ],
    );
  }
}

/// A resposta: a ação comercial. Ouro em superfície grande (L5): a folga é a
/// tela quente do app, e o ouro é a única cor da paleta que diz "descanso".
class _Resposta extends StatelessWidget {
  const _Resposta({required this.f, required this.mesAlvo, required this.ouro});

  final FolgaResult f;
  final String mesAlvo;
  final Color ouro;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    if (f.jaCoberto) {
      return PanelCard(
        accent: ouro,
        padding: const EdgeInsets.all(Space.x5),
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.beach_access_outlined, color: ouro, size: 32),
              const SizedBox(height: Space.x3),
              Text(
                'Sua provisão de férias já cobre ${f.diasFolga} dias.',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: Space.x2),
              Text(
                'Pode parar em $mesAlvo tranquilo, na hora que você já cobra.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final String frase =
        'Pra parar ${f.diasFolga} dias em $mesAlvo, sua hora precisa ser ${moneyBRL(f.valorHoraNovo)} nos próximos contratos. Hoje é ${moneyBRL(f.valorHoraAtual)}.'
        '${f.estouraCapacidade ? ' Mais hora não cabe na sua semana: o caminho é a hora mais cara.' : ' Ou ${f.horasExtrasMes} horas a mais por mês, na hora de hoje.'}';

    return Semantics(
      liveRegion: true,
      label: frase,
      child: ExcludeSemantics(
        child: PanelCard(
          accent: ouro,
          padding: const EdgeInsets.all(Space.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'SUA HORA PRECISA SER',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: Space.x1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: moneyBRL(f.valorHoraNovo),
                        style: AppType.valueXl.copyWith(color: ouro),
                      ),
                      TextSpan(
                        text: '/hora',
                        style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.x1),
              Text(
                'hoje: ${moneyBRL(f.valorHoraAtual)}/hora · pra parar ${f.diasFolga} dias em $mesAlvo',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: Space.x4),
              Divider(color: cs.outlineVariant, height: 1),
              const SizedBox(height: Space.x4),
              if (f.estouraCapacidade)
                Text(
                  'Mais hora não cabe na sua semana. O caminho é a hora mais cara.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: <InlineSpan>[
                      const TextSpan(text: 'ou '),
                      TextSpan(
                        text: '+${f.horasExtrasMes} h por mês',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' até lá, na hora de hoje.'),
                    ],
                  ),
                ),
              const SizedBox(height: Space.x3),
              Text(
                'Faltam ${moneyBRL(f.faltaTotal)} entrando antes da folga'
                '${f.cobertoPelaProvisao > 0 ? ', já descontando o que sua provisão de férias cobre' : ''}.',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
