# REDESIGN PREMIUM — "a luz que faltava"

> Spec de design · 2026-07-19 · alvo v0.6.x
> Fonte: síntese da auditoria de 4 especialistas (cor/textura, motion, produto/UX, a11y)
> sobre o código real. Este documento é a fonte de verdade para o plano de implementação.

---

## 1. Contexto e objetivo

O app está numa boa fase de craft, mas o dono percebe (com razão) que **ainda parece
simples demais** — quer uma cara moderna, premium, "meio translúcida", com sensação de
"app do futuro" e uma navbar **viva**, sem cair em RGB/gamer. Também quer um controle de
**tamanho de fonte** nas Configurações (baixa visão) e notou texto "estourando" em telas.

**Objetivo:** elevar a percepção de qualidade a "vale pagar por isso" **sem trocar a
identidade** "Cofre Aberto" (esmeralda = é seu · ouro = reserva/imposto guardado · aço =
info · terracota = atenção · roxo 4YU só assinatura). Nenhuma cor nova entra na paleta.

## 2. O insight central

**O app não está simples por falta de craft — está simples porque o craft mora num lugar
só.** O `VitrineCard` (herói) já é uma joia: aurora radial + fio-de-ouro + grain sob
`RepaintBoundary`. Todo o resto (cards de ação, card da Divisão, fundo, navbar) é chapado
(`elevation: 0`, sem borda, no escuro). Há um degrau de qualidade gritante.

A solução **não é inventar** — é **propagar a luz** que o herói já tem para as superfícies
que ficaram pra trás: fio-de-luz na borda + degradê tonal + glow de acento sutil.

## 3. Decisões e princípios inegociáveis

Estes são os guarda-corpos. Valem para todas as levas.

1. **Tetos de brilho colorido — a linha entre premium e gamer:**
   - acento nos cards: **≤ 8%** alpha
   - halo da navbar: **≤ 12%** alpha
   - glow do número-herói: **≤ 16%** alpha (só no escuro)
   Passar disso é exatamente o "RGB" que o dono rejeita. Não ceder.
2. **O número é sagrado.** **Nunca** gradiente no dígito, **nunca** vidro/blur atrás de
   número. O valor fica esmeralda sólido `#57E5A9` (9:1). O brilho mora na *superfície ao
   redor*, jamais no número. Uma decisão de preço se lê fria e clara.
3. **Vidro de verdade só na navbar.** Todo o resto é *faux-glass* (fio-de-luz + degradê +
   tint), custo perto de zero. Vidro-em-tudo é a armadilha do "exagerado" e mata bateria.
4. **Fonte é multiplicador SOBRE o sistema, nunca substituto** (ver §5). Substituir é
   regressão P0 de acessibilidade.
5. **Rótulos da navbar sempre visíveis.** Público leigo: rótulo é o mapa. Movimento dá
   vida; não esconde o mapa.
6. **Semântica preservada.** Navbar custom exige `Semantics` explícita de aba (ver §4.3).
7. **Reduce-motion cobre tudo.** Toda animação nova consulta `reduceMotionOf(context)`
   (gate já existente em `lib/core/theme/motion.dart`). Em reduce-motion: estado final
   direto, sem viagem.
8. **Higiene de raster.** Todo `BackdropFilter`/`ShaderMask`/`CustomPaint` novo sob
   `RepaintBoundary` (padrão que o app já segue).

---

## Coordenação com a trilha de personas (ler antes de começar)

> **ATUALIZAÇÃO 2026-07-19 — ordem definida:** execução **SEQUENCIAL**, não paralela. Esta
> trilha (visual) vai **primeiro e inteira** (as 3 levas), faz merge no `main`, e a trilha de
> personas assume **depois**, por cima da versão final. Motivo: acessibilidade tem que ser a
> **última** conferida, sobre a UI final (redesign visual é o que mais quebra a11y), e a
> dependência do `reserva_bar.dart` inverte a favor (eu crio ao reestilizar; ele só põe o
> rótulo depois). Consequência: as cautelas de "rebase/zona compartilhada" abaixo **não valem
> pro meu turno** (`main` limpo) — viram problema da trilha de personas quando ela assumir. O
> que eu mantenho: não invento trabalho no domínio dele e **preservo `Semantics`/`announce`**
> ao reestilizar.

