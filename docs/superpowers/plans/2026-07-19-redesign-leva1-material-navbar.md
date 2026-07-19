# Redesign Leva 1 — Material dos cards + Navbar de vidro — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recomendado) ou `superpowers:executing-plans` pra implementar tarefa a tarefa. Os passos usam checkbox (`- [ ]`) pra rastreio.

**Goal:** Acabar com o "chapado" da UI — propagar o material premium do herói (`VitrineCard`) pros cards planos e transformar a navbar num elemento flutuante de vidro real — sem trocar a identidade "Cofre Aberto" e sem colidir com a trilha de personas.

**Architecture:** Um `ThemeExtension<Materials>` guarda os tokens de luz/vidro (sem alpha mágico espalhado). Um widget `PanelCard` encapsula o material faux-glass (edge-light + degradê tonal + glow de acento) e substitui os `Card`/`Material` chapados. A navbar vira uma pílula flutuante de vidro (`extendBody` + `BackdropFilter`) construída **em volta do `NavigationBar` nativo** (preserva semântica de aba e o smoke test), com fallback opaco obrigatório. Tudo estático sob `RepaintBoundary`; o único custo de GPU é o blur da navbar, com desligamento automático.

**Tech Stack:** Flutter · Riverpod 3 (`NotifierProvider`) · `shared_preferences` · `flutter_test` (widget tests) · `dart:ui` (`ImageFilter.blur`). Nenhuma dependência nova.

## Global Constraints

- **Tetos de brilho colorido (a linha premium↔gamer, não ceder):** acento em card **≤ 0.08** · halo da navbar **≤ 0.12** · glow do número **≤ 0.16** (número é Leva 3). Copiar os valores exatos do spec `docs/design-build/REDESIGN-PREMIUM.md`.
- **O número é sagrado:** nunca gradiente no dígito, nunca blur/vidro atrás de número. (Não aplicável a esta leva, mas vale como trava.)
- **Vidro real só na navbar.** Todo o resto é faux-glass (sem `BackdropFilter`).
- **Tint da navbar ≥ 0.88 alpha** sobre o blur (piso de contraste WCAG, não estética — conteúdo rola atrás dos rótulos).
- **Fallback opaco obrigatório:** blur desligado quando `MediaQuery.of(context).accessibleNavigation` **OU** o setting "Reduzir transparência" estiver ligado.
- **Reduce-motion:** toda animação consulta `reduceMotionOf(context)` (`lib/core/theme/motion.dart`).
- **Higiene de raster:** todo `BackdropFilter`/`CustomPaint`/gradiente novo sob `RepaintBoundary`.
- **Coordenação (ordem SEQUENCIAL — esta trilha vai PRIMEIRO):** a trilha de personas assume depois, sobre o `main` já mergeado. No meu turno o `main` está limpo e NÃO há nada dele pra rebase/conflitar. Ainda assim, NÃO invento trabalho no domínio dele (`glossario/*`, `fx/*`, modelos, Semantics/copy) e ao reestilizar telas compartilhadas (`config_screen.dart`, `resultado_screen.dart`, `reserva_screen.dart`) PRESERVO qualquer `Semantics`/`announce` que já exista. `nav_shell.dart`, `tool_action_card.dart`, `divisao_bar.dart`, tema e `panel_card.dart`/`materials.dart` são 100% meus.
- **Comandos:** `fvm flutter test`, `fvm flutter analyze` (usar `fvm flutter …` se o `.fvmrc` exigir no ambiente).

---

## File Structure

- **Create** `lib/core/theme/materials.dart` — `ThemeExtension<Materials>` com os tokens de luz/vidro por tema.
- **Create** `lib/core/ui/panel_card.dart` — widget do material faux-glass reutilizável.
- **Modify** `lib/core/theme/app_theme.dart` — registrar `Materials` no `extensions:` + `navigationBarTheme` (indicador premium, transparente).
- **Modify** `lib/core/ui/tool_action_card.dart` — trocar o `Material` chapado por `PanelCard`.
- **Modify** `lib/features/painel/painel_screen.dart` — trocar `Card`s por `PanelCard`; wash de fundo; padding inferior.
- **Modify** `lib/features/resultado/resultado_screen.dart` — card da anatomia vira `PanelCard` (rebase antes).
- **Modify** `lib/core/settings/settings_repository.dart` + `lib/core/providers.dart` — setting `reduce_transparency` + provider.
- **Modify** `lib/features/config/config_screen.dart` — switch "Reduzir transparência" na seção APARÊNCIA.
- **Modify** `lib/app/nav_shell.dart` — navbar flutuante de vidro + `extendBody` + fallback.
- **Modify** `lib/core/ads/ads.dart` — `_AdPlaceholder` vira card flutuante arredondado.
- **Modify** `lib/features/historico/historico_screen.dart`, `lib/features/perfis/perfis_screen.dart` — padding inferior pro conteúdo não sumir atrás da navbar.
- **Tests:** `test/materials_test.dart`, `test/panel_card_test.dart`, `test/reduce_transparency_test.dart`, `test/nav_glass_test.dart` (novos); `test/painel_smoke_test.dart` (deve continuar passando).

