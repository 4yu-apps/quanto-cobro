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

/// Resultado (Blueprint §5.3): as 3 respostas com hierarquia clara. O perfil
/// chega da calculadora via `extra`. Momento "aha": o herói faz count-up.
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
                  onPressed: () => context.go(Routes.calc),
                  child: const Text('Refazer cálculo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final ValorHoraResult r = computeValorHora(p);
    final Divisao div = divisaoFromProfile(p, r);
    final bool custoMaiorQueMeta = p.custosTotal > p.renda;
    final bool stale = tabelasDefasadas(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Seu resultado')),
      body: ListView(
        padding: const EdgeInsets.all(Space.x4),
        children: <Widget>[
          Text('COBRE POR HORA',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Space.x1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              MoneyCountUp(
                r.valorHora,
                style: AppType.valueHero.copyWith(color: theme.colorScheme.primary),
                semanticLabel: 'Cobre ${moneyBRL(r.valorHora)} por hora',
              ),
              Text(' /hora',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          Text('Esse é o seu piso. Cobre mais quando o trabalho valer mais.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Space.x2),
          Text('≈ ${moneyBRL(r.valorDia)}/dia · ${moneyBRL(r.faturamento)}/mês faturados',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: Space.x6),
          StaggerIn(index: 1, child: _bloco(context, 'DE CADA PAGAMENTO, RESERVE', '${r.reservaPct}%', AppType.valueXl, d.reserva)),
          const SizedBox(height: Space.x6),
          StaggerIn(index: 2, child: _bloco(context, 'LUCRO REAL ESTIMADO', '${moneyBRL(r.lucro)}/mês', AppType.valueXl, d.lucro)),
          const SizedBox(height: Space.x6),
          StaggerIn(
            index: 3,
            child: DivisaoBar(
              lucro: div.lucro,
              reserva: div.reserva,
              custo: div.custo,
              emphasis: DivisaoEmphasis.lucro,
            ),
          ),
          if (custoMaiorQueMeta) ...<Widget>[
            const SizedBox(height: Space.x3),
            Text('Seus custos estão maiores que a renda que você quer. Vale rever.',
                style: theme.textTheme.bodyMedium?.copyWith(color: d.alerta)),
          ],
          if (stale) ...<Widget>[
            const SizedBox(height: Space.x3),
            StaleBanner(ano: kTabelasAno),
          ],
          const SizedBox(height: Space.x6),
          FilledButton(
            onPressed: () async {
              Haptics.commit();
              await ref.read(profileProvider.notifier).save(p);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Perfil salvo')));
                context.go(Routes.painel);
              }
            },
            child: const Text('Salvar este perfil'),
          ),
          TextButton(
            onPressed: () => context.push(Routes.detalhe),
            child: const Text('Ver detalhamento'),
          ),
          const SizedBox(height: Space.x4),
          const EstimativaSeal(),
        ],
      ),
    );
  }

  Widget _bloco(BuildContext context, String label, String value, TextStyle style, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
        const SizedBox(height: Space.x1),
        Text(value, style: style.copyWith(color: color)),
      ],
    );
  }
}
