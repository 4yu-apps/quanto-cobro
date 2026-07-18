# MOTION-SPEC — Quanto Cobro?

> **Motion design de nível prêmio, pronto pra implementar.**
> Personalidade: **calmo e confiante** — o "Sócio que entende de número". O motion existe pra
> mostrar **causa→efeito com dinheiro** (o número chega, a barra reparte), nunca pra enfeitar.
> Nada pisca, nada salta, nada compete com o número-herói.
>
> Base: [Design-System §5.4](../Design-System.md) (tokens `Motion` em
> `lib/core/theme/tokens.dart`: quick 120 · base 200 · emphasized 350 · slow 500 · countUp 600 ·
> fill 450) e [UX-SPEC](UX-SPEC.md) §0–§1. As curvas e o gate de reduce-motion **já existem** em
> `lib/core/theme/motion.dart` (`MotionCurves`, `reduceMotionOf`, `Haptics`, `PressableScale`,
> `StaggerIn`) — este spec os coloca pra trabalhar.
>
> **Restrições duras (não negociar):** Flutter puro, zero pacotes novos. Sem áudio — feedback
> físico só via `HapticFeedback.*`. **Toda** animação passa por `reduceMotionOf(context)`
> (`MediaQuery.disableAnimations`): em reduce-motion, estado final estático, informação intacta.

## Regras da casa (valem para tudo abaixo)

1. **Uma hierarquia de movimento por tela.** O número-herói é o protagonista; tudo o mais entra
   antes ou junto, nunca depois dele assentar. O último pixel a parar de se mover é o dinheiro.
2. **Nunca animar o que o usuário está digitando.** Recalcular ao vivo continua instantâneo;
   só a *apresentação* do número corre atrás do dedo (`Motion.quick`).
3. **Movimento pequeno.** Deslizes de 8–24dp / 8–12% da largura. Nada atravessa a tela.
4. **Durações = tokens, sempre.** Nenhum `Duration(milliseconds: ...)` literal em tela — só
   `Motion.*` de `tokens.dart`. Curvas só de `MotionCurves`.
5. **Haptic é pontuação, não trilha sonora.** Um evento discreto do usuário = no máximo 1 haptic.
   Nunca em frame de animação, digitação ou chegada de tela. `SystemSound.click`: **não usar** —
   o teclado do SO já clica; som extra em app financeiro é ruído (decisão fechada).

---

## 1. Assinaturas de motion

Os quatro momentos que definem o app. Se só der pra implementar quatro coisas, são estas.

### 1.1 O "aha" do Resultado — count-up + Divisão repartindo, coreografados

**Onde:** `lib/features/resultado/resultado_screen.dart` (o momento mais importante do app —
Blueprint §5.3 "resultado nasce").

**Coreografia (timeline única, t=0 = primeiro frame da tela já em posição):**

| t (ms) | O que anima | Duração | Curva | Técnica |
|---|---|---|---|---|
| 0 | `Haptics.resultBorn()` (1× lightImpact) | — | — | no `initState`/primeiro build |
| 0 | **Número-herói** conta 0 → valorHora | `Motion.countUp` (600) | `MotionCurves.easeOut` | `MoneyCountUp` (já aplicado ✅) |
| 0 | **DivisaoBar** preenche 0 → frações finais | `Motion.fill` (450) | `MotionCurves.emphasizedDecel` | `AnimatedDivisaoBar` modo *nasce* (§1.3) |
| 80 | Bloco "DE CADA PAGAMENTO, RESERVE" — fade + sobe 12dp | `Motion.emphasized` (350) | emphasizedDecel | `StaggerIn(index: 1)` |
| 160 | Bloco "LUCRO REAL ESTIMADO" — fade + sobe 12dp | `Motion.emphasized` (350) | emphasizedDecel | `StaggerIn(index: 2)` |
| 450 | Barra termina de repartir | — | — | — |
| 600 | **Número assenta — nada mais se move** | — | — | — |

Por que nessa ordem: barra (450) termina **antes** do número (600) de propósito — os olhos veem o
dinheiro se dividir e então o valor "fecha". O número é sempre o último a parar (regra 1).
Botões, aviso de custo, selo e banner stale: **estáticos** (entram com a rota) — abaixo da dobra,
movimento lá é distração.

