import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/calc/tax_tables.dart';
import '../../core/common/money.dart';
import '../../core/model/perfil.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/stale_banner.dart';

/// Resultado (Blueprint §5.3): as 3 respostas com hierarquia clara. Regra da
/// casa: resposta de dinheiro vive numa SUPERFÍCIE, nunca solta no fundo —
/// resposta-mãe em cima (card vitrine), anatomia embaixo (card de leitura).
class ResultadoScreen extends ConsumerWidget {
  const ResultadoScreen({super.key, this.perfil});

  final Perfil? perfil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Perfil? p = perfil;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seu resultado')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.x6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Não recebi os dados do cálculo. Vamos refazer?',
                    textAlign: TextAlign.center),
                const SizedBox(height: Space.x4),
                FilledButton(
                  onPressed: () => context.push(Routes.calc),
                  child: const Text('Refazer cálculo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final ValorHoraResult r = computeValorHora(p);
    final Divisao div = divisaoFromProfile(p, r);
    final bool custoMaiorQueMeta = p.custosTotal > p.renda;
    final bool stale = tabelasDefasadas(DateTime.now());
    final bool dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Seu resultado')),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          // Card-vitrine: a resposta-mãe (mesma moldura do herói do Painel).
          StaggerIn(
            index: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: dark
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[cs.surfaceContainerHigh, cs.surfaceContainer],
                      )
                    : null,
                color: dark ? null : cs.surfaceContainerHigh,
                borderRadius: const BorderRadius.all(Radii.xl),
                border: dark ? null : Border.all(color: cs.outlineVariant),
              ),
              padding: const EdgeInsets.all(Space.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('COBRE POR HORA',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.5)),
                  const SizedBox(height: Space.x1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        MoneyCountUp(
                          r.valorHora,
                          style: AppType.valueHero.copyWith(color: cs.primary),
                          semanticLabel: 'Cobre ${moneyBRL(r.valorHora)} por hora',
                        ),
                        Text(' /hora',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.x1),
                  Text('Esse é o seu piso. Cobre mais quando o trabalho valer mais.',
                      style:
                          theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: Space.x2),
                  Text(
                      '≈ ${moneyBRL(r.valorDia)}/dia · ${moneyBRL(r.faturamento)}/mês faturados',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.x4),

          // Card de anatomia: as outras 2 respostas + a Divisão.
          StaggerIn(
            index: 1,
            child: Card(
              color: cs.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(Space.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MergeSemantics(
                      child: _bloco(
                          context, 'DE CADA PAGAMENTO, RESERVE', '${r.reservaPct}%', d.reserva),
                    ),
                    const Divider(),
                    MergeSemantics(
                      child: _bloco(
                          context, 'LUCRO REAL ESTIMADO', '${moneyBRL(r.lucro)}/mês', d.lucro),
                    ),
                    const Divider(),
                    DivisaoBar(
                      lucro: div.lucro,
                      reserva: div.reserva,
                      custo: div.custo,
                      emphasis: DivisaoEmphasis.lucro,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (custoMaiorQueMeta) ...<Widget>[
            const SizedBox(height: Space.x3),
            StaggerIn(
              index: 2,
              child: Container(
                padding: const EdgeInsets.all(Space.x3),
                decoration: BoxDecoration(
                  color: d.alertaContainer,
                  borderRadius: const BorderRadius.all(Radii.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.trending_down, size: 20, color: d.onAlertaContainer),
                    const SizedBox(width: Space.x2),
                    Expanded(
                      child: Text(
                        'Seus custos estão maiores que a renda que você quer. Vale rever.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: d.onAlertaContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (stale) ...<Widget>[
            const SizedBox(height: Space.x3),
            StaleBanner(ano: kTabelasAno),
          ],
          const SizedBox(height: Space.x6),
          FilledButton(
            onPressed: () async {
              Haptics.commit();
              await ref.read(profilesProvider.notifier).saveAndActivate(p);
              // Sem snackbar: o count-up + stagger do Painel É a confirmação
              // (e o haptic já selou o gesto).
              if (context.mounted) context.go(Routes.painel);
            },
            child: const Text('Salvar este trabalho'),
          ),
          TextButton(
            onPressed: () => context.push(Routes.detalhe, extra: p),
            child: const Text('Ver detalhamento'),
          ),
          const SizedBox(height: Space.x4),
          const EstimativaSeal(),
        ],
      ),
    );
  }

  Widget _bloco(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                )),
        const SizedBox(height: Space.x1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              maxLines: 1, style: AppType.valueXl.copyWith(color: color)),
        ),
      ],
    );
  }
}
