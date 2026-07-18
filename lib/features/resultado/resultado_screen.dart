import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/perfil.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/ui/divisao_bar.dart';
import '../../core/ui/estimativa_seal.dart';

/// Resultado (Blueprint §5.3): as 3 respostas com hierarquia clara. O perfil
/// chega da calculadora via `extra`. Se faltar (navegação direta), degrada com
/// transparência em vez de quebrar.
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Não recebi os dados do cálculo. Vamos refazer?',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
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
    // Sinal de input incoerente (Blueprint §5.9): custos fixos maiores que a
    // renda que a pessoa quer tirar — vale revisar antes de fechar o preço.
    final bool custoMaiorQueMeta = p.custosTotal > p.renda;

    return Scaffold(
      appBar: AppBar(title: const Text('Seu resultado')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _bloco(context, 'COBRE POR HORA', '${moneyBRL(r.valorHora)} /hora',
              AppType.valueHero, theme.colorScheme.primary),
          Text('≈ ${moneyBRL(r.valorDia)}/dia · ${moneyBRL(r.faturamento)}/mês faturados',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          _bloco(context, 'DE CADA PAGAMENTO, RESERVE', '${r.reservaPct}%',
              AppType.valueXl, d.reserva),
          const SizedBox(height: 24),
          _bloco(context, 'LUCRO REAL ESTIMADO', '${moneyBRL(r.lucro)}/mês',
              AppType.valueXl, d.lucro),
          const SizedBox(height: 24),
          DivisaoBar(lucro: div.lucro, reserva: div.reserva, custo: div.custo),
          if (custoMaiorQueMeta) ...<Widget>[
            const SizedBox(height: 12),
            Text('Seu custo está maior que sua meta. Reveja os custos ou a renda desejada.',
                style: theme.textTheme.bodyMedium?.copyWith(color: d.alerta)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
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
          const SizedBox(height: 16),
          const EstimativaSeal(),
        ],
      ),
    );
  }

  Widget _bloco(BuildContext context, String label, String value, TextStyle style, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value, style: style.copyWith(color: color)),
      ],
    );
  }
}