O aviso "custos maiores que a renda" e o `StaleBanner`, quando presentes, entram com
`StaggerIn(index: 3)` (fade + 12dp) — **nunca** piscam nem mudam de cor animando: atenção calma
(DS §5.4).

**Reduce-motion:** `MoneyCountUp` e `StaggerIn` já colapsam para estado final; a barra pinta as
frações finais direto (§1.3). Haptic **mantém** (não é movimento; é confirmação física — quem
desliga animação não pediu pra desligar tato).

### 1.2 A chegada do Painel — stagger de cards (o app "se apresenta")

**Onde:** `lib/features/painel/painel_screen.dart` → `_PainelBody`.

**Coreografia** — cascata de 3 blocos, passo de 60ms (o `StaggerIn` existente já faz delay =
`60 * index`, duração `Motion.emphasized`, fade + subida de 12dp, emphasizedDecel):

| index (delay) | Bloco |
|---|---|
| 0 (0ms) | `HeroValueCard` (o valor-hora conta junto via `MoneyCountUp` interno ✅) |
| 1 (60ms) | Row dos dois `ToolActionCard` ("Recebi um pagamento" / "Vou orçar um projeto") |
| 2 (120ms) | Seção "DE CADA MÊS" + `DivisaoBar` (fill *nasce*, `Motion.fill`) + linha da reserva |

Botão "Recalcular" e `EstimativaSeal`: estáticos. Três blocos é o teto — stagger de 5+ itens vira
desfile, não chegada.

```dart
// _PainelBody.build → ListView(children:)
StaggerIn(index: 0, child: HeroValueCard(...)),
// ...
StaggerIn(index: 1, child: Row(children: [ToolActionCard(...), ...])),
// ...
StaggerIn(index: 2, child: Column(children: [Text('DE CADA MÊS'...), DivisaoBar(...), ...])),
```

**Quando animar:** na **montagem** do `_PainelBody` — que acontece ao abrir o app e ao voltar do
"Salvar perfil" (nasceu um resultado novo: é exatamente quando o count-up + fill pagam a promessa
causa→efeito). Ao *voltar* de um tool via pop, o Painel não remonta (rota preservada na pilha) —
logo não re-anima. Comportamento correto de graça; não adicionar flags de sessão.

**Sem haptic** na chegada do Painel — chegada de tela nunca vibra (regra 5). O haptic do fluxo
"salvei perfil" já aconteceu no botão Salvar (§4).

**Reduce-motion:** `StaggerIn` retorna o child direto (já implementado ✅); `MoneyCountUp` estático.

### 1.3 O preenchimento da DivisaoBar — a assinatura do produto ganha vida

**Onde:** `lib/core/ui/divisao_bar.dart`. Hoje: `Expanded(flex:)` — reparte instantâneo, zero
animação. É a mudança de maior retorno visual do app inteiro (a barra aparece em Painel,
Resultado, Simulador e Detalhe — anima uma vez, anima em todo lugar).

**Dois modos, um widget:**

- **Modo *nasce*** (default; Painel/Resultado/Detalhe ao montar): um progresso global `p: 0→1`
  escala a largura dos três segmentos juntos — a barra **cresce da esquerda já repartida** (os
  três crescem proporcionais, com o trilho `d.track` visível atrás). Duração `Motion.fill` (450),
  curva `emphasizedDecel`.
- **Modo *ao vivo*** (Simulador com a tela já aberta; frações mudam ao digitar): as larguras
  animam **entre a fração anterior e a nova** com `Motion.quick` (120) + `standard` — a barra
  "respira" atrás da digitação, nunca re-cresce do zero.

**Técnica** — `Expanded` não anima; trocar por larguras explícitas em `LayoutBuilder`:

