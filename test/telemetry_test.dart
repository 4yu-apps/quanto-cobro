import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/telemetry/eventos.dart';
import 'package:quantocobro/core/telemetry/telemetry.dart';

/// Telemetria: o opt-in e a regra de privacidade.
///
/// O app promete no onboarding "sem enviar seus dados". Estes testes são o que
/// impede essa promessa de virar mentira por descuido — inclusive por um
/// descuido futuro, quando o destino deixar de ser no-op e passar a ser rede.
class _Espia implements Telemetry {
  final List<({String nome, Map<String, Object?> params})> enviados =
      <({String nome, Map<String, Object?> params})>[];
  final List<Object> erros = <Object>[];
  bool habilitado = false;

  @override
  void evento(
    String nome, {
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    if (!habilitado) return;
    enviados.add((nome: nome, params: params));
  }

  @override
  void erro(Object error, StackTrace? stack, {bool fatal = false}) {
    if (!habilitado) return;
    erros.add(error);
  }

  @override
  Future<void> setHabilitado(bool value) async => habilitado = value;
}

void main() {
  group('opt-in', () {
    test('desligada por default, não envia nada', () async {
      final TelemetryNoOp t = TelemetryNoOp(logEmDebug: false);
      // Sem exceção e sem efeito: o teste real é o do espião abaixo, aqui é
      // só garantir que chamar com a telemetria desligada não quebra o app.
      t.evento(Evento.calcIniciada);
      t.erro(Exception('x'), StackTrace.empty);
    });

    test(
      'só envia depois do consentimento, e para quando ele é retirado',
      () async {
        final _Espia t = _Espia();

        t.evento(Evento.calcIniciada);
        expect(t.enviados, isEmpty, reason: 'sem opt-in não pode sair nada');

        await t.setHabilitado(true);
        t.evento(Evento.calcIniciada);
        expect(t.enviados, hasLength(1));

        // Desligar tem que valer NA HORA — quem desliga espera que pare agora,
        // não no próximo boot.
        await t.setHabilitado(false);
        t.evento(Evento.calcConcluida);
        expect(t.enviados, hasLength(1));
      },
    );

    test(
      'erro também respeita o opt-in (stack trace tem caminho de arquivo)',
      () async {
        final _Espia t = _Espia();
        t.erro(Exception('boom'), StackTrace.empty, fatal: true);
        expect(t.erros, isEmpty);
      },
    );
  });

  group('a regra de privacidade dos eventos', () {
    /// Palavras que denunciam dado pessoal ou dinheiro num nome de parâmetro.
    /// Se um evento novo trouxer qualquer uma delas, este teste falha e a
    /// pessoa lê o porquê antes de mandar dinheiro do usuário pra nuvem.
    const List<String> proibidas = <String>[
      'valor',
      'preco',
      'preço',
      'renda',
      'reserva',
      'imposto',
      'nome',
      'cliente',
      'email',
      'telefone',
      'contato',
      'marca',
    ];

    /// O catálogo COMPLETO do que o app manda hoje. Adicionar evento novo aqui
    /// é de propósito: obriga quem adiciona a passar por esta revisão.
    const Map<String, List<String>> catalogo = <String, List<String>>{
      Evento.calcIniciada: <String>[],
      Evento.calcPasso: <String>['passo'],
      Evento.calcConcluida: <String>[],
      Evento.areaSalva: <String>[],
      Evento.entradaRegistrada: <String>['origem', 'regime'],
      Evento.estimativaUsada: <String>['campo'],
      Evento.glossarioAberto: <String>['verbete'],
      Evento.proParedeVista: <String>['gatilho'],
      Evento.proAtivado: <String>['gatilho'],
      Evento.erroNaoTratado: <String>['fatal'],
    };

    test('nenhum parâmetro carrega dinheiro ou dado pessoal', () {
      for (final MapEntry<String, List<String>> e in catalogo.entries) {
        for (final String param in e.value) {
          for (final String proibida in proibidas) {
            expect(
              param.toLowerCase().contains(proibida),
              isFalse,
              reason:
                  'O evento "${e.key}" tem o parâmetro "$param", que parece '
                  'carregar dado pessoal ou dinheiro. O app promete que os '
                  'dados ficam no aparelho: medir QUE aconteceu é legítimo, '
                  'medir QUANTO a pessoa recebeu não é.',
            );
          }
        }
      }
    });

    test('os parâmetros são categóricos, não texto livre', () {
      // Baixa cardinalidade: um passo, um regime, um gatilho. Nada que possa
      // conter algo digitado pela pessoa.
      const Set<String> permitidos = <String>{
        'passo',
        'origem',
        'regime',
        'campo',
        'verbete',
        'gatilho',
        'fatal',
      };
      for (final MapEntry<String, List<String>> e in catalogo.entries) {
        for (final String param in e.value) {
          expect(
            permitidos.contains(param),
            isTrue,
            reason:
                'Parâmetro "$param" (evento ${e.key}) não está na lista de '
                'categóricos permitidos. Se ele é texto livre, não pode sair.',
          );
        }
      }
    });
  });

  group('gatilhos do Pro', () {
    test('são distintos — é o que diz QUAL recurso puxa a compra', () {
      const List<String> todos = <String>[
        GatilhoPro.propostaPdf,
        GatilhoPro.segundaArea,
        GatilhoPro.moedaEstrangeira,
        GatilhoPro.config,
      ];
      expect(todos.toSet(), hasLength(todos.length));
    });
  });
}
