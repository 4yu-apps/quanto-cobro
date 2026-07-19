# Redesign Leva 2 — Tamanho de fonte + fim do estouro — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recomendado) ou `superpowers:executing-plans`. Passos usam checkbox (`- [ ]`).

**Goal:** Dar ao usuário controle de tamanho de fonte (multiplicador SOBRE o do sistema, com trava) e consertar os pontos onde texto/dinheiro estoura sob fonte grande — os dois são o mesmo trabalho.

**Architecture:** Uma função pura de escala efetiva (`effectiveTextScale`) clampa `sistema × app` em [0.85, 2.0]; aplicada UMA vez no `builder:` do `MaterialApp.router` via `MediaQuery(textScaler:)`. A preferência vive em `SettingsRepository` + um `NotifierProvider<double>` (espelhando `themeModeProvider`). Os consertos de overflow trocam `Row` rígidas de dinheiro por `Flexible`+`FittedBox`/`Wrap` — encolhe, não corta.

**Tech Stack:** Flutter 3.44 · Riverpod 3 · `shared_preferences` · `flutter_test`. Sem dep nova.

## Global Constraints

- **Multiplicador SOBRE o sistema, NUNCA substituto:** `efetivo = fatorSistema × multApp`, clamp **[0.85, 2.0]**. Substituir o `textScaler` do sistema = regressão P0 de acessibilidade (WCAG 2.2 1.4.4). O teto 2.0 é o alvo do 1.4.4.
- **Níveis (4):** Compacto `0.90` · Padrão `1.00` · Grande `1.15` · Enorme `1.30`. Rótulos por extenso (não "P/M/G").
- **O número é sagrado:** consertos de overflow ENCOLHEM o dinheiro (`FittedBox scaleDown`), nunca o cortam nem o escondem.
- **Preservar a11y da outra trilha:** a Fase 1/2 (personas) já adicionou `Semantics`/`announce`/`ReservaBar`/`HelpDot` nestes arquivos — **NÃO remover** nada disso ao consertar layout. Só mexer na camada de layout (Flexible/Wrap/FittedBox).
- **Reduce-motion / RepaintBoundary:** manter o que já existe; esta leva não adiciona animação.
- **Comandos (fvm):** `fvm flutter test`, `fvm flutter analyze` (Flutter não está no PATH).
- **Splash fora da escala:** o `SplashOverlay` NÃO recebe o `textScaler` do usuário (a marca não distorce) — fica fora do `MediaQuery` escalado, no mesmo `Stack`.

---

## File Structure

- **Modify** `lib/core/settings/settings_repository.dart` — chave `text_scale` (double, default 1.0).
- **Modify** `lib/core/providers.dart` — `TextScaleNotifier` + `textScaleProvider`.
- **Create** `lib/core/ui/text_scale.dart` — a função pura `effectiveTextScale(systemFactor, appMultiplier)` + a lista de níveis (`TextScaleLevel`).
- **Modify** `lib/app/app.dart` — aplicar `MediaQuery(textScaler:)` no `builder:`, fora do splash.
- **Modify** `lib/features/config/config_screen.dart` — bloco "Tamanho do texto" (RadioListTile + prévia + announce) na seção APARÊNCIA.
- **Modify (overflow)** `lib/core/ui/divisao_bar.dart`, `lib/features/reserva/reserva_screen.dart`, `lib/features/detalhe/detalhe_screen.dart`, `lib/features/resultado/resultado_screen.dart`.
- **Tests:** `test/text_scale_test.dart` (função pura), `test/overflow_test.dart` (não estoura em 2.0). Suítes existentes (`reserva_a11y_test`, `painel_smoke`, `nav_glass`, etc.) devem seguir verdes.

---

## Task 1: Persistência + provider do tamanho de fonte

**Files:**
- Modify: `lib/core/settings/settings_repository.dart` (chave `text_scale`, mirror do bloco `_kReduceTransparency`)
- Modify: `lib/core/providers.dart` (`TextScaleNotifier` + `textScaleProvider`, mirror de `ReduceTransparencyNotifier`)
- Test: `test/text_scale_test.dart` (parte de persistência)

