# UI-SPEC — Quanto Cobro? · camada visual "A Divisão"

> **Escopo:** especificação de UI pronta pra implementar em Flutter (Material 3),
> derivada 100% do `docs/Design-System.md` e do `docs/UX-Blueprint.md`. Nada aqui
> inventa linguagem nova — só materializa a existente em widgets, tokens e dp.
> **Não** é código; é o contrato que o build segue.
>
> **Fonte da verdade de tokens:** `lib/core/theme/tokens.dart` (Space/Radii/Motion),
> `lib/core/theme/divisao_colors.dart` (ThemeExtension `DivisaoColors`),
> `lib/core/theme/color_scheme.dart` (roles M3), `lib/core/theme/app_typography.dart`
> (`AppType` — números Sora).
>
> **Tema padrão: Escuro.** Toda cor citada é role do `ColorScheme` ou token de
> `DivisaoColors` — **zero hex solto em widget**. Os hexes abaixo são só para leitura.

---

## 0. Diagnóstico do estado atual (o que falta pra ter alma)

O código hoje é Material cru: `ListView` + `Text` + `FilledButton` default. Os tokens
existem, mas **as telas quase não os usam**. Lacunas que este spec resolve:

| Lacuna hoje | Consequência | Onde resolvo |
|---|---|---|
| Nenhum `TextTheme` custom no `AppTheme._build` | corpo/rótulos caem no Roboto/tamanho default do M3, não no Inter+escala do DS §4.3 | §1.0 (Fundação) |
| `AppType` só tem hero/xl/lg/md | falta `value.display` (40) e `value.keypadKey` (28) do DS §4.2 | §1.0 |
| Sem card-herói, sem elevação, sem profundidade | número-herói "solto" no fundo, sem presença; tela sem hierarquia | §1.1 |
| Botões = `FilledButton`/`OutlinedButton` default (não pill 56dp) | não é a linguagem do DS §6.4/§6.3 | §1.4, §1.5 |
| `DivisaoBar` sem ícones na legenda, sem hachura em Custos, sem animação | fere DS §6.2 (sinal não-cromático) e §5.4 (motion do "aha") | §1.2 |
| Botões dos tools são um `FilledButton` + um `OutlinedButton` empilhados | a virada pede **dois cards-ação lado a lado** com peso ≥ herói | §1.6, §2.1 |
| Sem campo monetário grande, sem selo/stale/chips/stepper/banner reutilizáveis | cada tela reimplementa cru | §1.3, §1.7–§1.13 |
| Painel: reserva mostrada como texto pequeno | a virada (§0.1 do blueprint) exige Divisão + "Recebi um pagamento" com peso ≥ valor-hora | §2.1 |

**Regra transversal do build:** todo número de dinheiro usa `moneyBRL()` (`lib/core/common/money.dart`)
e um estilo de `AppType` (Sora, `tnum`). Todo rótulo/corpo usa `Theme.of(context).textTheme.*`
(Inter, depois de §1.0). Toque mínimo 48dp. Reduce-motion respeitado (`MediaQuery.disableAnimations`).

---

## 1. Biblioteca de componentes (`lib/core/ui/`)

Convenção: cada componente é `StatelessWidget` puro (sem lógica de negócio), lê cor de
`Theme.of(context).colorScheme` e `Theme.of(context).extension<DivisaoColors>()!`, e recebe
dados prontos. Base widget indicado por componente. **Radii/Space/Motion sempre dos tokens.**

### 1.0 Fundação — wiring de tema (pré-requisito, `lib/core/theme/`)

Antes dos componentes, três ajustes de tema que destravam tudo:

**(a) `AppType` — adicionar os 2 estilos faltantes** (`app_typography.dart`, DS §4.2):

```
value.display : Sora 40 / w600 / tnum / height 1.0 / tracking -1   → campo monetário em foco
value.keypadKey: Sora 28 / w600 / tnum                              → teclas do keypad (§1.3 opcional)
```

**(b) `TextTheme` Inter + escala M3 do DS §4.3** — montar em `app_theme.dart` e passar em
`ThemeData(textTheme: …)`. Todos com `fontFamily: 'Inter'`; os de número/dinheiro na UI
podem receber `fontFeatures: AppType.tnum` quando exibem valor inline.

| Role M3 | size/line | weight |
|---|---|---|
| displaySmall | 36/44 | 600 |
| headlineMedium | 28/36 | 600 |
| headlineSmall | 24/32 | 600 |  ← perguntas-título do fluxo guiado |
| titleLarge | 22/28 | 600 |
| titleMedium | 16/24 | 600 |
| titleSmall | 14/20 | 500 |
| bodyLarge | 16/24 | 400 |  ← corpo mínimo 16sp |
| bodyMedium | 14/20 | 400 |  ← helpers ⓘ |
| labelLarge | 16/20 | 600 |  ← botões |
| labelMedium | 13/16 | 500 |
| labelSmall | 11/16 | 500 |  ← selo, "Publicidade" |