```dart
// dentro do build, substituindo o Row de Expanded:
final bool reduce = reduceMotionOf(context);
Widget bar = LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
  const double gap = 2;
  final double w = c.maxWidth - 2 * gap;
  final double fL = lucro / t, fR = reserva / t, fC = custo / t;
  return TweenAnimationBuilder<double>(
    // modo NASCE: progresso 0→1 (uma vez, ao montar)
    tween: Tween<double>(begin: reduce ? 1 : 0, end: 1),
    duration: reduce ? Duration.zero : Motion.fill,
    curve: MotionCurves.emphasizedDecel,
    builder: (BuildContext context, double p, Widget? _) => Stack(children: <Widget>[
      Positioned.fill(child: ColoredBox(color: d.track)),          // trilho atrás
      Row(children: <Widget>[
        // modo AO VIVO de graça: AnimatedContainer anima quando fL/fR/fC mudam
        AnimatedContainer(duration: reduce ? Duration.zero : Motion.quick,
            curve: MotionCurves.standard, width: w * fL * p, color: d.lucro),
        const SizedBox(width: gap),
        AnimatedContainer(duration: reduce ? Duration.zero : Motion.quick,
            curve: MotionCurves.standard, width: w * fR * p, color: d.reserva),
        const SizedBox(width: gap),
        AnimatedContainer(duration: reduce ? Duration.zero : Motion.quick,
            curve: MotionCurves.standard, width: w * fC * p,
            child: CustomPaint(painter: _HatchPainter(hatch))),
      ]),
    ]),
  );
});
```

Um só mecanismo cobre os dois modos: o `TweenAnimationBuilder` roda o *nasce* uma vez; depois de
`p == 1`, qualquer mudança de fração é animada pelos `AnimatedContainer` (120ms). **Preservar
intacto:** `ClipRRect(Radii.sm)`, altura 20, gap de 2, hachura nos Custos, `ExcludeSemantics` na
barra + a frase única de `Semantics` (a animação é 100% visual; o leitor de tela lê o estado
final sempre).

A legenda (3 linhas) **não** anima individualmente — entra com o bloco (`StaggerIn` do chamador).
Legenda pingando linha a linha = teatral demais pro tom.

**Reduce-motion:** `begin: 1` + `Duration.zero` pintam o estado final no primeiro frame (código
acima já resolve, sem branch de árvore separada).

### 1.4 O fluxo guiado — passos que deslizam com direção + stepper que vira pill

**Onde:** `lib/features/calc/calc_screen.dart`. Hoje: `AnimatedSwitcher(duration: Motion.base)`
com fade default **sem direção**, e pontos de progresso estáticos (`Container` 8×8).

**a) Slide direcional entre passos** — avançar desliza da direita (+12% da largura), voltar da
esquerda. Guardar `_prevStep` e usar no `transitionBuilder`:

```dart
// state: int _prevStep = 0;  → em _next/_back: _prevStep = _step; antes do setState
// IMPORTANTE: FocusScope.of(context).unfocus() ANTES do setState (teclado não "pula" no slide)
AnimatedSwitcher(
  duration: reduceMotionOf(context) ? Duration.zero : Motion.base, // 200ms
  switchInCurve: MotionCurves.standard,
  switchOutCurve: MotionCurves.standard,
  transitionBuilder: (Widget child, Animation<double> anim) {
    final bool forward = _step >= _prevStep;
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(forward ? 0.12 : -0.12, 0), end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  },
  layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
    alignment: Alignment.topLeft, // perguntas alinham no topo, não no centro
    children: <Widget>[...previous, if (current != null) current],
  ),
  child: SingleChildScrollView(key: ValueKey<int>(_step), ...), // key já existe ✅
)
```

**b) Stepper `●●●○○` premium** — o ponto ativo vira **pill** (8→20dp de largura), os concluídos
ficam 8dp preenchidos de `primary`, os futuros 8dp `outlineVariant`. Só `AnimatedContainer`:

```dart
for (int i = 0; i <= _lastStep; i++)
  AnimatedContainer(
    duration: reduceMotionOf(context) ? Duration.zero : Motion.base,
    curve: MotionCurves.standard,
    margin: const EdgeInsets.only(right: 6),
    width: i == _step ? 20 : 8,          // ativo = pill
    height: 8,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radii.full),
      color: i <= _step ? cs.primary : cs.outlineVariant,
    ),
  ),
```

O pill desliza de ponto em ponto conforme avança/volta — progresso visível sem número, e o
"Passo X de 5" do AppBar continua carregando a informação em texto (a11y).

**Haptic:** `Haptics.select()` no `_next` **quando avança de verdade** (após `_stepValid`), nada
no `_back` (voltar é neutro). No último passo, o "Ver resultado" não vibra aqui — a vibração é do
resultado nascendo (§1.1); duas seguidas seria eco.

**Reduce-motion:** `Duration.zero` nos dois — troca seca de passo, pill muda sem deslizar.

