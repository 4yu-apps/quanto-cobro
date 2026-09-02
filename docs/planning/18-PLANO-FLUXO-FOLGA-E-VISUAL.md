# 18 — Plano de execução: fluxo claro + folga + visual com personalidade (v0.10.0)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sair da 0.9.2 (publicada) pra uma 0.10.0 em que (1) o passo das horas deixa de confundir, (2) a proposta tem prazo e pagamento selecionáveis, (3) existe o Simulador de folga (férias como decisão de preço, não como cofrinho), (4) o app ganha personalidade visual sem trocar o Design System, e (5) os termos param de prometer "nunca terá anúncio".

**Architecture:** Duas trilhas em commits separados, como no [plano 17](17-PLANO-REDESIGN-E-FEATURES.md): **trilha B (fluxo/cálculo/modelo)** primeiro, **trilha A (visual)** depois, porque o visual estreia nas telas que a trilha B cria. Nada de aba nova, nada de cor nova, nada de plugin nativo novo. O motor de cálculo só ganha funções ao lado (`horasBrutasPorRotina`, `computeFolga`); `computeValorHora`, `computeReserva` e `computeSimulador` não mudam.

**Tech Stack:** Flutter 3.x / Dart 3.12 · Riverpod 3 · go_router 17 · shared_preferences · testes de widget com `test/support/tela.dart`.

**Spec:** a seção 0 deste documento (decisões tomadas com o Gabriel em 01/09/2026). Não existe spec separada de propósito: um agente executor lê um arquivo só.

## Global Constraints

- **Sem travessão (—) em NENHUM texto visível ao usuário.** Vírgula, dois-pontos ou ponto. (Regra da casa, commit `8d9b665`.)
- **Nenhuma cor nova na paleta.** Esmeralda (`cs.primary`), ouro (`DivisaoColors.reserva`), aço (`DivisaoColors.staleBg/staleFg`), terracota (`DivisaoColors.alerta*`), roxo 4YU só em Pro. Tetos de alpha da [doutrina](../design-build/DOUTRINA-DE-CONTENCAO.md): acento em card ≤ 8%, halo ≤ 12%, glow do herói ≤ 16%.
- **Três abas, sempre.** Início · Trabalhos · Ajustes. O teste `painel_smoke_test.dart` garante. Folga é ferramenta (rota empilhada), não aba.
- **Nada de SDK de anúncio nesta versão.** O anúncio entra depois (decisão do Gabriel, 01/09/2026). Ver Apêndice A.
- **Regra de privacidade da telemetria:** nenhum evento carrega dinheiro, nome ou texto digitado (`lib/core/telemetry/eventos.dart`).
- **Acessibilidade:** todo widget tocável novo tem `Semantics`/`SemanticButton`; toda animação consulta `reduceMotionOf(context)`; alvo mínimo 48dp; tudo precisa caber em `Tela.celularEmPe` (320×640) com `textScale` 2.0 sem estourar (os testes `layout_matrix`, `overflow` e `tablet` cobram).
- **Copy pro leigo:** nunca "faturável", "provisionar", "carga horária". Diga "horas que dá pra cobrar", "folga", "o que sobra".
- **Ritual de fecho de cada task:** `flutter analyze` sem issue → `flutter test` verde → commit próprio com a mensagem indicada. Nunca deixar o app quebrado entre tasks.
- **Não publicar nada** (site ou Play) sem o Gabriel dizer "vai" naquele momento. O plano marca os pontos.

---

## 0. As decisões (o que este plano implementa e por quê)

### 0.1 O passo das horas confunde (P0)
O passo 2 da calculadora ([calc_screen.dart:425](../../lib/features/calc/calc_screen.dart)) mistura três unidades numa tela: título "por semana", steppers "dias por semana" e "horas num dia", caixa "VOCÊ COBRA POR MÊS · 85 h". E o 85 não bate com 5 × 6 = 30 h/semana ≈ 130 h/mês, porque o app tira 35% em silêncio (`fatorPago = 0.65`). O leigo lê "o app errou" ou "eu não cobro por mês".

**Decisão:** as duas perguntas ficam (são exatamente "quantas horas por dia, quantos dias por semana"). Muda a **resposta**: uma frase com a conta à vista ("Você trabalha umas 130 h por mês. Dessas, dá pra cobrar umas 85 h."), o "digitar na mão" vira link discreto, e o pedaço de folga do desconto vira **explícito**: um terceiro stepper "Dias de folga por ano" (default 30). É a única pergunta nova, e é o que faz o valor-hora já embutir as férias.

### 0.2 Anúncio: os termos prometem "nunca", o Pro vende "sem anúncios"
O Gabriel **vai** colocar anúncio na versão grátis, mais pra frente. O Pro continua vendendo "sem anúncios" ([pro_screen.dart:107](../../lib/features/pro/pro_screen.dart), [config_screen.dart:184](../../lib/features/config/config_screen.dart)). O que sai é a promessa de "não integra nenhuma rede" dos **termos** (app + site), trocada por um texto verdadeiro hoje e que não precisa ser reescrito quando o anúncio entrar.

### 0.3 Doc do amigo: o que entra
| Sugestão | Decisão | Onde neste plano |
|---|---|---|
| Prazo da proposta só número + "dias" | ✅ | Task 5 |
| Forma de pagamento selecionável (Pix, cartão, boleto, sinal) | ✅ | Task 5 |
| Férias visível no cálculo | ✅ (dias de folga por ano) | Tasks 2, 3 |
| Prazo do projeto + tempo restante | ✅ (data de entrega no Trabalho, sem cronômetro) | Task 6 |
| Férias como "quanto minha hora precisa valer" (não cofrinho) | ✅ adaptado: **Simulador de folga** sem calendário, sem tracking, sem barra de progresso | Tasks 9, 10 |
| Alerta "capacidade no limite, reajuste o ticket" | ✅ adaptado: uma condição no Simulador de projeto | Task 7 |
| Botão de adicionar custo em cima | ✅ (um "+" ao lado do título) | Task 8 |
| IA pra dúvida de imposto | ❌ quebra offline, R5 (número fiscal errado) e custo | glossário ganha verbetes (Task 11) |
| Cronômetro / horas por dia / redistribuição de débito / burnout | ❌ é Toggl; sem hábito diário vira tela morta | não entra |
| Aba "Férias" | ❌ três abas | não entra |
| Taxas bancárias/internacionais na proposta | ❌ não é informação pro cliente | não entra |

### 0.4 Layout: por que ficou "card genérico de uma cor só"
As referências (dating lime, fitness laranja, audiobook, Taskez) têm em comum: **um acento quente usado grande** (não espalhado), **imagem/ilustração**, **elementos circulares**, **cabeçalho com identidade** ("Hey William!") e **navbar com ação central**. A nossa doutrina aplicou a "regra dos 10%" como timidez.

**Decisão (sem trocar DS):**
| # | Mudança | Task |
|---|---|---|
| L1 | "Recebi um pagamento" vira botão redondo esmeralda colado na navbar, alcançável de qualquer aba | 12 |
| L2 | Cabeçalho com nome ("Boa tarde, Gabriel"), nome opcional no onboarding e em Ajustes | 13 |
| L3 | Anel em vez de barra no Teto do MEI | 14 |
| L4 | Ilustração assinatura (`Cena`), composta em código com a marca `CofreMark`, com slot pra raster depois | 16 |
| L5 | Ouro em superfície grande no Simulador de folga | 10 |
| L6 | Ações rápidas em ícones redondos no Painel (Orçar · Folga · Histórico · Recalcular) | 15 |

---

## 1. Mapa de arquivos

| Arquivo | Tarefa | O que muda |
|---|---|---|
| `lib/features/legal/legal_texts.dart` | 1, 13 | §3 anúncios; §2 cita o nome |
| `../website/site/quanto-cobro/privacidade/index.html` | 1, 13 | espelho do acima + meta description |
| `lib/core/ads/ads.dart` | 1 | docstring reflete a decisão nova |
| `lib/features/pro/pro_screen.dart` | 1 | "chegando" vira "hoje" |
| `lib/core/model/area.dart` | 2 | `diasFolgaAno` |
| `lib/core/calc/calc_engine.dart` | 2, 9 | `horasBrutasPorRotina`, `horasFaturaveisPorRotina(diasFolgaAno)`, `computeFolga` |
| `lib/features/calc/calc_screen.dart` | 3, 8 | passo 2 reescrito; "+" no passo 3 |
| `lib/features/resultado/resultado_screen.dart` | 4 | copy "faturados" |
| `lib/core/model/proposta.dart` | 5 | helpers de prazo e pagamento |
| `lib/features/proposta/proposta_screen.dart` | 5 | chips de prazo/pagamento |
| `lib/core/model/trabalho.dart` | 6 | `entregaEm` |
| `lib/core/common/datas.dart` | 6, 13 | `prazoEntregaTexto`, `saudacao` |
| `lib/features/trabalhos/trabalho_form_screen.dart` | 6 | date picker |
| `lib/features/trabalhos/trabalho_detalhe_screen.dart` | 6 | linha "faltam N dias" |
| `lib/features/trabalhos/trabalhos_screen.dart` | 6 | subtítulo da linha |
| `lib/features/simulador/simulador_screen.dart` | 7 | alerta de capacidade |
| `lib/app/routes.dart`, `lib/app/router.dart` | 10 | rota `/folga` |
| `lib/features/folga/folga_screen.dart` (novo) | 10 | a tela |
| `lib/core/glossario/glossario.dart` | 11 | verbetes `folga`, `horas_cobraveis` |
| `lib/core/telemetry/eventos.dart` | 10 | `folgaSimulada` |
| `lib/app/nav_shell.dart` | 12 | `_BotaoRecebi` |
| `lib/core/settings/settings_repository.dart`, `lib/core/providers.dart` | 13 | `nome` |
| `lib/features/onboarding/onboarding_screen.dart` | 13, 16 | campo nome; `Cena` |
| `lib/features/config/config_screen.dart` | 13 | "Seu nome" |
| `lib/features/painel/painel_screen.dart` | 13, 14, 15 | saudação; `_AnelTeto`; `_AcoesRapidas` |
| `lib/core/ui/cena.dart` (novo) | 16 | ilustração assinatura |
| `lib/core/ui/empty_state_hero.dart` | 16 | usa `Cena` |
| `pubspec.yaml` | 17 | `0.10.0+21` |

---

## 2. Trilha B: fluxo, cálculo, modelo

> **Ordem de execução:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → **11 → 10** (o glossário antes da tela de folga) → 12 → 13 → 14 → 15 → 16 → 17.

### Task 1: Termos honestos sobre anúncio + Pro "chegando" vira "hoje"

**Files:**
- Modify: `lib/features/legal/legal_texts.dart:59-64` (privacidade §3) e `:239-247` (termos §8)
- Modify: `../website/site/quanto-cobro/privacidade/index.html:16,23,128-129,205-206`
- Modify: `lib/core/ads/ads.dart:1-24` (docstring)
- Modify: `lib/features/pro/pro_screen.dart:95-115`
- Test: `test/legal_anuncio_test.dart` (novo)

**Interfaces:**
- Produces: nada de código; só copy. `LegalTexts.privacidade` e `LegalTexts.termos` continuam `static const String`.

- [ ] **Step 1: Escrever o teste que falha**

```dart
// test/legal_anuncio_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/features/legal/legal_texts.dart';

/// Decisão de 01/09/2026: a versão grátis PODE passar a exibir anúncio; o Pro
/// nunca. Os termos não podem prometer "nunca terá anúncio", e o Pro continua
/// vendendo "sem anúncios". Este teste trava as duas pontas.
void main() {
  test('privacidade não promete ausência eterna de anúncio', () {
    expect(LegalTexts.privacidade, isNot(contains('não exibe anúncios')));
    expect(LegalTexts.privacidade, isNot(contains('não tem anúncios')));
    expect(LegalTexts.privacidade, contains('pode passar a exibir anúncios'));
    expect(LegalTexts.privacidade, contains('o Pro continuará sem anúncios'));
  });

  test('termos: o Pro inclui a ausência de anúncios', () {
    expect(LegalTexts.termos, contains('sem anúncios'));
  });

  test('nenhum travessão em texto visível', () {
    expect(LegalTexts.privacidade, isNot(contains('—')));
    expect(LegalTexts.termos, isNot(contains('—')));
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/legal_anuncio_test.dart`
Expected: FAIL nos dois primeiros (o texto atual diz "não exibe anúncios"). Se o terceiro também falhar, é travessão herdado: corrija junto.

- [ ] **Step 3: Trocar o §3 da privacidade no app**

Substituir o bloco inteiro do item 3 em `legal_texts.dart` por:

```
3. Anúncios

Hoje o ${AppConfig.appName} não exibe anúncios e não integra nenhuma rede de
publicidade: não existe SDK de anúncio no app, e o seu identificador de
publicidade não é lido. A versão gratuita pode passar a exibir anúncios em uma
versão futura. Se isso acontecer, esta política será atualizada antes,
descrevendo a rede usada e os dados envolvidos, e o Pro continuará sem anúncios.
A receita do app hoje vem da assinatura Pro, descrita no item 6.
```

