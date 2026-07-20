import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/custo.dart';
import '../../core/model/area.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/money_count_up.dart';
import '../../core/ui/money_field.dart';

/// Detalhamento ("como cheguei aqui", Blueprint §5.4): a conta linha a linha,
/// custo a custo, com renda e horas editáveis inline e recálculo ao vivo.
/// Aceita o area via rota (extra) — assim o Resultado mostra a conta CERTA
/// mesmo antes de salvar (confiança é a função desta tela).
class DetalheScreen extends ConsumerStatefulWidget {
  const DetalheScreen({super.key, this.area});

  final Area? area;

  @override
  ConsumerState<DetalheScreen> createState() => _DetalheScreenState();
}

class _DetalheScreenState extends ConsumerState<DetalheScreen> {
  Area? _area;
  bool _dirty = false;
  final TextEditingController _renda = TextEditingController();
  final TextEditingController _horas = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Prioridade: area vindo da rota (draft do Resultado) > area salvo.
    final Area? fromRoute = widget.area;
    if (fromRoute != null) {
      _area = fromRoute;
    } else {
      final AreaState st = ref.read(areaAtivaProvider);
      if (st is AreaPronta) _area = st.area;
    }
    final Area? p = _area;
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

  int _digits(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _edit(Area novo) => setState(() {
    _area = novo;
    _dirty = true;
  });

  @override
  Widget build(BuildContext context) {
    final Area? p = _area;
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
          : _body(context, p, ref.watch(regimeProvider)),
    );
  }

  Widget _body(BuildContext context, Area p, RegimeId regime) {
    final ThemeData theme = Theme.of(context);
    final ValorHoraResult r = computeValorHora(p, regime);
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
                    _edit(p.copyWith(renda: _digits(v).toDouble())),
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
        Text(
          'COMO VOCÊ RECEBE',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: Space.x2),
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x2,
          children: <Widget>[
            for (final Regime opcao in Regime.all.values)
              ChoiceChip(
                label: Text(opcao.tag),
                selected: regime == opcao.id,
                // O regime é da PESSOA: mudar aqui vale pro app inteiro.
                onSelected: (_) =>
                    ref.read(regimeProvider.notifier).set(opcao.id),
              ),
          ],
        ),
        const SizedBox(height: Space.x4),
        Card(
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(Space.x5),
            child: Column(
              children: <Widget>[
                _linha(context, 'Renda desejada', moneyBRL(p.renda)),
                _linha(context, '+ Custos fixos', moneyBRL(r.custos)),
                // A transparência mora aqui: cada custo, linha a linha.
                for (final Custo c in p.custos)
                  _sublinha(
                    context,
                    c.label,
                    moneyBRL(c.valor),
                    onTap: () => _editarCusto(p, c),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('+ Provisão férias/13º'),
                  subtitle: Text(
                    p.provisaoCustom
                        ? 'Valor ajustado por você'
                        : '1 mês da sua renda por ano — toque pra ajustar',
                  ),
                  trailing: Text(moneyBRL(r.provisao)),
                  onTap: () => _editarProvisao(p),
                ),
                _linha(
                  context,
                  regime == RegimeId.mei
                      ? '+ DAS (fixo do MEI)'
                      : '+ Imposto estimado (~${r.reservaPct}% efetivo)',
                  moneyBRL(r.imposto),
                ),
                if (regime == RegimeId.simples)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.x2),
                    child: Text(
                      'Estimativa pelo Anexo III (serviços). Se seu contador fala em Fator R ou Anexo V, confirme o número com ele.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const Divider(),
                _linha(
                  context,
                  '= Preciso faturar',
                  moneyBRL(r.faturamento),
                  forte: true,
                ),
                _linha(context, '÷ Horas de trabalho no mês', '${p.horas} h'),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('= Valor-hora', style: theme.textTheme.titleMedium),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: MoneyCountUp(
                          r.valorHora,
                          duration: Motion.quick,
                          style: AppType.valueLg.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          semanticLabel: 'Valor-hora: ${moneyBRL(r.valorHora)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.x4),
        OutlinedButton.icon(
          onPressed: () => context.push(Routes.calc, extra: p),
          icon: const Icon(Icons.tune),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Refazer com o passo a passo'),
          ),
        ),
        const SizedBox(height: Space.x2),
        FilledButton(
          onPressed: !_dirty
              ? null
              : () async {
                  Haptics.commit();
                  await ref.read(areasProvider.notifier).saveAndActivate(p);
                  if (context.mounted) {
                    setState(() => _dirty = false);
                    if (context.canPop()) context.pop();
                  }
                },
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Salvar alterações'),
          ),
        ),
        const SizedBox(height: Space.x4),
        const EstimativaSeal(),
      ],
    );
  }

  Widget _linha(
    BuildContext context,
    String label,
    String valor, {
    bool forte = false,
  }) {
    final TextTheme t = Theme.of(context).textTheme;
    final TextStyle? style = (forte ? t.titleMedium : t.bodyLarge)?.copyWith(
      fontFeatures: AppType.tnum,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(child: Text(label, style: style)),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(valor, style: style, textAlign: TextAlign.end),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sublinha(
    BuildContext context,
    String label,
    String valor, {
    VoidCallback? onTap,
  }) {
    final TextStyle? style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFeatures: AppType.tnum,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.only(left: Space.x4, top: 6, bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(child: Text(label, style: style)),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(valor, style: style, textAlign: TextAlign.end),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarCusto(Area area, Custo custo) async {
    final TextEditingController controller = TextEditingController(
      text: custo.valor.round().toString(),
    );
    final double? valor = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          Space.x6,
          Space.x2,
          Space.x6,
          Space.x6 + MediaQuery.of(sheet).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Editar ${custo.label}',
              style: Theme.of(sheet).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.x4),
            MoneyField(
              controller: controller,
              label: 'Valor por mês',
              prefix: r'R$ ',
              autofocus: true,
            ),
            const SizedBox(height: Space.x4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(sheet, _digits(controller.text).toDouble()),
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);
    if (valor == null || !mounted) return;
    _edit(
      area.copyWith(
        custos: <Custo>[
          for (final Custo item in area.custos)
            item.id == custo.id
                ? Custo(id: item.id, label: item.label, valor: valor)
                : item,
        ],
      ),
    );
  }

  Future<void> _editarProvisao(Area area) async {
    final TextEditingController controller = TextEditingController(
      text: area.provisaoEfetiva.round().toString(),
    );
    final double? valor = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          Space.x6,
          Space.x2,
          Space.x6,
          Space.x6 + MediaQuery.of(sheet).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Sua provisão mensal',
              style: Theme.of(sheet).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.x2),
            const Text('1 mês da sua renda por ano, pra férias e 13º.'),
            const SizedBox(height: Space.x4),
            MoneyField(
              controller: controller,
              label: 'Valor por mês',
              prefix: r'R$ ',
              autofocus: true,
            ),
            const SizedBox(height: Space.x4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(sheet, _digits(controller.text).toDouble()),
                child: const Text('Usar este valor'),
              ),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 600), controller.dispose);
    if (valor == null || !mounted) return;
    _edit(area.copyWith(provisao: valor, provisaoCustom: true));
  }
}
