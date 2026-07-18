# UX-SPEC — Quanto Cobro?

> **Agente de UX/Interação · spec pronta para implementar.**
> Escopo: microinterações, fluxos novos, matriz de estados, acessibilidade e prevenção de erro —
> em **Flutter concreto** (widget, duração, curva, arquivo). Não altera o motor de cálculo
> (`core/calc/calc_engine.dart` é puro e correto) nem redefine cor/tipografia (isso é do
> [Design-System](../Design-System.md)). Base: [UX-Blueprint](../UX-Blueprint.md) (matriz §5.9, a
> virada §0.1), [IA §2.12](../planning/03-ARQUITETURA-DE-INFORMACAO.md), código atual em
> `lib/features/*`.
>
> **Como ler:** cada item traz **o que fazer · onde no código · widget/abordagem · duração+curva ·
> comportamento em reduce-motion**. Onde o texto é copy de produto, aponto para o **[Agente de
> Copy]** — não invento microcopy final aqui.

---

## 0. Fundamentos que faltam antes de qualquer microinteração

O `Motion` de `lib/core/theme/tokens.dart` já tem as **durações** (quick 120 · base 200 ·
emphasized 350 · slow 500 · countUp 600 · fill 450). Faltam **as curvas** (o DS §5.4 as define, o
código não) e **um gate único de reduce-motion**. Sem isso, cada tela reinventa e diverge. Criar:

**`lib/core/theme/motion.dart`** (novo — estende os tokens, não os substitui):

```dart
import 'package:flutter/material.dart';

/// Curvas do Design System §5.4 (as durações já vivem em tokens.dart `Motion`).
abstract final class AppCurves {
  static const Cubic standard = Cubic(0.2, 0, 0, 1);            // quick, base
  static const Cubic emphasizedDecel = Cubic(0.05, 0.7, 0.1, 1); // emphasized, slow, fill
  static const Curve countUp = Curves.easeOut;                   // números sobem
}

/// Gate ÚNICO de "reduzir movimento". SO (acessibilidade) OU futura preferência
/// do app. Toda microinteração passa por aqui — nunca lê MediaQuery solta.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Duração que colapsa para zero quando o usuário pediu menos movimento.
Duration motion(BuildContext context, Duration d) =>
    reduceMotion(context) ? Duration.zero : d;
```

Regra da casa: **nenhuma tela chama `MediaQuery` de animação diretamente** — sempre `motion(context, Motion.xxx)` ou `reduceMotion(context)`. Isso garante que ligar/desligar movimento é uma decisão só.

---

## 1. Microinterações (Flutter concreto)

### 1.1 Count-up do número-herói quando um resultado nasce

**Hoje:** `Text(moneyBRL(r.valorHora))` estático em `resultado_screen.dart`, `painel_screen.dart`,
`reserva_screen.dart`, `simulador_screen.dart`. O número aparece pronto — perde o "aha" de ver o
dinheiro chegar.

**Fazer:** um widget reutilizável `MoneyCountUp` que anima de um valor anterior até o final,
formatando cada frame com `moneyBRL` (mantém `tnum`, sem "dançar").

**`lib/core/ui/money_count_up.dart`** (novo):

```dart
class MoneyCountUp extends StatelessWidget {
  const MoneyCountUp(this.value, {super.key, required this.style, this.suffix = ''});
  final num value;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final Duration d = motion(context, Motion.countUp); // 600ms, zero em reduce-motion
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: d,
      curve: AppCurves.countUp,
      builder: (context, v, _) => Text(
        '${moneyBRL(v)}$suffix',
        style: style,
        // Semantics do número real (§4.1) — o leitor não deve "contar junto".
        semanticsLabel: null, // definido pelo Semantics do chamador
      ),
    );
  }
}
```

- **Abordagem:** `TweenAnimationBuilder<double>` — dispara sozinho no primeiro build e a cada
  mudança de `end` (reanima do valor corrente). É o caminho mais barato; não precisa de
  `AnimationController`/`State`.
- **Duração/curva:** `Motion.countUp` (600 ms) · `AppCurves.countUp` (ease-out). O número
  desacelera ao chegar — sensação de "assentar" no valor.
- **`%` e valor-hora inteiro:** para `reservaPct` (ex.: `16%`) use a mesma ideia com `int` e sufixo
  `%`. Para `R$ 92 /hora`, `suffix: ' /hora'`.
- **Onde aplicar:**
  - `resultado_screen.dart` → os 3 blocos (`_bloco`): valor-hora (`valueHero`), reserva %
    (`valueXl`), lucro real (`valueXl`). É o momento "resultado nasce" — count-up + fill juntos.
  - `reserva_screen.dart` → `res.reserva` (herói). Aqui o valor muda **enquanto digita** → ver 1.3
    (transição curta, não count-up longo).
  - `simulador_screen.dart` → `res.lucro`. Idem 1.3.
  - `painel_screen.dart` → valor-hora ao **entrar** no Painel vindo do "Salvar perfil" (nasce um
    resultado). Ao só reabrir o app, é aceitável estático (não é "nascimento"); se quiser, anime só
    na primeira montagem da sessão.
- **Reduce-motion:** `motion()` devolve `Duration.zero` → `TweenAnimationBuilder` pinta direto o
  valor final. Nenhum branch extra.