- [ ] **Step 4: Ajustar o §8 dos termos (Assinatura Pro)**

Trocar a primeira frase por: `O Pro é uma assinatura recorrente, cobrada pela Google Play, que libera recursos adicionais e garante o uso sem anúncios.` O resto do parágrafo fica igual.

- [ ] **Step 5: Espelhar no site (as duas versões têm que dizer a MESMA coisa)**

Em `../website/site/quanto-cobro/privacidade/index.html`:
- linha 16 e 23: `Local-first, sem cadastro, sem anúncios.` → `Local-first, sem cadastro, sem pegadinha.`
- `<h3>3. Este app não exibe anúncios</h3>` → `<h3>3. Anúncios</h3>`, e o `<p>` seguinte recebe o mesmo texto do Step 3 (trocando `${AppConfig.appName}` por `Quanto Cobro?` e com `<strong>` em "pode passar a exibir anúncios" e "o Pro continuará sem anúncios").
- §8 dos termos: mesma frase do Step 4.

- [ ] **Step 6: Registrar a decisão em `ads.dart`**

Trocar as três primeiras linhas do docstring por:

```dart
/// Monetização por anúncio — **decidido em 01/09/2026: entra DEPOIS, não agora.**
///
/// Até 01/09 a decisão era "nunca" (o raciocínio dos reviews está abaixo e
/// continua verdadeiro). O Gabriel decidiu que a versão grátis vai ter anúncio
/// numa versão futura e que o Pro vende "sem anúncios" desde já. Os termos já
/// dizem isso. Antes de ligar qualquer SDK, ler o Apêndice A do
/// `docs/planning/18-PLANO-FLUXO-FOLGA-E-VISUAL.md` (Data Safety, AD_ID, R6).
```

O resto do arquivo (`AdInterstitial.maybeShowOnSave` no-op) fica.

- [ ] **Step 7: Pro: mover o que já foi entregue pra "hoje"**

Em `pro_screen.dart`, `_hoje` passa a ser:

```dart
  static const List<(IconData, String)> _hoje = <(IconData, String)>[
    (
      Icons.switch_account_outlined,
      'Vários trabalhos (cliente recorrente x avulso)',
    ),
    (Icons.picture_as_pdf_outlined, 'Orçamento em PDF pra mandar ao cliente'),
    (Icons.tune, 'Detalhamento do imposto (faixas, INSS, deduções)'),
    (Icons.public, 'Recebimento em dólar, convertido pela PTAX'),
    (Icons.trending_up, 'Projeção do ano no teto do MEI'),
    (Icons.block, 'Sem anúncios: quando eles chegarem, você nunca os verá'),
  ];

  static const List<(IconData, String)> _chegando = <(IconData, String)>[];
```

E no `build`, envolver o título "Chegando: já incluso no seu Pro" e o `for` de `_chegando` em `if (_chegando.isNotEmpty) ...<Widget>[ ... ]`.

- [ ] **Step 8: Rodar tudo e commitar**

Run: `flutter test test/legal_anuncio_test.dart && flutter analyze && flutter test`
Expected: verde.

```bash
git add lib/features/legal/legal_texts.dart lib/core/ads/ads.dart lib/features/pro/pro_screen.dart test/legal_anuncio_test.dart
git commit -m "fix(legal): termos param de prometer 'nunca tera anuncio'; Pro lista o que ja entrega

O Pro vende 'sem anuncios' e vai continuar vendendo: o anuncio na versao
gratis entra numa versao futura. Os termos (app e site) passam a dizer isso.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

O site é outro repo (`../website`): commitar lá com `git -C ../website add site/quanto-cobro/privacidade/index.html && git -C ../website commit -m "fix(quanto-cobro): politica de privacidade espelha a nova clausula de anuncios"`. **Deploy (`python3 ../website/scripts/deploy.py site`) só com o "vai" do Gabriel**: publicar é ação externa.

---

### Task 2: Motor: horas brutas + dias de folga explícitos

**Files:**
- Modify: `lib/core/model/area.dart`
- Modify: `lib/core/calc/calc_engine.dart:475-489`
- Test: `test/calc_engine_test.dart` (adicionar group)

**Interfaces:**
- Produces:
  - `const int kDiasFolgaPadrao = 30;` (em `calc_engine.dart`)
  - `Area.diasFolgaAno` (`int?`, nullable pra dado antigo) e `int get diasFolgaEfetivos => diasFolgaAno ?? kDiasFolgaPadrao;`
  - `int horasBrutasPorRotina({required int diasSemana, required int horasDia})` → `(diasSemana * horasDia * 52 / 12).round()`
  - `int horasFaturaveisPorRotina({required int diasSemana, required int horasDia, int diasFolgaAno = kDiasFolgaPadrao, double fatorPago = 0.74})`
- Invariante a preservar: `Area.padrao()` (5 dias × 6 h × 30 folga) continua dando **85 h**. Conta: semanas = 52 − 30/5 = 46; brutas = 30 × 46 / 12 = 115; × 0,74 = 85,1 → 85.

- [ ] **Step 1: Teste que falha**

Adicionar em `test/calc_engine_test.dart`:

```dart
  group('rotina → horas (v0.10, folga explícita)', () {
    test('brutas: 5 dias × 6 h = 130 h/mês', () {
      expect(horasBrutasPorRotina(diasSemana: 5, horasDia: 6), 130);
    });

    test('cobráveis com 30 dias de folga continua 85 (o default histórico)', () {
      expect(
        horasFaturaveisPorRotina(diasSemana: 5, horasDia: 6),
        85,
      );
    });

    test('mais folga = menos horas cobráveis; zero folga = mais', () {
      final int base = horasFaturaveisPorRotina(diasSemana: 5, horasDia: 6);
      expect(
        horasFaturaveisPorRotina(diasSemana: 5, horasDia: 6, diasFolgaAno: 60),
        lessThan(base),
      );
      expect(
        horasFaturaveisPorRotina(diasSemana: 5, horasDia: 6, diasFolgaAno: 0),
        greaterThan(base),
      );
    });

    test('folga absurda não zera nem fica negativa', () {
      expect(
        horasFaturaveisPorRotina(diasSemana: 1, horasDia: 1, diasFolgaAno: 365),
        greaterThanOrEqualTo(1),
      );
    });

    test('Area serializa diasFolgaAno e usa 30 quando ausente', () {
      final Area a = Area.padrao().copyWith(diasFolgaAno: 45);
      expect(Area.fromJson(a.toJson()).diasFolgaAno, 45);
      expect(Area.padrao().diasFolgaEfetivos, 30);
      final Map<String, dynamic> antigo = Area.padrao().toJson()
        ..remove('diasFolgaAno');
      expect(Area.fromJson(antigo).diasFolgaAno, isNull);
      expect(Area.fromJson(antigo).diasFolgaEfetivos, 30);
    });
  });
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/calc_engine_test.dart`
Expected: FAIL ("horasBrutasPorRotina isn't defined", "diasFolgaAno isn't defined").

- [ ] **Step 3: Model**

Em `area.dart`: adicionar o campo ao construtor (`this.diasFolgaAno,`), declarar

```dart
  /// Dias de folga por ano (férias + feriados + ponte). Explícito desde a
  /// v0.10: antes morava escondido no fator 0,65 e o leigo achava que o app
  /// tinha errado a conta. Null = dado antigo, cai em [kDiasFolgaPadrao].
  final int? diasFolgaAno;

  int get diasFolgaEfetivos => diasFolgaAno ?? kDiasFolgaPadrao;
```

(importar `../calc/calc_engine.dart` pra `kDiasFolgaPadrao`; se der ciclo de import, mova a constante pra `area.dart` e reexporte no engine com `export '../model/area.dart' show kDiasFolgaPadrao;`), incluir em `copyWith`, `toJson` (`if (diasFolgaAno != null) 'diasFolgaAno': diasFolgaAno`), `fromJson` (`(json['diasFolgaAno'] as num?)?.toInt()`), e em `Area.padrao()` passar `diasFolgaAno: 30`.

- [ ] **Step 4: Engine**

Substituir `horasFaturaveisPorRotina` por:

```dart
/// Dias de folga por ano que o app assume quando a pessoa não disse (férias
/// de 30 dias, o que a CLT dá e o freelancer esquece de se dar).
const int kDiasFolgaPadrao = 30;

/// Horas que a pessoa SENTA pra trabalhar por mês, sem desconto nenhum. É o
/// número que ela reconhece ("130 h? é, faz sentido") e que abre a explicação
/// de por que só uma parte dá pra cobrar.
int horasBrutasPorRotina({required int diasSemana, required int horasDia}) =>
    (diasSemana * horasDia * 52 / 12).round();

/// Horas cobráveis/mês a partir da ROTINA real. Dois descontos, agora
/// separados e explicáveis: a FOLGA (dias por ano, visível no passo 2) e o
/// tempo não pago dentro da semana de trabalho (e-mail, proposta, imprevisto),
/// num fator só. Antes era um 0,65 que embutia os dois e ninguém entendia.
/// Regra de segurança: na dúvida, MENOS horas (o valor-hora sobe).
int horasFaturaveisPorRotina({
  required int diasSemana,
  required int horasDia,
  int diasFolgaAno = kDiasFolgaPadrao,
  double fatorPago = 0.74,
}) {
  final double semanasFolga = diasFolgaAno / math.max(1, diasSemana);
  final double semanas = (52 - semanasFolga).clamp(1, 52);
  final double brutasMes = diasSemana * horasDia * semanas / 12;
  return (brutasMes * fatorPago).round().clamp(1, 400);
}
```

- [ ] **Step 5: Rodar tudo, commitar**

Run: `flutter analyze && flutter test`
Expected: verde. Se `calc_engine_test` antigo assertar 0,65 em algum lugar, atualize a expectativa pra 85 (o valor default não muda).

```bash
git add lib/core/model/area.dart lib/core/calc/calc_engine.dart test/calc_engine_test.dart
git commit -m "feat(calc): dias de folga por ano explicitos; horas brutas expostas

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Passo 2 da calculadora reescrito (a resposta com a conta à vista)

**Files:**
- Modify: `lib/features/calc/calc_screen.dart:50-60,85-90,121-135,372-378,425-510,575-640`
- Test: `test/calc_passo_horas_test.dart` (novo)

**Interfaces:**
- Consumes: `horasBrutasPorRotina`, `horasFaturaveisPorRotina(diasFolgaAno:)`, `Area.diasFolgaAno`.
- Produces: o stepper genérico `_stepper` ganha `int step = 1`.

- [ ] **Step 1: Teste que falha**

```dart
// test/calc_passo_horas_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

/// v0.10: o passo das horas fala em UMA unidade por frase e mostra a conta
/// ("130 h por mês → dá pra cobrar 85 h"). Nada de "VOCÊ COBRA POR MÊS".
Future<void> _atePasso2(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const QuantoCobroApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Começar'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, '5000');
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('passo 2: título, três steppers e a conta explicada', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _atePasso2(tester);
      expect(find.text('Como é sua semana de trabalho?'), findsOneWidget);
      expect(find.text('Dias por semana'), findsOneWidget);
      expect(find.text('Horas num dia normal'), findsOneWidget);
      expect(find.text('Dias de folga por ano'), findsOneWidget);
      expect(find.textContaining('Você trabalha umas 130 h por mês'), findsOneWidget);
      expect(find.textContaining('dá pra cobrar umas 85 h'), findsOneWidget);
      expect(find.textContaining('VOCÊ COBRA'), findsNothing);
    });
  });

  testWidgets('mais folga derruba as horas cobráveis na hora', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _atePasso2(tester);
      // O "+" do stepper de folga (o terceiro par de botões).
      final Finder mais = find.widgetWithIcon(IconButton, Icons.add).at(2);
      await tester.ensureVisible(mais);
      await tester.tap(mais); // 30 → 35
      await tester.pumpAndSettle();
      expect(find.text('35 dias'), findsOneWidget);
      expect(find.textContaining('dá pra cobrar umas 8'), findsOneWidget);
      expect(find.textContaining('dá pra cobrar umas 85 h'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/calc_passo_horas_test.dart`
Expected: FAIL ("Como é sua semana de trabalho?" não existe).

- [ ] **Step 3: Estado do passo**

Em `_CalcScreenState`: adicionar `late int _folga;` ao lado de `_dias`/`_horasDia`; em `initState`, `_folga = _draft.diasFolgaAno ?? kDiasFolgaPadrao;`. Em `_recalcHorasPorRotina`:

```dart
  void _recalcHorasPorRotina() {
    final int horas = horasFaturaveisPorRotina(
      diasSemana: _dias,
      horasDia: _horasDia,
      diasFolgaAno: _folga,
    );
    setState(() {
      _horasManual = false;
      _draft = _draft.copyWith(
        horas: horas,
        diasSemana: _dias,
        horasDia: _horasDia,
        diasFolgaAno: _folga,
      );
    });
  }
```

Em `_stepTitle`: `1 => 'Como é sua semana de trabalho?'`.