**(c) Elevação/superfície** — no escuro a hierarquia vem do **tom de superfície**
(`surfaceContainer*`), não de sombra (DS §5.3). Padronizar helpers de nível:

```
elev.0 → fundo/fluxo guiado (surface, sem sombra)
elev.1 → cards de tool e de pergunta (surfaceContainerLow no escuro / outline sutil no claro)
elev.2 → card-herói e botão primário (surfaceContainerHigh no escuro; sombra leve no claro)
elev.3 → sheets/menus (surfaceContainerHigh + shadow)
```

State layers: hover 8% · focus/press 12% (DS §5.3).

---

### 1.1 `HeroValueCard` — card-herói do valor-hora ⭐ (DS §6.1)

O elemento de maior presença do app. Envolve o número-herói num contêiner de profundidade.

- **Base:** `Card` (M3, `elevation: 0`) com `color: surfaceContainerHigh` **ou** `Container`
  com `BoxDecoration`. Preferir `Card` pela ripple/semântica.
- **Forma/tokens:** `borderRadius: Radii.xl` (24) · `padding: EdgeInsets.all(Space.x6)` (24) ·
  superfície `colorScheme.surfaceContainerHigh` · elevação nível 2 (§1.0c).
- **Anatomia (Column, `crossAxisAlignment.start`):**
  1. rótulo `SEU VALOR-HORA` — `textTheme.labelLarge`, `onSurfaceVariant`, `letterSpacing 0.5`.
  2. `SizedBox(height: Space.x1)` (4).
  3. **número-herói** `R$ 92 /hora` — `AppType.valueHero` (72) `color: colorScheme.primary`.
     O `/hora` numa `TextSpan` filha em `titleMedium onSurfaceVariant` (não compete).
  4. linha de contexto `pra ganhar R$ 5.000/mês` — `textTheme.bodyLarge`, `onSurfaceVariant`.
  5. `SizedBox(height: Space.x3)` (12).
  6. `TextButton.icon(icon: receipt_long 18, label: "Ver como cheguei aqui")` — cor `primary`,
     alinhado à esquerda (`Align`), alvo ≥ 48dp.
- **Estados:**
  - *com cálculo:* padrão acima.
  - *sem cálculo:* card **não existe** (Painel usa `EmptyStateHero`, §1.11).
  - *dado de regime desatualizado:* logo abaixo do número, um `StaleBanner` (§1.9) discreto.
- **Motion:** ao entrar (primeira montagem pós-resultado), o número faz count-up
  (`Motion.countUp` 600ms, ease-out). Em reduce-motion, estático.
- **A11y:** `Semantics(label: "Seu valor-hora: noventa e dois reais por hora")` no número.

---

### 1.2 `DivisaoBar` — a assinatura ⭐ (DS §2.3 / §6.2) — **refatorar o existente**

O componente já existe (`lib/core/ui/divisao_bar.dart`) mas está incompleto. Elevar para o
padrão do DS. **É o coração do produto — capricho máximo aqui.**

- **Base:** `Column` — barra (`ClipRRect` + `Row` de `Expanded`) + legenda.
- **Barra:**
  - altura **20dp** (DS §6.2 diz 16–20; usar 20 para presença), `borderRadius: Radii.sm` (12).
  - 3 segmentos `Expanded(flex:)` proporcionais, ordem **fixa Lucro → Reserva → Custos**.
  - cores: `d.lucro` · `d.reserva` · `d.custo` (nunca role primary — são tokens da Divisão).
  - **gap de 2dp entre segmentos** (via `SizedBox(width:2)` ou padding interno) para leitura.
  - **hachura obrigatória no segmento de Custos** (sinal não-cromático, DS §6.2/§7): pintar
    por cima um `CustomPaint` com linhas diagonais sutis `onSurfaceVariant @ 24%`. É o que
    permite ao daltônico distinguir Custos sem depender do verde×azul.
  - trilho vazio (`total<=0`) = `d.track`.
- **Legenda (abaixo, `Space.x3`=12 de gap):** 3 linhas, cada uma:
  `[bolinha 12dp cor] [ícone 16 da parte] [rótulo bodyMedium] … [R$ + "·" + N% labelLarge tnum]`.
  Ícones por parte (DS §5.5): Lucro `account_balance_wallet` · Reserva `lock`/`savings` ·
  Custos `build`. Bolinha `borderRadius: Radii.sm` reduzida (3dp) como hoje.
- **Variantes (parâmetro `emphasis`):**
  - `DivisaoEmphasis.overview` (Painel) — os 3 de relance, legenda completa, nenhum realçado.
  - `DivisaoEmphasis.lucro` (Resultado/Simulador) — segmento Lucro ganha `FontWeight.w700` no
    valor da legenda + leve `outline` no segmento da barra.
  - `DivisaoEmphasis.reserva` (Reserva) — colapsa para **2 segmentos** (Reserva + Sobra),
    Reserva realçada; a Reserva no tool usa `d.reserva`, a Sobra usa `d.lucro`.
