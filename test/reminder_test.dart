import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/model/perfil.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/settings/settings_repository.dart';
import 'package:quantocobro/features/painel/painel_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fase 4 Task 8 — nudge mensal in-app (sem plugin nativo, sem notificação
/// do SO): lembra o usuário de registrar a renda de um trabalho recorrente
/// ("mensal") quando o mês ainda não teve nada registrado.
void main() {
  test('reminderMensal default é true e persiste', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsRepository repo = SettingsRepository(
      await SharedPreferences.getInstance(),
    );
    expect(repo.reminderMensal(), isTrue);
    await repo.setReminderMensal(false);
    expect(repo.reminderMensal(), isFalse);
  });

  group('shouldNudge (função pura)', () {
    test('mostra quando ligado + mensal + nada registrado no mês', () {
      expect(
        shouldNudge(
          enabled: true,
          tipo: TipoContrato.mensal,
          brutoDoMes: 0,
        ),
        isTrue,
      );
    });

    test('não mostra quando o lembrete está desligado', () {
      expect(
        shouldNudge(
          enabled: false,
          tipo: TipoContrato.mensal,
          brutoDoMes: 0,
        ),
        isFalse,
      );
    });

    test('não mostra pra trabalho avulso', () {
      expect(
        shouldNudge(
          enabled: true,
          tipo: TipoContrato.avulso,
          brutoDoMes: 0,
        ),
        isFalse,
      );
    });

    test('não mostra quando já tem renda registrada no mês', () {
      expect(
        shouldNudge(
          enabled: true,
          tipo: TipoContrato.mensal,
          brutoDoMes: 1000,
        ),
        isFalse,
      );
    });
  });

  group('nudge no Painel', () {
    String profilesJson(Perfil p) => jsonEncode(<String, dynamic>{
          'activeId': p.id,
          'profiles': <Map<String, dynamic>>[p.toJson()],
        });

    testWidgets('trabalho mensal sem renda no mês: o card aparece', (
      WidgetTester tester,
    ) async {
      final Perfil mensal = Perfil.padrao().copyWith(
        tipoContrato: TipoContrato.mensal,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_done': true,
        'profiles_v2': profilesJson(mensal),
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const QuantoCobroApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Novo mês começou'), findsOneWidget);
      expect(find.text('Registrar agora'), findsOneWidget);
    });

    testWidgets('trabalho avulso: o card não aparece', (
      WidgetTester tester,
    ) async {
      final Perfil avulso = Perfil.padrao();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding_done': true,
        'profiles_v2': profilesJson(avulso),
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const QuantoCobroApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Novo mês começou'), findsNothing);
    });
  });
}
