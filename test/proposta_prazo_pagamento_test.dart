import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/proposta.dart';

void main() {
  group('prazo', () {
    test('gera a frase certa, com plural e tipo', () {
      expect(Proposta.prazoDe(15), '15 dias úteis');
      expect(Proposta.prazoDe(1), '1 dia útil');
      expect(Proposta.prazoDe(10, uteis: false), '10 dias corridos');
      expect(Proposta.prazoDe(1, uteis: false), '1 dia corrido');
    });

    test('lê de volta o que gerou, e texto livre antigo', () {
      expect(Proposta.prazoParse('15 dias úteis'), (15, true));
      expect(Proposta.prazoParse('10 dias corridos'), (10, false));
      expect(Proposta.prazoParse('Ex.: 3 semanas'), (null, true));
      expect(Proposta.prazoParse(''), (null, true));
    });
  });

  group('forma de pagamento', () {
    test('default dos chips é exatamente o default histórico', () {
      expect(
        Proposta.formaPagamentoDe(
          meios: <String>['PIX'],
          condicao: Proposta.kCondicoes.first,
        ),
        Proposta.kFormaPagamentoPadrao,
      );
    });

    test('vários meios viram "ou"; extra entra no fim', () {
      expect(
        Proposta.formaPagamentoDe(
          meios: <String>['PIX', 'Cartão'],
          condicao: 'À vista na entrega',
          extra: 'Cartão em até 3x',
        ),
        'PIX ou Cartão · À vista na entrega · Cartão em até 3x',
      );
    });

    test('parse recupera meios e condição; texto desconhecido vira extra', () {
      final r = Proposta.formaPagamentoParse(Proposta.kFormaPagamentoPadrao);
      expect(r.meios, <String>['PIX']);
      expect(r.condicao, Proposta.kCondicoes.first);
      expect(r.extra, '');
      final s = Proposta.formaPagamentoParse('Depósito na conta, 30 dias');
      expect(s.meios, isEmpty);
      expect(s.condicao, Proposta.kCondicoes.first);
      expect(s.extra, 'Depósito na conta, 30 dias');
    });
  });
}
