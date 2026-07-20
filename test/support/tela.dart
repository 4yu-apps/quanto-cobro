import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os tamanhos de tela reais em que este app roda — e em que ele precisa ser
/// testado.
///
/// Antes disso, **todo** widget test do repositório rodava na superfície padrão
/// de 800×600. 800dp não é celular: é tablet pequeno. Ou seja, a suíte inteira
/// nunca tinha visto a largura em que o app de fato vive, e nunca teria pegado
/// um estouro de 360dp nem um layout de tablet quebrado.
enum Tela {
  /// Moto E e afins: o celular barato, que é o público. É o piso.
  celularEmPe(Size(320, 640)),

  /// Celular deitado. Largo e BAIXO — o oposto do caso de origem do layout.
  celularDeitado(Size(640, 360)),

  /// Tablet pequeno em pé / dobrável aberto.
  tabletEmPe(Size(600, 960)),

  /// Tablet deitado. A largura onde texto sem clamp fica ilegível.
  tabletDeitado(Size(1024, 768));

  const Tela(this.size);

  final Size size;
}

/// Fixa a superfície de teste em [tela] e desfaz no fim.
///
/// `tester.view.physicalSize` é global do binding: sem o reset, o próximo teste
/// do arquivo herda o tamanho e o motivo da falha fica escondido três testes
/// adiante.
Future<void> comTela(
  WidgetTester tester,
  Tela tela,
  Future<void> Function() corpo, {
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = tela.size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await corpo();
}

/// Envolve [child] numa escala de fonte, do jeito que o sistema faz.
Widget comFonte(double escala, Widget child) => MediaQuery(
  data: MediaQueryData(textScaler: TextScaler.linear(escala)),
  child: child,
);