- **Estados:**
  - *normal:* 3 segmentos + legenda.
  - *custo > meta:* barra ainda desenha; abaixo, faixa `alerta` "Seu custo é maior que sua
    meta — reveja". Nunca trava.
  - *reserva = 0:* segmento savailable some; legenda mostra "—".
  - *reduce motion:* sem fill anim.
- **Motion:** preenchimento `Motion.fill` (450ms, emphasized) quando o valor muda ou a barra
  aparece num Resultado. Implementar com `TweenAnimationBuilder<double>` nos flexes.
- **A11y:** barra `ExcludeSemantics` (já é); legenda é a leitura. Agrupar num `Semantics`
  container: "Lucro R$ 5.000, 50 por cento. Reserva R$ 1.600, 16 por cento. Custos R$ 850, 8 por cento."

---

### 1.3 `MoneyField` — campo de valor monetário grande (DS §6.5)

- **Base:** `TextField` com `decoration: InputDecoration`.
- **Anatomia:** rótulo curto acima (`textTheme.titleMedium`) · campo com `prefixText: 'R$ '`
  (ou `suffixText: 'h/mês'` para horas) · valor digitado em `AppType.valueDisplay` (40, Sora,
  tnum) via `style:` · linha de ajuda ⓘ abaixo (`bodyMedium onSurfaceVariant`) quando houver.
- **Tokens:** `borderRadius: Radii.md` (16) no `OutlineInputBorder` · foco: borda `primary` 2dp ·
  erro: borda `error` + `errorText` humano (microcopy do DS §1.4) + ícone `error`.
- **Comportamento:** `keyboardType: TextInputType.number`,
  `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` (como já feito), seleção total ao
  focar, formatação de milhar ao vivo (recomendado: formatter que reescreve com `moneyBRL`).
- **Estados:** vazio (placeholder `onSurfaceVariant`, CTA dependente inativo) · preenchido ·
  erro · foco.
- **Keypad próprio (opcional, DS §6.5):** `NumericKeypad` — teclas ≥ 64dp, `Radii.md`,
  `surfaceContainerHigh`, dígitos em `AppType.valueKeypadKey` (28). Só se um teclado dedicado
  fizer sentido; MVP usa o nativo.

---

### 1.4 `PillButton` — botão primário / Recalcular / Começar (DS §6.4)

- **Base:** `FilledButton` com `style: FilledButton.styleFrom(...)`.
- **Tokens:** forma pill `RoundedRectangleBorder(borderRadius: Radii.full)` (999) · altura fixa
  **56dp** (`minimumSize: Size(?, 56)`) · label `textTheme.labelLarge` (16/600) · fill
  `colorScheme.primary` · texto/ícone `onPrimary` · elevação nível 2.
- **Estados:** normal · press (state layer 12% + `scale 0.98` via `AnimatedScale`) · disabled
  (`onSurface @ 12%` fill, `onSurface @ 38%` texto — ex.: "Continuar" com renda vazia).
- **Uso:** botão primário do fluxo guiado (largura total), "Começar" (estado vazio, largura
  generosa), "Recalcular" (Painel), CTA da tela Pro.

---

### 1.5 `TonalButton` — ação secundária pill (DS §6.4 variante)

- **Base:** `FilledButton.tonal`. Forma pill `Radii.full`, altura 48–56dp, fill
  `secondaryContainer`, texto `onSecondaryContainer`. Ex.: "Usar R$ 4.260" no aviso do
  simulador, "Agora não" na provisão.

---

### 1.6 `ToolActionCard` — card dos 2 tools recorrentes ⭐ (DS §6.3)

Os dois motores de retenção. Na virada, têm peso ≥ ao card-herói. **Dois lado a lado.**

- **Base:** `Card`/`InkWell` — `Row` de dois `Expanded` com `SizedBox(width: Space.x3)` (12) entre.
- **Cada card:**
  - fundo `colorScheme.secondaryContainer` (azul-calmo de confiança) · texto/ícone
    `onSecondaryContainer` · `borderRadius: Radii.lg` (20) · altura **≥ 72dp** (usar 96–112dp
    para dar peso de protagonista) · elevação nível 1 · `padding: Space.x4` (16).
  - conteúdo (Column, start): ícone 28 (`payments` / `request_quote`) · `SizedBox(Space.x2)` ·
    título em 2 linhas `textTheme.titleMedium` ("Recebi um\npagamento" / "Vou orçar\num projeto").
- **Estados:** normal · press (state layer 12%) · foco (outline `primary`).
- **A11y:** `Semantics(button: true, label: "Recebi um pagamento")`.

---

### 1.7 `StepperHeader` — progresso do fluxo guiado (DS §6.6)