### 1.5 Causa→efeito no dinheiro vivo — o número corre atrás do dedo

**Onde:** `lib/features/reserva/reserva_screen.dart` (herói `res.reserva`),
`lib/features/simulador/simulador_screen.dart` (herói `res.lucro`),
`lib/features/detalhe/detalhe_screen.dart` (valor-hora ao editar, quando a edição inline existir).
Hoje os dois tools usam `Text` estático — o número **salta** de R$ 320 pra R$ 480 sem transição.

**Fazer:** parametrizar o `MoneyCountUp` (hoje trava em `Motion.countUp`):

```dart
// lib/core/ui/money_count_up.dart — adicionar parâmetros com default atual:
const MoneyCountUp(this.value, {super.key, required this.style, this.semanticLabel,
    this.duration = Motion.countUp, this.curve = MotionCurves.easeOut});
```

`TweenAnimationBuilder` já anima **do valor exibido atual** para o novo `end` (o `begin: 0` só
vale no primeiro build) — então basta trocar o `Text` do herói por
`MoneyCountUp(res.reserva, duration: Motion.quick, ...)` e cada tecla reinicia um tween de 120ms:
o número "corre" suave atrás da digitação. **Não** debounçar o cálculo (é O(1), o número seguir o
dedo é a confiança do tool); não usar 600ms aqui (atrasaria o feedback — DS §5.4 pede `quick`).

A **barra colapsada** Reserva × Sobra da Reserva (`Expanded(flex:)` hoje): mesmo tratamento do
modo *ao vivo* da §1.3 (larguras `AnimatedContainer`, `Motion.quick`).

**Primeira aparição do resultado** (campo estava vazio → digitou o 1º dígito): o bloco
`RESERVE PRO LEÃO` entra com fade+12dp via `AnimatedSwitcher`/`StaggerIn(index: 0)` de
`Motion.base` — nasce uma vez, depois só corre. Sem haptic em digitação, nunca (regra 5).

**Reduce-motion:** `MoneyCountUp` já retorna `Text` estático; `AnimatedContainer` com
`Duration.zero` — comportamento idêntico ao atual.

---

## 2. Transições de rota (go_router)

**Onde:** `lib/app/router.dart` (hoje: `GoRoute(builder:)` default — transição Material genérica
pra tudo). Trocar por `pageBuilder` + `CustomTransitionPage` com **dois sabores** — e um helper
único pra não repetir código:

```dart
// lib/app/router.dart (ou lib/app/transitions.dart)

/// Hub→tool: rápida, deslize horizontal sutil — "abri uma gaveta".
CustomTransitionPage<void> toolPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: Motion.base,          // 200ms
      reverseTransitionDuration: Motion.base,
      transitionsBuilder: (BuildContext context, Animation<double> a,
          Animation<double> sec, Widget child) {
        if (reduceMotionOf(context)) return child; // corte seco, sem fade órfão
        return FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: MotionCurves.standard),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: MotionCurves.standard)),
            child: child,
          ),
        );
      },
      child: child,
    );

/// Hub→fluxo/resultado: sobe do rodapé — "entrei num modo focado" / "a resposta chega".
CustomTransitionPage<void> flowPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: Motion.emphasized,    // 350ms
      reverseTransitionDuration: Motion.base,   // sair é mais rápido que entrar (sempre)
      transitionsBuilder: (BuildContext context, Animation<double> a,
          Animation<double> sec, Widget child) {
        if (reduceMotionOf(context)) return child;
        return FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: MotionCurves.standard),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: MotionCurves.emphasizedDecel)),
            child: child,
          ),
        );
      },
      child: child,
    );
```

**Mapa rota→sabor:**

| Rota | Sabor | Racional |
|---|---|---|
| `/reserva`, `/simulador`, `/detalhe`, `/historico`, `/config`, `/perfis`, `/legal` | `toolPage` (200ms, desliza 6% da direita + fade) | Tools/consulta: entrar e sair rápido, lateral = "ao lado do hub" |
| `/calc` | `flowPage` (350ms, sobe 8% + fade) | Entrar no fluxo guiado é mudar de modo — merece peso |
| `/resultado` | `flowPage` | A resposta **sobe** até o usuário; encadeia com a coreografia §1.1 (a tela assenta em 350ms, count-up de 600 já rodando — total percebido ~600ms, um só gesto) |
| `/pro` | `flowPage` | Momento de decisão, mesmo peso de modo |
| `/` (painel), `/onboarding` | default (são raízes; a chegada do Painel já tem o stagger §1.2) | — |

