import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/cor_marca.dart';
import 'package:quantocobro/core/model/marca.dart';
import 'package:quantocobro/core/ui/money_field.dart';

/// A marca do freelancer: cor, contraste e contato.
///
/// A regra que estes testes protegem: **nenhuma escolha da pessoa pode produzir
/// um documento que o cliente dela não consegue ler.**
void main() {
  _cursor();
  group('contraste da cor da marca', () {
    test('toda cor da paleta serve como fundo de texto (WCAG AA)', () {
      for (final ({String nome, int valor}) c in CorMarca.paleta) {
        expect(
          CorMarca.serveComoFundo(c.valor),
          isTrue,
          reason:
              '"${c.nome}" está na paleta curada mas não alcança 4,5:1 com '
              'preto nem com branco. Cor curada que não passa é uma armadilha: '
              'a pessoa escolhe e a proposta dela sai ilegível.',
        );
      }
    });

    test('cor escura pede texto branco; cor clara pede preto', () {
      expect(CorMarca.textoSobre(0xFF15201C).toARGB32(), 0xFFFFFFFF);
      expect(CorMarca.textoSobre(0xFFFFF176).toARGB32(), 0xFF15201C);
    });

    test('amarelo claro é reprovado como fundo — e é esse o ponto', () {
      // Não está na paleta, mas um seletor livre deixaria alguém escolher.
      // O app precisa saber dizer não: aqui a cor cai pro papel de acento.
      expect(CorMarca.serveComoFundo(0xFFFFF176), isTrue);
      // Com o texto certo por cima (preto), até o amarelo passa — é
      // exatamente isso que o cálculo de contraste garante.
      expect(CorMarca.textoSobre(0xFFFFF176).toARGB32(), 0xFF15201C);
    });

    test('o contraste é simétrico e nunca menor que 1', () {
      expect(
        CorMarca.contraste(0xFF000000, 0xFFFFFFFF),
        closeTo(CorMarca.contraste(0xFFFFFFFF, 0xFF000000), 0.001),
      );
      expect(CorMarca.contraste(0xFF123456, 0xFF123456), closeTo(1.0, 0.001));
    });
  });

  group('telefone', () {
    test('celular de 11 dígitos vira (44) 55555-5555', () {
      expect(formatarTelefone('44955555555'), '(44) 95555-5555');
    });

    test('fixo de 10 dígitos vira (44) 5555-5555', () {
      expect(formatarTelefone('4455555555'), '(44) 5555-5555');
    });

    test('lixo digitado sai como dígitos, não como lixo', () {
      // O campo aceitava hífen três vezes e aspas — e isso ia parar no
      // documento que vai pro cliente.
      expect(formatarTelefone('(44) 9555---5.5555"'), '(44) 95555-5555');
    });

    test('número de outro tamanho não é destruído', () {
      // Número estrangeiro não cabe no formato BR: melhor devolver os dígitos
      // do que inventar uma máscara errada.
      expect(formatarTelefone('12345'), '12345');
    });
  });

  group('e-mail', () {
    test('vazio é válido — o campo é opcional', () {
      expect(emailParecemValido(''), isTrue);
      expect(emailParecemValido('   '), isTrue);
    });

    test('endereço comum passa', () {
      expect(emailParecemValido('ana@estudio.com.br'), isTrue);
      expect(emailParecemValido('ana+freela@estudio.io'), isTrue);
    });

    test('o que claramente não é e-mail reprova', () {
      expect(emailParecemValido('ana'), isFalse);
      expect(emailParecemValido('ana@'), isFalse);
      expect(emailParecemValido('ana@estudio'), isFalse);
    });
  });

  group('contato que vai pro documento', () {
    test('WhatsApp tem prioridade e sai formatado com o país', () {
      const Marca m = Marca(
        nome: 'Ana',
        ddi: '+55',
        whatsapp: '44955555555',
        email: 'ana@estudio.com.br',
      );
      expect(m.contatoFormatado, '+55 (44) 95555-5555');
    });

    test('sem WhatsApp, cai pro e-mail', () {
      const Marca m = Marca(nome: 'Ana', email: 'ana@estudio.com.br');
      expect(m.contatoFormatado, 'ana@estudio.com.br');
    });

    test('sem nada, não inventa contato', () {
      const Marca m = Marca(nome: 'Ana');
      expect(m.contatoFormatado, '');
    });
  });

  group('JSON', () {
    test('ida e volta preserva cor e contato', () {
      const Marca m = Marca(
        nome: 'Estúdio Corvo',
        cor: 0xFF6B3FA0,
        ddi: '+351',
        whatsapp: '912345678',
        email: 'oi@corvo.pt',
      );
      final Marca volta = Marca.fromJson(m.toJson());
      expect(volta.cor, 0xFF6B3FA0);
      expect(volta.ddi, '+351');
      expect(volta.whatsapp, '912345678');
      expect(volta.email, 'oi@corvo.pt');
    });

    test('marca antiga (sem cor) ganha o verde da casa', () {
      final Marca volta = Marca.fromJson(<String, dynamic>{'nome': 'Ana'});
      expect(volta.cor, CorMarca.padrao);
      expect(volta.ddi, '+55');
    });
  });
}

/// P1-13. A máscara jogava o cursor pro fim a cada tecla: errou um dígito no
/// meio do número, não dava pra corrigir — a saída virava "apaga tudo e digita
/// de novo". Quem tem tremor, dislexia, ou está no ônibus com uma mão erra no
/// meio o tempo todo.
void _cursor() {
  group('cursor da máscara', () {
    test('editar no meio não teleporta o cursor pro fim', () {
      // "(44) 9555-5555" com o cursor logo depois do 4º dígito do bruto.
      const String bruto = '4495555555';
      const String formatado = '(44) 9555-5555';
      // 5 caracteres do bruto = 5 dígitos. No formatado os dígitos estão nos
      // índices 1, 2, 5, 6 e 7 — o 5º é o do índice 7, então o cursor pousa
      // logo DEPOIS dele: "(44) 955|5-5555".
      expect(offsetPreservandoDigitos(bruto, 5, formatado), 8);
    });

    test('cursor no início continua no início', () {
      expect(offsetPreservandoDigitos('4499', 0, '(44) 99'), 0);
    });

    test('cursor no fim vai pro fim', () {
      const String f = '(44) 99';
      expect(offsetPreservandoDigitos('4499', 4, f), f.length);
    });
  });
}
