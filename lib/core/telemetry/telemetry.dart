import 'dart:async';

import 'package:flutter/foundation.dart';

/// A camada de telemetria — uma interface, duas implementações, zero
/// dependência de Firebase no resto do app.
///
/// **Por que uma abstração e não chamar o Firebase direto:** o projeto Firebase
/// deste app ainda não existe (criar projeto exige passo humano no console —
/// service account não cria projeto sem organização). Sem esta camada, "ligar
/// telemetria depois" significaria caçar e editar dezenas de call sites no
/// momento de maior pressa, que é véspera de lançamento. Com ela, os eventos
/// já estão nos lugares certos e ligar é trocar UMA linha em `main.dart`.
///
/// **Por que isso importa:** bug/trava é 17,2% das reclamações do mercado e
/// **21,2% no nosso nicho** (`docs/research/ANALISE-QUANTITATIVA-REVIEWS.md`).
/// Crash não se descobre por review — se descobre pela nota caindo três semanas
/// depois, quando a média agregada já travou.
abstract interface class Telemetry {
  /// Registra um evento. `params` só aceita valor categórico de baixa
  /// cardinalidade — ver a regra de privacidade em `eventos.dart`.
  void evento(String nome, {Map<String, Object?> params});

  /// Registra um erro não tratado.
  void erro(Object error, StackTrace? stack, {bool fatal = false});

  /// Liga/desliga em runtime, seguindo o opt-in do usuário (LGPD).
  Future<void> setHabilitado(bool value);
}

/// A implementação ativa hoje: **não envia nada pra lugar nenhum.**
///
/// Em debug ela imprime, pra dar pra conferir na mão que o evento certo dispara
/// no lugar certo — que é justamente o que a gente não teria como testar depois,
/// quando o destino for a nuvem.
class TelemetryNoOp implements Telemetry {
  TelemetryNoOp({this.logEmDebug = true});

  final bool logEmDebug;
  bool _habilitado = false;

  @override
  void evento(
    String nome, {
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    if (!_habilitado) return;
    if (logEmDebug && kDebugMode) {
      debugPrint('[telemetria] $nome ${params.isEmpty ? '' : params}');
    }
  }

  @override
  void erro(Object error, StackTrace? stack, {bool fatal = false}) {
    // Erro é registrado MESMO com telemetria desligada? Não: a promessa do
    // onboarding é "sem enviar seus dados", e stack trace pode conter caminho
    // de arquivo. Sem opt-in, nada sai — em debug, ainda assim aparece no log
    // local pra quem está desenvolvendo.
    if (kDebugMode) {
      debugPrint('[telemetria] erro${fatal ? ' FATAL' : ''}: $error');
    }
  }

  @override
  Future<void> setHabilitado(bool value) async => _habilitado = value;
}

/// Instância global. Trocada por uma implementação real (Firebase) em
/// `main.dart` quando o `google-services.json` existir — ver
/// `docs/planning/08-PLANO-OFICIAL.md §3`.
Telemetry telemetry = TelemetryNoOp();

/// Captura tudo que escapa: erro de widget, erro assíncrono da plataforma e
/// erro dentro da zona onde o app roda.
///
/// Instalado no boot mesmo com a telemetria desligada — o funil precisa existir
/// antes de ter pra onde despejar, senão ligar depois não captura o retroativo.
void instalarCapturaDeErros() {
  final FlutterExceptionHandler? anterior = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    telemetry.erro(details.exception, details.stack, fatal: false);
    // Mantém o comportamento padrão (log no console, tela vermelha em debug):
    // engolir o erro deixaria o desenvolvimento cego.
    anterior?.call(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    telemetry.erro(error, stack, fatal: true);
    return false; // false = não foi tratado; deixa o runtime seguir seu curso
  };
}

/// Roda [corpo] numa zona que captura erro assíncrono solto.
Future<void> rodarComCapturaDeErros(FutureOr<void> Function() corpo) async {
  await runZonedGuarded<Future<void>>(
    () async {
      await corpo();
    },
    (Object error, StackTrace stack) {
      telemetry.erro(error, stack, fatal: true);
    },
  );
}
