# Melhorias do teste de 8 personas — Plano de Execução

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (recomendado) ou `superpowers:executing-plans` pra implementar tarefa a tarefa. Os passos usam checkbox (`- [ ]`) pra rastreio.

**Goal:** Corrigir os furos que 8 testadores-persona acharam no "Quanto Cobro?" — sem colidir com a trilha visual que roda em paralelo — cobrindo leitor de tela, linguagem para leigo, moeda/câmbio e gestão de projeto recorrente.

**Architecture:** Quatro fases independentes, cada uma entregando software testável sozinho. A minha trilha é **lógica, dados, semântica de leitor de tela e copy**; a trilha visual (outro agente) é **cards, nav, tema, motion e escala de fonte**. Onde as trilhas se cruzam (`config_screen.dart`, `reserva_screen.dart`, `onboarding_screen.dart`, `resultado_screen.dart`), este plano cede o visual e fica só na sua camada.

**Tech Stack:** Flutter · Riverpod 3 · go_router 17 · intl 0.20 · shared_preferences 2.5 · flutter_test. Fase 3 adiciona `http` (cotação) — dep nova, ver Fase 3.

## Global Constraints

- **Offline-first, não offline-absoluto.** A única exceção de rede permitida é **puxar cotação de câmbio pública** (Fase 3), sob ação explícita do usuário, com mensagem transparente ("ligue a internet pra atualizar a cotação"). **Nenhum dado do usuário sai do device, nunca.** Isso vira 1 item no Data Safety da Play.
- **Formatação de dinheiro SEMPRE via `intl`** (`core/common/money.dart`), nunca concatenação manual.
- **Multi-trabalho continua Pro.** Grátis = 1 trabalho. Recorrência mensal/avulso funciona no trabalho único grátis (pra o hábito valer pra todos); gerir **vários** trabalhos segue Pro (`entitlement.isPro`).
- **Todo JSON persistido precisa migrar campo novo com default** (`fromJson` tolera ausência) — há backup/restore em produção (`perfil_json_test.dart` guarda isso).
- **Todo momento que VIBRA ou ANIMA também FALA** (regra Amara): valor novo relevante → `announce(context, ...)` de `core/ui/a11y.dart`.
- **Nomenclatura na UI:** "trabalho" (nunca "perfil"), "reserva"/"o Leão" pra imposto — mas a Fase 2 revisa quando a metáfora confunde.

---

## Coordenação com a trilha visual (ler antes de começar)

O outro agente está mexendo em: nav bar (flutuante/translúcida), cards/componentes premium (`core/ui/*`, `theme/*`), e **ajuste de tamanho de fonte** nas Config (pequeno/padrão/grande) + "fontes estourando".

**Regras de não-colisão:**

1. **NÃO tocar em visual/tema/nav/motion.** Fica com ele: `nav_shell.dart`, `hero_value_card.dart`, `tool_action_card.dart`, `vitrine_card.dart`, `app_colors.dart`, `tokens.dart`, `color_scheme.dart`, `app_typography.dart`, `motion.dart`.
2. **Escala de fonte é dele.** Os achados do Seu Ademir (barra 20px fixa, legendas/ícones que não crescem com a fonte, chevron 18px, alvos no AppBar/nav) **saem deste plano** e viram handoff pra trilha visual (seção "Handoff pra trilha visual" no fim). Não implementar aqui.
3. **`config_screen.dart` é zona compartilhada.** O setting de fonte é dele. Meus settings (Fase 4: lembrete/recorrência) entram **por último** e só depois de confirmar com ele que a estrutura da tela estabilizou. Se possível, adiciono minha seção sem reescrever as dele.
4. **`reserva_screen.dart` / `onboarding_screen.dart` / `resultado_screen.dart` são compartilhados.** Eu mexo só na **camada semântica/copy/lógica** (Semantics, `announce`, texto, seletor de moeda); ele mexe no **visual** (estilo do card, cores, motion). Antes de editar, `git pull`/rebase e conferir se ele acabou de tocar o arquivo.
5. **Sinal +/− no lucro (Rafael)** é apresentação → handoff pra trilha visual.

