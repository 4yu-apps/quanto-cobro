import 'package:flutter/material.dart';

import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/model/projeto.dart';
import '../../core/projetos/agenda.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/panel_card.dart';

/// O card de um projeto na lista (07 §B.3): nome · status · valor · próximo
/// recebimento · quanto já recebeu · selo da reserva. Nada de barra de
/// progresso, tarefa ou responsável — se um campo não responde "quanto vem,
/// quando, quanto é imposto?", ele não entra aqui.
class ProjetoCard extends StatelessWidget {
  const ProjetoCard({
    super.key,
    required this.projeto,
    required this.jaRecebeu,
    required this.selo,
    required this.onTap,
    required this.onRecebi,
    this.hoje,
  });

  final Projeto projeto;
  final double jaRecebeu;
  final SeloReserva selo;
  final VoidCallback onTap;
  final VoidCallback onRecebi;
  final DateTime? hoje;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final DateTime agora = hoje ?? DateTime.now();
    final DateTime? proximo = projeto.proximoRecebimento;
    final bool atrasado =
        proximo != null &&
        projeto.status.esperaRecebimento &&
        proximo.isBefore(DateTime(agora.year, agora.month, agora.day));

    // O resumo do projeto é UM alvo de leitor de tela, com a frase pronta —
    // seis fragmentos soltos ("Ativo", "R$ 2.000", "10/ago") obrigariam a
    // pessoa a remontar o sentido de cabeça. O "Recebi" fica FORA dessa
    // fusão: é a ação recorrente da tela e precisa ser alcançável sozinha.
    final Widget resumo = Semantics(
      button: true,
      label: _semantica(agora),
      onTapHint: 'abrir o projeto',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        projeto.nome,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Space.x1),
                      Text(
                        '${projeto.status.label} · ${projeto.recorrenciaLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.x3),
                Text(
                  moneyBRL(projeto.valor),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: AppType.numberFamily,
                    fontFeatures: AppType.tnum,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x3),
            Wrap(
              spacing: Space.x4,
              runSpacing: Space.x1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (proximo != null)
                  _linha(
                    context,
                    atrasado ? Icons.error_outline : Icons.event_outlined,
                    atrasado
                        ? 'Era ${dataCurta(proximo, hoje: agora)}'
                        : 'Próximo: ${dataCurta(proximo, hoje: agora)}',
                    atrasado ? d.onAlertaContainer : cs.onSurfaceVariant,
                  ),
                if (jaRecebeu > 0)
                  _linha(
                    context,
                    Icons.check_circle_outline,
                    'Já recebeu ${moneyBRL(jaRecebeu)}',
                    cs.onSurfaceVariant,
                  ),
                if (selo != SeloReserva.nenhum)
                  _linha(
                    context,
                    selo == SeloReserva.emDia
                        ? Icons.lock_outline
                        : Icons.savings_outlined,
                    selo == SeloReserva.emDia
                        ? 'imposto separado'
                        : 'falta separar',
                    selo == SeloReserva.emDia ? d.reserva : d.onAlertaContainer,
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    return PanelCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.x4,
                  Space.x4,
                  Space.x4,
                  Space.x3,
                ),
                child: resumo,
              ),
            ),
          ),
          if (projeto.status.esperaRecebimento)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.x4,
                0,
                Space.x4,
                Space.x4,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: onRecebi,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Recebi'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _linha(BuildContext context, IconData icon, String texto, Color cor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: cor),
        const SizedBox(width: Space.x1),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cor,
            fontFeatures: AppType.tnum,
          ),
        ),
      ],
    );
  }

  String _semantica(DateTime agora) {
    final StringBuffer sb = StringBuffer()
      ..write('${projeto.nome}. ${projeto.status.label}, ')
      ..write('${projeto.recorrenciaLabel.toLowerCase()}, ')
      ..write('${moneyBRL(projeto.valor)}. ');
    final DateTime? proximo = projeto.proximoRecebimento;
    if (proximo != null) {
      final bool atrasado = proximo.isBefore(
        DateTime(agora.year, agora.month, agora.day),
      );
      sb.write(
        atrasado
            ? 'Recebimento atrasado desde ${dataPorExtenso(proximo)}. '
            : 'Próximo recebimento em ${dataPorExtenso(proximo)}. ',
      );
    }
    if (jaRecebeu > 0) sb.write('Já recebeu ${moneyBRL(jaRecebeu)}. ');
    if (selo == SeloReserva.emDia) {
      sb.write('Imposto deste mês já separado.');
    } else if (selo == SeloReserva.faltaSeparar) {
      sb.write('Falta separar a reserva.');
    }
    return sb.toString();
  }
}