- **Base:** `Row` — `IconButton(arrow_back, 48dp)` + `Text("Passo 2 de 5" labelMedium)` +
  fileira de 5 pontos.
- **Pontos:** `Container` 8dp circular; preenchidos = `primary`, vazios = `outlineVariant`;
  gap 6dp. Anima 1 ponto por avanço (`Motion.base` 200ms).
- **Substitui** a `LinearProgressIndicator` crua de hoje no `calc_screen`.
- **A11y:** `Semantics(label: "Passo 2 de 5")` no grupo; barra decorativa.

---

### 1.8 `QuestionScaffold` — card de pergunta (uma por tela) (DS §6.7)

Estrutura do fluxo guiado. Fundo `surface` (elev.0, foco total — sem card com sombra).

- **Base:** `Column` dentro de `SafeArea` → `StepperHeader` no topo · `Expanded(SingleChildScrollView)`
  com o corpo · botão primário fixo no rodapé (`Padding Space.x4`).
- **Corpo (Column start):** pergunta-título `textTheme.headlineSmall` (máx 2 linhas) ·
  `SizedBox(Space.x4)` · 1 campo OU 1 grupo de opções · helper ⓘ (`bodyMedium onSurfaceVariant`)
  OU **helper de erro comum** em `HintTeachCard` (§1.8a) · ação secundária opcional
  ("estimar pra mim") · (rodapé) `PillButton`.
- **Regra:** um campo + um botão por foco. Default sempre presente.

**§1.8a `HintTeachCard`** (o ⚠ que ensina o erro comum, ex.: horas): `Container` fundo
`tertiaryContainer`, texto `onTertiaryContainer`, ícone `info`/`schedule` 20, `Radii.md`,
`padding Space.x3`. Âmbar-calmo "puxa o olho" sem alarmar (DS §6.7). Usado no Passo 2.

---

### 1.9 `EstimativaSeal` (§6.11) e `StaleBanner` (§2.4) — **refatorar/criar**

`EstimativaSeal` já existe e está correto (fundo `sealBg`, `sealFg`, ícone ⓘ 16, `Radii.sm`).
Manter. Onipresente em toda tela com número de imposto. **Jamais** vermelho/âmbar.

**`StaleBanner` (novo):** faixa "Valores base de 2025 — confirme as alíquotas atuais."
- fundo `d.staleBg` (azul calmo = info) · texto `d.staleFg` · ícone `info` 16 · `Radii.md` ·
  `padding: EdgeInsets.symmetric(h: Space.x3, v: Space.x2)`. `labelMedium`. Discreto, não alarme.
- Aparece: abaixo do herói no Painel/Resultado e no rodapé da Reserva/Simulador quando o ano
  das tabelas < ano corrente.

---

### 1.10 `CostChip` + `CostRow` — chips de custo e item adicionado (DS §6.8)

- **`CostChip` (lembrança):** `ActionChip` — fundo `tertiaryContainer`, label `onTertiaryContainer`,
  ícone de forma 18 (DS §5.5: Contador `calculate`, Coworking `chair`, Cursos `school`,
  Energia `bolt`, Internet `wifi`, Equipamento `devices`, Pró-labore `account_balance`,
  Saúde `health_and_safety`, Software `apps`, Marketing `campaign`, Transporte `directions_car`),
  `shape: StadiumBorder` (`Radii.full`), alvo 48dp. Toque adiciona o custo. **11 chips**
  (DS §12); os 3 primeiros em destaque, resto atrás de "+ mais".
- **`CostRow` (já adicionado):** `ListTile` — leading ✓ (`check_circle` primary), título nome,
  trailing = valor editável (`moneyBRL`) + `IconButton(close)` remover.

---

### 1.11 `EmptyStateHero` — estado vazio primeiro uso (DS §6.16)

- **Base:** `Column` centrada, `padding Space.x6` (24).
- título-fisga `textTheme.headlineSmall` "Você provavelmente cobra menos do que deveria." ·
  apoio `bodyLarge onSurfaceVariant` "Descubra seu valor-hora justo em 5 perguntas." ·
  `SizedBox(Space.x6)` · `PillButton` "Começar" (largo) · `SizedBox(Space.x3)` · rodapé de
  confiança `Row(lock 16 + "Leva 2 minutos · 100% offline" labelMedium)`.

---

### 1.12 `AdSlot` — banner AdMob (DS §6.18 / §8)

- **Base:** `Container` fundo `d.adSurface` (`surfaceContainerLow`), `Radii.lg`, separado do
  conteúdo por `Space.x4` (16), com rótulo `Publicidade` `labelSmall d.adLabel` no topo.
- **Regra inviolável:** **só** no rodapé do Painel quando há espaço. Nunca sobre número, nunca
  no fluxo, nunca na Reserva/Simulador no momento da resposta. Quando `entitlement.adFree`,
  o widget retorna `SizedBox.shrink()`.
- Slot de altura fixa (banner 320×50 / adaptive) reservado — não empurra conteúdo com jump.

