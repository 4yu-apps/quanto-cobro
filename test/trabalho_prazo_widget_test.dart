import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/trabalho.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/a11y.dart';
import 'package:quantocobro/features/trabalhos/trabalho_form_screen.dart';
import 'package:quantocobro/features/trabalhos/trabalhos_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dois defeitos que a revisão pegou depois do commit original da Task 6, os
/// dois em caminhos que a suíte não exercitava:
///
/// 1. `_semantica()` falava o prazo de um trabalho ENCERRADO mesmo o texto
///    visível (`_linhaApoio()`) escondendo ele — a exata divergência entre
///    leitor de tela e olho que a task tentou evitar.
/// 2. `showDatePicker` exige que `initialDate` caia dentro de
///    `firstDate..lastDate`. Um `entregaEm` salvo há mais de um ano derrubava
///    o app ao abrir editar, porque o `initialDate` era o prazo salvo, sem
///    clamp.
void main() {
  Future<SharedPreferences> prefsCom(Map<String, Object> seed) async {
    SharedPreferences.setMockInitialValues(seed);
    return SharedPreferences.getInstance();
  }

  Map<String, Object> semente(List<Trabalho> trabalhos) => <String, Object>{
    'onboarding_done': true,
    'areas_v1': jsonEncode(<String, dynamic>{
      'activeId': 'a1',
      'areas': <Map<String, dynamic>>[Area.padrao(nome: 'Design').toJson()],
    }),
    'trabalhos_v1': jsonEncode(
      trabalhos.map((Trabalho t) => t.toJson()).toList(),
    ),
  };

  testWidgets(
    'encerrado com prazo: leitor de tela fala só "Encerrado", como o olho vê',
    (WidgetTester tester) async {
      final DateTime agora = DateTime.now();
      final SharedPreferences prefs = await prefsCom(
        semente(<Trabalho>[
          Trabalho(
            id: 't1',
            areaId: 'a1',
            nome: 'Augusto',
            criadoEm: agora,
            encerrado: true,
            entregaEm: agora.add(const Duration(days: 10)),
          ),
        ]),
      );

      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const TrabalhosScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // O texto visível já acertava isso antes (é `_linhaApoio()`, que
      // retorna cedo pra encerrado): confirma que continua assim.
      expect(find.text('Encerrado'), findsOneWidget);
      expect(find.textContaining('Faltam'), findsNothing);

      // O que o leitor de tela fala é o `label` do `SemanticButton` do card.
      final SemanticsNode no = tester.getSemantics(
        find.byType(SemanticButton),
      );
      expect(
        no.label,
        isNot(contains('Faltam')),
        reason:
            'o card está encerrado: o prazo não pode vazar pro leitor de '
            'tela se o olho não vê ele.',
      );
      expect(
        no.label,
        isNot(contains('Entrega')),
      );
      expect(no.label, endsWith('Encerrado.'));

      handle.dispose();
    },
  );

  testWidgets(
    'editar trabalho com prazo salvo há mais de um ano não derruba o app',
    (WidgetTester tester) async {
      final DateTime agora = DateTime.now();
      // Bem fora da janela [ano-1 .. ano+3] que o form usa pro showDatePicker
      // — é exatamente o caso que fazia o `initialDate` cair fora do range.
      final DateTime prazoVelho = DateTime(agora.year - 3, 6, 1);
      final SharedPreferences prefs = await prefsCom(
        semente(<Trabalho>[
          Trabalho(
            id: 't1',
            areaId: 'a1',
            nome: 'Augusto',
            criadoEm: prazoVelho,
            entregaEm: prazoVelho,
          ),
        ]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const <Locale>[Locale('pt', 'BR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const TrabalhoFormScreen(trabalhoId: 't1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sem o clamp, este toque joga `initialDate` fora de `firstDate` pro
      // `showDatePicker`, e o assert do framework derruba o teste (e o app).
      await tester.tap(find.text('Prazo de entrega (opcional)'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    },
  );
}