---

## Task 1: `Materials` ThemeExtension (tokens de luz/vidro)

**Files:**
- Create: `lib/core/theme/materials.dart`
- Modify: `lib/core/theme/app_theme.dart:22` (registrar no `extensions:`)
- Test: `test/materials_test.dart`

**Interfaces:**
- Produces: `Materials` (`ThemeExtension`) com campos `edgeHighlight`, `edgeShadow`, `panelFillTop`, `panelFillBottom`, `glassFill`, `glassBlurSigma` (`double`), `navHalo` (`Color`) e `Materials.dark`/`Materials.light` estáticos. Acesso via `Theme.of(context).extension<Materials>()!`.

- [ ] **Step 1: Escrever o teste que falha** — `test/materials_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/theme/materials.dart';

void main() {
  test('Materials está registrado nos dois temas', () {
    expect(AppTheme.dark.extension<Materials>(), isNotNull);
    expect(AppTheme.light.extension<Materials>(), isNotNull);
  });

  test('Materials.lerp interpola sem crashar e respeita os tetos', () {
    final Materials m = Materials.dark.lerp(Materials.light, 0.5);
    expect(m.glassBlurSigma, greaterThan(0));
    // Teto de brilho: o halo da nav nunca passa de 0.12 de alpha.
    expect(Materials.dark.navHalo.a, lessThanOrEqualTo(0.12 + 0.001));
    expect(m.edgeHighlight, isA<Color>());
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `fvm flutter test test/materials_test.dart`
Expected: FAIL — `materials.dart` não existe.

- [ ] **Step 3: Criar `Materials`** — `lib/core/theme/materials.dart` (mesmo formato do `DivisaoColors`):

```dart
import 'package:flutter/material.dart';

/// Tokens de LUZ e MATERIAL (proposta Lúa) — o "Cofre Aberto" chegando nas
/// superfícies que ficaram chapadas. Croma perto de zero nas luzes (é luz, não
/// cor nova). Tetos: acento de card ≤0.08, halo da nav ≤0.12, glow nº ≤0.16.
@immutable
class Materials extends ThemeExtension<Materials> {
  const Materials({
    required this.edgeHighlight,
    required this.edgeShadow,
    required this.panelFillTop,
    required this.panelFillBottom,
    required this.glassFill,
    required this.glassBlurSigma,
    required this.navHalo,
  });

  final Color edgeHighlight; // fio-de-luz no topo da borda
  final Color edgeShadow; // sombra baixa da borda (assenta o card)
  final Color panelFillTop; // degradê do card: topo (mais claro)
  final Color panelFillBottom; // degradê do card: base
  final Color glassFill; // fill tintado da navbar (>=0.88 alpha)
  final double glassBlurSigma; // sigma do BackdropFilter da navbar
  final Color navHalo; // halo colorido da navbar (<=0.12)

  static const Materials dark = Materials(
    edgeHighlight: Color(0x14FFFFFF), // branco 8%
    edgeShadow: Color(0x1A000000), // preto 10%
    panelFillTop: Color(0xFF272B29), // surfaceContainerHigh
    panelFillBottom: Color(0xFF1E2120), // surfaceContainer
    glassFill: Color(0xE1272B29), // surfaceContainerHigh @ ~0.88
    glassBlurSigma: 18,
    navHalo: Color(0x1E57E5A9), // esmeralda ~12% (dentro do teto 0.12)
  );

  static const Materials light = Materials(
    edgeHighlight: Color(0x33FFFFFF), // branco 20% (papel precisa mais)
    edgeShadow: Color(0x0D0D211B), // verde-tinta baixíssimo
    panelFillTop: Color(0xFFFFFFFF), // branco puro flutua
    panelFillBottom: Color(0xFFFCFBF8), // surfaceContainer claro
    glassFill: Color(0xE1FDFDFC), // ~0.88 sobre papel
    glassBlurSigma: 18,
    navHalo: Color(0x14007D54), // esmeralda escuro 8% (claro é sóbrio)
  );