---

### 1.13 Auxiliares menores

- **`ResultBlock`** (Resultado, §6.10): `Column` — rótulo `labelLarge` + valor grande. Já
  existe inline em `resultado_screen._bloco`; extrair. Passa `TextStyle` (hero/xl) + cor
  (primary / d.reserva / d.lucro).
- **`RegimeRadioTile`** (§6.9): já existe inline em `calc_screen._regimeOption`; extrair. Ao
  selecionar → container `secondaryContainer` + borda `primary` `Radii.md`, título humano +
  subtítulo 1 linha.
- **`ComparativoAlerta`** (§6.12): já existe inline no simulador. Extrair: faixa
  `d.alertaContainer` + `trending_down` `d.onAlertaContainer` + texto + `TonalButton` "Usar R$…".
- **`EstimarHorasSheet`** (§6.14): já existe inline no `calc_screen`. Elevar topo do sheet a
  `Radii.xl2` (28) e usar `showDragHandle`. Devolve "~110 h/mês".
- **`ProfileTile`** (§6.15), **`ProBenefitRow`** (§6.19), **`AppSnackBar`** (§6.17,
  `inverseSurface`/`inverseOnSurface`/`inversePrimary` + Desfazer): criar conforme DS.

---

## 2. Composição por tela (wireframe + hierarquia + tokens)

Padding de tela = `Space.x4` (16). Gap entre seções = `Space.x6` (24). Gap entre cards = `Space.x3` (12).

### 2.1 Painel / Home ⭐ — **honrar a virada** (Blueprint §0.1 / §5.1)

**A mudança-chave:** hoje o Painel mostra herói → 2 botões empilhados → reserva em texto
pequeno. A virada exige que **a Divisão + "Recebi um pagamento" tenham peso ≥ ao valor-hora**.
Reorganizar assim (de cima pra baixo num `ListView`, padding 16):

```
┌───────────────────────────────────────┐
│  Quanto Cobro?                  [⚙]    │  AppBar: título titleLarge, settings 48dp
│                                        │
│  ┌── HeroValueCard (§1.1) ──────────┐  │  surfaceContainerHigh · Radii.xl · elev.2
│  │  SEU VALOR-HORA                   │  │  labelLarge onSurfaceVariant
│  │  R$ 92 /hora                      │  │  ← HERÓI (value.hero 72, primary)
│  │  pra ganhar R$ 5.000/mês          │  │  bodyLarge onSurfaceVariant
│  │  ⟳ ver como cheguei aqui          │  │  TextButton primary
│  └───────────────────────────────────┘  │
│         ↕ Space.x6 (24)                 │
│  ┌── ToolActionCard ─┐┌──────────────┐  │  ← DOIS CARDS lado a lado (§1.6)
│  │ 💰 Recebi um       ││ 📄 Vou orçar  │  │  secondaryContainer · Radii.lg
│  │    pagamento       ││   um projeto  │  │  altura ~104dp · titleMedium
│  └────────────────────┘└──────────────┘  │  PESO ≥ herói (a virada)
│         ↕ Space.x6                      │
│  DE CADA PAGAMENTO                      │  labelLarge onSurfaceVariant
│  ┌── DivisaoBar overview (§1.2) ─────┐  │  ← A ASSINATURA, protagonista
│  │ ▓▓▓▓▓░░░▒▒  (barra 20dp)          │  │  Lucro→Reserva→Custos
│  │ 💚 Lucro (é seu)    R$ 5.000 · 50% │  │  legenda com ícones + R$ + %
│  │ 🔒 Reserva (imposto) R$ 1.600 · 16%│  │  reserva em d.reserva
│  │ 🔧 Custos            R$ 850 ·  8%  │  │  Custos com hachura
│  └───────────────────────────────────┘  │
│  Reserve ~16% de cada pagamento (MEI).  │  bodyMedium (d.reserva)
│         ↕ Space.x6                      │
│  ╔═══ Recalcular (PillButton) ═══╗      │  primary pill 56dp (§1.4)
│  EstimativaSeal (§1.9)                  │  sealBg/sealFg, ⓘ
│  ──────────────────────────────────    │
│  AdSlot (§1.12) — só se cabe, adFree=off│  adSurface, "Publicidade"
└───────────────────────────────────────┘
```

- **Herói:** `HeroValueCard`. **Co-heróis (peso da virada):** os `ToolActionCard` e a
  `DivisaoBar`. A reserva **não** é mais texto solto — vive na Divisão + numa linha de reforço.
- **Estados:** `ProfileEmpty` → `EmptyStateHero` (§1.11, não mostra herói/tools/divisão) ·
  `ProfileError` → view de erro atual (manter) · `ProfileReady` → acima ·
  regime desatualizado → `StaleBanner` sob o herói.
- **Ordem intencional:** herói primeiro (a dor), mas os tools **antes** da Divisão porque são
  o gesto recorrente de 1 toque; a Divisão logo abaixo ancora "pra onde vai cada real".

