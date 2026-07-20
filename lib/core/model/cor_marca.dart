import 'dart:math' as math;
import 'dart:ui';

/// A cor de acento da marca do freelancer na proposta.
///
/// **A regra que protege o documento:** a cor entra só como ACENTO — a barra do
/// valor, o rótulo "PROPOSTA" — nunca como fundo de texto corrido. Assim
/// nenhuma escolha da pessoa consegue quebrar a legibilidade do que o cliente
/// dela vai ler.
///
/// E o texto que porventura fique POR CIMA da cor não é escolhido no chute: o
/// app calcula o contraste e decide entre preto e branco. Um roxo escuro pede
/// texto branco; um ocre pede preto. Fixar isso faria a proposta de quem
/// escolhe uma cor clara sair ilegível — e a pessoa não teria como saber por quê.
abstract final class CorMarca {
  /// O verde da casa. É o default e o que aparece pra quem nunca escolheu.
  static const int padrao = 0xFF007D54;

  /// Paleta curada — cores que funcionam como acento sobre papel branco e
  /// cobrem os nichos mais comuns (design, foto, dev, social, beleza).
  static const List<({String nome, int valor})> paleta =
      <({String nome, int valor})>[
        (nome: 'Verde', valor: padrao),
        (nome: 'Azul', valor: 0xFF1B5FA8),
        (nome: 'Roxo', valor: 0xFF6B3FA0),
        (nome: 'Magenta', valor: 0xFFB0247A),
        (nome: 'Vermelho', valor: 0xFFB3261E),
        (nome: 'Laranja', valor: 0xFFB35A00),
        (nome: 'Ocre', valor: 0xFF8A6D0B),
        (nome: 'Grafite', valor: 0xFF37474F),
      ];

  static const int _preto = 0xFF15201C;
  static const int _branco = 0xFFFFFFFF;

  /// Luminância relativa (WCAG 2.x).
  static double _luminancia(int argb) {
    double canal(int c) {
      final double s = c / 255.0;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4) as double;
    }

    return 0.2126 * canal((argb >> 16) & 0xFF) +
        0.7152 * canal((argb >> 8) & 0xFF) +
        0.0722 * canal(argb & 0xFF);
  }

  static double contraste(int a, int b) {
    final double la = _luminancia(a);
    final double lb = _luminancia(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Preto ou branco por cima de [fundo] — o que tiver mais contraste.
  static Color textoSobre(int fundo) =>
      contraste(fundo, _preto) >= contraste(fundo, _branco)
      ? const Color(_preto)
      : const Color(_branco);

  /// A cor tem contraste suficiente pra carregar texto por cima?
  ///
  /// Abaixo de 4.5:1 (WCAG AA) ela NÃO vira fundo de texto — a proposta cai
  /// pro layout com a cor só na barra de acento. É o que garante que nenhuma
  /// escolha produza um documento que o cliente não consegue ler.
  static bool serveComoFundo(int cor) =>
      contraste(cor, textoSobre(cor).toARGB32()) >= 4.5;
}
