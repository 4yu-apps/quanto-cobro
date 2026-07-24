import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/money.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/help_dot.dart';

/// A folha de detalhamento do imposto (F4) — o raio-x "de onde vem esse número"
/// atrás de UM toque. **Profundidade Pro** (doc 15 §4.2): quem não tem Pro vê o
/// convite calmo, com a promessa de que o valor que ele guarda continua grátis,
/// sempre. Quem tem Pro vê a conta peça a peça (INSS · faixa · deduções).
///
/// Só abre pra regimes com mecânica real (CPF · carnê-leão · Simples). MEI (DAS
/// fixo, é a frente do teto) e intl (regra de bolso) não têm o que abrir e nem
/// chamam esta folha.
bool regimeTemDetalhamento(RegimeId regime) =>
    regime == RegimeId.cpf ||
    regime == RegimeId.carneLeao ||
    regime == RegimeId.simples;

/// Abre a folha. [faturamentoMensal] é a base já com gross-up (o
/// `ValorHoraResult.faturamento`) — a mesma sobre a qual o imposto foi calculado.
Future<void> showImpostoDetalheSheet(
  BuildContext context,
  WidgetRef ref, {
  required RegimeId regime,
  required double faturamentoMensal,
  double proLaboreMensal = 0,
}) async {
  if (!regimeTemDetalhamento(regime)) return;

  if (!ref.read(proProvider)) {
    telemetry.evento(
      Evento.proParedeVista,
      params: <String, Object?>{'gatilho': GatilhoPro.detalhamentoImposto},
    );
    final bool? verPro = await _mostrarGate(context);
    if (verPro == true && context.mounted) {
      await context.push(Routes.pro, extra: GatilhoPro.detalhamentoImposto);
    }
    return;
  }

  final ImpostoDetalhe d = detalharImposto(
    regime,
    faturamentoMensal,
    proLaboreMensal: proLaboreMensal,
  );
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheet) => _DetalheImposto(d: d),
  );
}

/// A folha Pro: a conta linha a linha, em linguagem de gente.
class _DetalheImposto extends StatelessWidget {
  const _DetalheImposto({required this.d});

