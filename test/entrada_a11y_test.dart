import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/data/entrada_repository.dart';
import 'package:quantocobro/core/model/entrada.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// O caminho de ouro — a tela mais usada do app, no gesto que se repete toda
/// semana. Os defeitos aqui são os que mais custam, e os mais fáceis de não
/// perceber olhando pra tela.
///
/// Desde F2 (23/07/2026): salvar SAI da tela (vai pra Meus Trabalhos), com o
/// Desfazer na SnackBar de lá. Não há mais "registrar outro" nem foco pós-save.
void main() {
  testWidgets('toque duplo em Guardar grava UMA entrada, não duas', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      final ProviderContainer container = await _abrirNaEntrada(tester);

      await tester.enterText(find.byType(TextField).first, '400');
      await tester.pumpAndSettle();

      // Dois toques ANTES de o primeiro terminar — é o que acontece com tremor,
      // com Switch Access, ou quando o leitor de tela dispara duas vezes.
      // `tester.tap` não serve: ele assenta o frame entre um e outro e a corrida
      // some. Gestos crus mantêm os dois na mesma janela — e o repositório lento
      // mantém o `await` do salvamento pendente, como no aparelho de verdade.
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

  testWidgets('depois de guardar, a tela é Meus Trabalhos (não fica na Reserva)', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      final ProviderContainer container = await _abrirNaEntrada(tester);

      await tester.enterText(find.byType(TextField).first, '400');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Saiu da Reserva: o "Guardar" não existe mais, e a AppBar é a de
      // Trabalhos (onde o pagamento aparece ligado a quem pagou — a confirmação
      // visual). O "registrar outro" morreu de propósito.
      expect(find.widgetWithText(FilledButton, 'Guardar'), findsNothing);
      expect(find.text('Registrar outro'), findsNothing);
      expect(find.widgetWithText(AppBar, 'Meus trabalhos'), findsOneWidget);
      expect(container.read(entradasProvider), hasLength(1));
    });
  });
}

/// Sobe o app inteiro (precisa do router: salvar navega) e chega na Reserva,
/// com o repositório LENTO pra abrir a janela de corrida do toque duplo.
Future<ProviderContainer> _abrirNaEntrada(WidgetTester tester) async {
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
      child: const QuantoCobroApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Recebi um pagamento'));
  await tester.pumpAndSettle();
  return container;
}

const String _umaArea =
    '{"activeId":"a1","areas":[{"id":"a1","nome":"Design","renda":5000,'
    '"horas":85,"provisao":0,"provisaoOn":true,"provisaoCustom":false,'
    '"diasSemana":5,"horasDia":6,"custos":[]}]}';

/// Gravar no disco leva alguns milissegundos no aparelho — e é nessa janela que
/// o segundo toque entra. Com `SharedPreferences` falso a gravação resolve num
/// microtask, a janela não existe, e o teste passaria verde sem exercitar a trava.
class _RepositorioLento extends EntradaRepository {
  _RepositorioLento(super.prefs);

  @override
  Future<void> add(Entrada entrada) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return super.add(entrada);
  }
}
