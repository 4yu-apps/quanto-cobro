import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/lembrete/lembrete.dart';
import 'package:quantocobro/core/model/regime.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F7 — o toggle nos Ajustes. As duas metades da promessa: só liga se a permissão
/// for concedida (degradar com elegância, nunca fingir), e desligar cancela. Roda
/// com um fake — o plugin nativo não existe em teste de unidade.
class _FakeLembretes implements Lembretes {
  _FakeLembretes({this.permite = true});

  bool permite;
  int agendou = 0;
  int cancelou = 0;
  RegimeId? ultimoRegime;

  @override
  Future<bool> pedirPermissao() async => permite;

  @override
  Future<void> agendar(RegimeId regime) async {
    agendou++;
    ultimoRegime = regime;
  }

  @override
  Future<void> cancelar() async => cancelou++;
}

Future<(ProviderContainer, _FakeLembretes)> _abrirConfig(
  WidgetTester tester, {
  required bool permite,
  bool jaLigado = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    'regime': 'mei',
    if (jaLigado) 'lembrete_enabled': true,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final _FakeLembretes fake = _FakeLembretes(permite: permite);
  final ProviderContainer container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      lembretesProvider.overrideWithValue(fake),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const QuantoCobroApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Lembrete de imposto'),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  return (container, fake);
}

void main() {
  testWidgets('permissão concedida: liga, agenda pelo regime e persiste', (
    WidgetTester tester,
  ) async {
    final (ProviderContainer container, _FakeLembretes fake) = await _abrirConfig(
      tester,
      permite: true,
    );
    expect(container.read(lembreteProvider), isFalse);

    await tester.tap(find.text('Lembrete de imposto'));
    await tester.pumpAndSettle();

    expect(container.read(lembreteProvider), isTrue);
    expect(fake.agendou, 1);
    expect(fake.ultimoRegime, RegimeId.mei);
  });

  testWidgets('permissão negada: não liga, e avisa como resolver', (
    WidgetTester tester,
  ) async {
    final (ProviderContainer container, _FakeLembretes fake) = await _abrirConfig(
      tester,
      permite: false,
    );

    await tester.tap(find.text('Lembrete de imposto'));
    await tester.pumpAndSettle();

    expect(container.read(lembreteProvider), isFalse); // não subiu
    expect(fake.agendou, 0);
    expect(find.textContaining('ative as notificações'), findsOneWidget);
  });

  testWidgets('desligar cancela o agendamento', (WidgetTester tester) async {
    final (ProviderContainer container, _FakeLembretes fake) = await _abrirConfig(
      tester,
      permite: true,
      jaLigado: true,
    );
    expect(container.read(lembreteProvider), isTrue);

    await tester.tap(find.text('Lembrete de imposto'));
    await tester.pumpAndSettle();

    expect(container.read(lembreteProvider), isFalse);
    expect(fake.cancelou, 1);
  });
}