> **Não usar** pacote externo (`animated_flip_counter`) — o app é offline/enxuto e `moneyBRL`
> (intl) já resolve a formatação por frame. Menos dependência, mesmo efeito.

### 1.2 Preenchimento animado da barra "A Divisão"

**Hoje:** `DivisaoBar` (`lib/core/ui/divisao_bar.dart`) usa `Expanded(flex: flex(v))` — reparte
instantâneo.

**Fazer:** animar as **frações** de 0→final (a barra "cresce" e se reparte). Como `Expanded` não
anima, trocar por `FractionallySizedBox`/`LayoutBuilder` com larguras animadas, dirigidas por um
`TweenAnimationBuilder<double>` de progresso 0→1.

Sketch dentro do `build` da barra:

```dart
final Duration d = motion(context, Motion.fill); // 450ms
TweenAnimationBuilder<double>(
  tween: Tween<double>(begin: 0, end: 1),
  duration: d,
  curve: AppCurves.emphasizedDecel,
  builder: (context, p, _) {
    return LayoutBuilder(builder: (context, c) {
      final double w = c.maxWidth;
      return Stack(children: [
        // trilho
        SizedBox(width: w, height: 18, child: ColoredBox(color: d.track)),
        // três segmentos crescendo juntos (larguras * p)
        Row(children: [
          SizedBox(width: w * fracLucro * p, child: ColoredBox(color: d.lucro)),
          SizedBox(width: w * fracReserva * p, child: ColoredBox(color: d.reserva)),
          SizedBox(width: w * fracCusto * p, child: ColoredBox(color: d.custo)),
        ]),
      ]);
    });
  },
)
```

- **Duração/curva:** `Motion.fill` (450 ms) · `emphasizedDecel` — combina com o count-up (600 ms) e
  termina antes, então o número "assenta" por último. Deliberado: os olhos veem a barra repartir e
  o número fechar.
- **Reanimação em recálculo:** ao editar item no detalhamento (2c) ou salvar novo cálculo, as
  frações mudam → o `TweenAnimationBuilder` interno das larguras precisa animar entre frações
  antigas e novas, não de 0. Para isso, no caso "recálculo ao vivo" use um `AnimatedFractionBar`
  que guarda as últimas frações e anima **entre** elas (`ImplicitlyAnimatedWidget` custom ou três
  `AnimatedContainer` de largura). Para o caso "nasce" use o progresso 0→1 acima.
- **Acessibilidade preservada:** manter o `ExcludeSemantics` na barra (já existe) — a leitura vem
  da legenda (§4.2). A animação é puramente visual.
- **Reduce-motion:** `d == Duration.zero` → pinta no estado final. Manter também a variante estática
  atual como fallback de 1 linha (`if (reduceMotion(context)) return _staticBar();`) para não pagar
  o `LayoutBuilder` à toa.

### 1.3 Recálculo ao vivo nos tools (reserva/simulador) — sem botão

**Hoje (bom):** `reserva_screen.dart` e `simulador_screen.dart` já recalculam no `onChanged` via
`setState` — **sem botão "calcular"**. Isso está correto e deve ser preservado. O que falta é a
**transição do número** quando ele salta (digitou outro dígito → herói pula de R$ 320 para R$ 480
sem transição).

**Fazer:**
- Envolver o herói num **count-up curto**: reusar `MoneyCountUp`, mas com `Motion.quick` (120 ms)
  em vez de `countUp` (600 ms) — o DS §5.4 pede "transição `motion.quick` no número" para tools ao
  vivo. Parametrizar: `MoneyCountUp(res.reserva, style: ..., duration: Motion.quick)`.
- **Debounce leve do count-up, não do cálculo:** o cálculo é instantâneo e deve continuar a cada
  tecla (o usuário confia no número seguindo o dedo). Só a animação usa `quick`; como cada tecla
  reinicia um tween de 120 ms, o efeito é um número que "corre" suave atrás da digitação. Não
  adicionar `Timer` de debounce — `computeReserva`/`computeSimulador` são O(1).
- **Barra colapsada da reserva** (Reserva × Sobra, hoje `Expanded(flex:)`): mesmo tratamento da 1.2,
  variante "entre frações" com `Motion.quick`.

- **Reduce-motion:** vira troca instantânea (é o que já acontece hoje) — comportamento idêntico ao
  atual, custo zero.

### 1.4 Transição entre passos do fluxo guiado

**Hoje:** `calc_screen.dart` faz `setState(() => _step++)` e o `_buildStep()` troca o conteúdo
**sem transição**. O progresso é um `LinearProgressIndicator` (não os pontos `●●○○○` do blueprint).

**Fazer:**

1. **Slide + fade entre passos** com `AnimatedSwitcher`:

```dart
AnimatedSwitcher(
  duration: motion(context, Motion.base), // 200ms
  switchInCurve: AppCurves.standard,
  transitionBuilder: (child, anim) {
    final bool forward = _step >= _prevStep;
    final Offset begin = Offset(forward ? 0.12 : -0.12, 0);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  },
  child: KeyedSubtree(key: ValueKey<int>(_step), child: _buildStep()),
)
```

   - `KeyedSubtree` com `ValueKey(_step)` é o que faz o `AnimatedSwitcher` reconhecer troca de passo.
   - Guardar `_prevStep` para saber a direção (avançar desliza da direita; voltar, da esquerda).
   - **Cuidado com foco/teclado:** ao trocar de passo, chamar `FocusScope.of(context).unfocus()`
     antes do `setState` para o teclado não "pular" entre campos durante o slide (evita jank).

