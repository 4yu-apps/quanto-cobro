import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Título de **seção** — e é isso que ele faz de diferente de um `Text` em
/// caixa alta: ele vira uma parada na navegação por cabeçalhos do leitor de
/// tela.
///
/// Esse gesto (pular de cabeçalho em cabeçalho) é o "sumário" de quem não vê:
/// é assim que se varre uma tela longa sem ouvir tudo. Sem `header: true`, ele
/// não existe — e a pessoa é obrigada a passar item por item.
///
/// **Nem todo sobrolho é seção, e essa é a decisão que importa aqui.** O app
/// tem dois tipos de texto em caixa alta, e eles se parecem na tela e são
/// opostos na fala:
///
/// - **Seção** — "ENTRADAS", "ANOTAÇÕES", "COR DA SUA MARCA". Nomeia um bloco
///   de conteúdo, e é um lugar pra onde se PULA. Usa este widget.
/// - **Sobrancelha de valor** — "SEU VALOR-HORA", "COBRE POR HORA", "LUCRO
///   REAL", "NO COFRE ESTE MÊS". Não nomeia um bloco: é o nome do número que
///   está logo abaixo, e o número já carrega essa frase no próprio rótulo
///   semântico. Marcar isto como cabeçalho encheria o sumário de legendas de
///   número — ruído exatamente pra quem o sumário serve. **Deixa como `Text`.**
///
/// A grafia em caixa alta é decisão de tipografia e fica só na tela: o rótulo
/// falado vai no texto natural, porque alguns motores de TTS soletram palavras
/// curtas em maiúsculas ("A-N-O-T-A-Ç-Õ-E-S").
class SecaoTitulo extends StatelessWidget {
  const SecaoTitulo(this.texto, {super.key, this.bottom = Space.x2});

  /// Na grafia natural — quem põe em caixa alta é este widget.
  final String texto;

  final double bottom;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Semantics(
        header: true,
        label: texto,
        child: ExcludeSemantics(
          child: Text(
            texto.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
