import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// A "camada sonora" do app (auditoria Amara): anúncios de leitor de tela
/// centralizados. Todo momento que VIBRA ou ANIMA também FALA — o mapa de
/// haptics e o de announces são o mesmo mapa.
void announce(BuildContext context, String message) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}

/// Card pintado à mão que se comporta como BOTÃO no leitor de tela.
///
/// O par `Semantics(button:) + ExcludeSemantics` é o padrão da casa — um rótulo
/// que conta a história inteira, e nada embaixo pra ninguém ouvir duas vezes. E
/// ele tem uma armadilha silenciosa: o `ExcludeSemantics` apaga a semântica do
/// `InkWell` lá dentro, **inclusive a `SemanticsAction.tap`**. Sobra um nó com
/// `isButton: true` e nenhuma ação. Duas consequências:
///
/// 1. O `onTapHint` é descartado sem aviso — ele é um *override* de dica que só
///    se aplica se o nó tiver a ação correspondente. A frase que alguém escreveu
///    pra guiar a pessoa nunca é falada.
/// 2. A ponte Android deriva `AccessibilityNodeInfo.setClickable()` de
///    `hasAction(TAP)`. Sem a ação, o varredor do **Switch Access não oferece o
///    item** — quem tem deficiência motora não abre o card. Mesma coisa no
///    VoiceOver, cujo `accessibilityActivate` depende da ação.
///
/// No TalkBack puro isso funciona por acidente (quando o nó não é clicável, ele
/// dispara um toque bruto no centro) — e é por isso que passa despercebido.
///
/// Aqui a ação é **obrigatória por assinatura**: não dá pra esquecer.
class SemanticButton extends StatelessWidget {
  const SemanticButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.tapHint,
    this.selected,
    this.container = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  /// Descreve **o que acontece**, nunca **como fazer**. O leitor de tela já diz
  /// o gesto sozinho; escrever "toque duas vezes" faz ele falar duas vezes — e
  /// é instrução falsa pra quem usa Switch Access ou teclado.
  final String? tapHint;
  final bool? selected;
  final bool container;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    container: container,
    label: label,
    onTapHint: tapHint,
    selected: selected,
    onTap: onTap,
    child: ExcludeSemantics(child: child),
  );
}