**Interfaces:**
- Produces: `textScaleProvider` (`NotifierProvider<TextScaleNotifier, double>`), default `1.0`. `SettingsRepository.textScale()` / `setTextScale(double)`.

- [ ] **Step 1: Teste que falha** — `test/text_scale_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('textScale default 1.0 e persiste', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsRepository repo = SettingsRepository(
      await SharedPreferences.getInstance(),
    );
    expect(repo.textScale(), 1.0);
    await repo.setTextScale(1.15);
    expect(repo.textScale(), 1.15);
  });
}
```

- [ ] **Step 2: Rodar → FAIL** (`fvm flutter test test/text_scale_test.dart`).

- [ ] **Step 3: Repo** — em `settings_repository.dart`, junto de `_kReduceTransparency`:

```dart
static const String _kTextScale = 'text_scale';
double textScale() => _prefs.getDouble(_kTextScale) ?? 1.0;
Future<void> setTextScale(double v) => _prefs.setDouble(_kTextScale, v);
```

- [ ] **Step 4: Provider** — em `providers.dart`, espelhar `ReduceTransparencyNotifier`:

```dart
class TextScaleNotifier extends Notifier<double> {
  @override
  double build() => ref.read(settingsRepositoryProvider).textScale();
  Future<void> set(double v) async {
    await ref.read(settingsRepositoryProvider).setTextScale(v);
    state = v;
  }
}

final NotifierProvider<TextScaleNotifier, double> textScaleProvider =
    NotifierProvider<TextScaleNotifier, double>(TextScaleNotifier.new);
```

- [ ] **Step 5: Rodar → PASS.** Full `fvm flutter test` + `fvm flutter analyze` clean.
- [ ] **Step 6: Commit** — `feat(a11y): persistencia + provider do tamanho de fonte`. Trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## Task 2: Escala efetiva (função pura) + aplicação no app

**Files:**
- Create: `lib/core/ui/text_scale.dart`
- Modify: `lib/app/app.dart` (builder)
- Test: `test/text_scale_test.dart` (adicionar casos da função pura)

**Interfaces:**
- Consumes: `textScaleProvider` (Task 1).
- Produces: `double effectiveTextScale(double systemFactor, double appMultiplier)` (clamp [0.85, 2.0]); `const List<TextScaleLevel> kTextScaleLevels` com `(label, value)`.

- [ ] **Step 1: Testes que falham** — adicionar em `test/text_scale_test.dart`:

```dart
import 'package:quantocobro/core/ui/text_scale.dart';
// ...
test('effectiveTextScale multiplica sistema x app', () {
  expect(effectiveTextScale(1.0, 1.15), closeTo(1.15, 1e-9));
  expect(effectiveTextScale(1.3, 1.15), closeTo(1.495, 1e-9));
});
test('effectiveTextScale clampa em [0.85, 2.0]', () {
  expect(effectiveTextScale(2.0, 1.30), 2.0);   // teto
  expect(effectiveTextScale(0.5, 0.90), 0.85);  // piso
});
test('4 níveis, valores corretos', () {
  expect(kTextScaleLevels.map((TextScaleLevel l) => l.value).toList(),
      <double>[0.90, 1.00, 1.15, 1.30]);
});
```

- [ ] **Step 2: Rodar → FAIL** (`text_scale.dart` não existe).

- [ ] **Step 3: Implementar** — `lib/core/ui/text_scale.dart`:

```dart
/// Escala de texto: multiplicador do app POR CIMA do fator do sistema, clampado.
/// Nunca substitui o zoom do sistema (baixa visão) — combina.
double effectiveTextScale(double systemFactor, double appMultiplier) =>
    (systemFactor * appMultiplier).clamp(0.85, 2.0);

/// Um nível nomeado do seletor de fonte.
class TextScaleLevel {
  const TextScaleLevel(this.label, this.value);
  final String label;
  final double value;
}

const List<TextScaleLevel> kTextScaleLevels = <TextScaleLevel>[
  TextScaleLevel('Compacto', 0.90),
  TextScaleLevel('Padrão', 1.00),
  TextScaleLevel('Grande', 1.15),
  TextScaleLevel('Enorme', 1.30),
];
```

