import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/model/marca.dart';
import '../../core/providers.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';

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
  final TextEditingController _contato = TextEditingController();
  String? _erroNome;

  @override
  void initState() {
    super.initState();
    final Marca m = ref.read(marcaProvider);
    _nome.text = m.nome;
    _contato.text = m.contato;
  }

  @override
  void dispose() {
    _nome.dispose();
    _contato.dispose();
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
              .copyWith(nome: nome, contato: _contato.text.trim()),
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
      body: ListView(
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
          TextField(
            controller: _contato,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Contato (WhatsApp ou e-mail)',
              hintText: 'O que você quer que o cliente use',
            ),
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
    );
  }
}