- [ ] **Step 4: O stepper ganha `step`**

Na assinatura de `_stepper` adicionar `int step = 1,` e nos dois botões usar `onChanged(value - step)` / `onChanged(value + step)`; o `enabled` do "−" vira `value - step >= min`, e do "+" `value + step <= max`.

- [ ] **Step 5: Reescrever `_stepHoras`**

```dart
  Widget _stepHoras() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int brutas = horasBrutasPorRotina(
      diasSemana: _dias,
      horasDia: _horasDia,
    );
    final int cobraveis = _draft.horas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title('Como é sua semana de trabalho?'),
        _subtitle('Me conta sua rotina que eu faço a conta pra você.'),
        const SizedBox(height: Space.x6),
        _stepper(
          label: 'Dias por semana',
          value: _dias,
          min: 1,
          max: 7,
          suffix: _dias == 1 ? 'dia' : 'dias',
          onChanged: (int v) {
            _dias = v;
            _recalcHorasPorRotina();
          },
        ),
        const SizedBox(height: Space.x5),
        _stepper(
          label: 'Horas num dia normal',
          helper: 'Conta só o tempo sentado pra trabalhar.',
          value: _horasDia,
          min: 1,
          max: 16,
          suffix: _horasDia == 1 ? 'hora' : 'horas',
          onChanged: (int v) {
            _horasDia = v;
            _recalcHorasPorRotina();
          },
        ),
        const SizedBox(height: Space.x5),
        _stepper(
          label: 'Dias de folga por ano',
          helper: 'Férias, feriado, ponte. Quem trabalha por conta também para.',
          value: _folga,
          min: 0,
          max: 90,
          step: 5,
          suffix: 'dias',
          onChanged: (int v) {
            _folga = v;
            _recalcHorasPorRotina();
          },
        ),
        const SizedBox(height: Space.x6),
        // A resposta, em frase de gente e com a conta à vista. Uma unidade
        // (mês) e os dois números que a pessoa precisa reconhecer: o que ela
        // trabalha e o que dá pra cobrar.
        Semantics(
          liveRegion: true,
          label: _horasManual
              ? 'Você digitou $cobraveis horas cobráveis por mês.'
              : 'Você trabalha umas $brutas horas por mês. Dessas, dá pra cobrar umas $cobraveis horas.',
          child: ExcludeSemantics(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.x5),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: const BorderRadius.all(Radii.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_horasManual)
                    Text(
                      'Você digitou $cobraveis h cobráveis por mês.',
                      style: theme.textTheme.titleMedium,
                    )
                  else ...<Widget>[
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.titleMedium,
                        children: <InlineSpan>[
                          const TextSpan(text: 'Você trabalha umas '),
                          TextSpan(
                            text: '$brutas h',
                            style: AppType.valueMd.copyWith(
                              color: cs.onSurface,
                              fontSize: 22,
                            ),
                          ),
                          const TextSpan(text: ' por mês.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.x2),
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.titleMedium,
                        children: <InlineSpan>[
                          const TextSpan(text: 'Dessas, dá pra cobrar umas '),
                          TextSpan(
                            text: '$cobraveis h',
                            style: AppType.valueMd.copyWith(
                              color: cs.primary,
                              fontSize: 22,
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.x2),
                  Text(
                    _horasManual
                        ? 'Toque nos + / − acima pra voltar pra sua rotina.'
                        : 'O resto vai em e-mail, orçamento, imprevisto e folga. Quase ninguém cobra o dia inteiro.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.x3),
        // O caminho do avançado: link, não botão. Antes competia com a resposta.
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _digitarHorasNaMao,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('Já sei minhas horas cobráveis, digitar'),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 6: Bottom sheet do "digitar na mão"**

Trocar os textos: título `'Suas horas cobráveis por mês'`, corpo `'Se você já sabe quantas horas consegue cobrar num mês, coloca aqui.'`, label do campo `'Horas cobráveis por mês'`. No `setState` que reconstrói a `Area`, passar também `diasFolgaAno: _draft.diasFolgaAno` (o construtor exige listar tudo).

- [ ] **Step 7: Rodar, commitar**

Run: `flutter test test/calc_passo_horas_test.dart && flutter analyze && flutter test`
Expected: verde. Se `layout_matrix`/`overflow` reclamarem do passo 2 em 320×640 com fonte 200%, o culpado costuma ser o `fontSize: 22` fixo: troque por `AppType.valueMd` sem override e rode de novo.

```bash
git add lib/features/calc/calc_screen.dart test/calc_passo_horas_test.dart
git commit -m "feat(calc): passo das horas fala uma unidade por frase e mostra a conta

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Resultado: "faturados" vira frase de gente

**Files:**
- Modify: `lib/features/resultado/resultado_screen.dart:207-213`
- Test: `test/resultado_copy_test.dart` (novo)

- [ ] **Step 1: Teste que falha**

```dart
// test/resultado_copy_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/resultado/resultado_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('resultado não diz "faturados"; diz o que precisa cobrar', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
      'regime': 'mei',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: ResultadoScreen(area: Area.padrao()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('faturados'), findsNothing);
    expect(find.textContaining('precisa cobrar'), findsOneWidget);
  });
}
```

`AppTheme.dark` é um getter estático (`app_theme.dart:13`), sem parênteses.

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/resultado_copy_test.dart` → FAIL.

- [ ] **Step 3: Trocar a linha**

```dart
                    Text(
                      '≈ ${moneyBRL(r.valorDia)} por dia · você precisa cobrar ${moneyBRL(r.faturamento)} por mês',
                      style: theme.textTheme.bodyMedium,
                      semanticsLabel:
                          'Cerca de ${moneyBRL(r.valorDia)} por dia. Pra fechar o mês, você precisa cobrar ${moneyBRL(r.faturamento)} no total.',
                    ),
```

- [ ] **Step 4: Rodar, commitar**

Run: `flutter analyze && flutter test` → verde.

```bash
git add lib/features/resultado/resultado_screen.dart test/resultado_copy_test.dart
git commit -m "fix(copy): resultado troca 'faturados' por 'precisa cobrar'

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: Proposta: prazo em dias + forma de pagamento por chips

**Files:**
- Modify: `lib/core/model/proposta.dart`
- Modify: `lib/features/proposta/proposta_screen.dart:32-33,48-49,75-77,165-175,211-220`
- Test: `test/proposta_prazo_pagamento_test.dart` (novo)

**Interfaces:**
- Produces (em `Proposta`, estáticos):
  - `static const List<String> kMeios = <String>['PIX', 'Transferência', 'Cartão', 'Boleto'];`
  - `static const List<String> kCondicoes = <String>['50% de sinal, 50% na entrega', 'À vista na entrega', 'Parcelado'];`
  - `static String prazoDe(int dias, {bool uteis = true})` → `'15 dias úteis'`
  - `static (int? dias, bool uteis) prazoParse(String s)`
  - `static String formaPagamentoDe({required List<String> meios, required String condicao, String extra = ''})` → `'PIX · 50% de sinal, 50% na entrega'`
  - `static ({List<String> meios, String condicao, String extra}) formaPagamentoParse(String s)`
- O modelo continua guardando `prazo` e `formaPagamento` como **String**: PDF e papel ([proposta_pdf.dart:359](../../lib/core/proposta/proposta_pdf.dart), [proposta_papel.dart:169](../../lib/features/proposta/proposta_papel.dart)) não mudam.

- [ ] **Step 1: Teste que falha**

```dart
// test/proposta_prazo_pagamento_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/proposta.dart';

void main() {
  group('prazo', () {
    test('gera a frase certa, com plural e tipo', () {
      expect(Proposta.prazoDe(15), '15 dias úteis');
      expect(Proposta.prazoDe(1), '1 dia útil');
      expect(Proposta.prazoDe(10, uteis: false), '10 dias corridos');
      expect(Proposta.prazoDe(1, uteis: false), '1 dia corrido');
    });

    test('lê de volta o que gerou, e texto livre antigo', () {
      expect(Proposta.prazoParse('15 dias úteis'), (15, true));
      expect(Proposta.prazoParse('10 dias corridos'), (10, false));
      expect(Proposta.prazoParse('Ex.: 3 semanas'), (null, true));
      expect(Proposta.prazoParse(''), (null, true));
    });
  });

  group('forma de pagamento', () {
    test('default dos chips é exatamente o default histórico', () {
      expect(
        Proposta.formaPagamentoDe(
          meios: <String>['PIX'],
          condicao: Proposta.kCondicoes.first,
        ),
        Proposta.kFormaPagamentoPadrao,
      );
    });

    test('vários meios viram "ou"; extra entra no fim', () {
      expect(
        Proposta.formaPagamentoDe(
          meios: <String>['PIX', 'Cartão'],
          condicao: 'À vista na entrega',
          extra: 'Cartão em até 3x',
        ),
        'PIX ou Cartão · À vista na entrega · Cartão em até 3x',
      );
    });

    test('parse recupera meios e condição; texto desconhecido vira extra', () {
      final r = Proposta.formaPagamentoParse(Proposta.kFormaPagamentoPadrao);
      expect(r.meios, <String>['PIX']);
      expect(r.condicao, Proposta.kCondicoes.first);
      expect(r.extra, '');
      final s = Proposta.formaPagamentoParse('Depósito na conta, 30 dias');
      expect(s.meios, isEmpty);
      expect(s.condicao, Proposta.kCondicoes.first);
      expect(s.extra, 'Depósito na conta, 30 dias');
    });
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/proposta_prazo_pagamento_test.dart` → FAIL.

- [ ] **Step 3: Helpers no modelo**

Adicionar em `Proposta`:

```dart
  static const List<String> kMeios = <String>[
    'PIX',
    'Transferência',
    'Cartão',
    'Boleto',
  ];

  /// A primeira é o default: sinal protege o freelancer de sumiço.
  static const List<String> kCondicoes = <String>[
    '50% de sinal, 50% na entrega',
    'À vista na entrega',
    'Parcelado',
  ];

  static String prazoDe(int dias, {bool uteis = true}) {
    final String unidade = dias == 1 ? 'dia' : 'dias';
    final String tipo = uteis
        ? (dias == 1 ? 'útil' : 'úteis')
        : (dias == 1 ? 'corrido' : 'corridos');
    return '$dias $unidade $tipo';
  }

  static (int?, bool) prazoParse(String s) {
    final RegExpMatch? m = RegExp(
      r'^\s*(\d+)\s*dias?\s*(úteis|útil|uteis|util|corridos?)?\s*$',
      caseSensitive: false,
    ).firstMatch(s);
    if (m == null) return (null, true);
    final String tipo = (m.group(2) ?? 'úteis').toLowerCase();
    return (int.parse(m.group(1)!), !tipo.startsWith('corrid'));
  }

  static String formaPagamentoDe({
    required List<String> meios,
    required String condicao,
    String extra = '',
  }) {
    final List<String> partes = <String>[
      if (meios.isNotEmpty) meios.join(' ou '),
      condicao,
      if (extra.trim().isNotEmpty) extra.trim(),
    ];
    return partes.join(' · ');
  }

  static ({List<String> meios, String condicao, String extra})
  formaPagamentoParse(String s) {
    final String baixo = s.toLowerCase();
    final List<String> meios = kMeios
        .where((String m) => baixo.contains(m.toLowerCase()))
        .toList();
    final String condicao = kCondicoes.firstWhere(
      (String c) => baixo.contains(c.toLowerCase()),
      orElse: () => kCondicoes.first,
    );
    final bool reconhecido =
        meios.isNotEmpty || kCondicoes.any((String c) => baixo.contains(c.toLowerCase()));
    return (
      meios: meios,
      condicao: condicao,
      extra: reconhecido || s.trim().isEmpty ? '' : s.trim(),
    );
  }
```

- [ ] **Step 4: Rodar o teste do modelo**

Run: `flutter test test/proposta_prazo_pagamento_test.dart` → PASS.

- [ ] **Step 5: Tela: estado**

Em `_PropostaScreenState`, **remover** `_prazo` e `_pagamento` (controllers) e adicionar:

```dart
  final TextEditingController _prazoDias = TextEditingController();
  bool _prazoUteis = true;
  final Set<String> _meios = <String>{'PIX'};
  String _condicao = Proposta.kCondicoes.first;
  final TextEditingController _pagamentoExtra = TextEditingController();
```

Em `initState`:

```dart
    final (int? dias, bool uteis) = Proposta.prazoParse(p.prazo);
    _prazoDias.text = dias?.toString() ?? '';
    _prazoUteis = uteis;
    final ({List<String> meios, String condicao, String extra}) fp =
        Proposta.formaPagamentoParse(p.formaPagamento);
    _meios
      ..clear()
      ..addAll(fp.meios.isEmpty && fp.extra.isEmpty ? <String>['PIX'] : fp.meios);
    _condicao = fp.condicao;
    _pagamentoExtra.text = fp.extra;
```

`dispose` libera `_prazoDias` e `_pagamentoExtra`. No getter `_proposta`:

```dart
    prazo: _digits(_prazoDias.text) > 0
        ? Proposta.prazoDe(_digits(_prazoDias.text), uteis: _prazoUteis)
        : '',
    formaPagamento: Proposta.formaPagamentoDe(
      meios: Proposta.kMeios.where(_meios.contains).toList(),
      condicao: _condicao,
      extra: _pagamentoExtra.text,
    ),
```

- [ ] **Step 6: Tela: campos**

No lugar do `TextField` de "Prazo de entrega":

```dart
            SecaoTitulo('Prazo de entrega', bottom: Space.x2),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 120,
                  child: MoneyField(
                    controller: _prazoDias,
                    label: 'Dias',
                    suffix: 'dias',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const <ButtonSegment<bool>>[
                      ButtonSegment<bool>(value: true, label: Text('úteis')),
                      ButtonSegment<bool>(value: false, label: Text('corridos')),
                    ],
                    selected: <bool>{_prazoUteis},
                    onSelectionChanged: (Set<bool> s) {
                      Haptics.select();
                      setState(() => _prazoUteis = s.first);
                    },
                  ),
                ),
              ],
            ),
```

(`MoneyField` já é o campo numérico da casa; se ele forçar prefixo `R$`, use um `TextField` com `keyboardType: TextInputType.number` e `inputFormatters: [FilteringTextInputFormatter.digitsOnly]`.) Se em 320dp a `Row` estourar, empilhe em `Column` quando `MediaQuery.sizeOf(context).width < 360`.

No lugar do `TextField` de "Forma de pagamento":

```dart
            SecaoTitulo('Forma de pagamento', bottom: Space.x1),
            Text(
              'O sinal é padrão de mercado, e te protege.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Space.x3),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: <Widget>[
                for (final String m in Proposta.kMeios)
                  FilterChip(
                    label: Text(m),
                    selected: _meios.contains(m),
                    onSelected: (bool v) {
                      Haptics.select();
                      setState(() => v ? _meios.add(m) : _meios.remove(m));
                    },
                  ),
              ],
            ),
            const SizedBox(height: Space.x3),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: <Widget>[
                for (final String c in Proposta.kCondicoes)
                  ChoiceChip(
                    label: Text(c),
                    selected: _condicao == c,
                    onSelected: (_) {
                      Haptics.select();
                      setState(() => _condicao = c);
                    },
                  ),
              ],
            ),
            const SizedBox(height: Space.x3),
            TextField(
              controller: _pagamentoExtra,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Outra condição (opcional)',
                hintText: 'Ex.: cartão em até 3x',
              ),
            ),
```

Use o mesmo estilo de `ChoiceChip` que já existe na validade (cores `surfaceContainerLow`/`secondaryContainer`, borda `primary` quando selecionado) pra rimar.

- [ ] **Step 7: Rodar tudo, commitar**

Run: `flutter analyze && flutter test`
Expected: verde. `proposta_salvar_test.dart` e `proposta_pdf_test.dart` podem digitar em "Prazo de entrega"/"Forma de pagamento" por `find.widgetWithText(TextField, ...)`: troque por preencher `Dias` e escolher chips, mantendo a asserção final (o texto que vai pro PDF).

```bash
git add lib/core/model/proposta.dart lib/features/proposta/proposta_screen.dart test/
git commit -m "feat(proposta): prazo em dias (uteis/corridos) e pagamento por chips

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Trabalho ganha data de entrega (sem cronômetro)

**Files:**
- Modify: `lib/core/model/trabalho.dart`
- Modify: `lib/core/common/datas.dart`
- Modify: `lib/features/trabalhos/trabalho_form_screen.dart`
- Modify: `lib/features/trabalhos/trabalho_detalhe_screen.dart:160-170`
- Modify: `lib/features/trabalhos/trabalhos_screen.dart` (subtítulo da linha, hoje "Última entrada em ...")
- Test: `test/trabalho_test.dart` (adicionar), `test/datas_prazo_test.dart` (novo)

**Interfaces:**
- Produces: `Trabalho.entregaEm` (`DateTime?`, json `'entregaEm'` ISO), `copyWith(entregaEm:, limparEntrega: bool)`; `String? prazoEntregaTexto(DateTime? entregaEm, {required DateTime hoje})` em `datas.dart`.
- A fronteira do produto ([trabalho.dart](../../lib/core/model/trabalho.dart) docstring) continua: uma data que a pessoa informa **uma vez**, nada que precise ser alimentado toda semana.

- [ ] **Step 1: Testes que falham**

```dart
// test/datas_prazo_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/common/datas.dart';

void main() {
  final DateTime hoje = DateTime(2026, 9, 1, 15, 30);
  test('sem data, sem texto', () {
    expect(prazoEntregaTexto(null, hoje: hoje), isNull);
  });
  test('hoje, amanhã, futuro', () {
    expect(prazoEntregaTexto(DateTime(2026, 9, 1), hoje: hoje), 'Entrega hoje');
    expect(prazoEntregaTexto(DateTime(2026, 9, 2), hoje: hoje), 'Entrega amanhã');
    expect(
      prazoEntregaTexto(DateTime(2026, 9, 13), hoje: hoje),
      'Faltam 12 dias pra entrega',
    );
  });
  test('passado, sem pânico', () {
    expect(prazoEntregaTexto(DateTime(2026, 8, 31), hoje: hoje), 'Entrega passou ontem');
    expect(
      prazoEntregaTexto(DateTime(2026, 8, 20), hoje: hoje),
      'Entrega passou há 12 dias',
    );
  });
}
```

E em `test/trabalho_test.dart`:

```dart
  test('entregaEm serializa e é opcional', () {
    final Trabalho t = Trabalho(
      id: 't1',
      areaId: 'a1',
      nome: 'Augusto',
      criadoEm: DateTime(2026, 1, 1),
      entregaEm: DateTime(2026, 10, 15),
    );
    expect(Trabalho.fromJson(t.toJson()).entregaEm, DateTime(2026, 10, 15));
    final Map<String, dynamic> antigo = t.toJson()..remove('entregaEm');
    expect(Trabalho.fromJson(antigo).entregaEm, isNull);
    expect(t.copyWith(limparEntrega: true).entregaEm, isNull);
  });
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/datas_prazo_test.dart test/trabalho_test.dart` → FAIL.

- [ ] **Step 3: Modelo**

Em `Trabalho`: construtor `this.entregaEm,`; campo

```dart
  /// Data combinada de entrega, quando existe. Informada UMA vez (na criação
  /// ou na edição), nunca "alimentada": o app só conta os dias e mostra. Sem
  /// cronômetro, sem status, sem alerta vermelho.
  final DateTime? entregaEm;
```

`copyWith` ganha `DateTime? entregaEm, bool limparEntrega = false` e usa `entregaEm: limparEntrega ? null : (entregaEm ?? this.entregaEm)`. `toJson`: `if (entregaEm != null) 'entregaEm': entregaEm!.toIso8601String()`. `fromJson`: `entregaEm: DateTime.tryParse(json['entregaEm'] as String? ?? '')`.

- [ ] **Step 4: Helper de data**

Em `datas.dart`:

```dart
/// A frase do prazo: conta os dias e diz. Sem cor de perigo no texto: atrasar
/// entrega é conversa com o cliente, não emergência do app.
String? prazoEntregaTexto(DateTime? entregaEm, {required DateTime hoje}) {
  if (entregaEm == null) return null;
  final DateTime alvo = DateTime(entregaEm.year, entregaEm.month, entregaEm.day);
  final DateTime dia = DateTime(hoje.year, hoje.month, hoje.day);
  final int dias = alvo.difference(dia).inDays;
  if (dias == 0) return 'Entrega hoje';
  if (dias == 1) return 'Entrega amanhã';
  if (dias > 1) return 'Faltam $dias dias pra entrega';
  if (dias == -1) return 'Entrega passou ontem';
  return 'Entrega passou há ${-dias} dias';
}
```

- [ ] **Step 5: Formulário**

Em `_TrabalhoFormScreenState`: `DateTime? _entregaEm;` carregado de `t.entregaEm`. Depois do `MoneyField` de valor combinado:

```dart
            const SizedBox(height: Space.x4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Prazo de entrega (opcional)'),
              subtitle: Text(
                _entregaEm == null
                    ? 'O app conta os dias pra você.'
                    : dataPorExtenso(_entregaEm!),
              ),
              trailing: _entregaEm == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      tooltip: 'Tirar o prazo',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _entregaEm = null),
                    ),
              onTap: () async {
                final DateTime agora = DateTime.now();
                final DateTime? d = await showDatePicker(
                  context: context,
                  initialDate: _entregaEm ?? agora.add(const Duration(days: 15)),
                  firstDate: DateTime(agora.year - 1),
                  lastDate: DateTime(agora.year + 3),
                  locale: const Locale('pt', 'BR'),
                  helpText: 'Quando você combinou entregar?',
                );
                if (d != null) setState(() => _entregaEm = d);
              },
            ),