- [ ] **Step 4: Aplicar no `app.dart`** — no `build()` externo, ler `final double appMult = ref.watch(textScaleProvider);`. No `builder:`, envolver SÓ o `child` num `MediaQuery` escalado (splash fica fora):

```dart
builder: (BuildContext context, Widget? child) {
  final MediaQueryData mq = MediaQuery.of(context);
  final double sysFactor = mq.textScaler.scale(14) / 14;
  final double eff = effectiveTextScale(sysFactor, appMult);
  final Widget scaled = MediaQuery(
    data: mq.copyWith(textScaler: TextScaler.linear(eff)),
    child: child ?? const SizedBox.shrink(),
  );
  return Stack(
    children: <Widget>[
      scaled,
      if (!_splashDone) SplashOverlay(onDone: () => setState(() => _splashDone = true)),
    ],
  );
},
```

Importar `../core/ui/text_scale.dart`.

- [ ] **Step 5: Rodar → PASS.** Full `fvm flutter test` + `fvm flutter analyze` clean (o app builder não deve quebrar smoke/nav_glass).
- [ ] **Step 6: Commit** — `feat(a11y): escala de fonte efetiva (mult sobre o sistema, clamp 0.85-2.0)`.

---

## Task 3: UI do tamanho de fonte na Config

**Files:**
- Modify: `lib/features/config/config_screen.dart` (bloco na seção APARÊNCIA, junto do switch "Reduzir transparência" que a Leva 1 já adicionou)

**Interfaces:**
- Consumes: `textScaleProvider` (Task 1), `kTextScaleLevels` (Task 2), `announce` (`lib/core/ui/a11y.dart`), `Haptics` (`lib/core/theme/motion.dart`).

- [ ] **Step 1: Implementar o bloco** — na seção APARÊNCIA (`_secao(context, 'APARÊNCIA')`), depois do bloco de tema/transparência, adicionar dentro de um `Card(color: surfaceContainer)`:
  - Um título `_secaoLinha`/`Text('Tamanho do texto')` (labelLarge).
  - Uma **prévia ao vivo**: `Text('Prévia: R\$ 1.234/hora', style: AppType.valueMd)` (herda o `textScaler` do app — redimensiona sozinha).
  - Um grupo de `RadioListTile<double>` (um por `kTextScaleLevels`), `value: level.value`, `groupValue: ref.watch(textScaleProvider)`, `onChanged: (v) { Haptics.select(); ref.read(textScaleProvider.notifier).set(v!); announce(context, 'Tamanho da fonte: ${level.label}'); }`.
  - Microcopy (labelSmall, onSurfaceVariant): `'Isto ajusta sobre o tamanho de fonte do seu celular.'`

  Importar `../../core/ui/text_scale.dart`, `../../core/ui/a11y.dart`, `../../core/theme/app_typography.dart` se necessário. Aditivo — não reescrever as outras seções.

- [ ] **Step 2: Teste de widget** — `test/config_font_test.dart`: pump a `ConfigScreen` (com `ProviderScope` + prefs mock), encontra 4 `RadioListTile`, toca em "Grande" e confirma que `textScaleProvider` virou 1.15. (Se o setup da tela for pesado, é aceito reduzir a um teste da presença dos 4 rótulos + a prévia; documentar.)

- [ ] **Step 3: Rodar → PASS.** Full `fvm flutter test` + analyze clean.
- [ ] **Step 4: Commit** — `feat(a11y): seletor de tamanho de fonte na Config (radios + previa + announce)`.

---

## Task 4: Consertos de overflow (o dinheiro encolhe, não corta)

> Pré-requisito real do Task 3: com "Grande/Enorme" ligável, estes pontos estouram se não consertados. A trilha de personas já mexeu nesses arquivos (Semantics/copy/ReservaBar) — **preserve tudo isso**; só ajuste a camada de layout.

**Files:**
- Modify: `lib/core/ui/divisao_bar.dart` (~L153 — o valor da legenda)
- Modify: `lib/features/reserva/reserva_screen.dart` (~L272 — Row com dois `_legenda` "Pra usar"/"Reserva")
- Modify: `lib/features/detalhe/detalhe_screen.dart` (~L200 — Row com `MoneyCountUp` valueLg; ~L244 `_linha` valor)
- Modify: `lib/features/resultado/resultado_screen.dart` (~L108 — CTA "Salvar este trabalho") + os CTAs do detalhe (~L222, ~L236)
- Test: `test/overflow_test.dart`

