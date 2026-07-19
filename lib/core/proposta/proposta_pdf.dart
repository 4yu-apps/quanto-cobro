import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../common/datas.dart';
import '../common/money.dart';
import '../model/marca.dart';
import '../model/proposta.dart';

/// O PDF da proposta comercial (07 §A.4): UM template, A4, sóbrio — não uma
/// galeria.
///
/// O que este arquivo NÃO imprime é a parte importante (07 §A.6): divisão,
/// reserva, imposto, custo e lucro não têm uma linha de código aqui. O
/// documento é do CLIENTE; esses números são a cozinha do freelancer e, na mão
/// de quem compra, viram munição de pechincha. Se um dia alguém for adicionar
/// "detalhamento de custos" neste layout, a resposta é não.
///
/// Sem marca d'água e sem citar o app (07 §A.5): a proposta sai com a marca
/// DELE. Um "feito com Quanto Cobro?" envergonharia justamente quem a feature
/// deveria fazer parecer profissional.
Future<Uint8List> gerarPropostaPdf({
  required Proposta proposta,
  required Marca marca,
  required DateTime emitidaEm,
}) async {
  final _Fontes fontes = await _carregarFontes();
  final String nomeMarca = marca.nome.trim();

  final pw.Document doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: fontes.regular,
      bold: fontes.semiBold,
    ).copyWith(defaultTextStyle: _corpo(fontes)),
    title: 'Proposta — ${proposta.servico.trim()}',
    // Autoria do documento é do freelancer, não nossa (07 §A.5).
    author: nomeMarca.isEmpty ? null : nomeMarca,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 44),
      // Rodapé em toda página: em proposta de 2+ páginas, a validade precisa
      // aparecer na folha que o cliente tem na mão, não só na primeira.
      footer: (pw.Context context) => _rodape(fontes, proposta, emitidaEm),
      build: (pw.Context context) => _corpoDoDocumento(fontes, proposta, marca),
    ),
  );

  return doc.save();
}

// ---------------------------------------------------------------------------
// Paleta de papel
// ---------------------------------------------------------------------------

/// A identidade do app adaptada pro papel: no branco, os cinzas de tela ficam
/// lavados e o esmeralda cheio vira neon na impressora. Tinta quase-preta pro
/// texto, esmeralda só como acento fino, e nada de fundo escuro (gasta tinta
/// de quem imprime a proposta pra assinar).
const PdfColor _tinta = PdfColor.fromInt(0xFF15201C);
const PdfColor _tintaSuave = PdfColor.fromInt(0xFF6A736F);
const PdfColor _linha = PdfColor.fromInt(0xFFDDE3E0);
const PdfColor _acento = PdfColor.fromInt(0xFF007D54); // BrandColors.verdeJusto
const PdfColor _fundoValor = PdfColor.fromInt(0xFFF3F7F5);

// Ritmo vertical espelhando tokens.dart (Space.x2/x4/x6/x8) em pontos.
const double _x2 = 8;
const double _x3 = 12;
const double _x4 = 16;
const double _x6 = 24;
const double _x8 = 32;

// ---------------------------------------------------------------------------
// Tipografia
// ---------------------------------------------------------------------------

/// Fontes embarcadas do próprio app. Helvetica (a default do PDF) usa
/// WinAnsi e já mordeu acentuação pt-BR — "Serviço" saindo "Servi?o" na
/// proposta do cliente é o tipo de erro que não dá pra desfazer.
final class _Fontes {
  const _Fontes({
    required this.regular,
    required this.medium,
    required this.semiBold,
    required this.heroi,
  });

  final pw.Font regular;
  final pw.Font medium;
  final pw.Font semiBold;
  final pw.Font heroi;
}

_Fontes? _cache;

Future<_Fontes> _carregarFontes() async {
  // Fonte é imutável e o arquivo é grande: relê a cada proposta é desperdício
  // puro num aparelho fraco.
  if (_cache != null) return _cache!;
  final _Fontes fontes = _Fontes(
    regular: pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Regular.ttf'),
    ),
    medium: pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Medium.ttf')),
    semiBold: pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'),
    ),
    heroi: pw.Font.ttf(await rootBundle.load('assets/fonts/Sora-Bold.ttf')),
  );
  return _cache = fontes;
}

pw.TextStyle _corpo(_Fontes f) => pw.TextStyle(
  font: f.regular,
  fontSize: 10.5,
  color: _tinta,
  lineSpacing: 3.5,
);

