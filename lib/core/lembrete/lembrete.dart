import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../calc/tax_tables.dart';
import '../model/regime.dart';

/// O plano de um lembrete: QUANDO (dia do mês + hora local) e O QUE dizer.
/// PURO — decidido só a partir do regime, sem tocar em plugin nenhum. É a peça
/// testável da F7; o resto é chamada de sistema que não roda em teste de unidade.
class LembretePlano {
  const LembretePlano({
    required this.dia,
    required this.hora,
    required this.titulo,
    required this.corpo,
  });

  final int dia; // dia do mês
  final int hora; // hora local (24h)
  final String titulo;
  final String corpo;
}

/// O que lembrar, por regime. MEI/Simples: o DAS, que vence dia 20.
/// CPF/carnê-leão/dólar: o carnê-leão, que vence no fim do mês seguinte —
/// lembramos dia 25 pra dar tempo de juntar e pagar. Todo regime tem lembrete:
/// esquecer de separar é a dor de todo mundo (a Receita provou: um lembrete de
/// DAS moveu +R$ 49 mi/mês de arrecadação).
LembretePlano planoLembrete(RegimeId regime) {
  switch (regime) {
    case RegimeId.mei:
      return const LembretePlano(
        dia: kDasVencimentoDia,
        hora: 10,
        titulo: 'O DAS do MEI vence dia 20',
        corpo: 'É o boleto fixo do mês. Já deixou o valor separado?',
      );
    case RegimeId.simples:
      return const LembretePlano(
        dia: kDasVencimentoDia,
        hora: 10,
        titulo: 'O DAS do Simples vence dia 20',
        corpo: 'Confira o valor do mês e deixe a parte do imposto separada.',
      );
    case RegimeId.cpf:
    case RegimeId.carneLeao:
      return const LembretePlano(
        dia: 25,
        hora: 10,
        titulo: 'Carnê-leão deste mês',
        corpo: 'Some o que entrou e separe o imposto antes de fechar o mês.',
      );
    case RegimeId.intl:
      return const LembretePlano(
        dia: 25,
        hora: 10,
        titulo: 'Separe o imposto do mês',
        corpo: 'Fim do mês: guarde a parte do imposto do que você recebeu.',
      );
  }
}

/// O contrato que a UI usa — pra o toggle poder ser testado com um fake, sem o
/// plugin nativo (que não roda em teste de unidade).
abstract interface class Lembretes {
  /// Pede a permissão de notificação (Android 13+). Retorna se pode notificar.
  Future<bool> pedirPermissao();

  /// Agenda o lembrete mensal do [regime] (substitui um agendamento anterior).
  Future<void> agendar(RegimeId regime);

  /// Cancela o lembrete.
  Future<void> cancelar();
}

/// Implementação real, sobre o flutter_local_notifications. DEFENSIVA em tudo:
/// a lição do AdMob (11-HANDOFF §6) é que plugin nativo não pode derrubar o app.
/// Cada método é blindado — na pior das hipóteses o lembrete não sai, mas nada
/// quebra. O cartão in-app de vencimento continua valendo; só não chega o push.
class LembreteService implements Lembretes {
  LembreteService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Id fixo: reagendar sempre SUBSTITUI o lembrete anterior, nunca acumula.
  static const int _kId = 4020;
  static const String _kCanal = 'lembrete_imposto';

  bool _iniciado = false;

  Future<bool> _garantirInit() async {
    if (_iniciado) return true;
    tzdata.initializeTimeZones();
    // O imposto é brasileiro: agenda no horário de Brasília mesmo que o relógio
    // do aparelho esteja noutro fuso. Se o nome do fuso faltar, cai no local.
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {}
    final bool? ok = await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _iniciado = ok ?? true;
    return _iniciado;
  }

  @override
  Future<bool> pedirPermissao() async {
    try {
      await _garantirInit();
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return true; // não-Android: sem esse gate
      final bool? ok = await android.requestNotificationsPermission();
      return ok ?? false;
    } catch (_) {
      return false; // negar com elegância: o toggle não liga, o app segue
    }
  }

  @override
  Future<void> agendar(RegimeId regime) async {
    try {
      await _garantirInit();
      final LembretePlano p = planoLembrete(regime);
      await _plugin.cancel(_kId);
      await _plugin.zonedSchedule(
        _kId,
        p.titulo,
        p.corpo,
        _proximaData(p.dia, p.hora),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _kCanal,
            'Lembretes de imposto',
            channelDescription:
                'Avisa quando chega a hora de separar o imposto do mês.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        // INEXATO de propósito: um lembrete mensal não precisa de precisão de
        // minuto, e evita a permissão de alarme exato (revisão extra da Play).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Repete todo mês, nesse dia e hora.
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (_) {
      // Silêncio proposital: sem push, mas o app segue de pé.
    }
  }

  @override
  Future<void> cancelar() async {
    try {
      await _garantirInit();
      await _plugin.cancel(_kId);
    } catch (_) {}
  }

  /// A próxima ocorrência do [dia]/[hora] deste mês; se já passou, o mês que vem.
  tz.TZDateTime _proximaData(int dia, int hora) {
    final tz.TZDateTime agora = tz.TZDateTime.now(tz.local);
    tz.TZDateTime data = tz.TZDateTime(
      tz.local,
      agora.year,
      agora.month,
      dia,
      hora,
    );
    if (!data.isAfter(agora)) {
      data = tz.TZDateTime(tz.local, agora.year, agora.month + 1, dia, hora);
    }
    return data;
  }
}