**Interfaces:** nenhuma nova; só ajuste de widgets de layout. Ler o código atual de cada ponto ANTES (a outra trilha pode ter deslocado linhas).

- [ ] **Step 1: Teste que falha** — `test/overflow_test.dart`: renderiza `DivisaoBar` (e a Row de legendas da Reserva, se destacável) numa largura estreita (ex.: 320px) sob `MediaQuery(textScaler: TextScaler.linear(2.0))` e espera **sem exceção de overflow**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/theme/divisao_colors.dart';
import 'package:quantocobro/core/ui/divisao_bar.dart';

void main() {
  testWidgets('DivisaoBar não estoura em textScaler 2.0 e largura estreita', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SizedBox(
              width: 320,
              child: DivisaoBar(lucro: 1234, reserva: 567, custo: 890),
            ),
          ),
        ),
      ),
    );
    // Se estourar, o pump lança um FlutterError e o teste falha aqui.
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Rodar → FAIL** (a `Row` do `_legend` estoura: o valor `moneyBRL(value)·pct%` não tem folga).

- [ ] **Step 3: Consertar cada ponto** (ler o código atual e aplicar o padrão):
  - `divisao_bar.dart` `_legend` (~L153): o `Text('${moneyBRL(value)}  ·  $pct%')` → `Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(...)))`.
  - `reserva_screen.dart` (~L272): a `Row(children: [_legenda('Pra usar'...), _legenda('Reserva'...)])` → `Wrap(spacing: Space.x4, runSpacing: Space.x2, children: [...])`. Manter os `_legenda` e seus Semantics.
  - `detalhe_screen.dart` (~L200): o `MoneyCountUp(... style: AppType.valueLg)` dentro da `Row(spaceBetween)` → `Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: MoneyCountUp(...)))`. E em `_linha` (~L244) dar `Flexible` também ao valor (o rótulo já é `Flexible`).
  - CTAs pill (`resultado_screen.dart` ~L108 "Salvar este trabalho"; `detalhe_screen.dart` ~L222 "Refazer com o passo a passo", ~L236 "Salvar alterações"): envolver o `Text` do label em `FittedBox(fit: BoxFit.scaleDown, child: Text(...))` — encolhe, mantém o pill.

- [ ] **Step 4: Rodar → PASS.** `fvm flutter test test/overflow_test.dart` verde; full suite + analyze clean (inclusive `reserva_a11y_test` da outra trilha — os Semantics não podem ter sumido).
- [ ] **Step 5: Commit** — `fix(a11y): dinheiro encolhe em vez de estourar sob fonte grande (Divisao/Reserva/Detalhe/CTAs)`.

---

## Self-Review — cobertura do spec (Leva 2, §5)

| Item do spec §5 | Task |
|---|---|
| Multiplicador sobre o sistema + clamp [0.85, 2.0] | T2 |
| Níveis 0.90/1.00/1.15/1.30 | T2 |
| Aplicar no builder do MaterialApp, splash fora | T2 |
| Persistência + provider | T1 |
| UI: RadioListTile + prévia ao vivo + announce | T3 |
| Overflow: DivisaoBar, Reserva (2 legendas), Detalhe, CTAs | T4 |
| Preservar Semantics/announce da outra trilha | T4 (constraint) |

**Fora da Leva 2 (não fazer aqui):** herói-joia + "acender o cofre" + sinal +/− (Leva 3); escala da ALTURA da barra (bar height 20) fica como polimento opcional — as LEGENDAS já herdam o textScaler; a barra em si é apresentação e pode ficar fixa por ora.

**Placeholders:** nenhum. Os pontos de overflow dão linha aproximada (`~L`) porque a outra trilha mexeu nos arquivos — o implementador LÊ o código atual e aplica o padrão nomeado.

---

## Execution Handoff
Plano salvo. Ordem: T1 → T2 (fundação testável) → T3 (UI) → T4 (overflow, o pré-requisito que torna "Grande/Enorme" seguro). Branch de integração `feat/redesign-leva23` (já contém Leva 1 + Fase 1-2 da outra trilha).