  @override
  Materials copyWith({
    Color? edgeHighlight,
    Color? edgeShadow,
    Color? panelFillTop,
    Color? panelFillBottom,
    Color? glassFill,
    double? glassBlurSigma,
    Color? navHalo,
  }) => Materials(
    edgeHighlight: edgeHighlight ?? this.edgeHighlight,
    edgeShadow: edgeShadow ?? this.edgeShadow,
    panelFillTop: panelFillTop ?? this.panelFillTop,
    panelFillBottom: panelFillBottom ?? this.panelFillBottom,
    glassFill: glassFill ?? this.glassFill,
    glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
    navHalo: navHalo ?? this.navHalo,
  );

  @override
  Materials lerp(ThemeExtension<Materials>? other, double t) {
    if (other is! Materials) return this;
    return Materials(
      edgeHighlight: Color.lerp(edgeHighlight, other.edgeHighlight, t)!,
      edgeShadow: Color.lerp(edgeShadow, other.edgeShadow, t)!,
      panelFillTop: Color.lerp(panelFillTop, other.panelFillTop, t)!,
      panelFillBottom: Color.lerp(panelFillBottom, other.panelFillBottom, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBlurSigma: (glassBlurSigma + (other.glassBlurSigma - glassBlurSigma) * t),
      navHalo: Color.lerp(navHalo, other.navHalo, t)!,
    );
  }
}
```

> NOTA: `Color.a` devolve alpha 0..1 no Flutter novo (mesmo do `withValues`). Se o ambiente ainda usa `.opacity`, trocar no teto do teste.

- [ ] **Step 4: Registrar no tema** — `lib/core/theme/app_theme.dart`, importar `materials.dart` e no `_build`, incluir a instância certa por brilho:

```dart
// no topo:
import 'materials.dart';
// dentro de _build(...), trocar a lista de extensions:
extensions: <ThemeExtension<dynamic>>[
  divisao,
  scheme.brightness == Brightness.dark ? Materials.dark : Materials.light,
],
```

- [ ] **Step 5: Rodar e ver passar**

Run: `fvm flutter test test/materials_test.dart`
Expected: PASS.

- [ ] **Step 6: Regressão + commit**

```bash
fvm flutter analyze && fvm flutter test
git add lib/core/theme/materials.dart lib/core/theme/app_theme.dart test/materials_test.dart
git commit -m "feat(theme): tokens de material (edge-light, glass, halo) como ThemeExtension"
```

---

## Task 2: `PanelCard` — o card faux-glass reutilizável

**Files:**
- Create: `lib/core/ui/panel_card.dart`
- Test: `test/panel_card_test.dart`

**Interfaces:**
- Consumes: `Materials` (Task 1), `Radii` (`lib/core/theme/tokens.dart`).
- Produces: `PanelCard({required Widget child, EdgeInsetsGeometry padding, Color? accent, Radius radius})` — pinta degradê tonal + fio-de-luz + (se `accent != null`) glow de acento ≤0.08 no canto superior-esquerdo. Usado pela Task 3.

- [ ] **Step 1: Escrever o teste que falha** — `test/panel_card_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/panel_card.dart';

void main() {
  testWidgets('PanelCard renderiza o filho e não usa BackdropFilter (é faux-glass)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: PanelCard(child: Text('conteúdo')),
        ),
      ),
    );
    expect(find.text('conteúdo'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing); // vidro real só na nav
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** — `fvm flutter test test/panel_card_test.dart` → FAIL (`panel_card.dart` não existe).

- [ ] **Step 3: Implementar `PanelCard`** — `lib/core/ui/panel_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/materials.dart';
import '../theme/tokens.dart';

/// Card faux-glass do "Cofre Aberto": degradê tonal (luz vem de cima) +
/// fio-de-luz na borda (branco, croma zero) + glow de acento opcional no canto
/// do ícone (≤0.08). Custo ~zero: gradientes estáticos, sem shader por frame,
/// sob RepaintBoundary. NÃO usa BackdropFilter (vidro real é só a navbar).
class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.x4),
    this.accent,
    this.radius = Radii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Cor do glow de acento (canto sup-esq). Null = sem glow.
  final Color? accent;
  final Radius radius;

  @override
  Widget build(BuildContext context) {
    final Materials m = Theme.of(context).extension<Materials>()!;
    return RepaintBoundary(
      child: DecoratedBox(
        // Camada 1: degradê tonal + borda de luz/sombra.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[m.panelFillTop, m.panelFillBottom],
          ),
          border: GradientBoxBorder(m.edgeHighlight, m.edgeShadow),
        ),
        child: DecoratedBox(
          // Camada 2: glow de acento no canto (só se accent != null).
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(radius),
            gradient: accent == null
                ? null
                : RadialGradient(
                    center: const Alignment(-0.9, -0.9),
                    radius: 0.9,
                    colors: <Color>[
                      accent!.withValues(alpha: 0.08), // TETO — não subir
                      accent!.withValues(alpha: 0),
                    ],
                  ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Borda 1px com gradiente vertical (topo = luz, base = sombra). Barata:
/// pinta a moldura com um Paint por vez, sem saveLayer.
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder(this.top, this.bottom);
  final Color top;
  final Color bottom;

  @override
  BorderSide get bottom => BorderSide(color: this.bottom);
  @override
  BorderSide get top => BorderSide(color: top);
  @override
  bool get isUniform => false;
  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final RRect rrect = (borderRadius ?? BorderRadius.zero)
        .toRRect(rect)
        .deflate(0.5);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[top, bottom],
      ).createShader(rect);
    canvas.drawRRect(rrect, p);
  }

  @override
  ShapeBorder scale(double t) => this;
}
```

- [ ] **Step 4: Rodar e ver passar** — `fvm flutter test test/panel_card_test.dart` → PASS.

- [ ] **Step 5: Verificar no device (craft visual — não é unit-testável)**

Rodar o app e abrir uma tela com `PanelCard`. **Aceite:** o card tem topo perceptivelmente mais claro que a base; a borda superior tem um fio de luz sutil; NÃO parece um retângulo chapado. Ajustar os alphas de `Materials` se necessário (o teto de acento é 0.08 — não subir).

- [ ] **Step 6: Commit**

```bash
fvm flutter analyze && fvm flutter test
git add lib/core/ui/panel_card.dart test/panel_card_test.dart
git commit -m "feat(ui): PanelCard — material faux-glass (edge-light + degrade + glow)"
```

---

## Task 3: Aplicar o material aos cards chapados

**Files:**
- Modify: `lib/core/ui/tool_action_card.dart:39-84` (trocar `Material` por `PanelCard`)
- Modify: `lib/features/painel/painel_screen.dart:160,237` (cards "DAS" e "DE CADA MÊS")
- Modify: `lib/features/resultado/resultado_screen.dart:~202` (card da anatomia) — ordem me-first: `main` limpo, sem rebase; só preservar textos/`Semantics` existentes
- Test: `test/painel_smoke_test.dart` (deve continuar passando)

**Interfaces:**
- Consumes: `PanelCard` (Task 2). `ToolActionCard` mantém a MESMA assinatura pública (`icon`, `title`, `subtitle`, `accent`, `onTap`) — só muda a pintura interna.

- [ ] **Step 1: Trocar em `ToolActionCard`** — dentro do `ExcludeSemantics > PressableScale`, substituir o `Material(color: cs.surfaceContainer) > InkWell > Container(decoration...)` por `PanelCard(accent: accent ?? cs.primary, ...)` envolvendo um `InkWell` transparente (o ripple continua). Preservar `Semantics`/`ExcludeSemantics` e `PressableScale` (não remover — a semântica é da outra trilha, o press é o motion existente):

```dart
child: ExcludeSemantics(
  child: PressableScale(
    child: PanelCard(
      accent: accent ?? cs.primary,
      padding: const EdgeInsets.all(Space.x4),
      child: InkWell(
        onTap: () { Haptics.select(); onTap(); },
        borderRadius: const BorderRadius.all(Radii.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          child: Column( /* ...conteúdo idêntico (ícone, título, subtítulo)... */ ),
        ),
      ),
    ),
  ),
),
```

> O `InkWell` precisa de um `Material` ancestral pro ripple. `PanelCard` usa `DecoratedBox` (sem Material). Solução: envolver o `InkWell` num `Material(type: MaterialType.transparency)`. Manter o `borderRadius` no `InkWell` pro ripple respeitar o canto.

- [ ] **Step 2: Trocar os `Card` do Painel** — em `painel_screen.dart`, trocar `Card(color: theme.colorScheme.surfaceContainer)` do bloco "DE CADA MÊS" (~L237) por `PanelCard(child: ...)` (sem accent — é painel neutro). O card do DAS (~L160, `secondaryContainer`) mantém a cor semântica de alerta, mas ganha o material: `PanelCard(accent: theme.colorScheme.secondary, child: ...)`.

- [ ] **Step 3: Trocar o card do Resultado** — em `resultado_screen.dart` (~L202), o `Card` da anatomia vira `PanelCard`. Como esta trilha vai primeiro, não há edição da outra trilha aqui ainda — só trocar o `Card` por `PanelCard`, preservando textos e qualquer `Semantics` existentes.

- [ ] **Step 4: Rodar a regressão** — o smoke test não deve quebrar (ele busca textos, não tipos de card):

Run: `fvm flutter test test/painel_smoke_test.dart`
Expected: PASS.

- [ ] **Step 5: Verificar no device** — **Aceite:** os dois `ToolActionCard` ("Recebi um pagamento" brilha ouro no canto; "Vou orçar" brilha aço), o card "DE CADA MÊS" e o do Resultado deixaram de parecer chapados; o degrau de qualidade vs. o herói sumiu a olho.

- [ ] **Step 6: Commit**

```bash
fvm flutter analyze && fvm flutter test
git add lib/core/ui/tool_action_card.dart lib/features/painel/painel_screen.dart lib/features/resultado/resultado_screen.dart
git commit -m "feat(ui): material premium nos cards de acao e paineis (fim do chapado)"
```

---

## Task 4: Wash de ambiente no fundo

**Files:**
- Modify: `lib/features/painel/painel_screen.dart` (envolver o corpo com o wash)
- Test: `test/painel_smoke_test.dart` (deve continuar passando)

**Interfaces:**
- Consumes: `ColorScheme` (esmeralda `primary`, ouro `tertiary`), `surface`.

- [ ] **Step 1: Adicionar o wash** — um `DecoratedBox` estático atrás do `ListView` do `_PainelBody`, sob `RepaintBoundary`. No escuro, dois glows radiais; no claro, ~nada:

```dart
Widget _ambientWash(BuildContext context, Widget child) {
  final ColorScheme cs = Theme.of(context).colorScheme;
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  if (!dark) return child; // claro é sóbrio
  return RepaintBoundary(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.9, -1),
          radius: 1.3,
          colors: <Color>[cs.primary.withValues(alpha: 0.04), cs.surface.withValues(alpha: 0)],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1, 1),
            radius: 1.3,
            colors: <Color>[cs.tertiary.withValues(alpha: 0.025), cs.surface.withValues(alpha: 0)],
          ),
        ),
        child: child,
      ),
    ),
  );
}
```

Envolver o `ListView` do `_PainelBody` com `_ambientWash(context, ListView(...))`.

- [ ] **Step 2: Regressão** — `fvm flutter test test/painel_smoke_test.dart` → PASS.

- [ ] **Step 3: Verificar no device** — **Aceite:** no escuro, o fundo tem um brilho esmeralda muito sutil no topo-esquerda e ouro no rodapé-direita (sensação "dentro do cofre"), sem "lavar" de verde. No claro, o fundo continua papel limpo.

- [ ] **Step 4: Commit**

```bash
fvm flutter analyze && fvm flutter test
git add lib/features/painel/painel_screen.dart
git commit -m "feat(ui): wash de ambiente (aurora do cofre) no fundo do painel"
```

---

## Task 5: Setting "Reduzir transparência" (habilita o fallback da navbar)

**Files:**
- Modify: `lib/core/settings/settings_repository.dart` (chave `reduce_transparency`)
- Modify: `lib/core/providers.dart` (`reduceTransparencyProvider`, espelhando `telemetryProvider`)
- Modify: `lib/features/config/config_screen.dart` (switch na seção APARÊNCIA) — **eu vou primeiro nesta tela**
- Test: `test/reduce_transparency_test.dart`

**Interfaces:**
- Produces: `reduceTransparencyProvider` (`NotifierProvider<ReduceTransparencyNotifier, bool>`), lido pela navbar (Task 6). `SettingsRepository.reduceTransparency()` / `setReduceTransparency(bool)`.

- [ ] **Step 1: Teste que falha** — `test/reduce_transparency_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reduceTransparency default é false e persiste', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsRepository repo = SettingsRepository(
      await SharedPreferences.getInstance(),
    );
    expect(repo.reduceTransparency(), isFalse);
    await repo.setReduceTransparency(true);
    expect(repo.reduceTransparency(), isTrue);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** — `fvm flutter test test/reduce_transparency_test.dart` → FAIL.

- [ ] **Step 3: Implementar no repo** — em `settings_repository.dart`, junto do `_kTelemetry`:

```dart
static const String _kReduceTransparency = 'reduce_transparency';
bool reduceTransparency() => _prefs.getBool(_kReduceTransparency) ?? false;
Future<void> setReduceTransparency(bool v) =>
    _prefs.setBool(_kReduceTransparency, v);
```

- [ ] **Step 4: Provider** — em `providers.dart`, espelhar `TelemetryNotifier`:

```dart
class ReduceTransparencyNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).reduceTransparency();
  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setReduceTransparency(value);
    state = value;
  }
}

