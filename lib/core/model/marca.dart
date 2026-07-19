/// A marca do freelancer no topo da proposta (07 §A.2). É o que compra a
/// confiança que o Bruno não tem — o documento não sai do app com a nossa
/// cara, sai com a DELE.
///
/// Mora em Configurações, mas nunca é pedida de cara: o setup aparece inline
/// na PRIMEIRA proposta (07 §D.7 — não se cobra setup de quem ainda não viu o
/// valor).
class Marca {
  const Marca({this.nome = '', this.contato = '', this.logoPath});

  final String nome;

  /// Um contato só: WhatsApp OU e-mail. Pedir os dois dobra o formulário e o
  /// cliente só vai usar um.
  final String contato;

  /// Caminho do arquivo da logo COPIADO pra pasta do app. Guardar o caminho
  /// original da galeria não serve: o Android revoga o acesso e a logo some
  /// da proposta semanas depois, em silêncio.
  final String? logoPath;

  bool get vazia => nome.trim().isEmpty;

  /// Já dá pra emitir proposta? Só o nome é obrigatório — logo e contato são
  /// "pode pular".
  bool get pronta => nome.trim().isNotEmpty;

  Marca copyWith({
    String? nome,
    String? contato,
    String? logoPath,
    bool limparLogo = false,
  }) => Marca(
    nome: nome ?? this.nome,
    contato: contato ?? this.contato,
    logoPath: limparLogo ? null : (logoPath ?? this.logoPath),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'nome': nome,
    'contato': contato,
    if (logoPath != null) 'logoPath': logoPath,
  };

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
    nome: json['nome'] as String? ?? '',
    contato: json['contato'] as String? ?? '',
    logoPath: json['logoPath'] as String?,
  );
}