Deslize de **6–8%**, nunca a tela inteira varrendo (regra 3). O pop reverte automaticamente
(`SlideTransition` com a animação invertida) — voltar desliza de volta pro hub, reforçando o
mapa mental hub-and-spoke.

**Reduce-motion:** o `if (reduceMotionOf(context)) return child;` dentro do `transitionsBuilder`
troca por corte seco mantendo a duração da rota (não zerar `transitionDuration` — go_router
mantém a página utilizável e o custo é nulo, só não desenha movimento).

**Sheets** (`showModalBottomSheet` do estimador de horas e futuros): manter o motion default do
Material (já respeita o SO e o `useSafeArea`); barrier fade default. Não customizar — sheet é
território do sistema.

---

## 3. Micro-feedback

### 3.1 Press state — escala 0.98 nos cards custom

Botões Material (`FilledButton`, `TextButton`, chips) já têm ink + state layers do tema — **não**
adicionar escala neles (dois feedbacks = nervoso). Escala é só para superfícies grandes custom:

- **`ToolActionCard`** (`lib/core/ui/tool_action_card.dart`): envolver o `Material` no
  `PressableScale` já pronto em `motion.dart` (`AnimatedScale 0.98`, `Motion.quick`, standard;
  reduce-motion já retorna o child ✅). O InkWell interno continua — ink + escala juntos é o
  padrão premium de card tocável.
- **Opções de regime** (`calc_screen._regimeOption`, InkWell em card): idem, `PressableScale`.
- `HeroValueCard`: **não** — não é tocável como um todo (só o TextButton interno).

### 3.2 Chips de custo ("Não esqueça") ao adicionar

**Onde:** `calc_screen._stepCustos`. Hoje: toque no `ActionChip` → chip some da lista "faltam" e
uma `ListTile` aparece na lista de custos — tudo seco, itens saltam de posição.

- Envolver a coluna de custos + o `Wrap` de chips num **`AnimatedSize`** (`Motion.base`,
  `MotionCurves.standard`, `alignment: Alignment.topCenter`): adicionar/remover acomoda o layout
  suavemente em vez de empurrar tudo num frame.
- O **"Total: R$ X/mês"** vira `MoneyCountUp(_draft.custosTotal, duration: Motion.quick)` — o
  toque no chip mostra o total *subindo*: causa→efeito de novo, a tese do app.
- Haptic: `Haptics.select()` no `onPressed` do chip **e** no remover custo (ambos são seleção
  discreta).
- **Reduce-motion:** `AnimatedSize` com `Duration.zero`; total estático.

### 3.3 Switch / radio (Provisão, Regime)

O `SwitchListTile` e as opções de regime já têm o motion do Material (thumb desliza, state
layer). Não redesenhar. Adicionar apenas `Haptics.select()` no `onChanged`/`onTap`. É o feedback
que o Material não dá e o usuário sente como "app caro".

### 3.4 Snackbar

Motion default do Material (slide-in do rodapé — respeita o SO). Regras:
- `ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(...)` sempre — nunca fila de
  dois snacks (UX-SPEC §1.5).
- **Sem haptic ao aparecer** — o haptic pertence à ação que o disparou (Salvar), não à
  confirmação visual; vibrar duas vezes pelo mesmo gesto é eco.
- Reduce-motion: nada a fazer (Material obedece o SO).

### 3.5 Sheet do estimador de horas

Abertura/fechamento default (§2). Dentro do sheet, os steppers de férias/%/feriados recalculam o
número estimado ao vivo: aplicar o mesmo `MoneyCountUp`-pattern com sufixo "h" e `Motion.quick`
(número corre, não salta). Ao confirmar ("Usar Xh"): `Haptics.select()`, o sheet fecha, e o campo
de horas do passo recebe o valor — o número do campo não anima (é um `TextField`; texto de campo
nunca anima sozinho, o usuário precisa confiar no que está escrito).

### 3.6 Botão "Usar R$ X" do simulador — o app corrige o orçamento *visivelmente*