Há um segundo agente na **trilha de personas** (lógica/dados/semântica de
leitor de tela/copy/moeda/gestão), plano em
`docs/superpowers/plans/2026-07-19-melhorias-personas.md`. Esta trilha (visual) cede o
não-visual e fica na camada de cor/material/nav/motion/**escala-de-fonte**.

**Arquivos 100% meus (ele não toca):** `nav_shell.dart`, `hero_value_card.dart`,
`tool_action_card.dart`, `vitrine_card.dart`, `divisao_bar.dart`, `app_colors.dart`,
`tokens.dart`, `color_scheme.dart`, `app_typography.dart`, `motion.dart`, `app_theme.dart`,
`panel_card.dart` (novo), `materials.dart` (novo), `app.dart`.

**Zonas compartilhadas (git pull/rebase antes de editar; conferir se ele acabou de tocar):**
- **`config_screen.dart`** — **eu vou primeiro** (reduzir-transparência L1, fonte L2). O
  toggle de lembrete dele entra **por último** (Fase 4 dele), depois da minha estrutura
  assentar. Adicionar seções, não reescrever.
- **`reserva_screen.dart`** — ele extrai `ReservaBar` (Fase 1) + Semantics/announce; eu faço
  overflow (L2) e o "acender do cofre" (L3) **depois** da Fase 1 dele. A escala de fonte da
  `ReservaBar` (o `height: 20` fixo) é minha → mexo em `reserva_bar.dart` (arquivo novo dele)
  só depois de ele criar.
- **`resultado_screen.dart`** — ele troca copy ("gross-up"→PT); eu faço material do card +
  overflow do CTA + herói-joia. Camadas diferentes, mesmo arquivo → rebase.
- **`historico_screen.dart` / `perfis_screen.dart`** — eu adiciono padding inferior (nav
  flutuante, L1); ele faz agregação do histórico (Fase 4). Eu vou primeiro no padding.
- **`settings_repository.dart` / `providers.dart`** — os dois adicionam chaves/providers
  **aditivos** (fonte+transparência meu; lembrete dele). Sem reescrita.

**Handoff que ACEITO dele** (itens visuais/escala que ele cedeu, achados das personas):
1. Barra da Reserva e da Divisão crescerem com a fonte (`height: 20` fixo; legendas que não
   respeitam `textScaler`) — Ademir P1 → **entra na Leva 2**.
2. Alvos de toque ≥48dp no AppBar/nav + chevron 18px que escala — Tiago/Ademir → **Leva 1**
   (a nav já garante ≥48dp; chevron/AppBar entram junto).
3. Espaçamento dos chips de custo (8→12–16dp) — Tiago → **só quando/se eu reestilizar os
   chips do calc; FORA das 3 levas atuais** (anotado, não esquecido).
4. Sinal +/− antes do número de lucro/prejuízo (Rafael/daltônico — cor não é o único canal,
   WCAG 1.4.1) — → **Leva 3** (casa com "cor não é o único canal").

**Regra de ouro compartilhada (dele, adotada aqui):** todo momento que VIBRA/ANIMA também
FALA. Minhas animações novas (cofre acendendo, count-up) não removem `Semantics`/`announce`
existentes ao reestilizar; a camada semântica é dele, e eu preservo.

---

## 4. LEVA 1 — O wow: material dos cards + navbar de vidro

Resolve ~70% do "simples" com risco baixo. Nada de blur exceto a navbar.

### 4.1 Sistema de material nos cards (`PanelCard` + tokens)

**Problema:** `ToolActionCard` (promovido a protagonista) e os `Card` crus do painel/
resultado são os widgets mais planos da tela — `surfaceContainer` chapado, `elevation: 0`
no escuro.

**Solução — três camadas baratas, pintadas uma vez (sem shader por frame):**
- **Fill em degradê vertical:** topo `surfaceContainerHigh` → base `surfaceContainer`
  ("a luz vem de cima").
- **Fio-de-luz (edge-light):** borda 1px com gradiente vertical, branco **8%** no topo →
  **4%** na base. **Croma zero** (OKLCH C≈0) — é *luz*, não cor nova. É o que evita o
  efeito arco-íris.
- **Glow de acento no canto do ícone:** `RadialGradient` na cor do destino a **8%**,
  centrado no topo-esquerda, raio ~0.9× largura. "Recebi um pagamento" brilha **ouro**;
  "Vou orçar" brilha **aço**. Cor fazendo hierarquia, reforçando a semântica.

**Entregáveis:**
- **Novo widget** `lib/core/ui/panel_card.dart` (`PanelCard`) encapsulando as 3 camadas.
  O `cardTheme` não faz degradê/edge-light (só shape+color), então o widget é o caminho
  certo; o `cardTheme` fica para cards secundários.
- **Novo** `lib/core/theme/materials.dart` como `ThemeExtension<Materials>`, registrado em
  `app_theme.dart` (junto de `DivisaoColors`). Tokens nomeados por tema (sem alpha mágico
  espalhado): `edgeHighlight`, `edgeShadow`, `panelFillTop`, `panelFillBottom`,
  `glassFill`, `glassBlurSigma`, `navHalo`, `heroGlow`.
- **Aplicar** em: `ToolActionCard` (troca o `Material` chapado), e os `Card(color:)` de
  `painel_screen.dart` (card "DE CADA MÊS" ~L237; lembrete DAS ~L160) e
  `resultado_screen.dart` (anatomia ~L202).

**Grain:** só no `VitrineCard` (área grande). **Não** propagar para cards pequenos — em
área pequena vira banding/sujeira.

### 4.2 Wash de ambiente no fundo

Uma `DecoratedBox` estática atrás do `ListView` do Painel (e telas-âncora), sob
`RepaintBoundary`:
- **Escuro:** `RadialGradient` topo-esquerda esmeralda **4%** → transparente +
  `RadialGradient` base-direita ouro **2.5%** → transparente, sobre `surface`. O app
  inteiro passa a parecer estar *dentro do cofre* — eco do `VitrineCard` no ambiente.
- **Claro:** pular ou ultra-fraco (esmeralda ~1.5% no topo). O papel "Recibo Premium" fica
  sóbrio; no claro a elegância mora na luz limpa.

### 4.3 Navbar de vidro real — **direção escolhida: "vidro real"**

O conteúdo rola **por baixo** da barra, com blur de verdade. É o maior salto visível.

**Estrutura** (`lib/app/nav_shell.dart`):
- `Scaffold(extendBody: true, ...)` — corpo estende por baixo da barra.
- `bottomNavigationBar` passa a hospedar, de baixo pra cima, uma `Column(min)`:
  **(a)** o banner (`AdSlot`) como **card flutuante** (margens laterais 16, faux-glass do
  §4.1, cantos arredondados) — mais elegante, alinhado com "anúncios não-irritantes";
  **(b)** gap; **(c)** a **pílula de vidro** da navbar.
- Pílula: margem 16 horizontal, ~12 do fundo (dentro de `SafeArea`), **altura 64**
  (mantém alvo ≥48dp), **raio 28** (`Radii.xl2` — squircle "premium", não `full` que lê
  "brinquedo").

**Material da pílula:**
- `ClipRRect(radius: 28)` → `BackdropFilter(ImageFilter.blur(sigma: 18–20))` → **fill
  tint ≥ 0.88** (`surfaceContainerHigh` no escuro / equivalente claro). **0.88 é piso de
  contraste, não estética:** como o conteúdo rola atrás dos rótulos pequenos (`labelMedium`
  13), abaixo disso o contraste do texto vira aposta a cada scroll. Ainda lê como vidro
  (cor/movimento borrados aparecem), com o texto garantido.
- **Fio-de-luz** na borda (branco 8% no topo) — é o que faz a pílula parecer viva, não um
  retângulo com blur.
- **Hairline** `outlineVariant` 1px — sem ela a forma some contra fundo claro (WCAG 1.4.11).
- **Sombra tintada + halo:** escuro = preto 35% (blur 24, y 8) + halo esmeralda **≤12%**
  (blur 32); claro = a verde-tinta que o `VitrineCard` já usa.

**Fallback obrigatório (dupla defesa — o Flutter não expõe "reduzir transparência"):**
- Se `MediaQuery.of(context).accessibleNavigation` (leitor de tela ativo) **OU** o setting
  novo "Reduzir transparência" (§4.4) estiver ligado → **troca o `BackdropFilter` por fill
  opaco** `surfaceContainerHigh`. Uma linha de `if`. É a diferença entre premium e travado
  em Android de entrada.

**Microinteração viva** (Kenji "Design A", implicit — **sem `AnimationController`**):
- Cada item é um `TweenAnimationBuilder<double>(end: selected ? 1 : 0, duration: 220ms,
  curve: MotionCurves.emphasizedDecel)`.
- **Pílula que "abraça"** o item ativo: `padding` interpola compacto→largo; cor do fill
  interpola `transparent → accentContainer @ 0.16`.
- **Ícone:** `Transform.scale(1 + 0.08·t)` + cor `onSurfaceVariant → accent` + swap
  outlined→filled (pares já existem: `home_outlined/home` etc).
- **Rótulos SEMPRE visíveis** (decisão §3.5). O ativo ganha peso/cor; os inativos ficam
  legíveis. (Nota: a descrição do dono "pega o ícone e às vezes a palavra" foi conscientemente
  ajustada aqui — o público leigo precisa do mapa. A vida vem do movimento do pill/ícone.)
- **"Viaja":** os dois itens (sai/entra) animam com a mesma curva simultaneamente → o pill
  encolhe num lugar e cresce no outro → lê como objeto deslizando. É a "emanação" pedida.
- **Overshoot opcional:** trocar a curva por `Cubic(0.34, 1.4, 0.5, 1.0)` (~8% overshoot,
  manso). Mola física de verdade só com `AnimationController`+`SpringSimulation` — **fora de
  escopo** (o cubic entrega 90% da sensação).
- **Haptic:** mantém `Haptics.select()` no tap (já existe).
- **Semântica (obrigatória, custom perde a nativa):** cada destino com
  `Semantics(button: true, selected: isSelected, inMutuallyExclusiveGroup: true,
  label: '<rótulo>')` + ordem de foco. Sem isso o TalkBack perde "aba 2 de 3".
- **Reduce-motion:** `t` salta 0/1, sem scale/slide.

**Consequências estruturais (obrigatórias nesta leva):**
- `ListView` das 3 abas (Painel, Histórico, Trabalhos) ganham `padding` inferior =
  altura(navbar + gap + banner) + `MediaQuery.padding.bottom`, senão o último item some.
- **Testar já com fonte de sistema grande:** rótulos da navbar não podem cortar; se não
  couber, a altura cresce — o rótulo nunca some.
- **Cor do accent por aba** (cor com sentido): Início = esmeralda, Histórico = **ouro**
  (é a cor da Reserva/Cofre), Trabalhos = esmeralda. Risco de poluição com 3 cores → corte
  seguro: pill sempre esmeralda-neutro e **só o ícone ativo** ganha o accent. Validar no
  device.
- **Alvos de toque ≥48dp no AppBar e chevrons (handoff personas #2):** ao reestilizar a nav
  e ao encostar em AppBars, garantir área de toque ≥48dp e ícones que crescem com o
  `textScaler` (o chevron 18px de `hero_value_card.dart` e afins). É pré-requisito de motor
  (Tiago) e baixa-visão (Ademir).

### 4.4 Setting "Reduzir transparência" (habilita o fallback)

Switch simples na Config (seção APARÊNCIA), default **desligado**. Persistido em
`SettingsRepository` (`reduce_transparency: bool`) + provider. Consumido pela navbar (§4.3)
e por qualquer faux-glass. Fecha o ciclo de perf/a11y de ponta a ponta.

---

## 5. LEVA 2 — A base séria: tamanho de fonte + fim do "estouro"

**São o mesmo trabalho.** "Texto estourando" é bug de layout sob `textScaler`; adicionar
"Grande" sem consertar **piora**. Vão no mesmo PR.

### 5.1 A feature — multiplicador SOBRE o sistema

**Conceito (o único jeito correto):** a preferência do app é multiplicador **por cima** do
fator do sistema: `efetivo = fator_do_sistema × multiplicador_do_app`, com clamp. Assim
"Grande" empurra quem não mexe no sistema, e **preserva** o zoom de quem já ampliou tudo
(baixa visão). Substituir o `textScaler` do sistema = regressão P0.

**Níveis (4):** Compacto `0.90` · Padrão `1.00` · Grande `1.15` · Enorme `1.30`. Rótulos
por extenso (não "P/M/G" — ruído pra dislexia e leitor de tela).

**Clamp global:** `[0.85, 2.0]`. Teto 2.0 = alvo do WCAG 2.2 1.4.4 (o próprio Android trava
a fonte do sistema em ~2.0). **Não** clampar abaixo do que o sistema sozinho pede. *Dívida
declarada aceitável:* teto temporário 1.6 se preciso shippar antes de fechar todos os
reflows do §5.2 — mas isso capa quem setou o sistema em 2.0, então é P1 a fechar, não
solução.

**Ponto de aplicação:** o `builder:` do `MaterialApp.router` em `lib/app/app.dart:62` —
único lugar onde o `MediaQuery` já existe (o `build()` externo não tem, por isso o
reduce-motion é lido do `platformDispatcher`). O splash fica **fora** da escala (marca não
distorce; o `Stack` já dá isso). Esboço:

```dart
// no build() externo:
final double appMult = ref.watch(textScaleProvider); // 0.90..1.30
// dentro do builder:
final MediaQueryData mq = MediaQuery.of(context);
final double sysFactor = mq.textScaler.scale(14) / 14;      // colapsa a curva do sistema
final double effective = (sysFactor * appMult).clamp(0.85, 2.0);
final Widget scaled = MediaQuery(
  data: mq.copyWith(textScaler: TextScaler.linear(effective)),
  child: child ?? const SizedBox.shrink(),
);
return Stack(children: [scaled, if (!_splashDone) SplashOverlay(...)]);
```

**Persistência + estado:** `SettingsRepository` (`text_scale: double`, default 1.0) +
`textScaleProvider` (`NotifierProvider<double>`), espelhando `themeModeProvider`. Guardar o
double direto (não enum) simplifica o `ref.watch` no builder.

**UI (Config › APARÊNCIA, logo após o tema):**
- **`RadioListTile`** (não `SegmentedButton` — 4 segmentos com "Enorme" seriam a *primeira*
  coisa a estourar). Alvo ≥48dp nativo, ótimo no TalkBack.
- **Prévia ao vivo:** `Text('Prévia: R$ 1.234/hora', style: AppType.valueMd)` que
  redimensiona no tamanho escolhido (herda o `textScaler` do app).
- **Anúncio por voz:** usar o helper `announce(context, 'Tamanho da fonte: Grande')` de
  `lib/core/ui/a11y.dart` no `onChanged`.
- **Microcopy:** "Isto ajusta sobre o tamanho de fonte do seu celular" (deixa claro que
  combina, não substitui).

### 5.2 Conserto do "estouro" (pré-requisito do §5.1)

Onde o padrão-ouro (`FittedBox` + texto-fantasma do `hero_value_card.dart:100`) falta e a
`Row` fixa dá `RenderFlex overflow` com fonte grande:

- **P1 — `lib/core/ui/divisao_bar.dart` (~L153):** valor final da legenda sem folga (o
  rótulo é `Expanded`). Como a Divisão aparece em Painel + Resultado, é o de maior alcance.
  → `Flexible(child: FittedBox(scaleDown, alignment: centerRight, child: ...))`.
- **P1 — `lib/features/reserva/reserva_screen.dart` (~L251):** duas etiquetas de dinheiro
  lado a lado sem `Flexible`. → trocar a `Row` por `Wrap(spacing: x4, runSpacing: x2)`.
- **P1 — `lib/features/detalhe/detalhe_screen.dart` (~L200):** `Row(spaceBetween)` com
  `MoneyCountUp` em `valueLg` (44px) sem folga. → `Flexible` + `FittedBox(scaleDown)`.
- **P1 — CTAs pill que cortam:** `resultado_screen.dart:119` ("Salvar este trabalho"),
  `detalhe_screen.dart:236` e `:222`. → label em `FittedBox(scaleDown, child: Text(...))`
  (encolhe, preserva o pill; não vira botão de 2 linhas).
- **P1 — Barras crescerem com a fonte (handoff personas #1):** a `ReservaBar` (`height: 20`
  fixo — arquivo `reserva_bar.dart` que a trilha de personas cria na Fase 1) e a `DivisaoBar`
  (`divisao_bar.dart`, altura/legendas fixas) não respeitam `textScaler`. Fazer a altura da
  barra e o tamanho das legendas escalarem (dentro de um teto), pra baixa-visão (Ademir).
  **Dependência de sequência:** mexer em `reserva_bar.dart` só *depois* de a Fase 1 dele
  criá-lo; a `divisao_bar.dart` é minha, sem dependência.
- **P2 (dívida):** `detalhe_screen.dart` `_linha` valor sem `Flexible`;
  `reserva_screen.dart:273` estado-salvo pode virar `Wrap`; título de `AppBar` elipsa em
  2.0 (aceitável); `ads.dart:97` "PUBLICIDADE" com `fontSize: 9` hardcoded → `labelSmall`.

**Salvaguarda global:** depois de fechar os P1, o clamp 2.0 é a rede para as `Row` não
previstas. Não perseguir cada pixel antes da hora.

---

## 6. LEVA 3 — O brilho: herói-joia + momentos emocionais

Refino sobre a base sólida. Reusa 100% a linguagem visual existente.

- **Herói como joia** (`vitrine_card.dart` `_CofrePainter`, `hero_value_card.dart`):
  - Aresta especular no topo (stroke de gradiente branco 10%→0, ~40% da largura) — a luz na
    quina de cima.
  - Boost de aurora no herói do **Painel** (hoje `climax` só liga no Resultado): boost ~1.2.
  - Número "iluminado por dentro": `shadows: [Shadow(esmeralda @ ≤16%, blur 18)]` **só no
    escuro**. **Nunca gradiente no dígito** (§3.2).
- **"Trancar o cofre" na Reserva** (`reserva_screen.dart` + `vitrine_card.dart`): hoje
  `highlight: _saved` é flip seco de cor (o painter não anima). Transformar em progresso:
  `TweenAnimationBuilder<double>(end: highlight ? 1 : 0, duration: 350ms, emphasizedDecel)`
  passado ao painter, que interpola `strokeWidth 1.0→1.5` e alpha do ouro `0.35→0.8`. O fio
  de ouro **acende** — o payoff de "guardei do Leão". `Haptics.commit()` já dispara no tap.
  Sheen varrendo a borda uma vez = opcional, primeiro a cortar em aparelho fraco.
- **Aterrissagem do count-up** (`money_count_up.dart:24`): trocar o default de nascimento de
  `easeOut` por `Cubic(0.12, 0.66, 0.1, 1)` (freia forte, o número "pousa"). **Não** mexer
  no caminho ao-vivo (tools). Micro-pop `scale 1→1.03→1` nos últimos 10% = opcional.
- **Nudge de press** (`motion.dart`/`tool_action_card.dart`): além do `PressableScale`
  0.98, o ícone-líder dá `AnimatedScale 1→1.05` (120ms, standard). **Sem** tilt/3D.
- **Transição de aba** (`router.dart`/`nav_shell.dart`): fade-through + slide ~16px na
  direção da viagem, sobre o `IndexedStack` (só opacity+translate pra preservar estado; ou
  o package `animations` se quiser shared-axis completo — dep nova, avaliar).
- **Continuidade card→tool** (opcional): `Hero` no ícone-líder voando pro header do destino.
- **Sinal +/− antes do lucro/prejuízo (handoff personas #4):** onde painel/resultado mostram
  lucro, o valor não pode depender **só de cor** (daltônico Rafael, WCAG 1.4.1). Prefixar
  `+`/`−` (ou seta) ao número, além da cor. Barato, e é sinal de "app sério".

---

## 7. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Blur da navbar em Android fraco | Fallback opaco duplo (§4.3): `accessibleNavigation` + setting. Blur é a ÚNICA GPU pesada. |
| Contraste de rótulo sobre vidro (conteúdo rolando) | Tint ≥ 0.88 + hairline. Verificado ≥7:1 escuro / ≥5:1 claro. |
| Glow virar "gamer" | Tetos rígidos 8/12/16%. Não ceder. |
| Fonte grande estourar telas | Consertos §5.2 no mesmo PR + clamp global 2.0. |
| Navbar custom quebrar TalkBack | `Semantics` de aba explícita (§4.3). |
| Legibilidade do número | Zero gradiente/vidro no dígito (§3.2). |
| `saveLayer` de blur/shader | Tudo sob `RepaintBoundary`. |

## 8. Fora de escopo / dívida declarada

- Mola física (`SpringSimulation`) na navbar; shared-axis completo (package `animations`);
  container transform card→tool. São upgrades, não requisitos.
- Subir o teto do clamp 1.6 → 2.0 (se shippar com dívida).
- `_linha`/estado-salvo/AppBar truncando em 2.0; `fontSize: 9` do rótulo de ad.
- `semanticsLabel` de dinheiro por extenso ("noventa e dois reais") pro TalkBack pt-BR.
- Features de produto do Ravi (gerar proposta pro cliente, nudge "cobrando barato?",
  renomear "Histórico" → "Guardado") — **valiosas, mas são produto, não este redesign.**
  Anotadas para roadmap.

## 9. Critérios de aceite (por leva)

**Leva 1:**
- `ToolActionCard` e cards do painel/resultado com material (edge-light + degradê + glow);
  degrau de qualidade vs. herói desaparece a olho.
- Navbar de vidro real com pílula viva, rótulos sempre visíveis, alvo ≥48dp, `Semantics` de
  aba funcionando no TalkBack.
- Fallback opaco confirmado com leitor de tela ligado e com o setting ligado.
- Conteúdo rola por baixo sem cobrir o último item (padding aplicado). Rótulos da navbar
  sobrevivem à fonte de sistema grande.
- Sem regressão de fps perceptível em Android de entrada.

**Leva 2:**
- 4 níveis funcionando como multiplicador sobre o sistema; zoom do sistema preservado
  (testar com sistema em ~200%).
- Prévia ao vivo + anúncio por voz. Clamp [0.85, 2.0] ativo.
- Os 4 pontos P1 de overflow (Divisão, Reserva, Detalhe, CTAs) não estouram em "Enorme".
- Re-testar a navbar da Leva 1 com "Enorme" ligado.

**Leva 3:**
- Cofre "acende" ao salvar na Reserva (animação, não flip). Count-up "pousa". Herói com
  acabamento de joia, número ainda 100% legível.

## 10. Arquivos tocados (mapa)

**Novos:** `lib/core/ui/panel_card.dart` · `lib/core/theme/materials.dart`

**Leva 1:** `lib/core/ui/tool_action_card.dart` · `lib/app/nav_shell.dart` ·
`lib/core/ads/ads.dart` · `lib/features/painel/painel_screen.dart` ·
`lib/features/resultado/resultado_screen.dart` · `lib/core/theme/app_theme.dart` ·
`lib/core/settings/settings_repository.dart` + `lib/core/providers.dart` (setting
transparência) · `lib/features/config/config_screen.dart`

**Leva 2:** `lib/app/app.dart` · `lib/core/settings/settings_repository.dart` +
`lib/core/providers.dart` (textScale) · `lib/features/config/config_screen.dart` ·
`lib/core/ui/divisao_bar.dart` · `lib/features/reserva/reserva_screen.dart` ·
`lib/features/detalhe/detalhe_screen.dart` · `lib/features/resultado/resultado_screen.dart`

**Leva 3:** `lib/core/ui/vitrine_card.dart` · `lib/core/ui/hero_value_card.dart` ·
`lib/core/ui/money_count_up.dart` · `lib/core/theme/motion.dart` ·
`lib/core/ui/tool_action_card.dart` · `lib/app/router.dart` · `lib/core/ui/divisao_bar.dart`

---

*A identidade "Cofre Aberto" fica intacta — significados semânticos preservados, nenhuma cor
nova. É só a luz que faltava batendo nas superfícies certas.*
