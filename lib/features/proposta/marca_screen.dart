import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/model/cor_marca.dart';
import '../../core/model/marca.dart';
import '../../core/providers.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/breakpoints.dart';
import '../../core/ui/money_field.dart';

/// "Sua marca — só uma vez" (07 §A.2/§F).
///
/// Aparece na PRIMEIRA proposta, nunca antes: pedir logo e contato a quem
/// ainda não viu o documento pronto é cobrar setup de quem não viu valor
/// (07 §D.7). Depois disso ela vive em Configurações.
class MarcaScreen extends ConsumerStatefulWidget {
  const MarcaScreen({super.key, this.primeiraVez = false});

  /// Muda só o tom: na 1ª vez a tela explica o porquê e o botão "continua" o
  /// fluxo da proposta; em Configurações ela é uma tela de edição comum.
  final bool primeiraVez;

  @override
  ConsumerState<MarcaScreen> createState() => _MarcaScreenState();
}

class _MarcaScreenState extends ConsumerState<MarcaScreen> {
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _whatsapp = TextEditingController();
  final TextEditingController _email = TextEditingController();
  String? _erroNome;
  String _ddi = '+55';
  late int _cor;

  @override
  void initState() {
    super.initState();
    final Marca m = ref.read(marcaProvider);
    _nome.text = m.nome;
    _whatsapp.text = formatarTelefone(m.whatsapp);
    _email.text = m.email;
    _ddi = m.ddi;
    _cor = m.cor;
  }

