import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/data/area_repository.dart';
import '../../core/data/entrada_repository.dart';
import '../../core/data/trabalho_repository.dart';
import '../../core/model/area.dart';
import '../../core/model/entrada.dart';
import '../../core/model/trabalho.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/panel_card.dart';
import '../../core/ui/breakpoints.dart';
import 'trabalho_detalhe_screen.dart';

/// Aba **Trabalhos** — os freelas da pessoa.
///
/// A hierarquia é LATENTE: com uma área só, a palavra "área" não aparece em
/// lugar nenhum e a lista é plana. O nível de cima só se revela pra quem tem a
/// segunda — que é o power user, e o único que precisa dele.
class TrabalhosScreen extends ConsumerStatefulWidget {
  const TrabalhosScreen({super.key});

  @override
  ConsumerState<TrabalhosScreen> createState() => _TrabalhosScreenState();
}

class _TrabalhosScreenState extends ConsumerState<TrabalhosScreen> {
  /// O trabalho aberto no painel direito. Só existe em tela larga — no celular
  /// tocar num card continua empilhando a tela, como sempre.
  String? _selecionado;

  @override
  Widget build(BuildContext context) {
    final AreasData areas = ref.watch(areasProvider);
    final List<Trabalho> todos = ref.watch(trabalhosProvider);
    final List<Entrada> entradas = ref.watch(entradasProvider);

    final Map<String, double> recebido = recebidoPorTrabalho(entradas);
    final Map<String, DateTime> ultima = ultimaEntradaPorTrabalho(entradas);
    final List<Trabalho> ordenados = ordenarTrabalhos(todos, ultima);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus trabalhos'),
        actions: <Widget>[
          if (ordenados.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Novo trabalho',
              onPressed: () => context.push(Routes.trabalhoForm),
            ),
        ],
      ),
      body: mestreDetalhe
          ? _mestreDetalhe(context, areas, ordenados, recebido, ultima)
          : ContentWidth(
              child: _lista(context, areas, ordenados, recebido, ultima),
            ),
    );
  }

  /// Lista à esquerda, trabalho aberto à direita — o padrão que o tablet
  /// inventou, e o ganho real da tela larga: tocar num trabalho deixa de fazer
  /// a tela inteira dar um pulo.
  ///
  /// Substituiu a grade de duas colunas que existia aqui. A grade era o plano
  /// B do §4.4 do plano ("se o mestre-detalhe custar caro, corta e fica só a
  /// grade") — não custou, e as duas juntas não fazem sentido: com a lista
  /// ocupando 380dp, duas colunas de card virariam duas tiras de 180dp.
  Widget _mestreDetalhe(
    BuildContext context,
    AreasData areas,
    List<Trabalho> ordenados,
    Map<String, double> recebido,
    Map<String, DateTime> ultima,
  ) {
    // O selecionado pode ter sido apagado no painel — sem isto o painel fica
    // preso num id que não existe mais.
    final bool valido =
        _selecionado != null &&
        ordenados.any((Trabalho t) => t.id == _selecionado);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          width: 380,
          child: ordenados.isEmpty
              ? const _Vazio()
              : _lista(context, areas, ordenados, recebido, ultima),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: valido
              ? TrabalhoDetalheScreen.painel(
                  key: ValueKey<String>(_selecionado!),
                  trabalhoId: _selecionado!,
                )
              : _PainelVazio(temTrabalhos: ordenados.isNotEmpty),
        ),
      ],
    );
  }

  Widget _lista(
    BuildContext context,
    AreasData areas,
    List<Trabalho> ordenados,
    Map<String, double> recebido,
    Map<String, DateTime> ultima,
  ) {
    return ordenados.isEmpty
        ? const _Vazio()
        : ListView(
            padding: EdgeInsets.fromLTRB(
              Space.x4,
              Space.x4,
              Space.x4,
              reservaDaNavbar(context),
            ),
            children: <Widget>[
              if (areas.hierarquiaVisivel)
                ..._porArea(context, ref, areas, ordenados, recebido, ultima)
              else
                ..._planos(context, ordenados, recebido, ultima),
              const SizedBox(height: Space.x4),
              OutlinedButton.icon(
                onPressed: () => context.push(Routes.trabalhoForm),
                icon: const Icon(Icons.add),
                label: const Text('Novo trabalho'),
              ),
            ],
          );
  }

  /// Lista plana — o caso de 99% das pessoas.
  List<Widget> _planos(
    BuildContext context,
    List<Trabalho> trabalhos,
    Map<String, double> recebido,
    Map<String, DateTime> ultima,
  ) => <Widget>[
    for (int i = 0; i < trabalhos.length; i++) ...<Widget>[
      if (i > 0) const SizedBox(height: Space.x3),
      StaggerIn(
        index: i.clamp(0, 4),
        child: _TrabalhoCard(
          trabalho: trabalhos[i],
          recebido: recebido[trabalhos[i].id] ?? 0,
          ultima: ultima[trabalhos[i].id],
          // No mestre-detalhe tocar SELECIONA (o painel troca ao lado); no
          // celular continua empilhando a tela.
          selecionado: mestreDetalhe && trabalhos[i].id == _selecionado,
          onSelecionar: mestreDetalhe
              ? () => setState(() => _selecionado = trabalhos[i].id)
              : null,
        ),
      ),
    ],
  ];

  bool get mestreDetalhe => WindowClass.of(context).isExpanded;

  /// Agrupado por área — só pra quem tem mais de uma.
  List<Widget> _porArea(
    BuildContext context,
    WidgetRef ref,
    AreasData areas,
    List<Trabalho> trabalhos,
    Map<String, double> recebido,
    Map<String, DateTime> ultima,
  ) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> out = <Widget>[];
    for (final Area area in areas.areas) {
      final List<Trabalho> daArea = trabalhos
          .where((Trabalho t) => t.areaId == area.id)
          .toList();
      if (daArea.isEmpty) continue;
      out
        ..add(_cabecalhoDeGrupo(theme, area.nome, daArea.length))
        ..addAll(_planos(context, daArea, recebido, ultima));
      out.add(const SizedBox(height: Space.x4));
    }
    // Trabalho cuja área foi apagada não pode sumir da tela em silêncio.
    final Set<String> conhecidas = areas.areas.map((Area a) => a.id).toSet();
    final List<Trabalho> orfaos = trabalhos
        .where((Trabalho t) => !conhecidas.contains(t.areaId))
        .toList();
    if (orfaos.isNotEmpty) {
      out
        ..add(_cabecalhoDeGrupo(theme, 'Sem área', orfaos.length, area: false))
        ..addAll(_planos(context, orfaos, recebido, ultima));
    }
    return out;
  }

  /// O cabeçalho de grupo — e ele precisa SER um cabeçalho.
  ///
  /// A hierarquia latente (só aparece com 2+ áreas) é uma boa ideia, mas tinha
  /// sido implementada só no canal visual: caixa alta, cinza, menor,
  /// `letterSpacing`. Todos esses sinais são TIPOGRÁFICOS. Na árvore de
  /// semântica isto era um `Text` como outro qualquer, então:
  ///
  /// - não dava pra pular de grupo em grupo (o gesto de navegar por cabeçalhos
  ///   é *o* jeito de varrer uma lista longa sem visão);
  /// - "DESIGN" é ambíguo — pode ser um trabalho chamado Design. A palavra
  ///   "área" não era falada em lugar nenhum;
  /// - caixa alta é armadilha à parte: alguns motores de TTS soletram palavras
  ///   curtas em maiúsculas ("D-E-S-I-G-N"). O visual em caixa alta é decisão
  ///   de tipografia; o rótulo vai na grafia natural.
  ///
  /// A contagem é o que substitui, na fala, o "bater o olho e ver que são
  /// três" — sem ela a pessoa varre o grupo inteiro só pra saber o tamanho.
  static Widget _cabecalhoDeGrupo(
    ThemeData theme,
    String nome,
    int quantos, {
    bool area = true,
  }) => Padding(
    padding: const EdgeInsets.only(top: Space.x2, bottom: Space.x2),
    child: Semantics(
      header: true,
      label:
          '${area ? 'Área $nome' : nome}. '
          '$quantos ${quantos == 1 ? 'trabalho' : 'trabalhos'}.',
      child: ExcludeSemantics(
        child: Text(
          nome.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ),
  );
}

class _TrabalhoCard extends StatelessWidget {
  const _TrabalhoCard({
    required this.trabalho,
    required this.recebido,
    required this.ultima,
    this.selecionado = false,
    this.onSelecionar,
  });

  final Trabalho trabalho;
  final double recebido;
  final DateTime? ultima;

  /// Aberto no painel ao lado — só existe no mestre-detalhe.
  final bool selecionado;

  /// Quando presente, tocar SELECIONA em vez de empilhar a tela.
  final VoidCallback? onSelecionar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;

    void abrir() {
      if (onSelecionar != null) {
        onSelecionar!();
      } else {
        context.push(Routes.trabalhoDetalhe, extra: trabalho.id);
      }
    }

    return SemanticButton(
      label: _semantica(),
      tapHint: onSelecionar == null ? 'abrir o trabalho' : 'abrir ao lado',
      // No mestre-detalhe o card é uma ESCOLHA de um-entre-N, e o leitor de
      // tela precisa saber qual está aberto — senão a pessoa não tem como
      // descobrir o que o painel ao lado está mostrando.
      selected: onSelecionar == null ? null : selecionado,
      onTap: abrir,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: abrir,
          borderRadius: const BorderRadius.all(Radii.lg),
          child: PanelCard(
            selecionado: selecionado,
            padding: const EdgeInsets.all(Space.x4),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        trabalho.nome,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: trabalho.encerrado
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Space.x1),
                      Text(
                        _linhaApoio(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.x3),
                // O dinheiro encolhe, nunca vaza. Sem isto o Row estourava
                // 45px em fonte 200% — e o que saía da tela era justamente o
                // valor recebido, que é a razão do card existir.
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          moneyBRL(recebido),
                          maxLines: 1,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: AppType.numberFamily,
                            fontFeatures: AppType.tnum,
                            color: recebido > 0 ? d.lucro : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        'recebido',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _linhaApoio() {
    if (trabalho.encerrado) return 'Encerrado';
    final DateTime? u = ultima;
    if (u == null) return 'Nenhuma entrada ainda';
    return 'Última entrada em ${dataCurta(u)}';
  }

  String _semantica() {
    final StringBuffer sb = StringBuffer(trabalho.nome)..write('. ');
    if (recebido > 0) {
      sb.write('Recebido ${moneyBRL(recebido)}. ');
    } else {
      sb.write('Nenhuma entrada ainda. ');
    }
    final DateTime? u = ultima;
    if (u != null) sb.write('Última entrada em ${dataPorExtenso(u)}. ');
    if (trabalho.encerrado) sb.write('Encerrado.');
    return sb.toString();
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Space.x6,
          Space.x6,
          Space.x6,
          reservaDaNavbar(context),
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
              'Seus trabalhos, num lugar só.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: Space.x3),
            Text(
              'Quando um pagamento cair, registre e diga de quem veio. O '
              'trabalho aparece aqui sozinho, com tudo que já entrou.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x6),
            FilledButton.icon(
              onPressed: () => context.push(Routes.entrada),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Registrar um pagamento'),
            ),
            const SizedBox(height: Space.x2),
            TextButton(
              onPressed: () => context.push(Routes.trabalhoForm),
              child: const Text('Ou cadastrar um trabalho'),
            ),
          ],
        ),
      ),
    );
  }
}

/// O painel direito antes de a pessoa escolher um trabalho.
///
/// Uma tela larga com metade em branco parece defeito. Dizer o que fazer ali
/// custa uma frase e resolve.
class _PainelVazio extends StatelessWidget {
  const _PainelVazio({required this.temTrabalhos});

  final bool temTrabalhos;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.work_outline,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: Space.x3),
            Text(
              temTrabalhos
                  ? 'Escolha um trabalho pra ver os pagamentos dele aqui.'
                  : 'Registre uma entrada e diga de quem veio. O trabalho '
                        'aparece aqui sozinho.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