/// Rótulo de seção: pequeno, caixa alta e espaçado — separa as seções sem
/// precisar de régua ou caixa em volta de cada uma.
pw.TextStyle _rotulo(_Fontes f) => pw.TextStyle(
  font: f.medium,
  fontSize: 7.5,
  color: _tintaSuave,
  letterSpacing: 1.1,
);

pw.Widget _secao(_Fontes f, String texto) =>
    pw.Text(texto.toUpperCase(), style: _rotulo(f));

// ---------------------------------------------------------------------------
// Corpo
// ---------------------------------------------------------------------------

/// Lista plana de propósito: o `MultiPage` só quebra entre os filhos do topo,
/// então empacotar tudo num `Column` faria texto longo estourar a página em
/// vez de continuar na seguinte. Pelo mesmo motivo os textos livres (descrição
/// e observações) vão com `TextOverflow.span` — sem isso o pdf trata o
/// parágrafo como bloco indivisível e joga exceção quando ele passa de uma
/// página.
List<pw.Widget> _corpoDoDocumento(_Fontes f, Proposta proposta, Marca marca) {
  final String servico = proposta.servico.trim();
  final String descricao = proposta.descricao.trim();
  final String cliente = proposta.cliente.trim();
  final String observacoes = proposta.observacoes.trim();

  return <pw.Widget>[
    _cabecalho(f, marca),
    pw.SizedBox(height: _x6),

    if (cliente.isNotEmpty) ...<pw.Widget>[
      _secao(f, 'Para'),
      pw.SizedBox(height: _x2 / 2),
      pw.Text(
        cliente,
        style: pw.TextStyle(font: f.semiBold, fontSize: 12, color: _tinta),
      ),
      pw.SizedBox(height: _x6),
    ],

    if (servico.isNotEmpty) ...<pw.Widget>[
      _secao(f, 'Serviço'),
      pw.SizedBox(height: _x2 / 2),
      pw.Text(
        servico,
        style: pw.TextStyle(
          font: f.semiBold,
          fontSize: 15,
          color: _tinta,
          lineSpacing: 3,
        ),
      ),
      pw.SizedBox(height: _x3),
    ],
    if (descricao.isNotEmpty) ...<pw.Widget>[
      pw.Text(descricao, style: _corpo(f), overflow: pw.TextOverflow.span),
      pw.SizedBox(height: _x2),
    ],

    pw.SizedBox(height: _x3),
    _valor(f, proposta),
    pw.SizedBox(height: _x8),

    ..._condicoes(f, proposta),

    if (observacoes.isNotEmpty) ...<pw.Widget>[
      pw.SizedBox(height: _x8),
      _secao(f, 'Observações'),
      pw.SizedBox(height: _x2),
      pw.Text(observacoes, style: _corpo(f), overflow: pw.TextOverflow.span),
    ],
  ];
}