2. **Stepper de pontos** `●●○○○` (substitui/acompanha a barra), como widget próprio
   **`lib/features/calc/_stepper_dots.dart`**: 5 `AnimatedContainer` (`Motion.base`) que animam
   cor `outlineVariant → primary` e um leve `scale` no ponto recém-ativado. DS §5.4: "o stepper
   anima 1 ponto por passo". Manter o `LinearProgressIndicator` é opcional; o blueprint pede os
   pontos.

- **Duração/curva:** `Motion.base` (200 ms) · `standard`.
- **Reduce-motion:** `AnimatedSwitcher` com `Duration.zero` corta o slide (troca seca); os pontos
  trocam de cor sem scale. Mantém orientação (o "Passo X de 5" textual já informa progresso).

### 1.5 Snackbar com Desfazer

**Hoje (lacuna):** `resultado_screen.dart` mostra `SnackBar(content: Text('Perfil salvo'))` **sem
ação**; `config_screen.dart` mostra `'Dados apagados'` **sem desfazer** — apesar de o blueprint §10
e a IA §3 pedirem *"snackbar com Desfazer"* para salvar/remover perfil e apagar dados.

**Fazer:** um helper único e usá-lo nas ações reversíveis.

**`lib/core/ui/snack.dart`** (novo):

```dart
void showUndoSnack(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
  String actionLabel = 'Desfazer',
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars() // nunca empilhar dois "Desfazer"
    ..showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5), // janela real de leitura+ação
      action: SnackBarAction(label: actionLabel, onPressed: onUndo),
    ));
}
```

- **Apagar dados (`config_screen._apagar`):** guardar o `Perfil` antes de `clear()`; no `onUndo`
  chamar `profileProvider.notifier).save(perfilAntigo)`. Como o dado é um documento só, o "desfazer"
  é trivial e confiável.
- **Remover perfil (fluxo 2b):** guardar o perfil removido + índice; `onUndo` reinsere.
- **Salvar perfil (`resultado`):** aqui "Desfazer" faz menos sentido (não é destrutivo); manter
  snack simples **sem** ação, ou usar ação `Ver` que leva ao Painel. Reservar "Desfazer" para o que
  destrói/remove.
- **Duração:** 5 s (não o default de 4 s) — dá tempo de ler e decidir. Em reduce-motion o snackbar
  não muda (é conteúdo, não movimento gratuito); o Material já respeita o slide-in do SO.
- **Copy** ("Dados apagados", "Perfil removido", "Desfazer"): **[Agente de Copy]** valida os textos
  finais; o DS §1 já sugere esses.

### 1.6 Respeitar "reduzir movimento" — checklist transversal

Já embutido em cada item acima via `motion(context, ...)`. Regras fixas:

- Count-up (1.1), fill (1.2), slide de passo (1.4) → **colapsam para o estado final estático**.
- O **aviso "abaixo do alvo"** (simulador) já é estático (`Container` com ícone `trending_down` +
  texto); se um dia ganhar fade-in (`Motion.base`), esse fade some em reduce-motion — **a informação
  nunca depende do movimento** (borda + ícone + texto carregam o sinal).
- Shimmer de loading (se algum dia existir, §3) → em reduce-motion vira bloco sólido `surfaceVariant`.
- **Teste manual:** Android → Configurações → Acessibilidade → "Remover animações". Verificar que
  todas as telas ainda entregam número e Divisão corretos, sem tela "morta".

---

## 2. Fluxos novos a desenhar

### 2a. Salvar reserva no histórico + Tela de Histórico de reservas do mês (IA §2.12)

**Motivação:** o J2 (reservar) é o motor de retenção; o histórico transforma o recorrente em
**progresso visível** ("quanto já separei pro imposto este mês?"). Hoje **não existe**: sem model,
sem repositório, sem rota, sem tela. É v2, mas o desenho de interação fica aqui.

**Modelo novo — `lib/core/model/reserva_registro.dart`:**

```dart
class ReservaRegistro {
  const ReservaRegistro({
    required this.id,          // uuid/time-based
    required this.recebido,    // valor que entrou
    required this.reservado,   // valor guardado
    required this.pct,
    required this.regimeTag,   // "MEI" — snapshot, não referência (regime pode mudar depois)
    required this.data,        // DateTime da marcação
  });
  // toJson/fromJson (mesmo padrão de Perfil/Custo)
}
```

