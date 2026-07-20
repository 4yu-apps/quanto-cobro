import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/data/entrada_repository.dart';
import 'package:quantocobro/core/model/entrada.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/entrada/entrada_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// O caminho de ouro — a tela mais usada do app, no gesto que se repete toda
/// semana. Os defeitos aqui são os que mais custam, e os mais fáceis de não
/// perceber olhando pra tela.
void main() {
  testWidgets('toque duplo em Guardar grava UMA entrada, não duas', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      final ProviderContainer container = await _pump(tester);

      await tester.enterText(find.byType(TextField).first, '400');
      await tester.pumpAndSettle();

      // Dois toques ANTES de o primeiro terminar — é o que acontece com
      // tremor, com Switch Access, ou quando o leitor de tela dispara duas
      // vezes. `tester.tap` não serve aqui: ele assenta o frame entre um e
      // outro, e aí o `await` do salvamento já terminou e a corrida some.
      // Gestos crus mantêm os dois dentro da mesma janela — e o repositório
      // lento (abaixo) mantém o `await` do salvamento pendente enquanto isso,
      // que é o que acontece no aparelho de verdade e não acontece com
      // SharedPreferences falso, onde a gravação resolve num microtask.
      //
      // Sem a trava saíam DUAS entradas — e o "Desfazer" removia uma só,
      // deixando dinheiro fantasma no cofre sem como tirar.
      final Finder guardar = find.widgetWithText(FilledButton, 'Guardar');
      await tester.ensureVisible(guardar);
      await tester.pumpAndSettle();

      final Offset centro = tester.getCenter(guardar);
      final TestGesture g1 = await tester.startGesture(centro);
      await g1.up();
      final TestGesture g2 = await tester.startGesture(centro);
      await g2.up();
      await tester.pumpAndSettle();

      expect(container.read(entradasProvider), hasLength(1));
    });
  });

  testWidgets('o Desfazer diz o que se perde, não só "Desfazer"', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester);
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.enterText(find.byType(TextField).first, '400');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      // Fora de contexto, "Desfazer, botão" é um cheque em branco: desfazer o
      // quê? O registro? O trabalho que nasceu junto? Tudo?
      expect(
        find.bySemanticsLabel(RegExp(r'Desfazer o registro de')),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  testWidgets('depois de guardar, o foco pousa no botão que nasceu', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester);

      await tester.enterText(find.byType(TextField).first, '400');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      // O "Guardar" é DESTRUÍDO na troca e nascem dois botões novos. Sem um
      // destino, o foco do leitor de tela recai no topo da tela e o "Desfazer"
      // vira um botão que ninguém acha.
      final FilledButton registrarOutro = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Registrar outro'),
      );
      expect(registrarOutro.focusNode?.hasFocus, isTrue);
    });
  });
}

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    'areas_v1': _umaArea,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      entradaRepositoryProvider.overrideWith(
        (Ref ref) => _RepositorioLento(ref.watch(sharedPreferencesProvider)),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.dark, home: const EntradaScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

const String _umaArea =
    '{"activeId":"a1","areas":[{"id":"a1","nome":"Design","renda":5000,'
    '"horas":85,"provisao":0,"provisaoOn":true,"provisaoCustom":false,'
    '"diasSemana":5,"horasDia":6,"custos":[]}]}';

/// Gravar no disco leva alguns milissegundos no aparelho — e é exatamente
/// nessa janela que o segundo toque entra. Com `SharedPreferences` falso a
/// gravação resolve num microtask, a janela não existe, e o teste passaria
/// verde sem nunca ter exercitado a trava.
class _RepositorioLento extends EntradaRepository {
  _RepositorioLento(super.prefs);

  @override
  Future<void> add(Entrada entrada) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return super.add(entrada);
  }
}