  final ImpostoDetalhe d;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('De onde vem esse imposto', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.x1),
            Text(
              'Como ${Regime.of(d.regime).tag}, mês a mês. É estimativa de '
              'planejamento — confirme o valor oficial com seu contador ou na Receita.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x5),
            ..._linhas(context),
            const SizedBox(height: Space.x5),
            const EstimativaSeal(),
            const SizedBox(height: Space.x4),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _linhas(BuildContext context) {
    switch (d.regime) {
      case RegimeId.cpf:
        return <Widget>[
          _Linha(
            'INSS',
            valor: d.inss,
            nota: 'A sua parte da Previdência: 20% do que entra, até o teto.',
            help: 'inss',
          ),
          ..._blocoIrpf(
            context,
            baseNota: 'sobre ${moneyBRL(d.baseIrpf)} — o que entrou menos o INSS',
            semIrpfNota:
                'Pela sua renda, você não paga imposto de renda este mês — só o INSS.',
          ),
          const _DividerLinha(),
          _Linha('Imposto do mês', valor: d.imposto, total: true),
          _rodapeEfetiva(context, comparativo: 'A tabela chega a 27,5%.'),
        ];
      case RegimeId.carneLeao:
        return <Widget>[
          ..._blocoIrpf(
            context,
            baseNota: 'sobre ${moneyBRL(d.baseIrpf)} que entraram',
            semIrpfNota:
                'Pela sua renda, não há imposto de renda este mês.',
          ),
          const _DividerLinha(),
          _Linha('Imposto do mês', valor: d.imposto, total: true),
          const SizedBox(height: Space.x3),
          _NotaBloco(
            'Sem INSS: como CPF que recebe do exterior, você não contribui '
            'como autônomo.',
          ),
          _rodapeEfetiva(context, comparativo: 'A tabela chega a 27,5%.'),
        ];
      case RegimeId.simples:
        final String anexo = d.simplesAnexo3 ? 'Anexo III' : 'Anexo V';
        return <Widget>[
          _Linha(
            'Seu anexo: $anexo',
            pctTexto: 'Fator R ${_pct(d.fatorR)}',
            nota: d.simplesAnexo3
                ? 'Seu pró-labore passa de 28% do que você fatura, então cai no Anexo III (mais barato).'
                : 'Seu pró-labore não chega a 28% do que você fatura, então cai no Anexo V (mais caro).',
            help: 'fator_r',
          ),
          _Linha(
            'Sua receita no ano (estimada)',
            valor: d.rbt12,
            nota: 'seu mês × 12 — é o que define a sua faixa.',
          ),
          _Linha(
            'Faixa do $anexo',
            pctTexto: _pct(d.simplesNominal),
            nota: 'a alíquota cheia da sua faixa (serviços).',
          ),
          if (d.simplesDeducao > 0)
            _Linha(
              'Parcela a deduzir da faixa',
              valor: d.simplesDeducao,
              subtrai: true,
              nota: 'desconto anual da faixa, pra não pagar demais.',
              help: 'parcela_deduzir',
            ),
          _Linha(
            'Alíquota efetiva',
            pctTexto: _pct(d.efetiva),
            nota: 'o que sobra depois do desconto — é o que você paga de verdade.',
            help: 'aliquota',
          ),
          const _DividerLinha(),
          _Linha('Imposto do mês', valor: d.imposto, total: true),
        ];
      // Regimes sem detalhamento não chegam aqui (guardado em [showImpostoDetalheSheet]).
      case RegimeId.mei:
      case RegimeId.intl:
        return const <Widget>[];
    }
  }

  /// O miolo do IRPF é igual pro CPF e pro carnê-leão — muda só o texto da base
  /// e a mensagem de "sem imposto".
  List<Widget> _blocoIrpf(
    BuildContext context, {
    required String baseNota,
    required String semIrpfNota,
  }) {
    if (d.semIrpf) {
      return <Widget>[const SizedBox(height: Space.x2), _NotaBloco(semIrpfNota)];
    }
    return <Widget>[
      _Linha(
        'Imposto de renda · faixa de ${_pct(d.faixaAliquota)}',
        valor: d.irpfBruto,
        nota: baseNota,
      ),
      if (d.deducaoFaixa > 0)
        _Linha(
          'Parcela a deduzir da faixa',
          valor: d.deducaoFaixa,
          subtrai: true,
          nota: 'desconto fixo da sua faixa.',
          help: 'parcela_deduzir',
        ),
      if (d.redutor > 0)
        _Linha(
          'Desconto da nova lei',
          valor: d.redutor,
          subtrai: true,
          nota: 'isenta quem recebe até R\$ 5.000 no mês.',
        ),
    ];
  }

  Widget _rodapeEfetiva(BuildContext context, {required String comparativo}) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.x3),
      child: Text(
        'Na prática, ${_pct(d.efetiva)} do que você fatura. $comparativo',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Uma linha da conta: rótulo (com "?" opcional) à esquerda, valor à direita,
/// apoio embaixo. [total] destaca a soma; [subtrai] mostra o sinal "−".
class _Linha extends StatelessWidget {
  const _Linha(
    this.label, {
    this.valor,
    this.pctTexto,
    this.nota,
    this.subtrai = false,
    this.total = false,
    this.help,
  });

  final String label;
  final double? valor;
  final String? pctTexto;
  final String? nota;
  final bool subtrai;
  final bool total;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    final String direita = pctTexto ??
        '${subtrai ? '− ' : ''}${moneyBRL(valor ?? 0)}';
    final TextStyle? labelStyle = total
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyLarge;
    final TextStyle? valorStyle = total
        ? theme.textTheme.titleLarge?.copyWith(
            color: d.reserva,
            fontFamily: AppType.numberFamily,
            fontWeight: FontWeight.w700,
            fontFeatures: AppType.tnum,
          )
        : theme.textTheme.bodyLarge?.copyWith(fontFeatures: AppType.tnum);

    return Padding(
      padding: EdgeInsets.only(top: total ? Space.x2 : Space.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Flexible(child: Text(label, style: labelStyle)),
                    if (help != null) HelpDot(verbeteId: help!, size: 18),
                  ],
                ),
              ),
              const SizedBox(width: Space.x3),
              Text(direita, style: valorStyle),
            ],
          ),
          if (nota != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              nota!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DividerLinha extends StatelessWidget {
  const _DividerLinha();

  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.only(top: Space.x3), child: Divider());
}

class _NotaBloco extends StatelessWidget {
  const _NotaBloco(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      texto,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// A folha do gate (grátis): o convite calmo, com a promessa que a pesquisa
/// manda cumprir — o valor que a pessoa guarda NUNCA fica atrás de pagamento.
/// Devolve `true` quando a pessoa toca "Ver o Pro" (a navegação acontece fora,
/// já com a folha fechada e um contexto vivo).
Future<bool?> _mostrarGate(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheet) {
      final ThemeData theme = Theme.of(sheet);
      final ColorScheme cs = theme.colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('A conta por dentro é do Pro', style: theme.textTheme.titleLarge),
              const SizedBox(height: Space.x3),
              Text(
                'Ver o passo a passo — INSS, faixa do imposto, deduções — faz '
                'parte do Pro. O quanto você guarda de cada pagamento continua '
                'grátis, sempre.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.x5),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheet).pop(true),
                  child: const Text('Ver o Pro'),
                ),
              ),
              const SizedBox(height: Space.x2),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(sheet).pop(false),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _pct(double frac) {
  final double v = frac * 100;
  final String s = v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1).replaceAll('.', ',');
  return '$s%';
}