final NotifierProvider<ReduceTransparencyNotifier, bool>
    reduceTransparencyProvider =
    NotifierProvider<ReduceTransparencyNotifier, bool>(
      ReduceTransparencyNotifier.new,
    );
```

- [ ] **Step 5: UI na Config** — em `config_screen.dart`, na seção APARÊNCIA (logo após o `SegmentedButton` de tema, antes do `SizedBox(height: Space.x6)` da L67), adicionar dentro de um `PanelCard` (ou `Card`) um `SwitchListTile`:

```dart
final bool reduzirTransp = ref.watch(reduceTransparencyProvider);
// ...
const SizedBox(height: Space.x3),
Card(
  color: theme.colorScheme.surfaceContainer,
  child: SwitchListTile(
    value: reduzirTransp,
    onChanged: (bool v) {
      Haptics.select();
      ref.read(reduceTransparencyProvider.notifier).set(v);
    },
    title: const Text('Reduzir transparência'),
    subtitle: const Text('Deixa a barra de navegação sólida (melhor em aparelhos mais simples).'),
  ),
),
```

- [ ] **Step 6: Rodar e ver passar** — `fvm flutter test test/reduce_transparency_test.dart` → PASS.

- [ ] **Step 7: Commit**

```bash
fvm flutter analyze && fvm flutter test
git add lib/core/settings/settings_repository.dart lib/core/providers.dart lib/features/config/config_screen.dart test/reduce_transparency_test.dart
git commit -m "feat(config): setting Reduzir transparencia (habilita fallback opaco da nav)"
```

---

## Task 6: Navbar flutuante de vidro real

**Files:**
- Modify: `lib/app/nav_shell.dart` (reestruturar: `extendBody`, pílula de vidro em volta do `NavigationBar` nativo, fallback)
- Modify: `lib/core/theme/app_theme.dart` (`navigationBarTheme` — indicador premium, transparente)
- Test: `test/nav_glass_test.dart` (novo) + `test/painel_smoke_test.dart` (deve continuar passando)

**Interfaces:**
- Consumes: `Materials` (Task 1), `reduceTransparencyProvider` (Task 5), `MediaQuery.accessibleNavigation`.
- Produces: nada pra outras tasks. Mantém o `NavigationBar` nativo (semântica de aba preservada) — por isso o smoke test (`find.byType(NavigationBar)`) continua válido.

**Decisão de design (travada):** envolver o `NavigationBar` NATIVO no vidro em vez de reconstruir custom. Preserva a semântica de aba do TalkBack (rec. Amara) e o smoke test. A "vida" vem do indicador nativo animado + o float de vidro + rótulos sempre visíveis. A pílula custom "que viaja" fica como upgrade futuro (exigiria `Semantics` manual + atualizar o smoke test) — fora desta leva.

- [ ] **Step 1: Teste que falha (fallback)** — `test/nav_glass_test.dart`: com leitor de tela ativo (`accessibleNavigation: true`), a navbar NÃO usa `BackdropFilter`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, {required bool accessible}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{'onboarding_done': true});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MediaQuery(
        data: MediaQueryData(accessibleNavigation: accessible),
        child: const QuantoCobroApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('navbar usa vidro (BackdropFilter) por padrão', (t) async {
    await _pump(t, accessible: false);
    expect(find.byType(BackdropFilter), findsWidgets);
  });

  testWidgets('com leitor de tela, navbar cai pro fallback opaco (sem blur)', (t) async {
    await _pump(t, accessible: true);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** — `fvm flutter test test/nav_glass_test.dart` → FAIL (hoje não há `BackdropFilter` e não há gate).

- [ ] **Step 3: Tema da NavigationBar** — em `app_theme.dart`, dentro do `_build`, adicionar (deixa a barra transparente pro vidro aparecer + indicador premium):

```dart
navigationBarTheme: NavigationBarThemeData(
  backgroundColor: Colors.transparent,
  surfaceTintColor: Colors.transparent,
  shadowColor: Colors.transparent,
  elevation: 0,
  height: 64,
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  indicatorColor: scheme.primary.withValues(alpha: 0.16), // ativo "abraçado"
  indicatorShape: const StadiumBorder(),
),
```

- [ ] **Step 4: Reestruturar a `NavShell`** — em `nav_shell.dart`, `extendBody: true`, corpo só o shell, e a `bottomNavigationBar` vira a pílula de vidro com fallback. Manter os `NavigationDestination` idênticos e o `Haptics.select()`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    extendBody: true,
    body: navigationShell, // conteúdo rola POR BAIXO da barra
    bottomNavigationBar: _GlassBottomBar(navigationShell: navigationShell),
  );
}
```