---

## File Structure (o que cada arquivo passa a ser responsável)

**Fase 1 — leitor de tela (não-visual):**
- `lib/features/reserva/reserva_screen.dart` — MODIFICAR: envolver a barra colapsada em `Semantics`; anunciar recálculo ao trocar regime.
- `test/reserva_a11y_test.dart` — CRIAR: garante rótulo semântico da barra e presença do valor recalculado.

**Fase 2 — linguagem para leigo (copy/help):**
- `lib/features/calc/calc_screen.dart` — MODIFICAR: "?" por regime no passo 4.
- `lib/features/resultado/resultado_screen.dart` — MODIFICAR: trocar "gross-up" por português.
- `lib/features/onboarding/onboarding_screen.dart` — MODIFICAR: explicar "regime" antes de citar; suavizar "pré-ajusta".
- `lib/core/glossario/glossario.dart` — CRIAR: fonte única dos textos de ajuda (Leão, regime, reserva, pró-labore, alíquota, carnê-leão), pra copy não espalhar.
- `lib/core/ui/help_dot.dart` — CRIAR: ícone "?" acessível reutilizável (abre bottom sheet com o verbete).

**Fase 3 — moeda & câmbio (offline-first):**
- `lib/core/model/moeda.dart` — CRIAR: `Moeda` (código, símbolo, casas decimais, locale).
- `lib/core/common/money.dart` — MODIFICAR: `money(value, moeda)` genérico; `moneyBRL` vira atalho.
- `lib/core/fx/fx_service.dart` — CRIAR: busca cotação (http), cacheia última em prefs, expõe `override` manual.
- `lib/core/fx/fx_repository.dart` — CRIAR: cache/leitura da cotação + timestamp.
- `lib/features/reserva/reserva_screen.dart` — MODIFICAR: seletor de moeda + linha de câmbio (só lógica/estado).
- `lib/core/model/regime.dart` + `lib/core/calc/tax_tables.dart` — MODIFICAR: separar "CPF exterior / carnê-leão puro" (sem INSS) do MEI.

**Fase 4 — gestão & recorrência (Pro na parte multi):**
- `lib/core/model/perfil.dart` — MODIFICAR: campo `tipoContrato` (mensal/avulso) + migração.
- `lib/core/model/reserva_entry.dart` — MODIFICAR: já tem `at` e `valor`; garantir agregação por mês/trabalho (sem mudança de schema, só leitura).
- `lib/core/data/reserva_history_repository.dart` — MODIFICAR: agregados "bruto recebido no mês por trabalho".
- `lib/features/historico/historico_screen.dart` — MODIFICAR: quebra por mês + total bruto por cliente (lógica; visual coordenado).
- `lib/core/reminders/reminder_service.dart` — CRIAR: lembrete local mensal pros trabalhos mensais (notificação local, opt-in).
- `lib/features/config/config_screen.dart` — MODIFICAR (POR ÚLTIMO, coordenado): toggle de lembrete.

---

## FASE 1 — Leitor de tela na Reserva (colisão-zero, começa aqui)

> Fecha os 2 furos da Joana (cega) na tela mais usada. Tudo é semântica/lógica invisível — não encosta em visual, então roda em paralelo com a trilha visual sem conflito.

### Task 1: `Semantics` na barra colapsada da Reserva

**Files:**
- Modify: `lib/features/reserva/reserva_screen.dart` (função `_barraColapsada`, ~linha 361)
- Test: `test/reserva_a11y_test.dart`

**Interfaces:**
- Consumes: `moneyBRL` (`core/common/money.dart`), `ReservaResult` (campos `reserva`), o padrão de `DivisaoBar` (`core/ui/divisao_bar.dart:55-63`) como referência.
- Produces: nada novo pra outras tasks; só um nó semântico com rótulo `"Pra usar <R$>, <p>%. Reserva <R$>, <p>%."`.