**Onde:** `simulador_screen.dart`, dentro do aviso âmbar. Hoje: `_valor.text = sugestao` →
rebuild seco; herói salta, aviso some num frame.

**Coreografia do toque:**
1. `Haptics.select()`.
2. `_valor.text` recebe a sugestão (campo atualiza seco — é input, regra do §3.5).
3. O herói **LUCRO REAL** anima do valor antigo ao novo com `MoneyCountUp` de
   `Motion.emphasized` (350ms — mudança deliberada merece mais peso que os 120ms da digitação;
   como o widget anima a partir do valor corrente, basta passar `duration: Motion.emphasized`
   nesse rebuild ou simplesmente aceitar o `quick` do modo ao vivo — decisão de implementação:
   `quick` é aceitável, `emphasized` é o ideal).
4. O **aviso âmbar sai** com `AnimatedSize` + `AnimatedSwitcher` (fade, `Motion.base`) — o bloco
   encolhe suave em vez de sumir num frame. Entrada do aviso: idem, fade + acomodação de altura
   (`Motion.base`), **jamais** piscar ou tremer — é atenção calma, não alarme (DS §5.4).
5. A `DivisaoBar` re-reparte no modo *ao vivo* (§1.3, já automático).

**Reduce-motion:** aviso entra/sai seco; herói troca direto — tudo via os mesmos gates.

---

## 4. Haptics map

API: só `HapticFeedback.lightImpact` / `mediumImpact` / `selectionClick`, sempre via a fachada
`Haptics` de `lib/core/theme/motion.dart` (um lugar pra ajustar/desligar tudo). `SystemSound`:
não usar (regra 5). Haptics **não** são desligados por reduce-motion (são tato, não movimento);
se um dia houver reclamação, a fachada ganha um kill-switch em Configurações.

| Evento | Chamada | Onde (arquivo) |
|---|---|---|
| Resultado nasce (abrir Resultado com perfil válido) | `Haptics.resultBorn()` (light) | `resultado_screen.dart` |
| Salvar este perfil | `Haptics.commit()` (medium) | `resultado_screen.dart` |
| Salvar no histórico (reserva guardada) | `Haptics.commit()` (medium) | `reserva_screen.dart` |
| Confirmar "Apagar dados" (2ª confirmação) | `Haptics.commit()` (medium) | `config_screen.dart` |
| Ativar/comprar Pro (sucesso) | `Haptics.commit()` (medium) | `pro_screen.dart` |
| Avançar passo do fluxo guiado | `Haptics.select()` | `calc_screen.dart` `_next` |
| Adicionar chip de custo / remover custo | `Haptics.select()` | `calc_screen.dart` |
| Selecionar regime (radio) / toggle provisão (switch) | `Haptics.select()` | `calc_screen.dart`, `reserva_screen.dart` (dropdown) |
| "Usar R$ X" (aplicar sugestão) | `Haptics.select()` | `simulador_screen.dart` |
| "Usar Xh" (aplicar estimativa do sheet) | `Haptics.select()` | `calc_screen.dart` (sheet) |
| Desfazer (ação do snackbar) | `Haptics.select()` | onde houver Undo |
| Trocar perfil ativo (Pro, futuro) | `Haptics.select()` | `perfis_screen.dart` |

**Onde haptic seria RUÍDO (proibido):**

| Não vibrar em | Por quê |
|---|---|
| Cada tecla digitada / recálculo ao vivo | O teclado do SO já dá feedback; vibrar por dígito transforma o tool de 5s em brinquedo |
| Frames/fim do count-up ou do fill | Animação não é evento do usuário |
| Chegada de qualquer tela (inclusive Painel) | Navegação vibrando = app inteiro tremendo |
| Aparição de snackbar, banner stale, aviso âmbar | A ação de origem já vibrou (ou é informação passiva) |
| Voltar (`_back`, pop de rota) | Desfazer caminho é neutro, não conquista |
| Scroll, abrir sheet/menu/dropdown | O SO já cuida do que precisa |
| Erro de validação de campo | Punir com vibração é hostil; a copy calma resolve |

Resumo da gramática: **medium = "guardei algo teu"** (commit com consequência) · **light = "teu
número chegou"** (1× por nascimento) · **selection = "te ouvi"** (escolha discreta). Três verbos,
sempre os mesmos — o usuário aprende o vocabulário sem perceber.