  @override
  void dispose() {
    _nome.dispose();
    _whatsapp.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _escolherLogo() async {
    try {
      final FilePickerResult? r = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      final String? path = r?.files.single.path;
      if (path == null) return;
      await ref.read(marcaProvider.notifier).setLogo(path);
      if (!mounted) return;
      announce(context, 'Logo escolhida.');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não consegui abrir essa imagem. Tenta outra?'),
          ),
        );
    }
  }

  /// Vibrar diz "algo aconteceu". Só a fala diz O QUÊ — e sem visão,
  /// "escolhi alguma coisa" não é "escolhi Roxo".
  void _escolherCor(({String nome, int valor}) c) {
    Haptics.select();
    setState(() => _cor = c.valor);
    announce(context, 'Cor ${c.nome} escolhida.');
  }

  Future<void> _salvar() async {
    final String nome = _nome.text.trim();
    if (nome.isEmpty) {
      const String msg = 'Preciso do seu nome pra assinar a proposta.';
      setState(() => _erroNome = msg);
      announce(context, msg);
      return;
    }
    Haptics.commit();
    await ref
        .read(marcaProvider.notifier)
        .save(
          ref
              .read(marcaProvider)
              .copyWith(
                nome: nome,
                ddi: _ddi,
                whatsapp: _whatsapp.text.replaceAll(RegExp(r'[^0-9]'), ''),
                email: _email.text.trim(),
                cor: _cor,
              ),
        );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Marca marca = ref.watch(marcaProvider);
    final String? logoPath = marca.logoPath;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.primeiraVez ? 'Sua marca — só uma vez' : 'Minha marca',
        ),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            Text(
              'Isso aparece no topo de toda proposta que você mandar. Capriche; '
              'dá pra mudar depois.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x6),
            TextField(
              controller: _nome,
              autofocus: widget.primeiraVez,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Seu nome ou do negócio',
                hintText: 'Ex.: Ana Ribeiro · Estúdio Corvo',
                errorText: _erroNome,
              ),
              onChanged: (_) {
                if (_erroNome != null) setState(() => _erroNome = null);
              },
            ),
            const SizedBox(height: Space.x4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 96dp fixos não cabem "🇵🇹 +351" nem com fonte normal: a
                // linha estourava 73px em TODA tela, e 185px com fonte 200%.
                // O seletor passa a pedir a largura que precisa e o campo do
                // telefone fica com o resto — que é o que ele sabe fazer.
                Flexible(
                  child: DropdownButtonFormField<String>(
                    initialValue: _ddi,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'País'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: '+55',
                        child: Text('🇧🇷 +55'),
                      ),
                      DropdownMenuItem<String>(
                        value: '+351',
                        child: Text('🇵🇹 +351'),
                      ),
                      DropdownMenuItem<String>(
                        value: '+1',
                        child: Text('🇺🇸 +1'),
                      ),
                      DropdownMenuItem<String>(
                        value: '+44',
                        child: Text('🇬🇧 +44'),
                      ),
                      DropdownMenuItem<String>(
                        value: '+34',
                        child: Text('🇪🇸 +34'),
                      ),
                    ],
                    onChanged: (String? v) {
                      if (v != null) setState(() => _ddi = v);
                    },
                  ),
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    inputFormatters: <TextInputFormatter>[_TelefoneFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp (opcional)',
                      hintText: '(44) 55555-5555',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.x4),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'E-mail (opcional)',
                // AVISA sem bloquear: travar quem digitou certo é pior que
                // deixar passar quem digitou errado.
                errorText: emailParecemValido(_email.text)
                    ? null
                    : 'Isso não parece um e-mail. Confere?',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.x6),

            Text(
              'COR DA SUA MARCA',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: Space.x1),
            Text(
              'Aparece como detalhe na proposta — no valor e no topo. O texto '
              'continua sempre legível, seja qual for a cor.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.x3),
            Wrap(
              spacing: Space.x3,
              runSpacing: Space.x3,
              children: <Widget>[
                for (final ({String nome, int valor}) c in CorMarca.paleta)
                  Semantics(
                    // Escolha de um-entre-N é RÁDIO, não botão: assim o leitor
                    // de tela anuncia "Roxo, marcado" e a posição no grupo, em
                    // vez de "Roxo, selecionado, botão".
                    inMutuallyExclusiveGroup: true,
                    checked: _cor == c.valor,
                    label: 'Cor ${c.nome}',
                    onTap: () => _escolherCor(c),
                    child: ExcludeSemantics(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => _escolherCor(c),
                        // Alvo de 48dp (a régua da casa e do Material); a joia
                        // continua com 44. 44 passa em WCAG 2.5.8 e reprova
                        // aqui — com 12dp entre eles, dedo grande em ônibus
                        // balançando erra de cor.
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Color(c.valor),
                                shape: BoxShape.circle,
                                // `outlineVariant` dá 1.41:1 contra o fundo
                                // escuro — e o tema padrão do app É o escuro.
                                // Com ele, "Grafite" (1.94:1) era um buraco
                                // preto sobre fundo preto, com contorno
                                // invisível: pra baixa visão, essa opção não
                                // existia. Azul, Roxo, Vermelho e Magenta
                                // ficavam abaixo de 3:1, reprovando em WCAG
                                // 1.4.11. `outline` dá 4.55:1 e é o que faz
                                // cada opção existir.
                                border: Border.all(
                                  color: _cor == c.valor
                                      ? cs.onSurface
                                      : cs.outline,
                                  width: _cor == c.valor ? 3 : 1.5,
                                ),
                              ),
                              child: _cor == c.valor
                                  ? Icon(
                                      Icons.check,
                                      size: 20,
                                      color: CorMarca.textoSobre(c.valor),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.x6),

            Text(
              'SUA LOGO (OPCIONAL)',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: Space.x3),
            if (logoPath != null && File(logoPath).existsSync())
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(Space.x2),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: const BorderRadius.all(Radii.md),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Image.file(
                      File(logoPath),
                      height: 48,
                      fit: BoxFit.contain,
                      // Imagem que some do disco não pode derrubar a tela.
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                      semanticLabel: 'Sua logo',
                    ),
                  ),
                  const SizedBox(width: Space.x4),
                  TextButton(
                    onPressed: _escolherLogo,
                    child: const Text('Trocar'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(marcaProvider.notifier).removerLogo(),
                    child: const Text('Tirar'),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _escolherLogo,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Escolher uma imagem'),
              ),

            const SizedBox(height: Space.x8),
            FilledButton(
              onPressed: _salvar,
              child: Text(widget.primeiraVez ? 'Pronto, continuar' : 'Salvar'),
            ),
            if (widget.primeiraVez) ...<Widget>[
              const SizedBox(height: Space.x2),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Agora não'),
              ),
            ],
            const SizedBox(height: Space.x4),
          ],
        ),
      ),
    );
  }
}

/// Máscara ao vivo do telefone brasileiro: `(44) 55555-5555`.
class _TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String d = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return const TextEditingValue();
    // 11 dígitos é o teto do celular BR — digitar além não deve virar lixo.
    final String limitado = d.length > 11 ? d.substring(0, 11) : d;
    final String texto = formatarTelefone(limitado);
    // `offset: texto.length` teleportava o cursor pro fim a cada tecla: errou
    // um dígito no meio do número, não dava pra corrigir. O cálculo já existia
    // no formatador de milhar; agora ele é compartilhado.
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(
        offset: offsetPreservandoDigitos(
          newValue.text,
          newValue.selection.baseOffset,
          texto,
        ),
      ),
    );
  }
}
