import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/routes.dart';
import '../../core/model/marca.dart';
import '../../core/model/projeto.dart';
import '../../core/model/proposta.dart';
import '../../core/proposta/proposta_pdf.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import 'proposta_papel.dart';

/// A pré-visualização — e a única parede Pro do fluxo (07 §A.5).
///
/// A pessoa monta a proposta inteira e VÊ o documento pronto de graça. A
/// parede só aparece na saída de alto valor (baixar/enviar o PDF), que é o
/// que respeita a regra anti-★1: o preço aparece depois de ela entender
/// exatamente o que compra, nunca depois de ela ter perdido o trabalho.
class PropostaPreviewScreen extends ConsumerStatefulWidget {
  const PropostaPreviewScreen({
    super.key,
    required this.proposta,
    this.projetoId,
  });

  final Proposta proposta;

  /// Quando a proposta nasceu de um projeto, não faz sentido oferecer
  /// "salvar como projeto" de novo.
  final String? projetoId;

  @override
  ConsumerState<PropostaPreviewScreen> createState() =>
      _PropostaPreviewScreenState();
}

class _PropostaPreviewScreenState extends ConsumerState<PropostaPreviewScreen> {
  late final DateTime _emitidaEm = DateTime.now();
  bool _gerando = false;

  Future<void> _enviar() async {
    if (!ref.read(proProvider)) {
      await _paredePro();
      return;
    }
    await _gerarECompartilhar();
  }

  Future<void> _paredePro() async {
    telemetry.evento(
      Evento.proParedeVista,
      params: <String, Object?>{'gatilho': GatilhoPro.propostaPdf},
    );
    final bool? verPro = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Enviar em PDF é Pro'),
        content: const Text(
          'Você já montou a proposta inteira — o Pro libera o envio com a sua '
          'marca, sem marca d’água.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ver o Pro'),
          ),
        ],
      ),
    );
    if (verPro != true || !mounted) return;

    await context.push(Routes.pro, extra: GatilhoPro.propostaPdf);
    // Virou Pro na volta? Então ela veio mandar a proposta — o app CONTINUA o
    // que ela pediu, sem exigir um segundo toque no mesmo botão. Quebrar a
    // promessa logo depois da compra é o pior lugar pra decepcionar.
    if (!mounted || !ref.read(proProvider)) return;
    announce(context, 'Pro ativado. Gerando sua proposta.');
    await _gerarECompartilhar();
  }

  Future<void> _gerarECompartilhar() async {
    setState(() => _gerando = true);
    try {
      final Marca marca = ref.read(marcaProvider);
      final Uint8List bytes = await gerarPropostaPdf(
        proposta: widget.proposta,
        marca: marca,
        emitidaEm: _emitidaEm,
      );

      final Directory dir = await getTemporaryDirectory();
      final String caminho = p.join(dir.path, _nomeDoArquivo());
      await File(caminho).writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      Haptics.commit();
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(caminho, mimeType: 'application/pdf')],
          subject: 'Proposta — ${widget.proposta.servico}',
        ),
      );

      if (!mounted) return;
      announce(context, 'Pronto. Isso tem cara de profissional.');
      await _oferecerSalvarComoProjeto();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não consegui gerar o PDF agora. Tenta de novo?'),
          ),
        );
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  /// O nome do arquivo é a primeira coisa que o CLIENTE vê no WhatsApp — um
  /// "documento.pdf" genérico desfaz metade do capricho do documento.
  String _nomeDoArquivo() {
    final String bruto = widget.proposta.servico.trim().isEmpty
        ? 'Proposta'
        : 'Proposta - ${widget.proposta.servico.trim()}';
    final String limpo = bruto
        .replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${limpo.length > 60 ? limpo.substring(0, 60).trim() : limpo}.pdf';
  }

  /// O nascimento do projeto (07 §C): a proposta que saiu vira algo que a
  /// pessoa acompanha, sem redigitar nada. Só é oferecido quando ela ainda não
  /// veio de um projeto.
  Future<void> _oferecerSalvarComoProjeto() async {
    if (widget.projetoId != null) return;

    final bool? salvar = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('Proposta enviada'),
        content: const Text('Quer acompanhar como projeto?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Salvar como projeto'),
          ),
        ],
      ),
    );
    if (salvar != true || !mounted) return;

    final Projeto projeto = Projeto(
      id: 'pj_${DateTime.now().microsecondsSinceEpoch}',
      nome: widget.proposta.servico.trim().isEmpty
          ? 'Novo projeto'
          : widget.proposta.servico.trim(),
      cliente: widget.proposta.cliente.trim().isEmpty
          ? null
          : widget.proposta.cliente.trim(),
      valor: widget.proposta.valor,
      recorrencia: Recorrencia.avulso,
      // Proposta enviada ≠ trabalho fechado. Ele nasce em Orçamento e só vira
      // Ativo quando o cliente aceita (ou quando o primeiro "Recebi" prova
      // que aceitou).
      status: ProjetoStatus.orcamento,
      criadoEm: DateTime.now(),
      perfilId: ref.read(profilesProvider).activeId,
    );
    await ref.read(projetosProvider.notifier).save(projeto);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"${projeto.nome}" está nos seus projetos'),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () =>
                context.push(Routes.projetoDetalhe, extra: projeto.id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Marca marca = ref.watch(marcaProvider);
    final bool isPro = ref.watch(proProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Como o cliente vai ver')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.x4,
          Space.x4,
          Space.x4,
          Space.x6,
        ),
        children: <Widget>[
          PropostaPapel(
            proposta: widget.proposta,
            marca: marca,
            emitidaEm: _emitidaEm,
          ),
          const SizedBox(height: Space.x4),
          Row(
            children: <Widget>[
              Icon(
                Icons.lock_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Space.x2),
              Expanded(
                child: Text(
                  'Seu cliente vê só isso. A Divisão, a reserva e o imposto '
                  'ficam com você.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          Space.x4,
          Space.x2,
          Space.x4,
          Space.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _gerando ? null : _enviar,
              icon: _gerando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share),
              label: Text(_gerando ? 'Gerando…' : 'Enviar / Baixar PDF'),
            ),
            if (!isPro) ...<Widget>[
              const SizedBox(height: Space.x2),
              Text(
                'Montar e ver é grátis. Enviar em PDF é Pro.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
