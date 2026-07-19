import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/marca.dart';
import 'package:quantocobro/core/model/proposta.dart';
import 'package:quantocobro/core/proposta/proposta_pdf.dart';

/// Um PDF não se testa por pixel — se testa por "gerou, abre e não vazou".
/// Aqui: bytes válidos, e nenhuma das entradas que na vida real chegam
/// pela metade (sem logo, logo apagada, campos vazios) derruba a geração.
void main() {
  // rootBundle (as fontes embarcadas) precisa do binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  final DateTime emitidaEm = DateTime(2026, 7, 19);

  const Proposta completa = Proposta(
    servico: 'Identidade visual completa',
    descricao: 'Logo, paleta de cores e manual de marca em PDF.',
    valor: 3500,
    prazo: '15 dias úteis',
    formaPagamento: Proposta.kFormaPagamentoPadrao,
    cliente: 'Padaria São José',
    observacoes: 'Inclui duas rodadas de ajuste.',
  );

  bool ehPdf(Uint8List bytes) =>
      bytes.length > 4 && String.fromCharCodes(bytes.sublist(0, 4)) == '%PDF';

  test('gera bytes de PDF válidos', () async {
    final Uint8List bytes = await gerarPropostaPdf(
      proposta: completa,
      marca: const Marca(nome: 'Estúdio Lira', contato: '(11) 90000-0000'),
      emitidaEm: emitidaEm,
    );

    expect(bytes, isNotEmpty);
    expect(ehPdf(bytes), isTrue);
  });

  test('marca sem logo gera normalmente', () async {
    final Uint8List bytes = await gerarPropostaPdf(
      proposta: completa,
      marca: const Marca(nome: 'Estúdio Lira'),
      emitidaEm: emitidaEm,
    );

    expect(ehPdf(bytes), isTrue);
  });

  test('logoPath apontando pra arquivo inexistente não quebra', () async {
    final Uint8List bytes = await gerarPropostaPdf(
      proposta: completa,
      marca: const Marca(
        nome: 'Estúdio Lira',
        logoPath: '/tmp/nao-existe-logo-quanto-cobro.png',
      ),
      emitidaEm: emitidaEm,
    );

    expect(ehPdf(bytes), isTrue);
  });

  test('arquivo de logo corrompido cai no nome, sem estourar', () async {
    final Directory dir = Directory.systemTemp.createTempSync('qc_logo');
    addTearDown(() => dir.deleteSync(recursive: true));
    final File lixo = File('${dir.path}/logo.png')
      ..writeAsBytesSync(<int>[1, 2, 3, 4, 5]);

    final Uint8List bytes = await gerarPropostaPdf(
      proposta: completa,
      marca: Marca(nome: 'Estúdio Lira', logoPath: lixo.path),
      emitidaEm: emitidaEm,
    );

    expect(ehPdf(bytes), isTrue);
  });

  test('campos opcionais vazios geram normalmente', () async {
    final Uint8List bytes = await gerarPropostaPdf(
      proposta: const Proposta(
        servico: 'Consultoria',
        valor: 1200,
        formaPagamento: '',
      ),
      marca: const Marca(nome: 'Ana Freela'),
      emitidaEm: emitidaEm,
    );

    expect(ehPdf(bytes), isTrue);
  });

  test('marca vazia (sem nome nem contato) ainda gera', () async {
    final Uint8List bytes = await gerarPropostaPdf(
      proposta: completa,
      marca: const Marca(),
      emitidaEm: emitidaEm,
    );

    expect(ehPdf(bytes), isTrue);
  });

  test('mostrarHoras: false é o caminho normal e funciona', () async {
    final Uint8List bytes = await gerarPropostaPdf(
      proposta: completa.copyWith(horas: 40, valorHora: 92),
      marca: const Marca(nome: 'Estúdio Lira'),
      emitidaEm: emitidaEm,
    );

    expect(completa.temDetalheHoras, isFalse);
    expect(ehPdf(bytes), isTrue);
  });

  test('mostrarHoras: true renderiza o detalhamento sem quebrar', () async {
    final Proposta comHoras = completa.copyWith(
      mostrarHoras: true,
      horas: 40,
      valorHora: 92,
    );

    expect(comHoras.temDetalheHoras, isTrue);
    expect(
      ehPdf(
        await gerarPropostaPdf(
          proposta: comHoras,
          marca: const Marca(nome: 'Estúdio Lira'),
          emitidaEm: emitidaEm,
        ),
      ),
      isTrue,
    );
  });

  test('texto longo pagina em vez de estourar', () async {
    final String longo = List<String>.filled(
      120,
      'Descrição detalhada do escopo acordado com o cliente.',
    ).join(' ');

    final Uint8List bytes = await gerarPropostaPdf(
      proposta: completa.copyWith(descricao: longo, observacoes: longo),
      marca: const Marca(nome: 'Estúdio Lira'),
      emitidaEm: emitidaEm,
    );

    expect(ehPdf(bytes), isTrue);
  });
}