---

## 5. Checklist de implementação (ordem = retorno visual por esforço)

Cada item é um PR pequeno e independente. Gate obrigatório em todos: `reduceMotionOf(context)`.

1. **[ ] DivisaoBar animada (modo nasce + ao vivo)** — §1.3
   `lib/core/ui/divisao_bar.dart`. Trocar `Expanded flex` por `LayoutBuilder` + progresso
   `Motion.fill` + larguras `AnimatedContainer(Motion.quick)`. Preservar ClipRRect/gap/hachura/
   Semantics. *Uma edição, quatro telas ganham a assinatura.*

2. **[ ] Transições de rota** — §2
   `lib/app/router.dart`. Helpers `toolPage`/`flowPage` (`CustomTransitionPage`) e mapear as 10
   rotas conforme a tabela. *O app inteiro deixa de "teleportar".*

3. **[ ] Coreografia do Resultado** — §1.1
   `lib/features/resultado/resultado_screen.dart`. `StaggerIn` nos blocos secundários (index 1–3)
   + `Haptics.resultBorn()` 1× no nascimento. (Count-up e fill já vêm dos itens 1 e do
   `MoneyCountUp` existente.)

4. **[ ] Chegada do Painel** — §1.2
   `lib/features/painel/painel_screen.dart`. `StaggerIn` index 0/1/2 nos três blocos.

5. **[ ] `MoneyCountUp` parametrizável + número vivo nos tools** — §1.5
   `lib/core/ui/money_count_up.dart` (params `duration`/`curve`), depois
   `lib/features/reserva/reserva_screen.dart` e `lib/features/simulador/simulador_screen.dart`:
   heróis viram `MoneyCountUp(..., duration: Motion.quick)`; barra Reserva×Sobra ao vivo.

6. **[ ] Fluxo guiado: slide direcional + stepper pill + unfocus** — §1.4
   `lib/features/calc/calc_screen.dart`. `_prevStep`, `transitionBuilder` com direção,
   `AnimatedContainer` no stepper (ativo 8→20dp), `unfocus()` antes do `setState`.

7. **[ ] "Usar R$ X" + entrada/saída do aviso âmbar** — §3.6
   `lib/features/simulador/simulador_screen.dart`. `AnimatedSize`+`AnimatedSwitcher` no aviso;
   count do herói na aplicação; `Haptics.select()`.

8. **[ ] Haptics em todos os pontos da tabela §4**
   `resultado_screen.dart` · `reserva_screen.dart` · `calc_screen.dart` ·
   `simulador_screen.dart` · `config_screen.dart` · `pro_screen.dart`. Sempre via `Haptics.*`.

9. **[ ] Custos: `AnimatedSize` + total com count-up quick** — §3.2
   `lib/features/calc/calc_screen.dart` `_stepCustos`.

10. **[ ] `PressableScale` nos cards tocáveis** — §3.1
    `lib/core/ui/tool_action_card.dart` · `calc_screen._regimeOption`.

11. **[ ] Sheet do estimador: número estimado com quick-count** — §3.5
    `lib/features/calc/calc_screen.dart` (builder do `showModalBottomSheet`).

12. **[ ] Auditoria final de reduce-motion**
    Android → Acessibilidade → "Remover animações": percorrer as 12 rotas; toda tela entrega
    número e Divisão finais, zero tela "morta", zero animação sobrando. Conferir também que
    nenhum `Duration(milliseconds:)` literal e nenhum `Curves.*` fora de `MotionCurves` entrou
    em tela (grep de CI, se quiser: `grep -rn "milliseconds:" lib/features lib/core/ui`).

**Já pronto, não refazer:** `Motion` (tokens.dart) · `MotionCurves`/`reduceMotionOf`/`Haptics`/
`PressableScale`/`StaggerIn` (motion.dart) · `MoneyCountUp` com reduce-motion e uso no
Resultado/Painel/Detalhe/Histórico · `AnimatedSwitcher` básico da calc (item 6 só o refina).

---

*MOTION-SPEC · Quanto Cobro? — tokens e curvas: [Design-System §5.4](../Design-System.md).
Microinterações irmãs e a11y: [UX-SPEC](UX-SPEC.md). Nada aqui adiciona dependência: 100%
implicit/explicit animations do framework.*
