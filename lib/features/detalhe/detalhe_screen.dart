import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/custo.dart';
import '../../core/model/perfil.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/money_field.dart';

/// Detalhamento ("como cheguei aqui", Blueprint §5.4): a conta linha a linha,
/// custo a custo, com renda e horas editáveis inline e recálculo ao vivo.
/// Aceita o perfil via rota (extra) — assim o Resultado mostra a conta CERTA
/// mesmo antes de salvar (confiança é a função desta tela).
class DetalheScreen extends ConsumerStatefulWidget {
  const DetalheScreen({super.key, this.perfil});

  final Perfil? perfil;

  @override
  ConsumerState<DetalheScreen> createState() => _DetalheScreenState();
}

class _DetalheScreenState extends ConsumerState<DetalheScreen> {
  Perfil? _perfil;
  bool _dirty = false;
  final TextEditingController _renda = TextEditingController();
  final TextEditingController _horas = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prioridade: perfil vindo da rota (draft do Resultado) > perfil salvo.
    final Perfil? fromRoute = widget.perfil;
    if (fromRoute != null) {
      _perfil = fromRoute;
    } else {
      final ProfileState st = ref.read(profileProvider);
      if (st is ProfileReady) _perfil = st.perfil;
    }
    final Perfil? p = _perfil;
    if (p != null) {
      _renda.text = p.renda.round().toString();
      _horas.text = p.horas.toString();
    }
  }

  @override
  void dispose() {
    _renda.dispose();
    _horas.dispose();
    super.dispose();
  }

  int _digits(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _edit(Perfil novo) => setState(() {
        _perfil = novo;
        _dirty = true;
      });

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
                      onPressed: () => context.push(Routes.calc),
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
                onChanged: (String v) => _edit(p.copyWith(renda: _digits(v).toDouble())),
              ),
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: MoneyField(
                controller: _horas,
                label: 'Horas',
                suffix: 'h',
                onChanged: (String v) => _edit(p.copyWith(horas: _digits(v))),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x6),
        Card(
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(Space.x5),
            child: Column(
              children: <Widget>[
                _linha(context, 'Renda desejada', moneyBRL(p.renda)),
                _linha(context, '+ Custos fixos', moneyBRL(r.custos)),
                // A transparência mora aqui: cada custo, linha a linha.
                for (final Custo c in p.custos) _sublinha(context, c.label, moneyBRL(c.valor)),
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
                    MoneyCountUp(
                      r.valorHora,
                      style: AppType.valueLg.copyWith(color: theme.colorScheme.primary),
                      semanticLabel: 'Valor-hora: ${moneyBRL(r.valorHora)}',
                    ),
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
          onPressed: !_dirty
              ? null
              : () async {
                  Haptics.commit();
                  await ref.read(profileProvider.notifier).save(p);
                  if (context.mounted) {
                    setState(() => _dirty = false);
                    if (context.canPop()) context.pop();
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
    final TextStyle? style = (forte ? t.titleMedium : t.bodyLarge)
        ?.copyWith(fontFeatures: AppType.tnum);
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

  Widget _sublinha(BuildContext context, String label, String valor) {
    final TextStyle? style = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontFeatures: AppType.tnum);
    return Padding(
      padding: const EdgeInsets.only(left: Space.x4, top: 2, bottom: 2),
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
