import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/trabalho.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/trabalho_field.dart';
import 'package:quantocobro/features/simulador/simulador_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **O orçamento validado não morre na tela.**
///
/// O furo: o simulador só tinha saída pra proposta; quem só queria dizer "esse
/// projeto eu vou fazer, guarda ele" não tinha botão. Agora "Salvar como
/// trabalho" cria o trabalho com o valor do projeto como combinado — memória,
/// não gestão: quando o pagamento cair, o valor já vem preenchido.
void main() {
  final Area area = Area.padrao();

  Future<ProviderContainer> abrir(WidgetTester tester) async {
    // Tela alta pra o botão "Salvar como trabalho" (fim do ListView) caber sem
    // depender de rolagem no hit-test.
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
      'areas_v1': jsonEncode(<String, dynamic>{
        'activeId': area.id,
        'areas': <Map<String, dynamic>>[area.toJson()],
      }),
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: const SimuladorScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('salvar o projeto orçado cria o trabalho com o combinado', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await abrir(tester);

    // valor e horas fazem o resultado (e o botão de salvar) aparecerem.
    await tester.enterText(find.byType(TextField).at(0), '3000');
    await tester.enterText(find.byType(TextField).at(1), '30');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar como trabalho'));
    await tester.pumpAndSettle();

    // A folha abriu.
    expect(find.text('Salvar esse projeto'), findsOneWidget);

    // Dá o nome do projeto (campo do sheet) e confirma.
    final Finder campoNome = find.descendant(
      of: find.byType(TrabalhoField),
      matching: find.byType(TextField),
    );
    await tester.enterText(campoNome, 'Site da Padaria');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    // Drena os timers pendentes: o announce (900ms) e o descarte adiado do
    // controller do seletor (600ms) — senão o teste fecha com '!timersPending'.
    await tester.pump(const Duration(seconds: 1));

    final List<Trabalho> trabalhos = container.read(trabalhosProvider);
    expect(trabalhos, hasLength(1));
    expect(trabalhos.single.nome, 'Site da Padaria');
    // O valor do projeto virou o combinado — pré-preenche a entrada no futuro.
    expect(trabalhos.single.valorCombinado, 3000);
  });
}
