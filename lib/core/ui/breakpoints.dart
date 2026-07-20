import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// A única régua de largura do app.
///
/// **A regra da casa: nenhuma tela lê `MediaQuery.sizeOf` direto.** Todas leem
/// `WindowClass.of(context)`. É o mesmo espírito do `announce()` centralizado —
/// a decisão mora num lugar só, e quando ela mudar, muda num lugar só. Largura
/// espalhada em quinze arquivos vira quinze breakpoints diferentes em três
/// meses, e ninguém consegue mais dizer como o app se comporta em 700dp.
///
/// Os cortes são os *window size classes* do Material 3, e são deles de
/// propósito: o Flutter, o Android e a Play Console já falam essa língua.
///
/// E o que manda é a **largura disponível**, nunca o dispositivo. "Tablet" não
/// é uma coisa só — um tablet em pé se parece mais com um celular grande do que
/// com ele mesmo deitado. Um celular deitado (640×360) é `medium`, e é bom que
/// seja: ali a tela é larga e BAIXA, e o layout que serve tablet em pé é
/// exatamente o que salva o celular deitado.
enum WindowClass {
  /// < 600dp — celular em pé. O layout de origem do app.
  compact,

  /// 600–839dp — tablet pequeno em pé, dobrável aberto, **celular deitado**.
  medium,

  /// >= 840dp — tablet deitado, tablet grande em pé, janela livre no desktop.
  expanded;

  static const double _mediumAt = 600;
  static const double _expandedAt = 840;

  static WindowClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static WindowClass fromWidth(double width) {
    if (width >= _expandedAt) return WindowClass.expanded;
    if (width >= _mediumAt) return WindowClass.medium;
    return WindowClass.compact;
  }

  /// Atalho pros dois casos que quase toda tela quer distinguir: "sou celular
  /// em pé" versus "tenho largura sobrando".
  bool get isCompact => this == WindowClass.compact;
  bool get isExpanded => this == WindowClass.expanded;

  /// De `medium` pra cima a navegação vira trilho lateral, e a barra de baixo
  /// (com os 88dp de reserva que ela cobra) deixa de existir.
  bool get usaTrilho => this != WindowClass.compact;
}

/// Quanto de rodapé a aba precisa reservar pro conteúdo não sumir sob a
/// navegação.
///
/// Com a barra de baixo, é a pílula (`kFloatingNavReserve`) mais o inset do
/// sistema. Com o **trilho**, a navegação saiu do rodapé — reservar 88dp ali
/// vira 88dp de vazio, e no celular deitado isso é um quarto da tela. Toda aba
/// usa isto no lugar da constante crua.
double reservaDaNavbar(BuildContext context) =>
    WindowClass.of(context).usaTrilho
    ? 0
    : kFloatingNavReserve + MediaQuery.viewPaddingOf(context).bottom;

/// Largura máxima de leitura, em dp.
///
/// Texto que atravessa 1000dp não se lê: o olho perde a linha na volta. Este é
/// o teto de uma coluna de conteúdo — o fundo (a aurora do Início, o vidro)
/// continua sangrando até a borda, porque fundo não se lê.
const double kMaxContentWidth = 600;

/// Clampa o conteúdo em [kMaxContentWidth] e centra. Uma linha por tela, e é o
/// que separa "esticado" de "desenhado".
///
/// Não faz nada em `compact` — lá a largura já é menor que o teto, e envolver
/// por envolver só adiciona um nó na árvore.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth});

  final Widget child;

  /// Só passe se esta tela tiver um motivo próprio. O default é a régua da
  /// casa, e o default é quase sempre o certo.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? kMaxContentWidth),
      child: child,
    ),
  );
}
