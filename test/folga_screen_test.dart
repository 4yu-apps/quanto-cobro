import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/folga/folga_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

Future<void> _pump(WidgetTester tester, {bool provisao = true}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    'regime': 'cpf',
    'areas_v1': jsonEncode(<String, dynamic>{
      'activeId': 'a1',
      'areas': <Map<String, dynamic>>[
        Area.padrao().copyWith(provisaoOn: provisao).toJson(),
      ],
    }),
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(theme: AppTheme.dark, home: const FolgaScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre com 10 dias, 3 meses, e já mostra a hora nova', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, provisao: false);
      expect(find.text('Vou tirar uma folga'), findsOneWidget);
      expect(find.text('10 dias'), findsOneWidget);
      expect(find.textContaining('SUA HORA PRECISA SER'), findsOneWidget);
      expect(find.textContaining('hoje: R\$'), findsOneWidget);
      expect(find.textContaining('ou +'), findsOneWidget);
      expect(find.textContaining('poup'), findsNothing); // nunca "poupar"
    });
  });

  // Ruling A: o `Semantics(label:) + ExcludeSemantics` do stepper cobre só o
  // valor (mesmo defeito já corrigido em `trabalho_detalhe_screen.dart:364`).
  // Os botões +/- ficam FORA do Exclude, com rótulo próprio — senão o leitor
  // de tela fala o valor e não alcança os controles.
  group('Ruling A · botões do stepper são alcançáveis no leitor de tela', () {
    testWidgets('os dois botões do stepper de dias carregam rótulo próprio', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await comTela(tester, Tela.celularEmPe, () async {
        await _pump(tester, provisao: false);

        final SemanticsNode menos = tester.getSemantics(
          find.byTooltip('Um dia a menos'),
        );
        final SemanticsNode mais = tester.getSemantics(
          find.byTooltip('Um dia a mais'),
        );

        expect(menos.tooltip, 'Um dia a menos');
        expect(mais.tooltip, 'Um dia a mais');
        // 10 dias está entre min (1) e max (60): os dois lados tocáveis.
        expect(
          menos.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          mais.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
      });
      handle.dispose();
    });

    testWidgets('no mínimo, o botão "a menos" não se anuncia tocável', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await comTela(tester, Tela.celularEmPe, () async {
        await _pump(tester, provisao: false);

        // "Daqui a quantos meses?" abre em 3, mínimo é 1: dois toques chegam
        // no piso.
        await tester.tap(find.byTooltip('Um mês a menos'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Um mês a menos'));
        await tester.pumpAndSettle();

        final SemanticsNode menos = tester.getSemantics(
          find.byTooltip('Um mês a menos'),
        );
        expect(
          menos.getSemanticsData().hasAction(SemanticsAction.tap),
          isFalse,
          reason: 'no mínimo, o leitor de tela não pode oferecer o toque',
        );

        // E o botão "a mais" continua alcançável normalmente.
        final SemanticsNode mais = tester.getSemantics(
          find.byTooltip('Um mês a mais'),
        );
        expect(
          mais.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
      });
      handle.dispose();
    });
  });

  // Ruling B: o HelpDot('folga') é só do primeiro stepper — no segundo
  // ("Daqui a quantos meses?") não faz sentido e não pode duplicar.
  testWidgets('o "?" de ajuda aparece uma vez só, no stepper de dias', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, provisao: false);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });
}
