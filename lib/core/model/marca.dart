import 'cor_marca.dart';

/// A marca do freelancer no topo da proposta (07 §A.2). É o que compra a
/// confiança que o Bruno não tem — o documento não sai do app com a nossa
/// cara, sai com a DELE.
///
/// Mora em Configurações, mas nunca é pedida de cara: o setup aparece inline
/// na PRIMEIRA proposta (07 §D.7 — não se cobra setup de quem ainda não viu o
/// valor).
class Marca {
  const Marca({
    this.nome = '',
    this.contato = '',
    this.logoPath,
    this.cor = CorMarca.padrao,
    this.ddi = '+55',
    this.whatsapp = '',
    this.email = '',
  });

  final String nome;

  /// Um contato só: WhatsApp OU e-mail. Pedir os dois dobra o formulário e o
  /// cliente só vai usar um.
  final String contato;

  /// Caminho do arquivo da logo COPIADO pra pasta do app. Guardar o caminho
  /// original da galeria não serve: o Android revoga o acesso e a logo some
  /// da proposta semanas depois, em silêncio.
  final String? logoPath;

  /// Cor de acento da proposta (ARGB). Só acento — nunca fundo de texto
  /// corrido; ver [CorMarca].
  final int cor;

  /// Código do país do WhatsApp, com o "+". Separado do número porque o
  /// cliente do freelancer pode estar em outro país — e porque salvar o país
  /// junto do número faz a máscara errar quando ele muda.
  final String ddi;

  /// Só os dígitos do WhatsApp, sem máscara. A máscara é apresentação; guardar
  /// ela junto quebraria a formatação quando o país mudasse.
  final String whatsapp;

  final String email;

  /// O contato como o CLIENTE lê no documento. Prioriza o WhatsApp (é como o
  /// brasileiro fecha negócio), e cai pro e-mail.
  String get contatoFormatado {
    if (whatsapp.isNotEmpty) return '$ddi ${formatarTelefone(whatsapp)}';
    if (email.isNotEmpty) return email;
    return contato; // legado: o campo único de texto livre
  }

  bool get vazia => nome.trim().isEmpty;

  /// Já dá pra emitir proposta? Só o nome é obrigatório — logo e contato são
  /// "pode pular".
  bool get pronta => nome.trim().isNotEmpty;

  Marca copyWith({
    String? nome,
    String? contato,
    String? logoPath,
    bool limparLogo = false,
    int? cor,
    String? ddi,
    String? whatsapp,
    String? email,
  }) => Marca(
    nome: nome ?? this.nome,
    contato: contato ?? this.contato,
    logoPath: limparLogo ? null : (logoPath ?? this.logoPath),
    cor: cor ?? this.cor,
    ddi: ddi ?? this.ddi,
    whatsapp: whatsapp ?? this.whatsapp,
    email: email ?? this.email,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nome': nome,
    'contato': contato,
    if (logoPath != null) 'logoPath': logoPath,
    'cor': cor,
    'ddi': ddi,
    'whatsapp': whatsapp,
    'email': email,
  };

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
    nome: json['nome'] as String? ?? '',
    contato: json['contato'] as String? ?? '',
    logoPath: json['logoPath'] as String?,
    cor: (json['cor'] as num?)?.toInt() ?? CorMarca.padrao,
    ddi: json['ddi'] as String? ?? '+55',
    whatsapp: json['whatsapp'] as String? ?? '',
    email: json['email'] as String? ?? '',
  );
}

/// `(44) 55555-5555` pra celular, `(44) 5555-5555` pra fixo.
///
/// Existe porque o campo aceitava qualquer coisa — hífen três vezes, aspas,
/// o que fosse — e isso saía no documento que vai pro cliente. Formata o que
/// dá e devolve o resto cru: número de outro país não pode virar lixo só
/// porque não cabe no formato brasileiro.
String formatarTelefone(String digitos) {
  final String d = digitos.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.length == 11) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }
  if (d.length == 10) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
  }
  return d;
}

/// Validação de e-mail que AVISA sem bloquear.
///
/// Bloquear seria pior: e-mail válido tem forma esquisita demais pra regex
/// julgar, e travar o salvamento de quem digitou certo é o tipo de coisa que
/// faz a pessoa desistir da proposta inteira.
bool emailParecemValido(String email) {
  if (email.trim().isEmpty) return true; // vazio é opcional, não é erro
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(email.trim());
}
