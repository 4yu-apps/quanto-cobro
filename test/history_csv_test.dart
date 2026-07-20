import 'package:flutter_test/flutter_test.dart';

import 'package:quantocobro/core/data/entrada_csv.dart';
import 'package:quantocobro/core/model/entrada.dart';

/// Fase 4 Task 7 — export CSV (Pro) do histórico "Guardado". Helper puro Dart
/// (zero dependência nova, RFC-4180), TDD antes de plugar na tela.
void main() {
  const String header = 'data,recebeu,guardou,regime,trabalho';

  test('lista vazia gera só o cabeçalho', () {
    expect(entradasCsv(const <Entrada>[]), '$header\n');
  });

  test('uma linha por registro, data ISO, campos na ordem certa', () {
    final DateTime at = DateTime(2026, 3, 10, 14, 30);
    final String csv = entradasCsv(<Entrada>[
      Entrada(
        valor: 1000,
        separado: 150,
        regimeTag: 'MEI',
        at: at,
        areaId: 'trabalho-a',
      ),
    ]);
    final List<String> linhas = csv.trimRight().split('\n');
    expect(linhas.length, 2);
    expect(linhas.first, header);
    expect(linhas[1], '${at.toIso8601String()},1000.0,150,MEI,trabalho-a');
  });

  test('várias linhas, na mesma ordem da lista recebida', () {
    final String csv = entradasCsv(<Entrada>[
      Entrada(
        valor: 100,
        separado: 15,
        regimeTag: 'MEI',
        at: DateTime(2026, 1, 1),
      ),
      Entrada(
        valor: 200,
        separado: 30,
        regimeTag: 'Simples',
        at: DateTime(2026, 1, 2),
      ),
    ]);
    final List<String> linhas = csv.trimRight().split('\n');
    expect(linhas.length, 3);
    expect(linhas[1], contains('MEI'));
    expect(linhas[2], contains('Simples'));
  });

  test('areaId nulo vira campo vazio', () {
    final Entrada entry = Entrada(
      valor: 500,
      separado: 75,
      regimeTag: 'Autônomo',
      at: DateTime(2026, 1, 1),
    );
    final String csv = entradasCsv(<Entrada>[entry]);
    expect(csv.trimRight(), endsWith(',Autônomo,'));
  });

  test('escapa campo com vírgula e aspas por RFC-4180', () {
    final Entrada entry = Entrada(
      valor: 100,
      separado: 10,
      regimeTag: 'MEI',
      at: DateTime(2026, 1, 1),
      areaId: 'Design, "freela"',
    );
    final String csv = entradasCsv(<Entrada>[entry]);
    final String linha = csv.trimRight().split('\n')[1];
    // vírgula/aspas -> campo entre aspas, aspas internas duplicadas.
    expect(linha, endsWith(',MEI,"Design, ""freela"""'));
  });
}