**Persistência:** `shared_preferences` já basta no v2 (lista JSON sob chave `reservas_v1`), atrás de
`ReservaHistoryRepository` — a mesma porta que `ProfileRepository` deixou aberta ("trocável por
Drift quando o histórico crescer"). Quando passar de ~centenas de registros, migrar para Drift sem
mexer na UI.

**Provider:** `reservaHistoryProvider` (Notifier<List<ReservaRegistro>>) com `add`, `remove(id)`,
`clearMonth`. O Painel e a tela de Histórico observam o **total do mês corrente**.

**Passo a passo — salvar (a partir da Reserva):**

1. Em `reserva_screen.dart`, quando `res != null`, aparece um botão **"Salvar no histórico"**
   (`FilledButton.tonal`, alvo ≥48dp) **abaixo** do herói e da barra — nunca sobre o número.
2. Toque → grava `ReservaRegistro` (recebido, reservado, pct, `regime.tag` como snapshot, `DateTime.now()`).
3. **Feedback:** `showUndoSnack(context, message: 'Reserva de {R$X} guardada', onUndo: () => remove(id))`
   (§1.5). O count-up do total no Painel (se visível ao voltar) reforça o progresso.
4. **Prevenção de duplicata:** se o usuário tocar "Salvar" duas vezes com o mesmo valor em <3 s,
   confirmar ("Guardar de novo o mesmo valor?") — evita registro dobrado por toque nervoso.
5. Após salvar, **não** limpar o campo automaticamente (o usuário pode querer conferir); oferecer
   "Registrar outro" que limpa e refoca o campo.

**Tela nova — `lib/features/historico/historico_screen.dart`** (rota `Routes.historico = '/historico'`):

- **Objetivo:** lista das reservas do mês + total guardado.
- **Anatomia:**
  - **Herói do mês:** "Guardado em {mês}" + total (`MoneyCountUp`, `valueXl`, cor `d.reserva`).
    Count-up ao abrir (nasce um número).
  - **Lista** (`ListView`) de registros: data · recebido → reservado · `regimeTag` em chip. Cada
    item com `Dismissible` (swipe) **ou** menu de remover → `showUndoSnack` ("Registro removido",
    Desfazer).
  - **Seletor de mês** discreto no topo (mês corrente por default; setas ‹ ›).
  - **Selo de estimativa** (`EstimativaSeal`) no rodapé — é número de imposto.
- **Entradas:** botão no Painel ("Ver histórico") **e** atalho ao salvar ("Ver histórico"). No
  Painel, um resumo de 1 linha: "Você já guardou {R$X} este mês →".
- **Estados:** ver §3 (linha Histórico).

**Reduce-motion:** herói do total sem count-up; `Dismissible` mantém (é gesto do usuário, não
animação gratuita) mas sem a animação de "fly-out" exagerada.

### 2b. Troca entre múltiplos perfis (Pro)

**Motivação:** preço muda por tipo de cliente ("recorrente" × "avulso"). Hoje `perfis_screen.dart`
mostra **um** perfil e uma porta pro Pro; `ProfileState` guarda **um** `Perfil`. Precisa evoluir o
modelo de "um perfil" para "N perfis + um ativo".

**Mudança de estado (núcleo):**
- `ProfileRepository` passa a guardar **lista** de perfis + `activeId`. Migração: o perfil `v1`
  atual vira o primeiro item da lista `v2` com `id` gerado (migrar no `loadSync`, sem perder dado —
  o backup também precisa acompanhar a versão).
- `Perfil` ganha `id` (hoje só tem `nome`). `ProfileReady` passa a expor `perfis` + `ativo`.
- **Free vs Pro:** free = 1 perfil (criar 2º dispara `Routes.pro`); Pro = N perfis.

**Passo a passo — trocar de perfil:**

1. Na `perfis_screen.dart`, listar todos os perfis como `RadioListTile`/`InkWell` (padrão do
   `_regimeOption` da calc), cada linha: nome · `{R$ X}/h` (via `computeValorHora`) · check no ativo.
   Alvo ≥48dp.
2. Toque num perfil não-ativo → `profileProvider.notifier).setActive(id)`.
3. **Feedback + transição:** ao voltar ao Painel, o valor-hora e a Divisão refletem o novo perfil
   **com count-up/fill** (1.1/1.2) — o usuário *vê* o Painel "virar" pro outro cenário. É o momento
   que justifica a animação existir. Snackbar curto "Perfil {nome} ativo".
4. **Criar** ("+ novo"): se free e já há 1 perfil → `Routes.pro` (gatilho no momento de valor, não
   pop-up). Se Pro → abre a **Calculadora** em modo "novo perfil" (draft limpo, pede nome ao salvar).
5. **Renomear/Remover** (Pro): `PopupMenuButton` por item. Remover → confirmação **só se for o
   ativo** (precisa escolher outro ativo) + `showUndoSnack`. Nunca deixar zero perfis: se remover o
   último, cai no estado vazio (§3) e volta pra Calculadora.

**Estados:** free com 1 perfil (upsell no "+ novo") · Pro com N (troca livre) · remoção do ativo
(reescolher) · falha ao salvar (snack "não salvou, tente de novo" + Desfazer — já previsto na matriz
§5.9).

**Reduce-motion:** troca de perfil ainda repinta Painel, mas sem count-up/fill (estado final direto).

### 2c. Edição inline no Detalhamento com recálculo ao vivo

**Motivação:** o blueprint §5.4 e a IA §2.6 querem *"editar qualquer item → recalcula na hora"*.
Hoje `detalhe_screen.dart` é **somente leitura** e o botão "Editar meu cálculo" **empurra de volta
pra Calculadora inteira** (`context.push(Routes.calc)`) — refaz o fluxo de 5 passos para trocar um
número. É o oposto do prometido.

**Fazer:** transformar as linhas editáveis (`Renda`, `Custos` por item, `Horas`, toggle Provisão) em
**campos inline** que recalculam e fazem **count-up do valor-hora** ao vivo. Vira `ConsumerStatefulWidget`
com um `Perfil _draft` local (igual à calc), partindo do perfil salvo.

**Interação por linha:**

1. Linha em modo leitura mostra `label` + valor (`tnum`, à direita) + affordance de edição (a linha
   inteira é `InkWell`, ou um ícone `edit` de 20dp — alvo do toque ≥48dp na linha).
2. Toque → o valor vira um `TextField` compacto **na própria linha** (`AnimatedSwitcher`
   texto↔campo, `Motion.quick`), teclado numérico, `prefixText: 'R$ '`, autofocus, seleção total.
3. `onChanged` → `setState` recalcula `computeValorHora(_draft)`; o **`= Valor-hora`** no rodapé faz
   **count-up** (`MoneyCountUp`, `Motion.countUp` na primeira mudança, ou `quick` se preferir seguir
   o dedo) — causa→efeito visível (DS §5.4: "editar do detalhamento → count-up até o novo valor").
   A linha `= Preciso faturar` também atualiza.
4. **Confirmar:** foco sai do campo (`onEditingComplete`/tap fora) → volta a modo leitura. Um botão
   fixo no rodapé **"Salvar alterações"** persiste (`profileProvider.notifier).save(_draft)`) e
   volta ao Painel com snackbar. Enquanto não salvar, mostrar aviso sutil "alterações não salvas"
   (`tertiaryContainer`, calmo) para não perder edição sem querer.
5. **Custos:** cada `Custo` é uma linha editável (valor) + remover; reaproveitar a UI do
   `_stepCustos` da calc (chips de "não esqueça" podem aparecer aqui também).

**Validação inline (reaproveita §5.9):** renda ≤ 0 ou horas ≤ 0 → `errorText` humano por campo
(mesma copy da calc: *"Preciso de pelo menos 1 hora faturável pra fazer a conta."*) e o valor-hora
**congela no último válido** em vez de mostrar `∞`/`R$ 0` — nunca pisca lixo.

**Reduce-motion:** troca texto↔campo instantânea; valor-hora atualiza sem count-up.

---

## 3. Matriz de estados revisada por tela

Legenda: ✅ já tratado no código · ⚠️ parcial · ❌ falta. "Loading" é quase sempre n/a (local-first,
leitura síncrona) — o que importa é **input inválido**, **dado desatualizado** e **erro reversível**.

| Tela (arquivo) | Vazio | Carregando | Erro | Input inválido | Lacuna a implementar |
|---|---|---|---|---|---|
| **Painel** (`painel_screen`) | ✅ `_EmptyView` (fisga + Começar) | ✅ instantâneo | ✅ `_ErrorView` (dado corrompido → refazer) | n/a | ❌ **Banner "valores base de {ano}"** (tokens `staleBg/staleFg` existem, **não usados**). Mostrar faixa calma quando `ano da tabela < ano atual` (Blueprint §5.9 estado global). ❌ Resumo "guardado este mês" (2a). |
| **Calc — Renda** (`calc_screen`) | ⚠️ campo pré-preenchido do default; blueprint pede vazio-com-dica | n/a | n/a | ✅ `errorText` humano + botão inativo | ⚠️ ok; garantir botão "Continuar" inativo enquanto `≤0` (já faz via `_stepValid`). |
| **Calc — Horas** | ✅ default ~82h + aviso + "estimar pra mim" | n/a | n/a | ✅ 0h bloqueia (div/zero) com copy humana | ✅ ok. |
| **Calc — Custos** | ✅ lista vazia permitida (total R$ 0) | n/a | n/a | ✅ só dígitos (input formatter) | ✅ ok. |
| **Calc — Regime** | ✅ default MEI selecionado | n/a | ⚠️ "tabela do ano indisponível → cai no intl" **não implementado** | n/a | ❌ fallback de tabela ausente → regime intl + aviso (Blueprint §5.9). Baixa prioridade (tabelas são embutidas). |
| **Resultado** (`resultado_screen`) | ✅ perfil null → "refazer" | ✅ instantâneo | ✅ degrada sem quebrar | ✅ **custo > meta** → mostra resultado + alerta `d.alerta` | ✅ bom exemplo do padrão "sempre devolve algo + alerta". |
| **Reserva** (`reserva_screen`) | ✅ campo vazio → "digite pra ver" | n/a | n/a | ✅ sem valor → sem resultado; só dígitos | ❌ botão "Salvar no histórico" (2a). ⚠️ regime sempre resolve (default MEI) — ok. |
| **Simulador** (`simulador_screen`) | ✅ campos vazios → dica | n/a | n/a | ✅ horas=0 → não calcula effVH; aviso comparativo | ✅ ok. Considerar dica quando `valor>0 && horas==0` explicando por que não há valor-hora. |
| **Detalhamento** (`detalhe_screen`) | ✅ sem perfil → "fazer cálculo" | n/a | n/a | ❌ (vira relevante com 2c) | ❌ edição inline + validação inline (2c). |
| **Perfis** (`perfis_screen`) | ✅ sem perfil → "faça o 1º" | n/a | ⚠️ falha ao salvar (matriz pede snack+Desfazer) | n/a | ❌ multi-perfil + troca + falha-ao-salvar com Desfazer (2b). |
| **Histórico** (novo) | ❌ "nenhuma reserva ainda este mês" + como registrar | n/a | ❌ falha ao ler → "não consegui abrir seu histórico" | n/a | ❌ tela inteira (2a). |
| **Configurações** (`config_screen`) | n/a | ⚠️ import é síncrono; se virar arquivo, mostrar progresso | ✅ import inválido → `FormatException` com copy humana | ✅ backup malformado tratado | ✅ Apagar tem confirmação **dupla**; ❌ falta **Desfazer** no snack pós-apagar (§1.5). |
| **Pro** (`pro_screen`) | — | ⚠️ compra real (`in_app_purchase`) vai ter loading/erro de billing | ❌ erro de compra/restore ("não consegui concluir, tente de novo") | n/a | ❌ estados de billing quando a compra real ligar (hoje é mock local). |

**Estados globais (transversais) a garantir em toda tela com número de imposto:**
- **Selo de estimativa** onipresente ✅ (`EstimativaSeal` já espalhado). Confirmar presença no
  Histórico (2a).
- **Dado tributário desatualizado** ❌ — implementar o banner stale (tokens já existem).
- **Input incoerente devolve algo + alerta, nunca trava** ✅ no Resultado; replicar a filosofia na
  edição inline (2c) e no simulador.

---

## 4. Acessibilidade concreta (onde aplicar no código)

### 4.1 Semantics nos números-herói

**Hoje:** o herói é `Text('${moneyBRL(r.valorHora)} /hora')` → o TalkBack lê `"R cifrão 92 barra
hora"` (ruim). O DS §9.3 quer *"noventa e dois reais por hora"*.

**Fazer:** envolver cada herói (ou o `MoneyCountUp`) num `Semantics` com `label` falado e
`excludeSemantics: true` (para o leitor não ler o `Text` cru **e** o label). Exemplo em
`resultado_screen._bloco`:

```dart
Semantics(
  label: 'Cobre por hora: ${moneyReadable(r.valorHora)} por hora',
  excludeSemantics: true,
  child: MoneyCountUp('${moneyBRL(r.valorHora)} /hora', style: ...),
)
```

- Criar `moneyReadable(num)` em `core/common/money.dart` (usa `intl` para soletrar, ou uma versão
  simples "92 reais"). O **[Agente de Copy]** define o padrão falado ("92 reais por hora" vs "noventa
  e dois reais").
- **Durante o count-up**, o leitor NÃO deve anunciar cada frame. Solução: o `Text` interno do
  `MoneyCountUp` já é coberto pelo `excludeSemantics` do pai; o `Semantics.label` do pai anuncia o
  **valor final** uma vez (usar o valor destino, não o animado). Passar o valor final ao label
  independentemente do frame.
- Aplicar nos heróis: Painel (valor-hora), Resultado (3 blocos), Reserva (reserva), Simulador
  (lucro), Histórico (total do mês).

### 4.2 Semantics na Divisão (leitura como conjunto)

**Hoje (bom começo):** `DivisaoBar` já faz `ExcludeSemantics` na barra colorida (correto — cor não
se lê). A legenda é lida linha a linha, mas **solta**. O DS §6.2 quer leitura agrupada: *"Lucro R$
5.000, 50%. Reserva R$ 1.600, 16%. Custos R$ 850, 8%."*

**Fazer:** envolver o conjunto legenda num `MergeSemantics` **ou** dar à `Column` da barra um
`Semantics(container: true, label: '...')` que concatena as três partes numa frase. Preferir um
`Semantics` explícito no `DivisaoBar.build`:

```dart
Semantics(
  container: true,
  label: 'A divisão do seu dinheiro. '
      'Lucro ${moneyReadable(lucro)}, ${pct(lucro)} por cento. '
      'Reserva de imposto ${moneyReadable(reserva)}, ${pct(reserva)} por cento. '
      'Custos ${moneyReadable(custo)}, ${pct(custo)} por cento.',
  child: /* barra (ExcludeSemantics) + legenda (também ExcludeSemantics agora) */,
)
```

- Ao mover a leitura para o `Semantics` pai, marcar a legenda visível como `ExcludeSemantics`
  também (senão duplica). A legenda continua visível para quem enxerga; o leitor usa a frase única.

### 4.3 Ordem de leitura

- **Fluxo guiado:** garantir ordem **pergunta → helper (ⓘ) → campo → botão**. Hoje a árvore de
  widgets já segue essa ordem (`_title` → texto → `TextField` → helper). Ao adicionar o
  `AnimatedSwitcher` (1.4), **não** quebrar a ordem — o `KeyedSubtree` preserva a subárvore.
- **Resultado/Painel:** herói primeiro, depois reserva/lucro, depois ações. A ordem visual = ordem
  do `ListView` = ordem de leitura ✅. Manter.
- **Tools:** campo(s) → resultado → selo. ✅. Ao inserir "Salvar no histórico" (2a), colocá-lo
  **depois** do número e da barra, nunca antes.

### 4.4 Alvos ≥ 48dp

- **`DropdownButton` da Reserva** (`reserva_screen`): checar altura do alvo; envolver em
  `SizedBox(height: 48)` ou usar `DropdownMenu`/`InputDecorator` com padding suficiente.
- **`IconButton` de remover custo** (`calc_screen._stepCustos`, `close`): `IconButton` já garante
  48dp de área — ok, confirmar que não foi encolhido.
- **`TextButton`s do Painel** ("Ver como cheguei", "Recalcular"): `TextButton` tem `minimumSize`
  padrão < 48 em altura em alguns temas — aplicar `TextButton.styleFrom(minimumSize: Size(0, 48))`
  no tema global (`app_theme.dart`) para valer em todo o app.
- **Linhas editáveis do Detalhamento (2c):** a linha inteira como alvo (≥48dp de altura), não só o
  ícone.
- **`ActionChip` de custos e regime options:** `_regimeOption` usa `padding: vertical 10` → ~44dp;
  subir para 12–14 ou `constraints` de 48dp.
- **Recomendação global:** definir no `app_theme.dart` os `*ButtonThemeData`/`ListTileThemeData`
  com `minimumSize`/`minVerticalPadding` garantindo 48dp, para não caçar tela a tela.

### 4.5 Teclado numérico

**Hoje (bom):** todos os campos de valor usam `keyboardType: TextInputType.number` +
`FilteringTextInputFormatter.digitsOnly`. ✅ Manter. Observações:
- Considerar `TextInputType.numberWithOptions(decimal: false)` (o app usa reais inteiros —
  `moneyBRL` com `decimalDigits: 0`) — reforça que não há centavos e evita a vírgula.
- Formatação de moeda **enquanto digita** (agrupador de milhar) melhora leitura de valores grandes;
  hoje o `TextField` mostra dígitos crus (`prefixText: 'R$ '` + `2000`). Um `TextInputFormatter` de
  milhar (ex.: `2.000`) reduz erro de digitação (Blueprint §9). Opcional, mas recomendado nos
  campos de valor da Reserva/Simulador/Calc.

### 4.6 Foco

- **Reserva** já usa `autofocus: true` no campo (bom — é tool de 5 s). Manter.
- **Calc:** ao trocar de passo, **mover o foco** para o campo do novo passo (ou removê-lo em passos
  sem campo — Custos/Regime/Provisão). Sem isso, o TalkBack fica "preso" no passo anterior. Usar um
  `FocusNode` por campo e `requestFocus()` no `didUpdateWidget`/pós-`setState`.
- **Sheet "estimar pra mim"**: ao fechar com resultado, devolver foco ao campo de horas (para
  continuidade de leitura).
- **Detalhamento inline (2c):** ao entrar em edição, `autofocus` no campo aberto + seleção total; ao
  sair, foco volta à linha.
- **Ordem de foco por Tab/teclado externo:** segue a árvore; não inserir widgets invisíveis
  focáveis.

### 4.7 Text-scaling

- **Prioridade do herói (DS §4):** o `value.hero` deve ter prioridade de espaço; rótulos encolhem
  antes. Testar com text scale do SO até **130%** (DS §3.12). Riscos concretos:
  - Herói `72sp` (`valueHero`) com `moneyBRL` longo (ex.: `R$ 10.100 /hora`) já é largo; a 130%
    **estoura**. Envolver o herói em `FittedBox(fit: BoxFit.scaleDown)` para reduzir só quando não
    couber — nunca cortar/reticências num número de dinheiro.
  - Blocos de rótulo (`labelLarge` em maiúsculas): permitir 2 linhas (`maxLines: 2`,
    `softWrap: true`) em vez de overflow.
- **Não fixar `textScaleFactor: 1.0`** em lugar nenhum (anti-padrão de acessibilidade). Deixar o SO
  mandar e testar o layout.
- **`AnimatedSwitcher`/count-up** com `FittedBox`: o `TweenAnimationBuilder` reconstrói o `Text` a
  cada frame — o `FittedBox` recalcula a escala; performático o suficiente para 60fps num número.

---

## 5. Prevenção de erro e copy de erro humana

Filosofia (Blueprint §5.9 / §9): **o app sempre devolve algo + orienta; nunca "input inválido";
nunca trava.** Toda copy final abaixo é **responsabilidade do [Agente de Copy]** — aqui fica o
gatilho, o tom e um rascunho.

### 5.1 Prevenção (desenhar o erro para fora)

- **Defaults sempre presentes:** já é regra (`Perfil.padrao`, ~82h, MEI). Nenhum passo trava por
  "não saber". ✅ Manter em toda entrada nova (Histórico, novo perfil).
- **Divisão por zero:** `calc_engine` já usa `math.max(1, p.horas)` e a UI bloqueia horas=0. ✅
- **Só dígitos** nos campos de valor (input formatter) — impossível digitar letra. ✅
- **Ações destrutivas com fricção proporcional:**
  - Apagar dados → **confirmação dupla** (dialog) + **Desfazer** no snackbar (§1.5, hoje falta o
    Desfazer). Duas camadas porque é irreversível de outra forma.
  - Remover custo / remover perfil / remover reserva → **1 camada** (Desfazer no snackbar basta;
    são reversíveis e de baixo custo).
- **Restaurar backup por cima de dado existente:** avisar "isso substitui seu cálculo atual" antes
  de importar (hoje `_importar` sobrescreve sem avisar). Oferecer Desfazer (guardar o perfil anterior).
- **Duplicata de reserva** (2a): confirmar salvamento repetido do mesmo valor em janela curta.
- **Simulador — projeto ruim:** o **aviso comparativo** já é prevenção de erro de negócio ("você ia
  cobrar de menos") ✅ — o exemplo-ouro do "app defende o usuário".
- **Sair da Calc/Detalhamento com edição não salva:** interceptar `PopScope`
  (`canPop: false` + `onPopInvoked`) e perguntar "sair sem salvar?" quando houver `_draft` sujo.

### 5.2 Copy de erro humana (tom: calmo, em 1ª pessoa do app, sem jargão)

Padrões **já bons no código** (manter e usar de referência):
- Calc renda: *"Coloque quanto você quer ganhar pra eu calcular."*
- Calc horas: *"Preciso de pelo menos 1 hora faturável pra fazer a conta."*
- Import: *"Esse texto não parece um backup do app."* / *"Não consegui ler esse backup."*
- Painel erro: *"Não consegui carregar seu cálculo. Vamos refazer?"*

**Rascunhos novos (validar com [Agente de Copy]):**

| Situação (onde) | Copy rascunho | Ação oferecida |
|---|---|---|
| Reserva sem valor (já ✅) | "Digite o valor recebido pra ver quanto guardar." | — |
| Simulador valor>0 mas horas=0 | "Me diz as horas do projeto pra eu achar o valor-hora." | foco em Horas |
| Histórico vazio no mês | "Você ainda não guardou nada em {mês}. Toda vez que receber, registre aqui." | "Recebi um pagamento" |
| Histórico falha ao ler | "Não consegui abrir seu histórico agora. Tente de novo." | Recarregar |
| Salvar perfil falhou (2b) | "Não consegui salvar. Tente de novo." | Desfazer / Repetir |
| Restaurar backup sobrescreve | "Isso vai substituir seu cálculo atual. Quer continuar?" | Cancelar / Restaurar |
| Detalhamento renda ≤ 0 (2c) | (reusar) "Coloque quanto você quer ganhar pra eu calcular." | congela valor-hora no último válido |
| Compra Pro falhou (billing real) | "Não consegui concluir a compra. Você não foi cobrado. Tente de novo." | Repetir / Restaurar compras |
| Tabela de imposto desatualizada (banner) | "Valores base de {ano}. Confirme as alíquotas atuais antes de decidir." | (link opcional) |

**Regras de tom (para o [Agente de Copy] aplicar):**
- Nunca "erro", "inválido", "falha" secos → sempre o que fazer a seguir.
- Nunca afirmar imposto devido ("você deve X") → sempre "estime reservar ~X%".
- Erro de imposto/número → tom **calmo** (nunca vermelho de pânico; o DS reserva carmim só para
  erro de campo real, âmbar só para "abaixo do alvo").

---

## Apêndice — Resumo de arquivos a criar/editar

**Criar:**
- `lib/core/theme/motion.dart` — curvas + gate de reduce-motion (§0).
- `lib/core/ui/money_count_up.dart` — count-up reutilizável (§1.1).
- `lib/core/ui/snack.dart` — snackbar com Desfazer (§1.5).
- `lib/features/calc/_stepper_dots.dart` — pontos ●●○○○ animados (§1.4).
- `lib/core/model/reserva_registro.dart` + `lib/core/data/reserva_history_repository.dart` +
  provider — histórico (§2a).
- `lib/features/historico/historico_screen.dart` + `Routes.historico` (§2a).
- `moneyReadable()` em `lib/core/common/money.dart` — leitura falada (§4.1).

**Editar (microinterações + a11y):**
- `lib/core/ui/divisao_bar.dart` — fill animado (§1.2) + Semantics de conjunto (§4.2).
- `resultado_screen.dart` · `painel_screen.dart` · `reserva_screen.dart` · `simulador_screen.dart` —
  trocar heróis por `MoneyCountUp` + `Semantics` (§1.1, §1.3, §4.1).
- `calc_screen.dart` — `AnimatedSwitcher` entre passos + stepper dots + foco por passo (§1.4, §4.6).
- `detalhe_screen.dart` — edição inline + count-up + validação (§2c).
- `perfis_screen.dart` (+ `ProfileRepository`/`Perfil`/`providers`) — multi-perfil + troca (§2b).
- `config_screen.dart` — Desfazer no apagar + aviso ao restaurar (§1.5, §5.1).
- `painel_screen.dart` — banner "valores base de {ano}" (tokens `staleBg/staleFg` já existem) +
  resumo do mês (§3, §2a).
- `app_theme.dart` — `minimumSize`/padding garantindo alvos ≥48dp global (§4.4).

**Preservar (já corretos, não regredir):**
- Recálculo ao vivo sem botão nos tools · `ExcludeSemantics` na barra colorida · teclado numérico +
  digitsOnly · matriz de 3 ramos do `ProfileState` · selo de estimativa onipresente · motor de
  cálculo puro.

---

*UX-SPEC · Quanto Cobro? — pronta para implementar. Textos finais de copy → [Agente de Copy]. Cor/
tipografia → [Design-System](../Design-System.md). Estrutura/fluxo → [UX-Blueprint](../UX-Blueprint.md).*