E o widget da barra (novo, no mesmo arquivo), consumindo o fallback:

```dart
class _GlassBottomBar extends ConsumerWidget {
  const _GlassBottomBar({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Materials m = Theme.of(context).extension<Materials>()!;
    final bool solido = MediaQuery.of(context).accessibleNavigation ||
        ref.watch(reduceTransparencyProvider);

    final Widget bar = NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (int i) {
        Haptics.select();
        navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
      },
      destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
        NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Histórico'),
        NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Trabalhos'),
      ],
    );

    // Fundo: sólido (fallback) OU vidro (blur + tint >=0.88). Um só ramo cria BackdropFilter.
    final Widget fundo = solido
        ? ColoredBox(color: m.glassFill.withValues(alpha: 1), child: bar)
        : BackdropFilter(
            filter: ImageFilter.blur(sigmaX: m.glassBlurSigma, sigmaY: m.glassBlurSigma),
            child: ColoredBox(color: m.glassFill, child: bar), // glassFill já é ~0.88
          );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x3),
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radii.xl2),
              boxShadow: <BoxShadow>[
                BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8)),
                BoxShadow(color: m.navHalo, blurRadius: 32), // halo <=0.12
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radii.xl2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
                  borderRadius: const BorderRadius.all(Radii.xl2),
                ),
                child: fundo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Imports a adicionar em `nav_shell.dart`: `dart:ui` (`ImageFilter`), `flutter_riverpod`, `../core/providers.dart`, `../core/theme/materials.dart`, `../core/theme/tokens.dart`.

> NOTA: o `AdSlot` saiu daqui (estava no `Column` do body). Ele volta na Task 7, como card flutuante acima da pílula.

- [ ] **Step 5: Rodar e ver passar** — `fvm flutter test test/nav_glass_test.dart` → PASS. E `fvm flutter test test/painel_smoke_test.dart` → PASS (o `NavigationBar` nativo continua lá, com os 3 rótulos).

- [ ] **Step 6: Verificar no device** — **Aceite:** a barra flutua descolada das bordas, cantos arredondados (28), com blur do conteúdo atrás visível mas rótulos 100% legíveis; halo esmeralda sutil; aba ativa "abraçada" pelo indicador; alvos ≥48dp. Ligar "Reduzir transparência" (ou TalkBack) → barra fica sólida, sem blur.

- [ ] **Step 7: Commit**

```bash
fvm flutter analyze && fvm flutter test
git add lib/app/nav_shell.dart lib/core/theme/app_theme.dart test/nav_glass_test.dart
git commit -m "feat(nav): navbar flutuante de vidro real com fallback opaco (a11y/perf)"
```

---

## Task 7: Padding do conteúdo + banner como card flutuante

**Files:**
- Modify: `lib/core/ads/ads.dart` (`_AdPlaceholder` vira card flutuante)
- Modify: `lib/app/nav_shell.dart` (compor o `AdSlot` acima da pílula, dentro do bottom bar)
- Modify: `lib/features/painel/painel_screen.dart`, `lib/features/historico/historico_screen.dart`, `lib/features/perfis/perfis_screen.dart` (padding inferior nas `ListView`)
- Test: `test/painel_smoke_test.dart` + `test/nav_glass_test.dart` (regressão)

**Interfaces:**
- Consumes: `AdSlot` (já existente, se auto-esconde quando Pro/sem cálculo).

- [ ] **Step 1: Banner como card flutuante** — em `ads.dart`, no `_AdPlaceholder`, trocar a `Container` de borda-topo por um card arredondado com margens laterais (combinar com a pílula da nav): `margin: EdgeInsets.symmetric(horizontal: Space.x4)`, `borderRadius: Radii.lg`, `border: Border.all(outlineVariant)`, remover o `Border(top:)`. Corrigir também o `fontSize: 9` hardcoded (L93) → usar `labelSmall` do tema (handoff a11y, item barato).

- [ ] **Step 2: Compor no bottom bar** — em `_GlassBottomBar` (Task 6), envolver o retorno num `Column(mainAxisSize: min)` com o `AdSlot()` acima da pílula:

```dart
return SafeArea(
  top: false,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const AdSlot(), // self-hides p/ Pro / antes do 1º cálculo
      const SizedBox(height: Space.x2),
      Padding(padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x3), child: /* pílula */),
    ],
  ),
);
```

- [ ] **Step 3: Padding inferior nas 3 abas** — como o conteúdo agora rola por baixo da barra, dar folga inferior nas `ListView` de Painel, Histórico e Trabalhos pra o último item não sumir. Trocar `padding: const EdgeInsets.all(Space.x4)` por um que reserve o rodapé:

```dart
padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, 120),
```

(120 ≈ pílula 64 + banner 56 + gaps; a `SafeArea` da barra cuida do inset do sistema. Ajustar no device se sobrar/faltar folga.)

- [ ] **Step 4: Regressão** — `fvm flutter test` (o smoke test troca de abas; garantir que não quebra e nada some).

- [ ] **Step 5: Verificar no device** — **Aceite:** com um cálculo salvo (não-Pro), o banner aparece como card flutuante acima da pílula; o último item de cada aba é totalmente visível (não fica atrás da barra); ligar Pro esconde o banner sem deixar buraco.

- [ ] **Step 6: Commit**

```bash
fvm flutter analyze && fvm flutter test
git add lib/core/ads/ads.dart lib/app/nav_shell.dart lib/features/painel/painel_screen.dart lib/features/historico/historico_screen.dart lib/features/perfis/perfis_screen.dart
git commit -m "feat(nav): banner como card flutuante + padding pro conteudo nao sumir sob a nav"
```

---

## Self-Review — cobertura do spec (Leva 1)

| Item do spec (Leva 1) | Task |
|---|---|
| §4.1 Material nos cards (`PanelCard` + `Materials`) | T1, T2, T3 |
| §4.1 Glow de acento ≤0.08 (ouro/aço nos ToolCards) | T2, T3 |
| §4.2 Wash de ambiente | T4 |
| §4.3 Navbar de vidro real (`extendBody`, blur, tint ≥0.88) | T6 |
| §4.3 Fallback opaco (accessibleNavigation OU setting) | T5, T6 |
| §4.3 Rótulos sempre visíveis + alvo ≥48dp + semântica nativa | T6 |
| §4.3 Banner vira card flutuante + padding das listas | T7 |
| §4.4 Setting "Reduzir transparência" | T5 |
| Handoff #2 (chevron/AppBar ≥48dp) | parcial em T6 (nav); chevron do herói fica pra Leva 3 (herói) |

**Placeholders:** nenhum — todo passo tem código ou comando concreto. Os passos de craft visual são explicitamente "verificar no device" com aceite objetivo (gradiente/alpha não são unit-testáveis; forçar assert neles seria pior).

**Consistência de tipos:** `Materials` (campos e estáticos) idêntico entre T1 (definição) e T2/T6 (uso). `reduceTransparencyProvider` idêntico entre T5 (definição) e T6 (uso). `PanelCard` assinatura idêntica entre T2 e T3.

**Fora da Leva 1 (não regredir, mas não fazer aqui):** escala de fonte + overflow (Leva 2), herói-joia + "acender o cofre" + sinal +/− (Leva 3), pílula custom "que viaja" (upgrade futuro).

---

## Execution Handoff

Plano salvo em `docs/superpowers/plans/2026-07-19-redesign-leva1-material-navbar.md`.

**Ordem sugerida:** T1 → T2 → T3 → T4 (material, colisão-zero) → T5 (setting) → T6 (navbar) → T7 (padding/banner). T1-T4 não encostam em nada da trilha de personas; T6/T7 são 100% meus; T3 (resultado) e T5 (config) pedem `git pull`/rebase antes por serem zonas compartilhadas.