### 2.2 Onboarding (2–3 telas) — Blueprint §0.1/§8

- Fundo `surface`, elev.0. Cada tela: ilustração/ícone grande (40) · título `headlineMedium` ·
  apoio `bodyLarge onSurfaceVariant` · indicador de página (3 pontos, mesmo estilo do
  `StepperHeader`) · `PillButton` "Continuar" / "Começar" no rodapé.
- Telas: (1) a dor "Pare de trabalhar de graça" · (2) "A Divisão" — mostra a barra em exemplo,
  ensina a leitura uma vez · (3) "100% offline, sem cadastro" com `lock`. Reforça privacidade.
- Skip discreto (`TextButton` topo-direita). Não pede nada sensível.

### 2.3 Calculadora guiada (5 passos) — Blueprint §5.2

Todo passo usa `QuestionScaffold` (§1.8) + `StepperHeader` (§1.7). Fundo `surface` (elev.0,
foco total). Botão primário `PillButton` fixo no rodapé ("Continuar" / "Ver resultado").

| Passo | Herói da tela | Componentes | Default |
|---|---|---|---|
| P1 Renda | `MoneyField` "R$ 5.000" (`value.display`) | pergunta headlineSmall + helper ⓘ "é o que sobra pra você" | 5000 |
| P2 Horas | `MoneyField` suffix "h/mês" | **`HintTeachCard` âmbar** "não são 160h…" + `TextButton.icon(auto_awesome)` "estimar pra mim" → `EstimarHorasSheet` | ~110 |
| P3 Custos | lista `CostRow` + total titleMedium | `Wrap` de `CostChip` "Não esqueça:" (3 destaque + "+ mais") | vazio ok |
| P4 Regime | grupo `RegimeRadioTile` (4) | selecionado = secondaryContainer + borda primary | "Não sei" 27% |
| P5 Férias/13º | `SwitchListTile` | apoio "autônomo não ganha de graça" | off |

- **Progressive disclosure:** cada tela = uma pergunta, um campo/grupo, um botão. Validação com
  microcopy humana (já implementada; manter as strings do DS §1.4).
- **Motion:** troca de passo desliza lateral `Motion.base`; ponto do stepper anima.

### 2.4 Resultado — Blueprint §5.3 / DS §6.10

```
┌───────────────────────────────────────┐
│  ← Seu resultado              [PDF*]   │  *Pro (TextButton, gatilho §8)
│  ┌── ResultBlock 1 ─────────────────┐  │
│  │ COBRE POR HORA                    │  │  labelLarge
│  │ R$ 92 /hora                       │  │  ← HERÓI value.hero primary
│  └───────────────────────────────────┘  │
│  ≈ R$ 736/dia · R$ 10,1k/mês faturados  │  bodyMedium
│         ↕ Space.x6                      │
│  DE CADA PAGAMENTO, RESERVE   16%       │  value.xl · d.reserva
│  LUCRO REAL ESTIMADO   R$ 5.000/mês     │  value.xl · d.lucro
│         ↕ Space.x6                      │
│  ┌── DivisaoBar emphasis:lucro ──────┐  │  ← preenche animado (Motion.fill)
│  └───────────────────────────────────┘  │  count-up no herói (o "aha")
│  [se custo>meta] faixa alerta reveja    │  d.alerta, nunca trava
│         ↕ Space.x6                      │
│  ╔══ Salvar este perfil (PillButton) ══╗│  primary 56dp
│  ▾ Ver detalhamento (TextButton)        │
│  EstimativaSeal                         │  onipresente, calmo
└───────────────────────────────────────┘
```

- **Hierarquia das 3 respostas** (valor-hora herói → reserva → lucro), preservada do blueprint.
- **Momento "aha":** ao abrir, herói faz count-up (`Motion.countUp`) **e** a Divisão preenche
  (`Motion.fill`). Reduce-motion → estático.

### 2.5 Detalhamento "como cheguei" — Blueprint §5.4 / DS §6.13

- `AppBar` "Como cheguei nesse número". Corpo = tabela linha a linha num `Card`
  (`surfaceContainerLow`, `Radii.lg`), valores `tnum` alinhados à direita, separadores
  `outlineVariant` (`Divider`).
- Linhas: `Renda + Custos + Provisão + Imposto = Faturamento ÷ Horas = Valor-hora`. As linhas
  de total/resultado em `titleMedium`/`value.md`, com destaque.
- **Cada item editável inline:** toque → `MoneyField` inline → recalcula com count-up no
  valor-hora final (causa→efeito, `Motion.countUp`). `EstimativaSeal` no rodapé.

### 2.6 Reserva (tool) — Blueprint §5.5 (caminho de ouro)