- [ ] **Step 1: Escrever o teste que falha** — `test/reserva_a11y_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/divisao_colors.dart';
// A barra é privada; testamos por um wrapper mínimo que replica a chamada.
// Alternativa aceita: extrair `_barraColapsada` pra um widget público
// `ReservaBar` (recomendado) e testar direto. Este teste assume ReservaBar.
import 'package:quantocobro/features/reserva/reserva_bar.dart';

void main() {
  testWidgets('ReservaBar expõe rótulo semântico com pra-usar e reserva', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const <ThemeExtension<dynamic>>[
          DivisaoColors.dark,
        ]),
        home: const Scaffold(
          body: ReservaBar(amount: 2000, reserva: 320),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'Pra usar.*1\.680.*Reserva.*320'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/reserva_a11y_test.dart`
Expected: FAIL — `reserva_bar.dart` não existe / label ausente.

- [ ] **Step 3: Extrair `ReservaBar` e envolver em `Semantics`** — criar `lib/features/reserva/reserva_bar.dart` movendo o corpo de `_barraColapsada`, agora com rótulo (espelha `DivisaoBar`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../../core/common/money.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';

/// Barra "Pra usar × Reserva" da tela de Reserva. Mesma regra da DivisaoBar:
/// rótulo semântico conta tudo numa parada; a pintura é ExcludeSemantics.
class ReservaBar extends StatelessWidget {
  const ReservaBar({super.key, required this.amount, required this.reserva});

  final int amount;
  final int reserva;

  @override
  Widget build(BuildContext context) {
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    final int usar = (amount - reserva).clamp(0, amount);
    int pct(int v) => amount <= 0 ? 0 : (v / amount * 100).round();
    final String semantica =
        'Pra usar ${moneyBRL(usar)}, ${pct(usar)} por cento. '
        'Reserva ${moneyBRL(reserva)}, ${pct(reserva)} por cento.';
    final double fR = amount <= 0 ? 0 : reserva / amount;

    return Semantics(
      container: true,
      label: semantica,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radii.sm),
          child: SizedBox(
            height: 20,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final bool reduce = reduceMotionOf(context);
                final double w = c.maxWidth - 2;
                return Row(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: reduce ? Duration.zero : Motion.quick,
                      curve: MotionCurves.standard,
                      width: w * (1 - fR),
                      color: d.custo,
                    ),
                    const SizedBox(width: 2),
                    AnimatedContainer(
                      duration: reduce ? Duration.zero : Motion.quick,
                      curve: MotionCurves.standard,
                      width: w * fR,
                      color: d.reserva,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

> NOTA de coordenação: a altura `20` fixa é reclamação de escala de fonte do Seu Ademir → **fica pra trilha visual** resolver quando fizer o setting de fonte. Aqui só mantenho o comportamento visual atual e adiciono a semântica.

- [ ] **Step 4: Trocar a chamada em `reserva_screen.dart`** — substituir `_barraColapsada(context, d, res, amount)` por `ReservaBar(amount: amount, reserva: res.reserva)` e remover a função privada antiga (importar `reserva_bar.dart`).

- [ ] **Step 5: Rodar e ver passar**

Run: `flutter test test/reserva_a11y_test.dart`
Expected: PASS.

- [ ] **Step 6: Regressão + commit**

```bash
flutter test
git add lib/features/reserva/reserva_bar.dart lib/features/reserva/reserva_screen.dart test/reserva_a11y_test.dart
git commit -m "a11y(reserva): barra Pra-usar×Reserva ganha rótulo de leitor de tela"
```

### Task 2: Anunciar recálculo ao trocar o regime na Reserva

**Files:**
- Modify: `lib/features/reserva/reserva_screen.dart` (`onSelected` do `ChoiceChip` de regime, ~linha 159; usar o mesmo `_announceResult`/`announce` que a tela já tem pro resultado)

**Interfaces:**
- Consumes: `announce(context, String)` (`core/ui/a11y.dart`), o cálculo de reserva já existente na tela (o mesmo que gera o anúncio automático de 900ms).
- Produces: nada novo; só passa a falar "Regime <tag>. Reserve <R$>. Sobra <R$>." ao trocar chip.

- [ ] **Step 1: Teste que falha** — adicionar em `test/reserva_a11y_test.dart` um teste que captura anúncios via canal de acessibilidade:

```dart
testWidgets('trocar regime na Reserva anuncia o novo valor', (
  WidgetTester tester,
) async {
  final List<String> announces = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
    SystemChannels.accessibility,
    (dynamic message) async {
      final Map<dynamic, dynamic> m = message as Map<dynamic, dynamic>;
      if (m['type'] == 'announce') {
        announces.add((m['data'] as Map<dynamic, dynamic>)['message'] as String);
      }
      return null;
    },
  );
  // ... montar a ReservaScreen com um valor já digitado (override de providers),
  // tocar no chip "Autônomo" e pumpAndSettle.
  // expect(announces.any((a) => a.contains('Reserve')), isTrue);
});
```

> NOTA: capturar `SystemChannels.accessibility` é o jeito honesto de testar `announce`. Se o setup de providers da `ReservaScreen` ficar caro, é aceito reduzir a um teste de unidade da função de montagem da string + verificação manual no device (documentar no PR). O importante é o Step 3.

- [ ] **Step 2: Rodar e ver falhar** — `flutter test test/reserva_a11y_test.dart` → FAIL (nenhum announce ao trocar chip).

- [ ] **Step 3: Chamar o anúncio no `onSelected`** — dentro do `onSelected` do chip (após o `setState` que faz `_regime = r.id; _saved = false;`), disparar o mesmo recálculo+anúncio que o campo já usa. Reaproveitar a função privada que hoje monta o texto do resultado (ex.: `_announceResult()`), garantindo que ela leia o `_regime` novo:

```dart
onSelected: (_) async {
  Haptics.select();
  setState(() {
    _regime = r.id;
    _saved = false;
  });
  _announceResult(); // <- espelha o que a Calculadora já faz (calc_screen.dart:875)
  if (st is ProfileReady) {
    await ref.read(settingsRepositoryProvider).setReservaRegime(
          st.perfil.id, st.perfil.regime.name, r.id.name,
        );
  }
},
```

Se `_announceResult` não existir com esse nome, extrair o trecho que hoje anuncia o resultado (o do debounce de 900ms) pra um método reusável e chamá-lo aqui.

- [ ] **Step 4: Rodar e ver passar** — `flutter test test/reserva_a11y_test.dart` → PASS.

- [ ] **Step 5: Commit**

```bash
flutter test
git add lib/features/reserva/reserva_screen.dart test/reserva_a11y_test.dart
git commit -m "a11y(reserva): trocar regime anuncia o novo valor no leitor de tela"
```

### Task 3 (condicional — 🤝 confirmar com a trilha visual): alvo de toque do "deletar custo"

**Só executar se o outro agente NÃO estiver reestilizando os chips de custo em `calc_screen.dart`.** Perguntar antes.

**Files:**
- Modify: `lib/features/calc/calc_screen.dart` (`IconButton` de remover custo, ~linha 627)

- [ ] **Step 1: Teste que falha** — `test/calc_touch_test.dart`: monta o passo de custos, encontra o `IconButton` de delete e afirma `tester.getSize(...) >= const Size(48, 48)`.
- [ ] **Step 2:** rodar → FAIL (alvo < 48dp).
- [ ] **Step 3:** dar `constraints: const BoxConstraints(minWidth: 48, minHeight: 48)` (ou `IconButton(style: IconButton.styleFrom(minimumSize: const Size(48,48)))`) ao botão; manter o ícone visual como está (não é restyle, é área de toque).
- [ ] **Step 4:** rodar → PASS.
- [ ] **Step 5:** commit `a11y(calc): alvo de toque do remover-custo ≥ 48dp`.

> Espaçamento de chips (8→12dp) e alvos no AppBar/nav → **handoff pra trilha visual** (ela está reestilizando esses componentes).

---

## FASE 2 — Linguagem para leigo (copy/help)

> Fecha o maior ofensor de "faz sentido?": Bruno (6/10) escolhe regime no chute; Dona Marta (6/10) quase desiste em "Leão/regime/pré-ajusta". Copy + um componente de ajuda. Baixa colisão (só divide arquivos compartilhados — sempre camada de texto, nunca visual).

**Cada verbete vive em `lib/core/glossario/glossario.dart`** (fonte única) e é exibido por `HelpDot` (`lib/core/ui/help_dot.dart`), um "?" de 24×24 com `Semantics(button:true, label:'O que é <termo>?')` que abre um `showModalBottomSheet` com a explicação em 1–2 frases.

**Tasks (viram plano TDD completo próprio ao iniciar a fase):**
1. **`Glossario`** — mapa `termo → (titulo, texto_leigo)` cobrindo: `leao`, `regime`, `reserva`, `prolabore`, `aliquota`, `carne_leao`, `das`, `simples`, `mei`, `cpf`, `gross_up`. Teste: cada verbete tem título e ≤ 220 chars. Texto exemplo — regime: *"É como você trabalha aos olhos do imposto. Nunca abriu empresa? Você provavelmente é 'Autônomo (CPF)'. Abriu MEI? Escolha MEI."*
2. **`HelpDot`** — widget "?" acessível + bottom sheet. Teste: tocar abre sheet com o texto do verbete; tem rótulo semântico.
3. **Passo 4 da calc** (`calc_screen.dart` ~832): um `HelpDot` por opção de regime (MEI/CPF/Simples/Intl), 1 frase cada. Teste: 4 HelpDots no passo 4.
4. **"gross-up" fora do resultado** (`resultado_screen.dart:398`): trocar por *"já considerando o imposto embutido"* (ou `HelpDot` no termo). Teste: a string "gross-up" não aparece na árvore renderizada do CPF.
5. **Onboarding** (`onboarding_screen.dart:206`): não citar "regime" sem explicar. Trocar *"pré-ajusta seu regime"* por *"já deixo pré-escolhido como você trabalha; você confirma no passo 4"*. Teste de widget: a palavra "regime" não aparece na 3ª tela do onboarding (ou aparece junto de um HelpDot).
6. **Chips de custo** `prolabore`/`equip` (`custo.dart`): rótulo mais claro ("Pró-labore (seu salário)") + verbete. Teste: label contém a dica.

> Coordenação: `onboarding_screen.dart` e `resultado_screen.dart` são compartilhados — editar só as strings/HelpDot, rebase antes.

---

## FASE 3 — Moeda & câmbio (offline-first, transparente)

> Fecha Marina (3/10): "exterior" não é dólar; sem moeda nem câmbio o cálculo é absurdo. Vira multi-moeda com cotação puxada sob demanda (com internet), cache da última, e override manual da taxa exata do recebimento.

**Arquitetura da exceção de rede (respeita a Global Constraint):**
- `Moeda` (`core/model/moeda.dart`): `{codigo:'USD', simbolo:'US\$', casas:2, locale:'en_US'}`. Lista curada: BRL, USD, EUR, GBP, e um "Outra…" que aceita código ISO.
- `FxService` (`core/fx/fx_service.dart`): `Future<FxRate> cotacao(Moeda de, Moeda para)`. Usa `http` GET numa API pública de câmbio (ex.: exchangerate.host / open.er-api.com — **sem chave, sem enviar dado**). Em erro/offline: devolve a **última cacheada** com `stale:true` e data.
- `FxRepository` (`core/fx/fx_repository.dart`): guarda `{par, taxa, at}` em prefs. Override manual grava `manual:true` e ganha prioridade.
- **Transparência:** ao escolher moeda ≠ BRL na Reserva, mostrar linha *"Cotação de DD/MM: US\$ 1 = R\$ X · [Atualizar] [Digitar a minha]"*. Se offline e sem cache: *"Ligue a internet uma vez pra puxar a cotação, ou digite a sua."* (só lógica/estado; o estilo dessa linha é da trilha visual).
- **Data Safety:** adicionar declaração "o app faz uma requisição de rede pra buscar cotação de câmbio pública; nenhum dado pessoal é coletado/enviado". (item de release, não código.)

**Regime carnê-leão puro:** hoje `RegimeId.intl` é flat 25–30% e `RegimeId.cpf` soma INSS. Marina (CPF exterior) não é nenhum. Adicionar tratamento "CPF exterior / carnê-leão sem INSS" — reusar o progressivo do CPF (`tax_tables.dart`) sem a parcela de INSS. Decisão de modelagem a confirmar na abertura da fase (novo `RegimeId` vs flag no CPF).

**Tasks (viram plano TDD completo ao iniciar):**
1. `Moeda` + lista curada (+ teste round-trip JSON).
2. `money(value, Moeda)` genérico em `money.dart`; `moneyBRL` = `money(v, Moeda.brl)`. Teste: `money(1000, USD)` → "US\$ 1,000".
3. `FxRepository` (cache prefs + timestamp + override). Teste com `SharedPreferences.setMockInitialValues`.
4. `FxService` com `http` (dep nova: `http: ^1.2.0`) — teste com `http` client mockado (sucesso, erro→stale, offline→cache).
5. Reserva: estado de moeda + linha de câmbio + override (lógica; visual coordenado). Teste: escolher USD converte o valor exibido e a reserva usa o valor em BRL convertido.
6. Regime carnê-leão puro no `calc_engine`/`tax_tables`. Teste de cálculo (sem INSS, progressivo).

> Dep nova `http` — confirmar com a trilha visual (não conflita, mas é edição de `pubspec.yaml`).

---

## FASE 4 — Gestão & recorrência (Pro na parte multi)

> Fecha Camila (4/10), a persona de maior retenção: sem mensal/avulso, sem lembrete, sem "quanto recebi no mês", histórico não soma bruto por cliente. Mudança de modelo de dados + migração + notificação local.

**Decisão de produto (Global Constraint):** multi-trabalho segue **Pro**. Mas `tipoContrato` e o loop "quanto recebi esse mês" funcionam **no trabalho único grátis** (deixa o hábito valer e a Camila *sentir* o valor antes de pagar). Gerir **vários** trabalhos = Pro (inalterado, `trabalho_switcher.dart:145`).

**Modelo de dados:**
- `Perfil.tipoContrato`: `enum TipoContrato { mensal, avulso }` (default `avulso` na migração — `fromJson` tolera ausência, igual ao padrão de `provisaoCustom`). Atualizar `toJson/fromJson/copyWith/Perfil.padrao` + **estender `perfil_json_test.dart`** (round-trip + legado sem o campo → `avulso`).
- `ReservaEntry` já tem `at` (DateTime) e `valor` (bruto) — **não muda schema**; a agregação é leitura.

**Tasks (viram plano TDD completo ao iniciar):**
1. `TipoContrato` + campos em `Perfil` (+ migração, + teste JSON legado). **Colisão-zero** (modelo puro).
2. `ReservaHistoryRepository`: `Map<String,int> brutoPorTrabalhoNoMes(DateTime)` e `int brutoDoMes(DateTime)`. Teste: soma correta, filtra por mês, ignora `das`.
3. Histórico agrupado por mês (cabeçalho jan/fev…) + total bruto por cliente (lógica; visual coordenado com a trilha visual). Teste de widget: aparece "GANHOU ESTE MÊS <R\$>" além de "GUARDADO".
4. `ReminderService` (`core/reminders/`): notificação local mensal pros trabalhos `mensal`, opt-in. Dep: `flutter_local_notifications`. Pergunta "quanto você recebeu esse mês?" → deep-link na Reserva. Teste: agenda/cancela conforme toggle. **Permissão nova (POST_NOTIFICATIONS)** → item de Data Safety/manifest.
5. **`config_screen.dart` (POR ÚLTIMO, coordenado com a trilha visual):** toggle "Lembrete mensal". Só adicionar a seção depois que o setting de fonte dele assentar.
6. Exportar histórico CSV (Pro) — `csv` simples do `ReservaEntry`. Teste: header + linhas.

---

## Self-Review — cobertura do relatório das 8 personas

| Achado (persona) | Fase/Task |
|---|---|
| Barra da Reserva muda no leitor de tela (Joana P1) | F1 T1 |
| Trocar regime recalcula em silêncio (Joana P1) | F1 T2 |
| Barra 20px + legendas não escalam com fonte (Ademir P1) | ⏭️ Handoff visual |
| Alvo "deletar custo" (Tiago P1) | F1 T3 (condicional) |
| Chips 8dp + alvos AppBar/nav (Tiago P1, Ademir P2) | ⏭️ Handoff visual |
| "regime" citado antes de explicar (Bruno/Marta P1) | F2 T3/T5 |
| Passo 4 sem "?" por regime (Bruno P1) | F2 T3 |
| "gross-up" em inglês (Bruno P1) | F2 T4 |
| "Leão/reserva=imposto?" confuso (Marta P0/P1) | F2 T1 (glossário) |
| "pró-labore/equipamento" sem explicação (Bruno P2) | F2 T6 |
| Moeda sempre R\$, sem USD (Marina P0) | F3 T1/T2/T5 |
| Sem câmbio (Marina P0) | F3 T3/T4/T5 |
| Carnê-leão puro inexistente (Marina P1) | F3 T6 |
| Sem mensal/avulso no modelo (Camila P0) | F4 T1 |
| Sem lembrete (Camila P0) | F4 T4/T5 |
| Multi-trabalho 100% Pro trava teste (Camila P0) | Decisão: mantido Pro; mensal/avulso liberado no grátis (F4 T1) |
| Histórico não soma bruto por cliente/mês (Camila P1) | F4 T2/T3 |
| "Meses anteriores" sem quebra (Camila P1) | F4 T3 |
| Sem exportar histórico (Camila P2) | F4 T6 |
| Sinal +/− no lucro (Rafael) | ⏭️ Handoff visual |

**Cobertura:** todos os P0/P1 têm dono. Os itens ⏭️ são cedidos à trilha visual de propósito (escala de fonte / apresentação), não esquecidos.

---

## Handoff pra trilha visual (itens que cedo de propósito)

Passar pro outro agente (são visual/escala de fonte, casam com o que ele já faz):
1. **Barra da Reserva e da Divisão crescerem com a fonte** (hoje `height: 20` fixo; legendas em `labelLarge` que não respeitam `textScaler`). — Ademir P1.
2. **Alvos de toque no AppBar/nav e chevron 18px** — ao redesenhar a nav flutuante e o AppBar, garantir ≥ 48dp e ícones que escalam. — Tiago/Ademir.
3. **Espaçamento dos chips de custo** (8→12–16dp) ao reestilizar os chips. — Tiago.
4. **Sinal +/− antes do número de lucro/prejuízo** no painel/resultado. — Rafael.
5. **Setting de tamanho de fonte** (pequeno/padrão/grande) — já é dele; meu único pedido é que o default não estoure as legendas da Divisão.

---

## Execution Handoff

Plano salvo em `docs/superpowers/plans/2026-07-19-melhorias-personas.md`. Duas formas de executar:

1. **Subagent-Driven (recomendado)** — um subagente novo por task, revisão entre tasks, iteração rápida. Começaria pela **Fase 1** (colisão-zero).
2. **Inline** — executo as tasks nesta sessão com checkpoints.

**Qual você prefere — e começamos pela Fase 1 (leitor de tela na Reserva), que não encosta na trilha visual?**
