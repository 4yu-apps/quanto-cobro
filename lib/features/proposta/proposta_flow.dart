import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/model/marca.dart';
import '../../core/model/proposta.dart';
import '../../core/providers.dart';

/// O que a rota da proposta recebe: o rascunho já preenchido e, quando ela
/// nasceu de um trabalho, de qual trabalho veio (pra não oferecer "salvar como
/// trabalho" o que já É um trabalho).
class PropostaArgs {
  const PropostaArgs({required this.inicial, this.trabalhoId});

  final Proposta inicial;
  final String? trabalhoId;
}

/// Porta de entrada única da proposta (07 §A.2). A proposta é uma AÇÃO, não
/// uma aba: ela empilha acima da casca, sempre logo depois de a pessoa validar
/// um preço — que é o momento psicológico em que "então manda pro cliente" é a
/// pergunta natural.
///
/// O setup de marca é cobrado aqui, na primeira vez, e não antes: quem ainda
/// não viu o documento pronto não tem motivo pra procurar a logo (07 §D.7).
Future<void> abrirProposta(
  BuildContext context,
  WidgetRef ref, {
  required Proposta inicial,
  String? trabalhoId,
}) async {
  final Marca marca = ref.read(marcaProvider);

  if (!marca.pronta) {
    final bool? seguiu = await context.push<bool>(Routes.marca, extra: true);
    // "Agora não" não é erro: a pessoa pode só estar espiando. Sai em silêncio,
    // sem sermão, e a proposta continua ali quando ela voltar.
    if (seguiu != true || !context.mounted) return;
  }
  if (!context.mounted) return;

  await context.push(
    Routes.proposta,
    extra: PropostaArgs(inicial: inicial, trabalhoId: trabalhoId),
  );
}