```
┌───────────────────────────────────────┐
│  ← Recebi um pagamento                 │
│  Quanto você recebeu?                   │  titleMedium
│  [ MoneyField  R$ 2.000 ] autofocus     │  value.display, keypad numérico
│  Regime: MEI ▾  (puxa do perfil)        │  DropdownButton, editável pontual
│         ↕ Space.x6                      │
│  RESERVE PARA IMPOSTO                    │  labelLarge
│  R$ 320                                 │  ← HERÓI value.hero · d.reserva
│  Sobra pra usar: R$ 1.680               │  bodyLarge
│  16% do que entrou é do leão.           │  bodyMedium d.reserva
│  ┌── DivisaoBar emphasis:reserva ──┐    │  colapsada: Reserva | Sobra
│  │ 🔒 Reserva R$ 320 · 🟢 Sobra R$… │    │  Reserva realçada
│  EstimativaSeal(short: true)            │
└───────────────────────────────────────┘
```

- **Ao vivo:** recalcula enquanto digita (`Motion.quick` no número), sem botão "calcular"
  (já implementado). **Herói = a Reserva** (`value.hero`, `d.reserva`). Usar `DivisaoBar`
  variante `reserva` (§1.2) em vez da barra inline crua de hoje.
- **Sem anúncio aqui** (regra §8).

### 2.7 Simulador (tool) — Blueprint §5.6

```
┌───────────────────────────────────────┐
│  ← Vou orçar um projeto                │
│  [MoneyField Valor do projeto R$ 3.000]│
│  [MoneyField Horas estimadas  30 h]    │
│  [MoneyField Custos (opcional) R$ 200] │
│         ↕ Space.x6                      │
│  LUCRO REAL   R$ 1.960                  │  ← HERÓI value.xl · d.lucro
│  Valor-hora efetivo: R$ 65/h            │  bodyLarge
│  ┌── ComparativoAlerta (§1.13) ──────┐ │  d.alertaContainer (âmbar calmo)
│  │ ↘ Abaixo do seu alvo (R$ 92/h).    │ │  trending_down + texto
│  │   Cobre ~R$ 4.260 pra manter lucro.│ │
│  │   [ Usar R$ 4.260 ] (TonalButton)  │ │  secondaryContainer pill
│  └────────────────────────────────────┘ │
│  DivisaoBar emphasis:lucro (opcional)   │  mostra Lucro | Reserva | Custos do projeto
│  EstimativaSeal(short: true)            │
└───────────────────────────────────────┘
```

- **Aviso comparativo** é o diferencial (defende o usuário). Âmbar = atenção, **nunca**
  vermelho. Já implementado inline; extrair para `ComparativoAlerta`. Adicionar a `DivisaoBar`
  do projeto (Lucro/Reserva/Custos) para coerência com a assinatura.

### 2.8 Perfis (Pro) — Blueprint §5.7 / DS §6.15

- Lista de `ProfileTile` (rádio + nome + valor-hora `tnum` à direita); selecionado destaca
  (`secondaryContainer`). Topo: `TextButton.icon(add)` "+ novo". Rodapé: nota "Vários perfis é
  recurso Pro" (`bodyMedium`) → toque abre Tela Pro (gatilho de valor).
- Tiles em `surfaceContainer`, `Radii.lg`.

### 2.9 Configurações — Blueprint §5.9 / DS §9

- `ListView` de seções (`ListTile`/`SwitchListTile`): moeda · modo BR/internacional · ano das
  tabelas · **apagar meus dados** (ação destrutiva → diálogo confirmação dupla, `error`) ·
  restaurar compras · Sobre.
- **Sobre:** único lugar com o selo **"by 4YU"** (`d.brand4yu` roxo `#6C4BD6`). Nunca na UI
  funcional.

### 2.10 Tela Pro (compra única) — Blueprint §11 / DS §6.19

- `AppBar` "Quanto Cobro? Pro". Lista de `ProBenefitRow` (ícone + benefício): vários perfis ·
  exportar PDF (âncora forte) · modo avançado por regime · remover anúncios. Preço único em
  `value.md`. `PillButton` "Desbloquear" (primary) · `TextButton` "Restaurar compras".
- Aparece **no gatilho de valor** (tocar PDF, criar 2º perfil, abrir avançado), não como
  pop-up. Fundo `surface`; benefícios em `surfaceContainerLow` cards.

---

## 3. Referências — 5 apps bonitos e 7 princípios pra roubar (dentro do DS)

Apps estudados (fintech/utilitário com número-herói e boa profundidade): **Nubank** (BR),
**Copilot Money** (iOS), **Monarch Money**, **YNAB**, **Revolut**. Destilei 7 princípios
concretos — cada um mapeado a uma decisão deste spec, **sem** fugir do DS.

1. **Um número manda na tela (Copilot/Nubank).** A tela tem um único protagonista tipográfico
   gigante; todo o resto é satélite menor. → **Aqui:** `value.hero` 72 no card-herói e no
   herói de cada tool; rótulos e `/hora` deliberadamente menores (`titleMedium`). Nunca dois
   números do mesmo tamanho competindo.

