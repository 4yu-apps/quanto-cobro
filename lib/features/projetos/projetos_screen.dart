import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/calc/calc_engine.dart';
import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/model/projeto.dart';
import '../../core/model/regime.dart';
import '../../core/model/reserva_entry.dart';
import '../../core/projetos/agenda.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/panel_card.dart';
import 'projeto_card.dart';

/// Aba Projetos (07 §B.2) — a evolução do slot que era "Trabalhos".
///
/// Quem abre uma aba com esse nome espera ver os clientes dele, não presets de
/// cálculo. O preset (multi-`Perfil`, Pro) desceu pro switcher do herói e pra
/// Configurações: é baixa frequência e ocupava um lugar nobre.
class ProjetosScreen extends ConsumerWidget {
  const ProjetosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Projeto> projetos = ref.watch(projetosProvider);
    final List<ReservaEntry> historico = ref.watch(reservaHistoryProvider);
    final DateTime hoje = DateTime.now();
    final Map<String, double> recebido = recebidoPorProjeto(historico);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projetos'),
        actions: <Widget>[
          if (projetos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Novo projeto',
              onPressed: () => context.push(Routes.projetoForm),
            ),
        ],
      ),
      body: projetos.isEmpty
          ? const _Vazio()
          : ListView(
              padding: EdgeInsets.fromLTRB(
                Space.x4,
                Space.x4,
                Space.x4,
                kFloatingNavReserve + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: <Widget>[
                _ProximosRecebimentos(projetos: projetos, hoje: hoje),
                for (int i = 0; i < projetos.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: Space.x3),
                  StaggerIn(
                    index: i.clamp(0, 4),
                    child: ProjetoCard(
                      projeto: projetos[i],
                      jaRecebeu: recebido[projetos[i].id] ?? 0,
                      selo: seloReserva(projetos[i], historico, hoje),
                      hoje: hoje,
                      onTap: () => context.push(
                        Routes.projetoDetalhe,
                        extra: projetos[i].id,
                      ),
                      onRecebi: () =>
                          registrarRecebimento(context, ref, projetos[i]),
                    ),
                  ),
                ],
                const SizedBox(height: Space.x4),
                OutlinedButton.icon(
                  onPressed: () => context.push(Routes.projetoForm),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo projeto'),
                ),
              ],
            ),
    );
  }
}

/// Abre a Reserva já sabendo de quem é o dinheiro. É o atalho de 2 toques que
/// faz o loop girar (07 §B.4): card → "Recebi" → reserva pré-preenchida.
void registrarRecebimento(
  BuildContext context,
  WidgetRef ref,
  Projeto projeto,
) {
  Haptics.select();
  context.push(Routes.reserva, extra: projeto.id);
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.x6,
          Space.x6,
          Space.x6,
          kFloatingNavReserve,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              Icons.folder_open_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: Space.x4),
            Text(
              'Seus projetos, num lugar só.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: Space.x3),
            Text(
              'Cliente fixo, freela avulso, aquele a cada 3 meses. Cadastre e '
              'nunca mais perca o fio de quem te paga quando — e de quanto é '
              'do imposto.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x6),
            FilledButton.icon(
              onPressed: () => context.push(Routes.projetoForm),
              icon: const Icon(Icons.add),
              label: const Text('Novo projeto'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Nos próximos 30 dias" (07 §B.5/§B.6) — a previsão de caixa com o imposto
/// já descontado. É o surface PRO: o power user com 10 projetos é exatamente
/// quem precisa dela, e quem paga por ela. No grátis mostramos a chamada com
/// o total real (o valor aparece ANTES do trabalho, regra anti-★1) e o
/// detalhe por cliente fica atrás da parede.
class _ProximosRecebimentos extends ConsumerWidget {
  const _ProximosRecebimentos({required this.projetos, required this.hoje});

  final List<Projeto> projetos;
  final DateTime hoje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<RecebimentoPrevisto> previstos = proximosRecebimentos(
      projetos,
      de: hoje,
    );
    if (previstos.isEmpty) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final bool isPro = ref.watch(proProvider);
    final ProfileState st = ref.watch(profileProvider);

    final double total = previstos.fold(
      0.0,
      (double s, RecebimentoPrevisto r) => s + r.valor,
    );
    // O imposto sai do MESMO motor da Reserva — a previsão não pode discordar
    // do número que a pessoa vê ao registrar o pagamento.
    final RegimeId regime = st is ProfileReady
        ? st.perfil.regime
        : RegimeId.mei;
    final double? taxa = st is ProfileReady
        ? computeValorHora(st.perfil).rate
        : null;
    final ReservaResult reservaTotal = computeReserva(
      total,
      regime,
      taxaEfetiva: taxa,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x4),
      child: PanelCard(
        padding: const EdgeInsets.all(Space.x5),
        accent: d.reserva,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.event_available_outlined,
                  size: 18,
                  color: d.reserva,
                ),
                const SizedBox(width: Space.x2),
                Text(
                  'NOS PRÓXIMOS 30 DIAS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x3),
            if (isPro)
              for (final RecebimentoPrevisto r in previstos)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.x2),
                  child: _linhaPrevisao(context, r, regime, taxa),
                ),
            const SizedBox(height: Space.x1),
            Text(
              'Total a receber: ${moneyBRL(total)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: AppType.numberFamily,
                fontFeatures: AppType.tnum,
              ),
            ),
            const SizedBox(height: Space.x1),
            Text(
              // No MEI o imposto do mês é um boleto fixo, não uma fatia de
              // cada pagamento — dizer "a reservar" sobre um percentual aqui
              // seria contradizer o que a Reserva ensina na outra tela.
              reservaTotal.isMei
                  ? 'Seu DAS do mês: ${moneyBRLCents(reservaTotal.dasMensal!)} — o resto é seu.'
                  : 'A reservar: ${moneyBRL(reservaTotal.reserva)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: d.reserva,
                fontFeatures: AppType.tnum,
              ),
            ),
            if (!isPro) ...<Widget>[
              const SizedBox(height: Space.x3),
              Text(
                'O Pro abre a previsão cliente por cliente: quem paga, quando, '
                'e quanto separar de cada um.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push(Routes.pro),
                  child: const Text('Ver o Pro'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _linhaPrevisao(
    BuildContext context,
    RecebimentoPrevisto r,
    RegimeId regime,
    double? taxa,
  ) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final ReservaResult res = computeReserva(
      r.valor,
      regime,
      taxaEfetiva: taxa,
    );
    final String quando = r.atrasado
        ? 'atrasado desde ${dataCurta(r.data, hoje: hoje)}'
        : dataCurta(r.data, hoje: hoje);

    return MergeSemantics(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${r.projeto.nome} · $quando',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: r.atrasado
                    ? d.onAlertaContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: Space.x2),
          Text(
            moneyBRL(r.valor),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFeatures: AppType.tnum,
            ),
          ),
          // O "reserve X" por linha só faz sentido quando o imposto é um
          // percentual do pagamento. No MEI ele é um boleto só do mês — repetir
          // o DAS inteiro em cada cliente somaria cinco vezes o mesmo imposto
          // na cabeça de quem lê.
          if (!res.isMei)
            Text(
              ' · reserve ${moneyBRL(res.reserva)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: d.reserva,
                fontFeatures: AppType.tnum,
              ),
            ),
        ],
      ),
    );
  }
}