```

No salvar, passar `entregaEm: _entregaEm, limparEntrega: _entregaEm == null` no `copyWith` (ou no construtor, se for trabalho novo).

- [ ] **Step 6: Detalhe e lista**

`trabalho_detalhe_screen.dart`, dentro do `PanelCard` do topo, logo depois do bloco `if (separado > 0)`:

```dart
                if (!trabalho.encerrado &&
                    prazoEntregaTexto(trabalho.entregaEm, hoje: DateTime.now()) != null) ...<Widget>[
                  const SizedBox(height: Space.x2),
                  Row(
                    children: <Widget>[
                      Icon(Icons.event_outlined, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: Space.x2),
                      Text(
                        prazoEntregaTexto(trabalho.entregaEm, hoje: DateTime.now())!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
```

`trabalhos_screen.dart`: na linha do trabalho, o subtítulo passa a preferir o prazo: `prazoEntregaTexto(t.entregaEm, hoje: agora) ?? 'Última entrada em ...'` (mantendo o texto atual como fallback).

- [ ] **Step 7: Rodar, commitar**

Run: `flutter analyze && flutter test` → verde.

```bash
git add lib/core/model/trabalho.dart lib/core/common/datas.dart lib/features/trabalhos/ test/
git commit -m "feat(trabalhos): data de entrega opcional, com 'faltam N dias'

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Simulador de projeto: alerta de capacidade

**Files:**
- Modify: `lib/features/simulador/simulador_screen.dart:126-140` (logo após o `MoneyField` "Horas estimadas")
- Test: `test/simulador_capacidade_test.dart` (novo)

- [ ] **Step 1: Teste que falha**

```dart
// test/simulador_capacidade_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/features/simulador/simulador_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O irmão do aviso "abaixo do alvo": se o projeto pede mais hora do que a
/// pessoa TEM no mês, o app diz. Cor de informação (aço), não de alerta.
Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    'regime': 'mei',
    'areas_v1': jsonEncode(<String, dynamic>{
      'activeId': 'a1',
      'areas': <Map<String, dynamic>>[Area.padrao().toJson()],
    }),
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(theme: AppTheme.dark, home: const SimuladorScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('horas acima da capacidade do mês mostram o aviso', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '10000');
    await tester.enterText(find.byType(TextField).at(1), '200'); // 85 é o mês
    await tester.pumpAndSettle();
    expect(find.textContaining('mais hora do que você tem'), findsOneWidget);
  });

  testWidgets('dentro da capacidade, nada de aviso', (WidgetTester tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '3000');
    await tester.enterText(find.byType(TextField).at(1), '20');
    await tester.pumpAndSettle();
    expect(find.textContaining('mais hora do que você tem'), findsNothing);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** → `flutter test test/simulador_capacidade_test.dart` FAIL.

- [ ] **Step 3: O aviso**

No `build`, depois de `final int horas = _digits(_horas.text);` adicionar:

```dart
    final int horasDoMes = st is AreaPronta ? st.area.horas : 0;
    final bool estouraMes = horasDoMes > 0 && horas > horasDoMes;
```

Logo após o `MoneyField` de "Horas estimadas" (antes do `SizedBox` seguinte):

```dart
            AnimatedSize(
              duration: reduce ? Duration.zero : Motion.base,
              curve: MotionCurves.standard,
              alignment: Alignment.topCenter,
              child: estouraMes
                  ? Padding(
                      padding: const EdgeInsets.only(top: Space.x3),
                      child: Container(
                        padding: const EdgeInsets.all(Space.x3),
                        decoration: BoxDecoration(
                          color: d.staleBg,
                          borderRadius: const BorderRadius.all(Radii.md),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(Icons.schedule_outlined, color: d.staleFg, size: 20),
                            const SizedBox(width: Space.x2),
                            Expanded(
                              child: Text(
                                'Isso é mais hora do que você tem pra cobrar no mês (umas $horasDoMes h). Cobre mais por hora, ou combine um prazo maior.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: d.staleFg),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
```

- [ ] **Step 4: Rodar, commitar**

Run: `flutter analyze && flutter test` → verde.

```bash
git add lib/features/simulador/simulador_screen.dart test/simulador_capacidade_test.dart
git commit -m "feat(simulador): aviso quando o projeto pede mais hora do que o mes tem

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Custos: "+" ao lado do título

**Files:**
- Modify: `lib/features/calc/calc_screen.dart` (`_stepCustos`, título; e o botão "Adicionar um custo meu" em ~`:761-775`)

- [ ] **Step 1: Extrair o handler**

Se o `onPressed` do botão "Adicionar um custo meu" for inline, extraia pra `Future<void> _abrirCustoNovo()` e use nos dois lugares.

- [ ] **Step 2: Título com "+"**

Trocar `_title('O que você gasta pra trabalhar?')` no `_stepCustos` por:

```dart
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _title('O que você gasta pra trabalhar?')),
            const SizedBox(width: Space.x2),
            IconButton.filledTonal(
              tooltip: 'Adicionar um custo meu',
              onPressed: _abrirCustoNovo,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ],
        ),
```

O botão de baixo fica (quem rolou até lá também precisa dele).

- [ ] **Step 3: Rodar, commitar**

Run: `flutter analyze && flutter test` → verde.

```bash
git add lib/features/calc/calc_screen.dart
git commit -m "feat(calc): '+' de custo ao lado do titulo, sem rolar

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Motor: `computeFolga`

**Files:**
- Modify: `lib/core/calc/calc_engine.dart` (no fim)
- Test: `test/folga_calc_test.dart` (novo)

**Interfaces:**
- Consumes: `computeValorHora(Area, RegimeId)`, `horasBrutasPorRotina`.
- Produces:

```dart
class FolgaResult {
  final int diasFolga;
  final double horasPerdidas;        // horas cobráveis que a folga come
  final double faturamentoPerdido;   // bruto: o que aquele pedaço de mês traria
  final double cobertoPelaProvisao;  // bruto: o que a provisão férias/13º já cobre
  final double custoFolgaBruto;      // custo da folga, com gross-up de imposto
  final double faltaTotal;           // bruto a mais que precisa entrar antes da folga
  final double faltaPorMes;          // faltaTotal / mesesAte
  final int valorHoraAtual;
  final int valorHoraNovo;           // opção A: hora mais cara nos meses até lá
  final int horasExtrasMes;          // opção B: horas a mais por mês na hora atual
  final bool estouraCapacidade;      // B não cabe na semana da pessoa
  final bool jaCoberto;              // faltaTotal ≈ 0: a provisão já paga a folga
}

FolgaResult computeFolga({
  required Area area,
  required RegimeId regime,
  required int diasFolga,
  required int mesesAte,
  double custoFolga = 0,
});
```

- Modelo (estimativa, conservadora de propósito): a folga é uma fração do mês (`diasFolga / diasÚteisDoMês`); o que aquele pedaço traria é `fração × faturamentoMensal` (renda + custos + provisão + imposto: os custos e o DAS continuam correndo na folga, então usar o faturamento cheio é o lado seguro). A provisão férias/13º, quando ligada, já cobre 1 mês de **renda líquida** por ano: desconta-se `min(fração, 1) × renda / (1 − rate)`. O custo da viagem sai do lucro, então entra com gross-up `custoFolga / (1 − rate)`. O que falta se espalha pelos meses até a folga.

- [ ] **Step 1: Teste que falha**

```dart
// test/folga_calc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/calc/calc_engine.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/model/regime.dart';

void main() {
  final Area a = Area.padrao(); // 5×6, 85 h, renda 5000, provisão ligada
  const RegimeId regime = RegimeId.cpf;
  final ValorHoraResult r = computeValorHora(a, regime);

  test('zero dias: não falta nada', () {
    final FolgaResult f = computeFolga(area: a, regime: regime, diasFolga: 0, mesesAte: 3);
    expect(f.faltaTotal, 0);
    expect(f.jaCoberto, isTrue);
    expect(f.valorHoraNovo, r.valorHora);
  });

  test('faturamento perdido é a fração do mês vezes o faturamento', () {
    final FolgaResult f = computeFolga(area: a, regime: regime, diasFolga: 10, mesesAte: 3);
    final double diasUteis = 5 * 52 / 12;
    expect(f.faturamentoPerdido, closeTo(10 / diasUteis * r.faturamento, 0.01));
    expect(f.horasPerdidas, closeTo(10 / diasUteis * a.horas, 0.01));
  });

  test('a provisão de férias abate, e sem ela falta mais', () {
    final FolgaResult com = computeFolga(area: a, regime: regime, diasFolga: 20, mesesAte: 3);
    final FolgaResult sem = computeFolga(
      area: a.copyWith(provisaoOn: false),
      regime: regime,
      diasFolga: 20,
      mesesAte: 3,
    );
    expect(com.cobertoPelaProvisao, greaterThan(0));
    expect(sem.cobertoPelaProvisao, 0);
    expect(sem.faltaTotal, greaterThan(com.faltaTotal));
  });

  test('custo da viagem entra com gross-up e sobe a hora nova', () {
    final FolgaResult base = computeFolga(area: a, regime: regime, diasFolga: 10, mesesAte: 3);
    final FolgaResult viagem = computeFolga(
      area: a, regime: regime, diasFolga: 10, mesesAte: 3, custoFolga: 3000,
    );
    expect(viagem.custoFolgaBruto, greaterThan(3000));
    expect(viagem.faltaTotal, greaterThan(base.faltaTotal));
    expect(viagem.valorHoraNovo, greaterThanOrEqualTo(base.valorHoraNovo));
    expect(viagem.valorHoraNovo, greaterThan(r.valorHora));
  });

  test('mais meses até lá = menos por mês; nunca divide por zero', () {
    final FolgaResult um = computeFolga(area: a, regime: regime, diasFolga: 20, mesesAte: 1, custoFolga: 2000);
    final FolgaResult seis = computeFolga(area: a, regime: regime, diasFolga: 20, mesesAte: 6, custoFolga: 2000);
    final FolgaResult zero = computeFolga(area: a, regime: regime, diasFolga: 20, mesesAte: 0, custoFolga: 2000);
    expect(seis.faltaPorMes, closeTo(um.faltaPorMes / 6, 0.01));
    expect(zero.faltaPorMes, um.faltaPorMes);
  });

  test('horas extras que não cabem na semana marcam estouraCapacidade', () {
    final FolgaResult f = computeFolga(
      area: a, regime: regime, diasFolga: 60, mesesAte: 1, custoFolga: 20000,
    );
    expect(f.estouraCapacidade, isTrue);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** → `flutter test test/folga_calc_test.dart` FAIL.

- [ ] **Step 3: Implementar**

No fim de `calc_engine.dart`:

```dart
/// Simulador de folga: férias como decisão de PREÇO, não como cofrinho.
///
/// A pergunta que responde: "pra parar N dias daqui a M meses, quanto minha
/// hora precisa valer nos contratos até lá?" (opção A) e "ou quantas horas a
/// mais por mês na hora de hoje?" (opção B). O entregável é uma ação
/// comercial, nunca um saldo. Vocabulário: "folga", "parar", nunca "poupar".
class FolgaResult {
  const FolgaResult({
    required this.diasFolga,
    required this.horasPerdidas,
    required this.faturamentoPerdido,
    required this.cobertoPelaProvisao,
    required this.custoFolgaBruto,
    required this.faltaTotal,
    required this.faltaPorMes,
    required this.valorHoraAtual,
    required this.valorHoraNovo,
    required this.horasExtrasMes,
    required this.estouraCapacidade,
    required this.jaCoberto,
  });

  final int diasFolga;
  final double horasPerdidas;
  final double faturamentoPerdido;
  final double cobertoPelaProvisao;
  final double custoFolgaBruto;
  final double faltaTotal;
  final double faltaPorMes;
  final int valorHoraAtual;
  final int valorHoraNovo;
  final int horasExtrasMes;
  final bool estouraCapacidade;
  final bool jaCoberto;
}

FolgaResult computeFolga({
  required Area area,
  required RegimeId regime,
  required int diasFolga,
  required int mesesAte,
  double custoFolga = 0,
}) {
  final ValorHoraResult r = computeValorHora(area, regime);
  final int diasSemana = area.diasSemana ?? 5;
  final int horasDia = area.horasDia ?? 6;
  final double diasUteisMes = diasSemana * 52 / 12;
  final double fracao = math.max(0, diasFolga) / diasUteisMes;
  // Gross-up com a alíquota efetiva do plano. Teto em 0,95 pra nunca dividir
  // por ~0 num regime absurdo.
  final double rate = r.rate.clamp(0.0, 0.95).toDouble();

  final double horasPerdidas = fracao * area.horas;
  final double faturamentoPerdido = fracao * r.faturamento;
  final double coberto = area.provisaoOn
      ? math.min(fracao, 1.0) * area.renda / (1 - rate)
      : 0;
  final double custoBruto = math.max(0, custoFolga) / (1 - rate);
  final double falta = math.max(0, faturamentoPerdido - coberto + custoBruto);
  final int meses = math.max(1, mesesAte);
  final double faltaPorMes = falta / meses;

  final int horas = math.max(1, area.horas);
  final int valorHoraNovo = ((r.faturamento + faltaPorMes) / horas).ceil();
  final int horasExtrasMes = (faltaPorMes / math.max(1, r.valorHora)).ceil();
  final int brutas = horasBrutasPorRotina(diasSemana: diasSemana, horasDia: horasDia);

  return FolgaResult(
    diasFolga: diasFolga,
    horasPerdidas: horasPerdidas,
    faturamentoPerdido: faturamentoPerdido,
    cobertoPelaProvisao: coberto,
    custoFolgaBruto: custoBruto,
    faltaTotal: falta,
    faltaPorMes: faltaPorMes,
    valorHoraAtual: r.valorHora,
    valorHoraNovo: falta < 0.5 ? r.valorHora : valorHoraNovo,
    horasExtrasMes: falta < 0.5 ? 0 : horasExtrasMes,
    estouraCapacidade: area.horas + horasExtrasMes > brutas,
    jaCoberto: falta < 0.5,
  );
}
```

- [ ] **Step 4: Rodar, commitar**

Run: `flutter test test/folga_calc_test.dart && flutter analyze && flutter test` → verde.

```bash
git add lib/core/calc/calc_engine.dart test/folga_calc_test.dart
git commit -m "feat(calc): computeFolga, ferias como decisao de preco

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10: Tela do Simulador de folga (com o ouro grande, L5)

**Files:**
- Create: `lib/features/folga/folga_screen.dart`
- Modify: `lib/app/routes.dart` (`static const String folga = '/folga';`)
- Modify: `lib/app/router.dart` (rota `_toolPage`)
- Modify: `lib/core/telemetry/eventos.dart` (`static const String folgaSimulada = 'folga_simulada';` no bloco do Sinal 3, sem params)
- Test: `test/folga_screen_test.dart` (novo)

**Interfaces:**
- Consumes: `computeFolga`, `areaAtivaProvider`, `regimeProvider`, `DivisaoColors.reserva` (ouro), `PanelCard(accent:)`, `MoneyField`, `announce`, `Haptics`, `ContentWidth`, `EstimativaSeal`, `kMeses` (de `datas.dart`).
- Produces: `class FolgaScreen extends ConsumerStatefulWidget` sem parâmetros.
- A Task 16 vai colocar a `Cena(tipo: CenaTipo.folga)` no topo desta tela; deixe um comentário `// Cena.folga entra aqui (Task 16)` acima do `ListView`.

- [ ] **Step 1: Teste que falha**

```dart
// test/folga_screen_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
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

  testWidgets('provisão ligada e folga curta: já coberto', (WidgetTester tester) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, provisao: true);
      expect(find.textContaining('já cobre'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** → FAIL (arquivo não existe).

- [ ] **Step 3: Rota**

`routes.dart`: `static const String folga = '/folga';` na seção de ferramentas. `router.dart`: `GoRoute(path: Routes.folga, pageBuilder: (_, GoRouterState s) => _toolPage(s, const FolgaScreen()))`, com o import.

- [ ] **Step 4: A tela**

```dart
// lib/features/folga/folga_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calc/calc_engine.dart';
import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/model/area.dart';
import '../../core/model/regime.dart';
import '../../core/providers.dart';
import '../../core/telemetry/eventos.dart';
import '../../core/telemetry/telemetry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/divisao_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/a11y.dart';
import '../../core/ui/breakpoints.dart';
import '../../core/ui/estimativa_seal.dart';
import '../../core/ui/help_dot.dart';
import '../../core/ui/money_field.dart';
import '../../core/ui/panel_card.dart';

/// Simulador de folga: "pra parar N dias daqui a M meses, minha hora precisa
/// ser quanto?". Férias como decisão de preço (é o nosso job), não como meta
/// de poupança (é o job do app de banco). Sem calendário, sem tracking, sem
/// barra de progresso: três perguntas e uma ação comercial.
class FolgaScreen extends ConsumerStatefulWidget {
  const FolgaScreen({super.key});

  @override
  ConsumerState<FolgaScreen> createState() => _FolgaScreenState();
}

class _FolgaScreenState extends ConsumerState<FolgaScreen> {
  int _dias = 10;
  int _meses = 3;
  final TextEditingController _custo = TextEditingController();

  @override
  void initState() {
    super.initState();
    telemetry.evento(Evento.folgaSimulada);
  }

  @override
  void dispose() {
    _custo.dispose();
    super.dispose();
  }

  int _digits(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final AreaState st = ref.watch(areaAtivaProvider);
    final RegimeId regime = ref.watch(regimeProvider);

    if (st is! AreaPronta) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vou tirar uma folga')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(Space.x6),
            child: Text('Calcule seu valor-hora primeiro. A folga parte dele.'),
          ),
        ),
      );
    }
    final Area area = st.area;
    final FolgaResult f = computeFolga(
      area: area,
      regime: regime,
      diasFolga: _dias,
      mesesAte: _meses,
      custoFolga: _digits(_custo.text).toDouble(),
    );
    final DateTime alvo = DateTime(DateTime.now().year, DateTime.now().month + _meses);
    final String mesAlvo = kMeses[alvo.month - 1];

    return Scaffold(
      appBar: AppBar(title: const Text('Vou tirar uma folga')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(Space.x4),
          children: <Widget>[
            // Cena.folga entra aqui (Task 16)
            _stepper(
              context,
              label: 'Quantos dias você quer parar?',
              value: _dias,
              min: 1,
              max: 60,
              suffix: 'dias',
              onChanged: (int v) => setState(() => _dias = v),
            ),
            const SizedBox(height: Space.x5),
            _stepper(
              context,
              label: 'Daqui a quantos meses?',
              helper: 'Em $mesAlvo, então.',
              value: _meses,
              min: 1,
              max: 12,
              suffix: _meses == 1 ? 'mês' : 'meses',
              onChanged: (int v) => setState(() => _meses = v),
            ),
            const SizedBox(height: Space.x5),
            MoneyField(
              controller: _custo,
              label: 'Quanto a folga custa? (opcional)',
              prefix: r'R$ ',
              helper: 'Viagem, passagem, o que for. Se for só ficar em casa, deixa em branco.',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.x6),
            _Resposta(f: f, mesAlvo: mesAlvo, ouro: d.reserva),
            const SizedBox(height: Space.x4),
            const EstimativaSeal(),
          ],
        ),
      ),
    );
  }

  Widget _stepper(
    BuildContext context, {
    required String label,
    String? helper,
    required int value,
    required int min,
    required int max,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    Widget btn(IconData icon, bool enabled, VoidCallback onTap) =>
        IconButton.filledTonal(
          onPressed: enabled
              ? () {
                  Haptics.select();
                  onTap();
                }
              : null,
          icon: Icon(icon),
          iconSize: 24,
          style: IconButton.styleFrom(
            minimumSize: const Size(52, 52),
            backgroundColor: cs.surfaceContainerHigh,
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
            const HelpDot(verbeteId: 'folga'),
          ],
        ),
        if (helper != null)
          Text(
            helper,
            style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        const SizedBox(height: Space.x3),
        Semantics(
          label: '$label: $value $suffix',
          child: ExcludeSemantics(
            child: Row(
              children: <Widget>[
                btn(Icons.remove, value > min, () => onChanged(value - 1)),
                Expanded(
                  child: Center(
                    child: Text(
                      '$value $suffix',
                      style: AppType.valueMd.copyWith(color: cs.onSurface),
                    ),
                  ),
                ),
                btn(Icons.add, value < max, () => onChanged(value + 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A resposta: a ação comercial. Ouro em superfície grande (L5): a folga é a
/// tela quente do app, e o ouro é a única cor da paleta que diz "descanso".
class _Resposta extends StatelessWidget {
  const _Resposta({required this.f, required this.mesAlvo, required this.ouro});

  final FolgaResult f;
  final String mesAlvo;
  final Color ouro;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    if (f.jaCoberto) {
      return PanelCard(
        accent: ouro,
        padding: const EdgeInsets.all(Space.x5),
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.beach_access_outlined, color: ouro, size: 32),
              const SizedBox(height: Space.x3),
              Text(
                'Sua provisão de férias já cobre ${f.diasFolga} dias.',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: Space.x2),
              Text(
                'Pode parar em $mesAlvo tranquilo, na hora que você já cobra.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final String frase =
        'Pra parar ${f.diasFolga} dias em $mesAlvo, sua hora precisa ser ${moneyBRL(f.valorHoraNovo)} nos próximos contratos. Hoje é ${moneyBRL(f.valorHoraAtual)}.'
        '${f.estouraCapacidade ? ' Mais hora não cabe na sua semana: o caminho é a hora mais cara.' : ' Ou ${f.horasExtrasMes} horas a mais por mês, na hora de hoje.'}';

    return Semantics(
      liveRegion: true,
      label: frase,
      child: ExcludeSemantics(
        child: PanelCard(
          accent: ouro,
          padding: const EdgeInsets.all(Space.x5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'SUA HORA PRECISA SER',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: Space.x1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: moneyBRL(f.valorHoraNovo),
                        style: AppType.valueXl.copyWith(color: ouro),
                      ),
                      TextSpan(
                        text: '/hora',
                        style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.x1),
              Text(
                'hoje: ${moneyBRL(f.valorHoraAtual)}/hora · pra parar ${f.diasFolga} dias em $mesAlvo',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: Space.x4),
              Divider(color: cs.outlineVariant, height: 1),
              const SizedBox(height: Space.x4),
              if (f.estouraCapacidade)
                Text(
                  'Mais hora não cabe na sua semana. O caminho é a hora mais cara.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: <InlineSpan>[
                      const TextSpan(text: 'ou '),
                      TextSpan(
                        text: '+${f.horasExtrasMes} h por mês',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' até lá, na hora de hoje.'),
                    ],
                  ),
                ),
              const SizedBox(height: Space.x3),
              Text(
                'Faltam ${moneyBRL(f.faltaTotal)} entrando antes da folga'
                '${f.cobertoPelaProvisao > 0 ? ', já descontando o que sua provisão de férias cobre' : ''}.',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Confira: `AppType.valueXl` existe (usado em `trabalho_detalhe_screen.dart`); `kMeses` vem de `datas.dart`; `AreaState`/`AreaPronta` vêm de `providers.dart`; o `HelpDot('folga')` depende do verbete da Task 11 (se a Task 11 ainda não rodou, o HelpDot deve degradar sem crash; se não degradar, faça a Task 11 antes desta).

- [ ] **Step 5: Rodar, commitar**

Run: `flutter test test/folga_screen_test.dart && flutter analyze && flutter test` → verde.

```bash
git add lib/features/folga/ lib/app/routes.dart lib/app/router.dart lib/core/telemetry/eventos.dart test/folga_screen_test.dart
git commit -m "feat(folga): simulador de folga, a hora que a ferias exige

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 11: Glossário: `folga` e `horas_cobraveis`

**Files:**
- Modify: `lib/core/glossario/glossario.dart` (adicionar dois verbetes ao mapa)
- Test: `test/glossario_test.dart` (adicionar)

- [ ] **Step 1: Teste que falha**

```dart
  test('v0.10: verbetes de folga e horas cobráveis existem e falam de gente', () {
    expect(Glossario.of('folga').titulo, isNotEmpty);
    expect(Glossario.of('horas_cobraveis').texto, contains('e-mail'));
    expect(Glossario.of('folga').texto, isNot(contains('poup')));
  });
```

(`Glossario.of` usa `!`: verbete inexistente crasha o HelpDot. Por isso esta task roda ANTES da Task 10.)

- [ ] **Step 2: Rodar e ver falhar.**

- [ ] **Step 3: Verbetes**

```dart
    'folga': Verbete(
      'Como o app calcula a folga?',
      'Ele vê quanto aqueles dias parados deixariam de trazer, desconta o '
          'que a sua provisão de férias já cobre, e espalha o resto pelos '
          'meses até lá. O resultado é uma hora mais cara nos próximos '
          'contratos, ou algumas horas a mais por mês. É estimativa: custos '
          'e imposto continuam correndo na folga, então a conta é pelo lado '
          'seguro.',
    ),
    'horas_cobraveis': Verbete(
      'O que são "horas cobráveis"?',
      'As horas do mês que você consegue cobrar de alguém. Não é todo o '
          'tempo que você trabalha: e-mail, orçamento, imprevisto e folga '
          'ninguém paga. Por isso o app tira uma parte antes de calcular a '
          'sua hora. Na dúvida, ele tira mais, pra sua hora não sair barata.',
    ),
```

- [ ] **Step 4: Rodar, commitar**

```bash
git add lib/core/glossario/glossario.dart test/glossario_test.dart
git commit -m "feat(glossario): verbetes de folga e horas cobraveis

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## 3. Trilha A: visual com personalidade

### Task 12: L1: "Recebi" vira botão redondo colado na navbar

**Files:**
- Modify: `lib/app/nav_shell.dart` (`_GlassBottomBar`, `_GlassRail`, novo `_BotaoRecebi`)
- Modify: testes que tocam em `'Recebi um pagamento'` no Painel: `test/entrada_fluxo_test.dart`, `test/entrada_usd_test.dart`, `test/entrada_a11y_test.dart`, `test/a11y_p0_test.dart` (vão passar a tocar `'Recebi'`, ver Step 5)
- Test: `test/nav_recebi_test.dart` (novo)

**Interfaces:**
- Consumes: `areaAtivaProvider` (`AreaPronta`), `Routes.entrada`, `Haptics.select()`, `Materials`, `Space`, `Radii`.
- Produces: `class _BotaoRecebi extends ConsumerWidget` (privado), com `Semantics(label: 'Recebi um pagamento')` e o texto visível `'Recebi'`.
- A Task 15 **remove** o botão "Recebi um pagamento" do Painel (o gesto passa a morar aqui). Até lá, os dois coexistem por um commit; é aceitável.

- [ ] **Step 1: Teste que falha**

```dart
// test/nav_recebi_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/app/app.dart';
import 'package:quantocobro/core/model/area.dart';
import 'package:quantocobro/core/providers.dart';
import 'package:quantocobro/features/entrada/entrada_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/tela.dart';

Future<void> _pump(WidgetTester tester, {required bool comPreco}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'onboarding_done': true,
    if (comPreco)
      'areas_v1': jsonEncode(<String, dynamic>{
        'activeId': 'a1',
        'areas': <Map<String, dynamic>>[Area.padrao().toJson()],
      }),
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const QuantoCobroApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('com preço: o botão Recebi está na navbar e abre a Entrada de qualquer aba', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, comPreco: true);
      await tester.tap(find.text('Trabalhos'));
      await tester.pumpAndSettle();
      expect(find.text('Recebi'), findsOneWidget);
      await tester.tap(find.text('Recebi'));
      await tester.pumpAndSettle();
      expect(find.byType(EntradaScreen), findsOneWidget);
    });
  });

  testWidgets('sem preço ainda: o botão não aparece', (WidgetTester tester) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, comPreco: false);
      expect(find.text('Recebi'), findsNothing);
    });
  });

  testWidgets('as três abas continuam sendo três', (WidgetTester tester) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pump(tester, comPreco: true);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
    });
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** → FAIL (não existe 'Recebi' na navbar).

- [ ] **Step 3: O botão**

Em `nav_shell.dart`, adicionar `import 'routes.dart';` e:

```dart
/// O gesto mais frequente do app, alcançável de QUALQUER aba: um círculo
/// esmeralda colado na pílula, com rótulo (público leigo: rótulo é o mapa).
/// Some enquanto não existe preço calculado: sem valor-hora não há reserva a
/// fazer, e um botão que abre uma tela que pede pra "calcular primeiro" é
/// promessa quebrada no primeiro toque.
class _BotaoRecebi extends ConsumerWidget {
  const _BotaoRecebi({this.compacto = false});

  /// No trilho lateral não cabe o rótulo embaixo: só o círculo, com tooltip.
  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(areaAtivaProvider) is! AreaPronta) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Widget circulo = SizedBox(
      width: 56,
      height: 56,
      child: FilledButton(
        onPressed: () {
          Haptics.select();
          context.push(Routes.entrada);
        },
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: const Icon(Icons.payments_outlined, size: 26),
      ),
    );
    return Semantics(
      button: true,
      label: 'Recebi um pagamento',
      child: ExcludeSemantics(
        child: Tooltip(
          message: 'Recebi um pagamento',
          child: compacto
              ? circulo
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    circulo,
                    const SizedBox(height: Space.x1),
                    Text(
                      'Recebi',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
```

(`Haptics` vem de `../core/ui/a11y.dart`; adicione o import se não estiver.)

- [ ] **Step 4: Encaixar na barra e no trilho**

`_GlassBottomBar.build`, o `return` vira:

```dart
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: _pilula(
                context,
                child: _vidro(context, solido: _solido(context, ref), child: bar),
              ),
            ),
            // Um Consumer interno decide se há espaço: sem preço, sem botão e
            // sem o vão de 12dp.
            Consumer(
              builder: (BuildContext context, WidgetRef ref, _) =>
                  ref.watch(areaAtivaProvider) is AreaPronta
                  ? const Padding(
                      padding: EdgeInsets.only(left: Space.x3, bottom: 2),
                      child: _BotaoRecebi(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
```

`_GlassRail`: no `NavigationRail`, adicionar `leading: const Padding(padding: EdgeInsets.only(top: Space.x2, bottom: Space.x2), child: _BotaoRecebi(compacto: true))`.

- [ ] **Step 5: Atualizar os testes que tocavam no botão do Painel**

Nos quatro arquivos listados acima, onde houver `find.text('Recebi um pagamento')` pra abrir a Entrada, **manter** por enquanto (o botão do Painel ainda existe até a Task 15). A Task 15 é quem troca por `find.text('Recebi')`. Aqui só rode e confirme verde.

- [ ] **Step 6: Rodar, commitar**

Run: `flutter test test/nav_recebi_test.dart test/nav_glass_test.dart test/painel_smoke_test.dart && flutter analyze && flutter test` → verde. Atenção ao `nav_glass_test` (um só `BackdropFilter` por ramo: o botão não pode criar outro).

```bash
git add lib/app/nav_shell.dart test/nav_recebi_test.dart
git commit -m "feat(nav): botao Recebi redondo colado na navbar, de qualquer aba

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 13: L2: nome opcional e cabeçalho com saudação

**Files:**
- Modify: `lib/core/settings/settings_repository.dart` (`nome`/`setNome`, chave `'nome'`)
- Modify: `lib/core/providers.dart` (`NomeNotifier`, `nomeProvider`)
- Modify: `lib/core/common/datas.dart` (`saudacao`)
- Modify: `lib/features/onboarding/onboarding_screen.dart` (campo na página 2, grava no `_finish`)
- Modify: `lib/features/painel/painel_screen.dart:44-60` (título do AppBar)
- Modify: `lib/features/config/config_screen.dart` (seção "Gestão": ListTile "Seu nome")
- Modify: `lib/features/legal/legal_texts.dart` §2 e `../website/site/quanto-cobro/privacidade/index.html` §2: acrescentar "o seu nome, se você informar" à lista do que fica no aparelho
- Test: `test/saudacao_test.dart` (novo), `test/onboarding_consent_test.dart` (adicionar 1 caso)

**Interfaces:**
- Produces: `String nome()` / `Future<void> setNome(String)` no `SettingsRepository`; `final NotifierProvider<NomeNotifier, String> nomeProvider`; `String saudacao(DateTime agora)` → `'Bom dia'` (5h–11h59), `'Boa tarde'` (12h–17h59), `'Boa noite'` (resto).

- [ ] **Step 1: Testes que falham**

```dart
// test/saudacao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/common/datas.dart';

void main() {
  test('saudação pela hora', () {
    expect(saudacao(DateTime(2026, 1, 1, 7)), 'Bom dia');
    expect(saudacao(DateTime(2026, 1, 1, 12)), 'Boa tarde');
    expect(saudacao(DateTime(2026, 1, 1, 18)), 'Boa noite');
    expect(saudacao(DateTime(2026, 1, 1, 2)), 'Boa noite');
  });
}
```

Em `onboarding_consent_test.dart`:

```dart
  testWidgets('nome digitado no onboarding vira saudação no Painel', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await boot(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Gabriel');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(c.read(nomeProvider), 'Gabriel');
    expect(find.textContaining(', Gabriel'), findsOneWidget);
  });
```

- [ ] **Step 2: Rodar e ver falhar.**

- [ ] **Step 3: Settings + provider + saudação**

`settings_repository.dart`:

```dart
  // Nome da pessoa, opcional, só pra saudação. Fica no aparelho como tudo.
  static const String _kNome = 'nome';
  String nome() => _prefs.getString(_kNome)?.trim() ?? '';
  Future<void> setNome(String v) => _prefs.setString(_kNome, v.trim());
```

`providers.dart` (ao lado do `TelemetryNotifier`):

```dart
class NomeNotifier extends Notifier<String> {
  @override
  String build() => ref.read(settingsRepositoryProvider).nome();

  Future<void> set(String value) async {
    await ref.read(settingsRepositoryProvider).setNome(value);
    state = value.trim();
  }
}

final NotifierProvider<NomeNotifier, String> nomeProvider =
    NotifierProvider<NomeNotifier, String>(NomeNotifier.new);
```

`datas.dart`:

```dart
/// A saudação do cabeçalho. Sem "Olá": é o que todo app diz.
String saudacao(DateTime agora) {
  final int h = agora.hour;
  if (h >= 5 && h < 12) return 'Bom dia';
  if (h >= 12 && h < 18) return 'Boa tarde';
  return 'Boa noite';
}
```

- [ ] **Step 4: Onboarding**

Em `_OnboardingScreenState`: `final TextEditingController _nome = TextEditingController();` (dispose junto). Na página 2 (`_page3`), dentro do `extra`, **antes** do "Você trabalha mais pra clientes:":

```dart
        TextField(
          controller: _nome,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Como posso te chamar? (opcional)',
            hintText: 'Seu primeiro nome',
          ),
        ),
        const SizedBox(height: Space.x5),
```

Em `_finish`, antes de `setModo`: `await ref.read(nomeProvider.notifier).set(_nome.text);`.

- [ ] **Step 5: Painel**

No `AppBar` do `PainelScreen`, o `Text(AppConfig.appName, ...)` vira:

```dart
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, _) {
                  final String nome = ref.watch(nomeProvider);
                  return Text(
                    nome.isEmpty
                        ? AppConfig.appName
                        : '${saudacao(DateTime.now())}, $nome',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: AppType.numberFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
```

- [ ] **Step 6: Ajustes**

Na seção "Gestão" de `config_screen.dart`, primeiro `ListTile`:

```dart
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Seu nome'),
                    subtitle: Text(nome.isEmpty ? 'Só pra te chamar pelo nome.' : nome),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final TextEditingController c = TextEditingController(text: nome);
                      final String? novo = await showDialog<String>(
                        context: context,
                        builder: (BuildContext ctx) => AlertDialog(
                          title: const Text('Como posso te chamar?'),
                          content: TextField(
                            controller: c,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(hintText: 'Seu primeiro nome'),
                          ),
                          actions: <Widget>[
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Salvar')),
                          ],
                        ),
                      );
                      if (novo != null) await ref.read(nomeProvider.notifier).set(novo);
                    },
                  ),
```

(com `final String nome = ref.watch(nomeProvider);` no `build`).

- [ ] **Step 7: Política (app + site, mesma sessão)**

No §2 da privacidade, a lista "a sua renda desejada, os seus custos, ..." ganha ", o seu nome (se você informar)". Mesma frase no HTML.

- [ ] **Step 8: Rodar, commitar**

Run: `flutter analyze && flutter test` → verde.

```bash
git add lib/ test/
git commit -m "feat(painel): saudacao com o nome (opcional, so no aparelho)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
git -C ../website add site/quanto-cobro/privacidade/index.html
git -C ../website commit -m "docs(quanto-cobro): politica cita o nome opcional"
```

---

### Task 14: L3: anel no Teto do MEI

**Files:**
- Modify: `lib/features/painel/painel_screen.dart` (`_TetoMeiCard` usa `_AnelTeto`; `_BarraTeto` é removida)
- Test: `test/teto_mei_card_test.dart` (adicionar 1 asserção)

**Interfaces:**
- Produces: `class _AnelTeto extends StatelessWidget { const _AnelTeto({required this.faturado, required this.cor}); }` desenhando um `CustomPaint` de 72dp: trilho `DivisaoColors.track`, arco preenchido `faturado / kTetoMeiComTolerancia` na cor da zona, um traço no ângulo de `kTetoAnualMei / kTetoMeiComTolerancia`, e no centro o % do teto de 81 mil.

- [ ] **Step 1: Teste que falha**

Em `teto_mei_card_test.dart`, no caso que já monta o cartão com `faturadoAno: 60000`:

```dart
    // v0.10: o teto é um anel, não uma barra (doutrina: elemento circular).
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('74%'), findsOneWidget); // 60.000 / 81.000
```

- [ ] **Step 2: Rodar e ver falhar.**

- [ ] **Step 3: O anel**

Substituir `_BarraTeto` por:

```dart
/// O teto como ANEL: trilho neutro, arco na cor da zona, um traço onde fica o
/// teto (81 mil) e o % no centro. A escala vai até o limite dos 20% (97,2 mil).
class _AnelTeto extends StatelessWidget {
  const _AnelTeto({required this.faturado, required this.cor});

  final double faturado;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DivisaoColors d = theme.extension<DivisaoColors>()!;
    final double fill = (faturado / kTetoMeiComTolerancia).clamp(0.0, 1.0);
    final int pctTeto = (faturado / kTetoAnualMei * 100).round();
    return ExcludeSemantics(
      child: SizedBox(
        width: 72,
        height: 72,
        child: CustomPaint(
          painter: _AnelTetoPainter(
            fill: fill,
            marca: kTetoAnualMei / kTetoMeiComTolerancia,
            cor: cor,
            trilho: d.track,
            traco: theme.colorScheme.surface,
          ),
          child: Center(
            child: Text(
              '$pctTeto%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cor,
                fontFamily: AppType.numberFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnelTetoPainter extends CustomPainter {
  const _AnelTetoPainter({
    required this.fill,
    required this.marca,
    required this.cor,
    required this.trilho,
    required this.traco,
  });

  final double fill;
  final double marca;
  final Color cor;
  final Color trilho;
  final Color traco;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 7;
    final Rect rect = Offset.zero & size;
    final Rect arco = rect.deflate(stroke / 2);
    const double inicio = -math.pi / 2;
    final Paint pTrilho = Paint()
      ..color = trilho
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final Paint pFill = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arco, inicio, 2 * math.pi, false, pTrilho);
    if (fill > 0) canvas.drawArc(arco, inicio, 2 * math.pi * fill, false, pFill);
    // O traço do teto (81 mil): um risco radial na cor do fundo, atravessando o anel.
    final double ang = inicio + 2 * math.pi * marca;
    final Offset c = rect.center;
    final double r = arco.width / 2;
    final Paint pTraco = Paint()
      ..color = traco
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      c + Offset(math.cos(ang), math.sin(ang)) * (r - stroke / 2 - 1),
      c + Offset(math.cos(ang), math.sin(ang)) * (r + stroke / 2 + 1),
      pTraco,
    );
  }

  @override
  bool shouldRepaint(_AnelTetoPainter old) =>
      old.fill != fill || old.cor != cor || old.trilho != trilho;
}
```

(`import 'dart:math' as math;` no topo do arquivo, se não houver.)

- [ ] **Step 4: Encaixar no cartão**

No `_TetoMeiCard.build`, onde estava `_BarraTeto(...)`, montar uma `Row`: `_AnelTeto(faturado: teto.faturado, cor: zonaCor)`, `SizedBox(width: Space.x4)`, e `Expanded(child: Column([o Text.rich "R$ 19.850 de R$ 81.000", _status(...)]))`. O `_projecao` fica abaixo da Row. Sob `RepaintBoundary` (higiene de raster da casa).

- [ ] **Step 5: Rodar, commitar**

Run: `flutter test test/teto_mei_card_test.dart && flutter analyze && flutter test` → verde.

```bash
git add lib/features/painel/painel_screen.dart test/teto_mei_card_test.dart
git commit -m "feat(painel): teto do MEI vira anel

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 15: L6: ações rápidas redondas no Painel (e o "Recebi" sai de lá)

**Files:**
- Modify: `lib/features/painel/painel_screen.dart` (`_Acoes` → `_AcoesRapidas`; remover o `TextButton` "Recalcular" do fim)
- Modify: `test/entrada_fluxo_test.dart`, `test/entrada_usd_test.dart`, `test/entrada_a11y_test.dart`, `test/a11y_p0_test.dart`: `find.text('Recebi um pagamento')` → `find.text('Recebi')` (o botão da navbar, Task 12)
- Test: `test/painel_smoke_test.dart` (adicionar 1 caso)

**Interfaces:**
- Consumes: `Routes.simulador`, `Routes.folga`, `Routes.historico`, `Routes.calc`, `SemanticButton`.

- [ ] **Step 1: Teste que falha**

Em `painel_smoke_test.dart`, um caso que monta o Painel com `Area.padrao()` (copie o `_pump` de `teto_mei_card_test.dart` com `regime: 'cpf'`):

```dart
  testWidgets('com preço: quatro ações rápidas redondas, e o Recebi mora na navbar', (
    WidgetTester tester,
  ) async {
    await comTela(tester, Tela.celularEmPe, () async {
      await _pumpComPreco(tester);
      for (final String a in <String>['Orçar', 'Folga', 'Histórico', 'Recalcular']) {
        expect(find.text(a), findsOneWidget, reason: a);
      }
      expect(find.text('Recebi um pagamento'), findsNothing);
      expect(find.text('Vou orçar um projeto'), findsNothing);
      expect(find.text('Recebi'), findsOneWidget);
    });
  });
```

- [ ] **Step 2: Rodar e ver falhar.**

- [ ] **Step 3: O widget**

Substituir `_Acoes` por:

```dart
/// Quatro ações rápidas em círculo, com rótulo (a fileira "Genres" do app de
/// audiolivro, adaptada). Terceira natureza de elemento na tela depois do
/// número solto e do anel. O "Recebi" NÃO está aqui: mora na navbar (Task 12),
/// que é onde o gesto mais frequente merece ficar.
class _AcoesRapidas extends StatelessWidget {
  const _AcoesRapidas({
    required this.onOrcar,
    required this.onFolga,
    required this.onHistorico,
    required this.onRecalcular,
  });

  final VoidCallback onOrcar;
  final VoidCallback onFolga;
  final VoidCallback onHistorico;
  final VoidCallback onRecalcular;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _Acao(icon: Icons.request_quote_outlined, label: 'Orçar', hint: 'simula um projeto', onTap: onOrcar)),
        Expanded(child: _Acao(icon: Icons.beach_access_outlined, label: 'Folga', hint: 'simula uma folga', onTap: onFolga)),
        Expanded(child: _Acao(icon: Icons.receipt_long_outlined, label: 'Histórico', hint: 'abre o histórico do mês', onTap: onHistorico)),
        Expanded(child: _Acao(icon: Icons.calculate_outlined, label: 'Recalcular', hint: 'refaz o cálculo', onTap: onRecalcular)),
      ],
    );
  }
}

class _Acao extends StatelessWidget {
  const _Acao({required this.icon, required this.label, required this.hint, required this.onTap});

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return SemanticButton(
      label: label,
      tapHint: hint,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            Haptics.select();
            onTap();
          },
          borderRadius: const BorderRadius.all(Radii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.x2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerHigh,
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Icon(icon, color: cs.onSurface),
                ),
                const SizedBox(height: Space.x2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

No `_Corpo.build`, o bloco 2) vira:

```dart
            StaggerIn(
              index: 1,
              child: _AcoesRapidas(
                onOrcar: () => context.push(Routes.simulador),
                onFolga: () => context.push(Routes.folga),
                onHistorico: () => context.push(Routes.historico),
                onRecalcular: () => context.push(Routes.calc),
              ),
            ),
```

E remover o `Center(child: TextButton.icon(... 'Recalcular'))` do fim da lista (o `EstimativaSeal` fica).

- [ ] **Step 4: Testes de entrada**

Nos quatro arquivos, trocar o toque em `'Recebi um pagamento'` por `'Recebi'`. Se algum deles fixar `Tela` maior que `compact` (trilho), o botão é `compacto` sem texto: use `find.bySemanticsLabel('Recebi um pagamento')`.

- [ ] **Step 5: Rodar, commitar**

Run: `flutter analyze && flutter test` → verde (inclusive `layout_matrix`, `overflow`, `tablet` no Painel; se "Recalcular" estourar a 200% em 320dp, reduza pra 3 ações tirando "Recalcular", que continua alcançável pelo link "ver como cheguei aqui" → Detalhamento → Recalcular).

```bash
git add lib/features/painel/painel_screen.dart test/
git commit -m "feat(painel): acoes rapidas em circulo; Recebi mora na navbar

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 16: L4: `Cena`, a ilustração assinatura (onboarding, vazio, folga)

**Files:**
- Create: `lib/core/ui/cena.dart`
- Modify: `lib/features/onboarding/onboarding_screen.dart` (`_page1` usa `Cena` no lugar do ícone de 96dp)
- Modify: `lib/core/ui/empty_state_hero.dart` (o `Card` com `DivisaoBar` vira `Cena`)
- Modify: `lib/features/folga/folga_screen.dart` (o comentário `// Cena.folga entra aqui` vira `const Cena(tipo: CenaTipo.folga)` + `SizedBox(height: Space.x5)`)
- Test: `test/cena_test.dart` (novo)

**Interfaces:**
- Produces: `enum CenaTipo { inicio, folga }` e `class Cena extends StatelessWidget { const Cena({super.key, required this.tipo, this.altura = 180}); }`.
- Composição em código (nada de asset): fundo com dois blobs circulares em alpha ≤ 0,10 (esmeralda pra `inicio`, ouro pra `folga`), grão do `DotPainter` (`texturas.dart`) por cima, e a marca `CofreMark` (a assinatura da casa) como protagonista. Em `folga`, o cofre fica menor à direita e um arco de ouro (sol) domina.
- **Slot pra raster depois:** `static const bool usaRaster = false;` no topo do arquivo. Quando o Gabriel gerar as imagens, ele declara `assets/ilustracoes/inicio.webp` e `folga.webp` no `pubspec.yaml`, vira a flag, e o `build` faz `if (usaRaster) return Image.asset('assets/ilustracoes/${tipo.name}.webp', height: altura, fit: BoxFit.contain, excludeFromSemantics: true);`. Spec do asset (pra geração por IA): 1024×1024, fundo transparente, estilo 3D suave, paleta esmeralda `#57E5A9` / ouro / cinza-carvão, sem texto, sem pessoas.
- `reduceMotionOf`: a `Cena` não anima. Sob `RepaintBoundary`.

- [ ] **Step 1: Teste que falha**

```dart
// test/cena_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/theme/app_theme.dart';
import 'package:quantocobro/core/ui/cena.dart';
import 'package:quantocobro/core/ui/cofre_mark.dart';

void main() {
  for (final CenaTipo tipo in CenaTipo.values) {
    testWidgets('cena $tipo desenha a marca e é decorativa pro leitor de tela', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: Center(child: Cena(tipo: tipo))),
        ),
      );
      expect(find.byType(CofreMark), findsOneWidget);
      expect(find.byType(ExcludeSemantics), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
```

- [ ] **Step 2: Rodar e ver falhar.**

- [ ] **Step 3: O widget**

```dart
// lib/core/ui/cena.dart
import 'package:flutter/material.dart';

import '../theme/divisao_colors.dart';
import '../theme/tokens.dart';
import 'cofre_mark.dart';
import 'texturas.dart';

/// Se um dia houver ilustração raster, declare os assets no pubspec e vire
/// isto. Até lá, a cena é composta em código com a marca da casa.
const bool kCenaUsaRaster = false;

enum CenaTipo { inicio, folga }

/// A ilustração assinatura: o que separa "app de IA" de "app com dono".
/// Composta com o que a paleta já tem (blobs a ≤10% de alpha, grão, e o
/// CofreMark). Decorativa: leitor de tela pula.
class Cena extends StatelessWidget {
  const Cena({super.key, required this.tipo, this.altura = 180});

  final CenaTipo tipo;
  final double altura;

  @override
  Widget build(BuildContext context) {
    if (kCenaUsaRaster) {
      return ExcludeSemantics(
        child: Image.asset(
          'assets/ilustracoes/${tipo.name}.webp',
          height: altura,
          fit: BoxFit.contain,
        ),
      );
    }
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DivisaoColors d = Theme.of(context).extension<DivisaoColors>()!;
    final Color principal = tipo == CenaTipo.inicio ? cs.primary : d.reserva;
    final Color apoio = tipo == CenaTipo.inicio ? d.reserva : cs.primary;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: altura,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radii.xl),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Blob grande, deslocado: o "acento quente usado grande".
                Positioned(
                  left: -altura * 0.2,
                  top: -altura * 0.25,
                  child: _blob(principal.withValues(alpha: 0.10), altura * 0.9),
                ),
                Positioned(
                  right: -altura * 0.15,
                  bottom: -altura * 0.3,
                  child: _blob(apoio.withValues(alpha: 0.07), altura * 0.7),
                ),
                if (tipo == CenaTipo.folga)
                  // O sol: um arco de ouro que domina; o cofre fica pequeno.
                  Positioned(
                    top: altura * 0.18,
                    child: Container(
                      width: altura * 0.5,
                      height: altura * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: principal.withValues(alpha: 0.55), width: 6),
                      ),
                    ),
                  ),
                // Grão por cima de tudo, bem sutil.
                Positioned.fill(
                  child: CustomPaint(
                    painter: DotPainter(cs.onSurface.withValues(alpha: 0.04)),
                  ),
                ),
                if (tipo == CenaTipo.inicio)
                  CofreMark(size: altura * 0.55)
                else
                  Positioned(
                    right: altura * 0.18,
                    bottom: altura * 0.12,
                    child: CofreMark(size: altura * 0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(Color cor, double diametro) => Container(
    width: diametro,
    height: diametro,
    decoration: BoxDecoration(shape: BoxShape.circle, color: cor),
  );
}
```

`DotPainter` recebe a cor como argumento posicional (`texturas.dart:37`).

- [ ] **Step 4: Usar nas três telas**

- `onboarding_screen.dart`, `_page1`: trocar `icon: Icons.savings_outlined` por `icon: null` e passar `extra: null`; no `_pageColumn`, quando `icon == null` e for a página 0, colocar `const Cena(tipo: CenaTipo.inicio)` + `SizedBox(height: Space.x6)` antes do título (adicione um parâmetro `Widget? topo` ao `_pageBody`/`_pageColumn` pra isso).
- `empty_state_hero.dart`: o `Card(... DivisaoBar ...)` vira `const Cena(tipo: CenaTipo.inicio)`.
- `folga_screen.dart`: o comentário vira `const Cena(tipo: CenaTipo.folga), const SizedBox(height: Space.x5),`.

- [ ] **Step 5: Rodar, commitar**

Run: `flutter test test/cena_test.dart test/onboarding_consent_test.dart test/painel_smoke_test.dart && flutter analyze && flutter test` → verde (o `painel_smoke` procura os textos do vazio, não a `DivisaoBar`; se procurar a barra, atualize).

```bash
git add lib/core/ui/cena.dart lib/features/onboarding/onboarding_screen.dart lib/core/ui/empty_state_hero.dart lib/features/folga/folga_screen.dart test/cena_test.dart
git commit -m "feat(ui): Cena, a ilustracao assinatura (onboarding, vazio, folga)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## 4. Release

### Task 17: 0.10.0+21, prints e ficha

**Files:**
- Modify: `pubspec.yaml:6` → `version: 0.10.0+21`
- Regenerar: `docs/screenshots/loja/*` via `flutter test test/ferramentas/prints_loja.dart` (é a ferramenta da casa; ler o cabeçalho do arquivo pra o comando exato)
- Modify: `docs/planning/14-FICHA-LOJA.md`: nota "Novidades 0.10.0" com: passo das horas mais claro · folga · prazo e pagamento na proposta · data de entrega · visual novo.

- [ ] **Step 1: Bump + prints + ficha**
- [ ] **Step 2: `flutter analyze && flutter test` verde, `flutter build appbundle --release` compila**
- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml docs/screenshots/loja docs/planning/14-FICHA-LOJA.md
git commit -m "chore(release): bump 0.10.0+21 (fluxo claro, folga, visual)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

- [ ] **Step 4: PARAR.** Subir pro teste interno e promover (`scripts/promote-to-production.py --commit`) é decisão do Gabriel, na hora. O `validate` (dry-run) pode rodar.

---

## Apêndice A: o dia em que o anúncio entrar (não é agora)

Checklist pra quem for ligar o SDK, pra não tomar ★1 nem reprovação na Play:

1. **R6 continua valendo:** anúncio jamais sobre um número de dinheiro nem no caminho crítico (calc → Resultado, Entrada). Slot: banner ancorado acima da pílula da navbar (o `kFloatingNavReserve` volta pra 140, ver o comentário em `tokens.dart`) **ou** intersticial pós-salvar no `AdInterstitial.maybeShowOnSave` (que hoje é no-op). Nunca os dois.
2. **Permissão `AD_ID`:** foi removida do manifest em `0215aad`. O AdMob exige. Volta junto com o SDK, e a **Data Safety** da Play precisa declarar "Device or other IDs → Advertising" e "Ads" como finalidade.
3. **`APPLICATION_ID` do AdMob no manifest** antes de qualquer `flutter run`: a falta dele já derrubou o boot deste app uma vez (histórico no `pubspec.yaml`). Init defensivo com try/catch, como o Firebase.
4. **Política de privacidade** (app + site, mesma sessão): o §3 já diz "pode passar a exibir"; no dia, ele passa a descrever a rede (Google AdMob), os dados (ID de publicidade, localização aproximada) e o consentimento UMP fora do Brasil. O texto do Deixei Aqui em `../website/site/deixei-aqui/privacidade/index.html` §4(a) é o modelo.
5. **Pro desliga tudo:** `isPro == true` → nenhum SDK inicializa. É a promessa vendida ("você nunca os verá").
6. **O número dos reviews continua o mesmo:** 6,7% das reclamações no nicho são anúncio (2,48× a média). Medir `pro_ativado` por gatilho antes e depois: se o anúncio não converter Pro nem pagar eCPM, ele sai de novo.

## Apêndice B: o que ficou de fora, de propósito

- Cronômetro / registro diário de horas / redistribuição de débito / burnout: é outra categoria (Toggl, Timesheet). Se um dia entrar, é "horas usadas vs. orçadas" por trabalho, digitado, não cronômetro.
- IA pra dúvida de imposto: quebra offline e R5.
- Aba "Férias": três abas.
- Taxas bancárias na proposta.
- Calendário de folga com progresso "horas faturadas na nova taxa": exige tracking; sem ele é tela morta.