2. **Cartão como unidade de profundidade, não borda (Monarch).** Blocos vivem em superfícies
   elevadas por **tom**, não por linha grossa. → **Aqui:** `surfaceContainerHigh` no herói,
   `surfaceContainerLow` nos cards de tool/detalhe; no escuro a hierarquia é tonal (DS §5.3),
   sombra só no claro. `Radii.xl` no herói dá o "cartão premium".

3. **Cor = significado, usada com parcimônia (YNAB/Nubank).** Verde/azul/âmbar têm papel fixo;
   o fundo é neutro-calmo pra a cor "acender". → **Aqui:** a regra cromática do DS (verde=seu,
   azul=guardado, âmbar=atenção, carmim=erro) já é isso. A tela é 80% neutra; a Divisão e o
   herói carregam a cor. Proíbe pintar botão/fundo de verde só "porque é a marca".

4. **Barra/dona-visual que ensina o dinheiro (Monarch "cash flow" / Copilot categorias).** Uma
   viz recorrente, sempre igual, que o usuário aprende a ler uma vez. → **Aqui:** é exatamente
   "A Divisão" — mesma ordem, cores e legenda no Painel, Resultado, Reserva e Simulador. Roubar
   deles o **capricho** da barra: cantos suaves (`Radii.sm`), gap entre segmentos, legenda
   alinhada com valor tabular à direita.

5. **Espaço em branco generoso = confiança (todos os premium).** Respiro alto acima do herói e
   entre seções faz o app parecer caro e calmo — crítico num app que fala de imposto. → **Aqui:**
   `Space.x6` (24) acima do herói e entre seções; `Space.x5` (20) de padding interno de card.
   Nunca amontoar; deixar o número respirar.

6. **Microinteração no momento do valor (Revolut/Copilot).** O número "chega" com count-up e a
   viz preenche — transforma dado em evento. → **Aqui:** `Motion.countUp` no herói + `Motion.fill`
   na Divisão ao nascer um Resultado; recálculo ao vivo nos tools (`Motion.quick`). Sempre com
   fallback reduce-motion. É o "aha" do DS §5.4.

7. **Pills e alvos generosos, hierarquia de botão clara (Nubank/Revolut).** Um único primário
   pill por tela, secundários tonais, terciários em texto. → **Aqui:** `PillButton` (primary,
   56dp) manda; `TonalButton` (secondaryContainer) para ações de apoio; `TextButton` para
   "ver detalhamento"/"recalcular". Nunca dois primários competindo na mesma dobra.

**Bônus (guarda-corpo anti-clone):** o que **não** roubar — o azul-fintech genérico e o visual
"planilha/banco frio". O DS já escolheu Verde-Justo e tom de "sócio que entende de número"
justamente pra fugir disso (DS §1.1, §2.1). Toda escolha deste spec serve a "ferramenta de
trabalho confiável e humana", não a "mais um app de banco".

---

## 4. Ordem de implementação sugerida (pro build)

1. **Fundação (§1.0):** wiring de `TextTheme` Inter + escala M3, `AppType.valueDisplay/keypadKey`,
   helpers de elevação. Destrava a "alma" em todas as telas de uma vez.
2. **`DivisaoBar` refactor (§1.2):** ícones na legenda, hachura em Custos, variantes, animação.
   É a assinatura — maior retorno visual.
3. **`HeroValueCard` + `ToolActionCard` (§1.1, §1.6):** reconstrói o Painel na virada (§2.1).
4. **`PillButton`/`TonalButton` (§1.4/§1.5) + `MoneyField` (§1.3):** aplicar em todas as telas.
5. **`StepperHeader` + `QuestionScaffold` + `HintTeachCard` (§1.7/§1.8):** eleva o fluxo guiado.
6. **Extrações menores (§1.13):** `ResultBlock`, `RegimeRadioTile`, `ComparativoAlerta`,
   `StaleBanner`, `CostChip`, `EmptyStateHero`, `AdSlot`.
7. **Motion (§2.4/§2.5):** count-up + fill no Resultado e no editar do Detalhamento.
8. **Telas restantes:** Onboarding, Perfis, Config, Pro.

**Checklist de aceite (do DS §14, aplicado):** número é o maior elemento de cada tela · Divisão
com legenda fixa Lucro→Reserva→Custos + R$ + % nas 4 telas · Reserva azul (nunca vermelho/âmbar) ·
selo calmo onipresente onde há imposto · zero hex solto · alvos ≥ 48dp · cor nunca é o único
sinal · reduce-motion previsto · anúncio nunca sobre número · roxo 4YU só no "Sobre".

---

*UI-SPEC — Quanto Cobro? · deriva de Design-System.md (A Divisão) e UX-Blueprint.md (a virada).
Tema padrão Escuro, claro com paridade. Pronto pra implementar em Flutter Material 3.*