pw.Widget _cabecalho(_Fontes f, Marca marca) {
  final String nome = marca.nome.trim();
  final String contato = marca.contato.trim();
  final pw.MemoryImage? logo = _lerLogo(marca.logoPath);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                if (logo != null) ...<pw.Widget>[
                  // Teto na altura E na largura: logo panorâmica sem limite de
                  // largura empurra o contato pra fora da página.
                  pw.ConstrainedBox(
                    constraints: const pw.BoxConstraints(
                      maxHeight: 48,
                      maxWidth: 180,
                    ),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                  if (nome.isNotEmpty) pw.SizedBox(height: _x2),
                ],
                if (nome.isNotEmpty)
                  pw.Text(
                    nome,
                    style: pw.TextStyle(
                      font: f.semiBold,
                      fontSize: 16,
                      color: _tinta,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: _x4),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Text(
                'PROPOSTA',
                style: pw.TextStyle(
                  font: f.medium,
                  fontSize: 8,
                  color: _acento,
                  letterSpacing: 2,
                ),
              ),
              if (contato.isNotEmpty) ...<pw.Widget>[
                pw.SizedBox(height: _x2 / 2),
                pw.Text(
                  contato,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    font: f.regular,
                    fontSize: 9.5,
                    color: _tintaSuave,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      pw.SizedBox(height: _x4),
      pw.Container(height: 1, color: _linha),
    ],
  );
}

/// A logo nunca pode derrubar a proposta: caminho nulo, arquivo apagado pelo
/// sistema ou imagem corrompida caem no nome em texto, que o cabeçalho já
/// desenha. O freelancer descobrindo isso é ruim; o cliente recebendo um PDF
/// que não abre é pior.
pw.MemoryImage? _lerLogo(String? caminho) {
  if (caminho == null || caminho.trim().isEmpty) return null;
  try {
    final File arquivo = File(caminho);
    if (!arquivo.existsSync()) return null;
    return pw.MemoryImage(arquivo.readAsBytesSync());
  } catch (_) {
    return null;
  }
}

/// O herói tipográfico: Sora grande, com a barra de acento à esquerda. É o
/// número que o cliente procura primeiro — se ele precisar caçar, o documento
/// falhou.
///
/// Dois contêineres aninhados em vez de um `Border(left:)`: o pdf proíbe
/// borda não-uniforme com raio, e a barra de acento é justamente de um lado só.
pw.Widget _valor(_Fontes f, Proposta proposta) => pw.Container(
  width: double.infinity,
  decoration: const pw.BoxDecoration(
    color: _acento,
    borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
  ),
  padding: const pw.EdgeInsets.only(left: 3),
  child: pw.Container(
    decoration: const pw.BoxDecoration(
      color: _fundoValor,
      borderRadius: pw.BorderRadius.horizontal(right: pw.Radius.circular(12)),
    ),
    padding: const pw.EdgeInsets.fromLTRB(_x6, _x4 + 2, _x6, _x4 + 2),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _secao(f, 'Valor'),
        pw.SizedBox(height: _x2 - 2),
        pw.Text(
          _valorFormatado(proposta.valor),
          style: pw.TextStyle(font: f.heroi, fontSize: 30, color: _tinta),
        ),
        if (proposta.temDetalheHoras) ...<pw.Widget>[
          pw.SizedBox(height: _x2 - 2),
          pw.Text(
            '${proposta.horas} ${proposta.horas == 1 ? 'hora' : 'horas'} × '
            '${_valorFormatado(proposta.valorHora!)}',
            style: pw.TextStyle(
              font: f.regular,
              fontSize: 10,
              color: _tintaSuave,
            ),
          ),
        ],
      ],
    ),
  ),
);

/// Reais redondos ficam sem os centavos (o app fala "R$ 3.500"), mas valor
/// quebrado imprime centavo: arredondar o preço de um documento comercial é
/// mentir sobre quanto o cliente vai pagar.
String _valorFormatado(double valor) {
  final bool redondo = (valor - valor.roundToDouble()).abs() < 0.005;
  return redondo ? moneyBRL(valor.roundToDouble()) : moneyBRLCents(valor);
}

/// Grade rótulo/valor em vez de frases soltas: o cliente lê condição comparando
/// linha com linha, e prazo perdido no meio de um parágrafo vira discussão
/// depois.
List<pw.Widget> _condicoes(_Fontes f, Proposta proposta) {
  final String prazo = proposta.prazo.trim();
  final String pagamento = proposta.formaPagamento.trim();

  return <pw.Widget>[
    _secao(f, 'Condições'),
    pw.SizedBox(height: _x3),
    if (prazo.isNotEmpty) _linhaCondicao(f, 'Prazo de entrega', prazo),
    _linhaCondicao(f, 'Validade da proposta', _validade(proposta.validadeDias)),
    if (pagamento.isNotEmpty) _linhaCondicao(f, 'Pagamento', pagamento),
  ];
}

pw.Widget _linhaCondicao(_Fontes f, String rotulo, String valor) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: _x3),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.SizedBox(
        width: 132,
        child: pw.Text(
          rotulo,
          style: pw.TextStyle(
            font: f.regular,
            fontSize: 10,
            color: _tintaSuave,
          ),
        ),
      ),
      pw.Expanded(
        child: pw.Text(
          valor,
          style: pw.TextStyle(
            font: f.medium,
            fontSize: 10.5,
            color: _tinta,
            lineSpacing: 3,
          ),
        ),
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Rodapé
// ---------------------------------------------------------------------------

/// Texto exato de 07 §F. Nada de "gerado por", número de página ou logo do
/// app: o rodapé é a linha mais fácil de contrabandear marca d'água, e é
/// justamente onde a regra manda não ter.
pw.Widget _rodape(_Fontes f, Proposta proposta, DateTime emitidaEm) =>
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.SizedBox(height: _x4),
        pw.Container(height: 0.7, color: _linha),
        pw.SizedBox(height: _x2),
        pw.Text(
          'Proposta gerada em ${dataNumerica(emitidaEm)} · válida por '
          '${_validade(proposta.validadeDias)}.',
          style: pw.TextStyle(
            font: f.regular,
            fontSize: 8.5,
            color: _tintaSuave,
          ),
        ),
      ],
    );

String _validade(int dias) => dias == 1 ? '1 dia' : '$dias dias';
