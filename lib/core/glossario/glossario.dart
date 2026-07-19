/// Glossário do app em linguagem de gente (auditoria Bruno/leigo e Dona Marta).
/// Fonte única dos verbetes de ajuda — o [HelpDot] lê daqui, pra o texto não
/// se espalhar e destoar entre telas. Cada verbete cabe num balão curto: uma
/// pessoa que "não sabe nada de imposto" tem que entender em 1 leitura.
class Verbete {
  const Verbete(this.titulo, this.texto);

  final String titulo;
  final String texto;
}

abstract final class Glossario {
  static const Map<String, Verbete> _all = <String, Verbete>{
    'leao': Verbete(
      'O que é "o Leão"?',
      'É o apelido do imposto — a parte do que você recebe que vai pro governo. '
          '"Guardar pro Leão" é separar essa parte antes de gastar, pra não '
          'tomar susto na hora de pagar.',
    ),
    'regime': Verbete(
      'O que é "regime"?',
      'É como você trabalha aos olhos do imposto. Nunca abriu empresa nem MEI? '
          'Você é "Autônomo (CPF)". Abriu MEI? É "MEI". Tem empresa no Simples? '
          'É "Simples".',
    ),
    'qual_regime': Verbete(
      'Qual é o meu?',
      'Nunca abriu empresa nem MEI: escolha "Autônomo (CPF)". Já abriu MEI: '
          'escolha "MEI". Tem empresa no Simples: "Simples". Recebe de fora e '
          'não sabe: use "Não sei / cliente no exterior".',
    ),
    'reserva': Verbete(
      'O que é "reserva"?',
      'É o dinheiro que você separa de cada pagamento pra pagar o imposto '
          'depois. Não é seu pra gastar — fica guardado até a hora de acertar '
          'com o Leão.',
    ),
    'prolabore': Verbete(
      'O que é "pró-labore"?',
      'É o seu "salário" quando você tem empresa: o quanto você tira pra você '
          'todo mês. Entra como custo do trabalho porque sai antes do lucro.',
    ),
    'aliquota': Verbete(
      'O que é "alíquota"?',
      'É a porcentagem do imposto. "Alíquota efetiva" é quanto você paga de '
          'verdade sobre o que ganha — quase sempre menos que a alíquota cheia '
          'da tabela.',
    ),
    'carne_leao': Verbete(
      'O que é "carnê-leão"?',
      'É o imposto mensal de quem trabalha por conta (CPF), muito comum pra '
          'quem recebe do exterior. Todo mês você calcula e paga sobre o que '
          'entrou.',
    ),
    'das': Verbete(
      'O que é "DAS"?',
      'É o boleto mensal do MEI: um valor fixo (não é porcentagem do que você '
          'fatura) que já junta os seus impostos num pagamento só.',
    ),
    'simples': Verbete(
      'O que é "Simples"?',
      'É um regime pra quem tem empresa: junta vários impostos numa guia só, '
          'com uma alíquota que sobe conforme o seu faturamento.',
    ),
    'mei': Verbete(
      'O que é "MEI"?',
      'Microempreendedor Individual: a empresa mais simples do Brasil. Paga o '
          'DAS (boleto fixo mensal) e tem um teto de faturamento por ano.',
    ),
    'cpf': Verbete(
      'O que é "Autônomo (CPF)"?',
      'É trabalhar por conta, sem abrir empresa — só com o seu CPF. O imposto '
          'vem pelo carnê-leão, pela sua faixa de renda, mais o INSS.',
    ),
    'exterior': Verbete(
      'O que é "Recebo de fora, sei que sou CPF"?',
      'É pra quem já sabe que trabalha como pessoa física (CPF) pra cliente '
          'no exterior. Você paga o IRPF pela sua faixa, igual ao carnê-leão '
          'do Autônomo — mas sem o INSS, porque não contribui como autônomo.',
    ),
    'grossup': Verbete(
      'Imposto embutido',
      'Quer dizer que a conta já considera o imposto por dentro do valor, pra o '
          'número que aparece pra você ser o final — sem surpresa depois.',
    ),
  };

  static Verbete of(String id) => _all[id]!;

  static Iterable<String> get ids => _all.keys;
}
