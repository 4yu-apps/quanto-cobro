import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/perfil.dart';
import '../../core/providers.dart';
import '../../core/ui/estimativa_seal.dart';

/// Detalhamento ("como cheguei aqui", Blueprint §5.4): abre a caixa-preta, a
/// conta linha a linha. Transparência = confiança em app de dinheiro. Editar
/// leva de volta à calculadora (edição inline fica pra o polish).
class DetalheScreen extends ConsumerWidget {
  const DetalheScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileState st = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Como cheguei nesse número')),
      body: switch (st) {
        ProfileReady(perfil: final Perfil p) => _body(context, p),
        _ => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Você ainda não tem um cálculo salvo.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go(Routes.calc),
                    child: const Text('Fazer meu cálculo'),
                  ),
                ],
              ),
            ),
          ),
      },
    );
  }

  Widget _body(BuildContext context, Perfil p) {
    final ValorHoraResult r = computeValorHora(p);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _linha(context, 'Renda desejada', moneyBRL(p.renda)),
        _linha(context, '+ Custos fixos', moneyBRL(r.custos)),
        if (p.provisaoOn) _linha(context, '+ Provisão férias/13º', moneyBRL(r.provisao)),
        _linha(context, '+ Imposto estimado (${r.reservaPct}%)', moneyBRL(r.imposto)),
        const Divider(),
        _linha(context, '= Preciso faturar', moneyBRL(r.faturamento), forte: true),
        _linha(context, '÷ Horas faturáveis', '${p.horas} h'),
        const Divider(),
        _linha(context, '= Valor-hora', '${moneyBRL(r.valorHora)}/h', forte: true),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push(Routes.calc),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar meu cálculo'),
        ),
        const SizedBox(height: 16),
        const EstimativaSeal(),
      ],
    );
  }

  Widget _linha(BuildContext context, String label, String valor, {bool forte = false}) {
    final TextTheme t = Theme.of(context).textTheme;
    final TextStyle? style = forte ? t.titleMedium : t.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(child: Text(label, style: style)),
          Text(valor, style: style),
        ],
      ),
    );
  }
}
