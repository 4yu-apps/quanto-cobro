import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/perfil.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/money_field.dart';

/// Detalhamento ("como cheguei aqui", Blueprint §5.4): a conta linha a linha,
/// com renda e horas EDITÁVEIS inline e recálculo ao vivo (causa -> efeito).
/// Transparência = confiança em app de dinheiro.
class DetalheScreen extends ConsumerStatefulWidget {
  const DetalheScreen({super.key});

  @override
  ConsumerState<DetalheScreen> createState() => _DetalheScreenState();
}

class _DetalheScreenState extends ConsumerState<DetalheScreen> {
  Perfil? _perfil;
  final TextEditingController _renda = TextEditingController();
  final TextEditingController _horas = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ProfileState st = ref.read(profileProvider);
    if (st is ProfileReady) {
      _perfil = st.perfil;
      _renda.text = st.perfil.renda.round().toString();
      _horas.text = st.perfil.horas.toString();
    }
  }

  @override
  void dispose() {
    _renda.dispose();
    _horas.dispose();
    super.dispose();
  }

  int _digits(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final Perfil? p = _perfil;
    return Scaffold(
      appBar: AppBar(title: const Text('Como cheguei nesse número')),
      body: p == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.x6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Você ainda não tem um cálculo salvo.'),
                    const SizedBox(height: Space.x4),
                    FilledButton(
                      onPressed: () => context.go(Routes.calc),
                      child: const Text('Fazer meu cálculo'),
                    ),
                  ],
                ),
              ),
            )
          : _body(context, p),
    );
  }

  Widget _body(BuildContext context, Perfil p) {
    final ThemeData theme = Theme.of(context);
    final ValorHoraResult r = computeValorHora(p);
    return ListView(
      padding: const EdgeInsets.all(Space.x4),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: MoneyField(
                controller: _renda,
                label: 'Renda desejada',
                prefix: r'R$ ',
                onChanged: (String v) =>
                    setState(() => _perfil = p.copyWith(renda: _digits(v).toDouble())),
              ),
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: MoneyField(
                controller: _horas,
                label: 'Horas',
                suffix: 'h',
                onChanged: (String v) => setState(() => _perfil = p.copyWith(horas: _digits(v))),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x6),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radii.lg)),
          child: Padding(
            padding: const EdgeInsets.all(Space.x5),
            child: Column(
              children: <Widget>[
                _linha(context, 'Renda desejada', moneyBRL(p.renda)),
                _linha(context, '+ Custos fixos', moneyBRL(r.custos)),
                if (p.provisaoOn) _linha(context, '+ Provisão férias/13º', moneyBRL(r.provisao)),
                _linha(context, '+ Imposto estimado (${r.reservaPct}%)', moneyBRL(r.imposto)),
                const Divider(),
                _linha(context, '= Preciso faturar', moneyBRL(r.faturamento), forte: true),
                _linha(context, '÷ Horas faturáveis', '${p.horas} h'),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('= Valor-hora', style: theme.textTheme.titleMedium),
                    MoneyCountUp(r.valorHora,
                        style: AppType.valueMd.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.x4),
        OutlinedButton.icon(
          onPressed: () => context.push(Routes.calc),
          icon: const Icon(Icons.tune),
          label: const Text('Editar custos e regime'),
        ),
        const SizedBox(height: Space.x2),
        FilledButton(
          onPressed: () async {
            await ref.read(profileProvider.notifier).save(p);
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Alterações salvas')));
            }
          },
          child: const Text('Salvar alterações'),
        ),
        const SizedBox(height: Space.x4),
        const EstimativaSeal(),
      ],
    );
  }

  Widget _linha(BuildContext context, String label, String valor, {bool forte = false}) {
    final TextTheme t = Theme.of(context).textTheme;
    final TextStyle? style = forte ? t.titleMedium : t.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x1),
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
