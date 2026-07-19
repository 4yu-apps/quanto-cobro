# C — Experiência e momento: qual é a sensação de usar o Quanto Cobro?

> Revisão de **motion e sensação**, feita depois de ler o app inteiro rodando.
> Contexto: o dono disse que o app ficou **extenso demais** e quer voltar pro simples.
> Então este documento **corta mais do que adiciona**. Uma microinteração nova, uma
> API nova, dez coisas que devem parar de se mexer.
>
> Base: [MOTION-SPEC](../../design-build/MOTION-SPEC.md) (o spec original, majoritariamente
> implementado) · [07 Proposta e Gestão](../07-PROPOSTA-E-GESTAO-DE-PROJETOS.md) ·
> tokens em `lib/core/theme/tokens.dart` e `lib/core/theme/motion.dart`.
>
> **Não contém código de produção.** Especificação em ms, curva, dp e widget.

---

## 0. A leitura: o clímax mudou de lugar e o movimento não acompanhou

Hoje o app gasta a maior parte do seu orçamento de movimento no **Resultado**: transição
`_flowPage` de 350ms, `Haptics.resultBorn()`, count-up de 600ms com `MotionCurves.landing`,
aurora de clímax na `VitrineCard`, seis blocos com `StaggerIn`, `announce()` calibrado pra
cair depois do count-up. É uma coreografia bonita e ela está certa — para **uma tela que a
pessoa vê duas ou três vezes na vida**. O próprio planejamento já diz isso: *"você define seu
preço raramente — a Calculadora é satélite"* ([03 §1](../03-ARQUITETURA-DE-INFORMACAO.md)).

O gesto que a pessoa faz **toda semana** é outro: *"recebi 400 do Gustavo"* → *"guarda 68"* →
salva → volta mês que vem. E esse gesto, hoje, termina assim (`lib/features/reserva/reserva_screen.dart:561-632`):
um `Haptics.commit()`, a borda de ouro da `VitrineCard` acendendo por 350ms, um botão que vira
"Guardado", e uma **snackbar de texto** dizendo *"R$ 68 guardado no histórico"*.

O problema não é que seja pouco movimento. É que **o movimento não entrega a recompensa que o
gesto merece**: a pessoa acabou de tirar dinheiro do próprio bolso e o app responde com um
recibo. O acúmulo — a única razão emocional de voltar — mora em **outra aba**, que ela precisa
ir buscar. O app pede o esforço numa tela e guarda o prêmio noutra.

**Confirmação do palpite: sim, o clímax mudou.** Mas com uma correção importante — não é para
tirar peso do Resultado e sim para parar de gastar movimento **em volta** dele. O Resultado é o
clímax da **estreia** (o trailer); o registro do recebimento é o clímax do **produto** (o filme).
Os dois existem; só um se repete.

E a sensação que falta tem nome: **"eu tenho"**, e não **"eu paguei"**.

---

## 1. Os momentos que merecem peso (5, e só)

### P0-1 — O registro do recebimento: o cofre fecha e o cofre engorda
`lib/features/reserva/reserva_screen.dart:561-632` · momento: *"recebi e separei o do Leão"*

O gesto repetido. Hoje tem haptic + borda de ouro + snackbar; falta a única coisa que importa
emocionalmente: **ver o total subir no mesmo lugar onde o esforço foi feito**. Especificado em
detalhe no §3 (é a microinteração-assinatura).

Por que ajuda a decidir: transforma um ato de **perda** (separar dinheiro que não é seu) num
ato de **construção** (o cofre tem mais do que tinha). É a diferença entre pagar imposto e
poupar — mesmo dinheiro, decisão emocional oposta.

### P0-2 — O primeiro valor-hora: manter, e limpar o entorno
`lib/features/resultado/resultado_screen.dart:44-203` · momento: *"então é isso que eu valho"*

Não mexer no herói: `MoneyCountUp` 600ms `landing` + `Haptics.resultBorn()` + aurora de clímax
+ `_flowPage` estão certos e afinados. **Mas cortar os `StaggerIn` de índice 2 e 3** (linhas
`:244`, `:293`, `:324`, `:353`): hoje seis blocos entram em cascata e três deles estão abaixo
da dobra, contrariando o próprio spec (*"Botões, aviso de custo, selo e banner stale:
estáticos"* — MOTION-SPEC §1.1). O clímax fica **mais forte** com menos coisa se mexendo em
volta dele. Detalhe no §2.

Por que ajuda a decidir: o número-herói é a resposta; tudo que se move junto com ele disputa a
atenção que deveria ser dele sozinho.

### P0-3 — O eco no nível de cima: "Já recebeu" subindo sozinho
`lib/features/projetos/projeto_detalhe_screen.dart:157-162` · momento: *voltar da Reserva pro projeto*

Hoje o detalhe do projeto mostra `Já recebeu R$ 4.200 neste projeto` como `Text` estático.
A tela **fica montada** embaixo da Reserva na pilha e observa `reservaHistoryProvider`, então
ao voltar do save ela rebuilda com o número novo — **saltando**.

**Fazer:** trocar esse `Text` por `MoneyCountUp(total, duration: Motion.emphasized (350ms),
curve: MotionCurves.landing)`. Como o widget continua montado, o `TweenAnimationBuilder`
anima **do valor exibido pro novo** de graça — zero API nova, zero flag de sessão.

Por que ajuda a decidir: é o movimento **ensinando a hierarquia**. O que ela fez lá dentro
subiu um nível e mudou o pai. Ela nunca mais pergunta "isso foi registrado no lugar certo?".

### P1-4 — A entrada no modo focado: a Reserva sobe, não desliza
`lib/app/router.dart:141-150` · momento: *tocar em "Recebi" / "Recebi um pagamento"*

`/reserva` está registrada como `_toolPage` (desliza 6% da direita, 200ms) — a mesma transição
de `/config`, `/legal` e `/detalhe`. Ou seja: **abrir o coração do app tem o mesmo movimento
de abrir as Configurações.**

**Fazer:** trocar pra `_flowPage` (sobe 8% do rodapé, 350ms, `emphasizedDecel`). Uma linha.
Ela é literalmente o exemplo do próprio spec de mudança de modo — *"entrei num modo focado"* —
e é assim que `/calc`, `/proposta` e `/pro` já se comportam.

Por que ajuda a decidir: cria a gramática de duas palavras que o §5 explora — **lateral = fui
mais fundo na estrutura · vertical = entrei num modo**. Com `/reserva` no sabor errado, a
gramática inteira não fecha.

### P1-5 — O mês novo que começa em zero: **explicitamente sem animação**
`lib/features/historico/historico_screen.dart:120-180` · momento: *dia 2 do mês, ela abre o Guardado*

O momento de maior risco de abandono do app inteiro: o herói diz **R$ 0** e parece que o app
esqueceu dela. A tentação é animar alguma coisa aqui. **Não animar nada.** A resposta é
material e de copy: o mês anterior continua visível logo abaixo, e o zero vem acompanhado do
acumulado que **nunca zera** (§4). Movimento aqui seria o app fazendo festa com um zero.

Por que ajuda a decidir: silêncio é uma decisão de motion. Este é o item que prova que o resto
da lista foi escolhido, não acumulado.

---

## 2. O que deve PARAR de se mover (corte é entrega)

Lista nominal, por arquivo:linha. Tudo abaixo se move hoje e não deveria.

| # | Onde | O que se move hoje | Por que sai |
|---|---|---|---|
| C1 | `historico_screen.dart:196` | `StaggerIn(index: i)` **sem clamp** nos cabeçalhos de mês | Com 8 meses, o último header entra com **480ms de delay**. É desfile, não chegada. O spec da casa diz "3 blocos é o teto". Guardado é tela de **consulta**: cascata atrasa leitura. **Remover inteiro.** |
| C2 | `projetos_screen.dart:61` | `StaggerIn(index: i.clamp(0,4))` em cada `ProjetoCard` | Lista de clientes fazendo cascata. Cada card carrega um `Opacity` (saveLayer) + `Transform` por 350–590ms. Lista se consulta, não se celebra. **Remover.** |
| C3 | `resultado_screen.dart:324` e `:353` | Dois `StaggerIn(index: 3)` **com o mesmo índice** — botões e `EstimativaSeal` | Dois véus simultâneos abaixo da dobra, em conteúdo que o MOTION-SPEC §1.1 mandou ser estático. **Remover os dois.** |
| C4 | `resultado_screen.dart:244` e `:293` | `StaggerIn(index: 2)` nos avisos (teto do MEI · custo > renda) | Um aviso que faz fade-in chega **depois** do resto — e é possivelmente a informação mais importante da tela. Aviso existe desde o frame 1. **Remover.** |
| C5 | `reserva_screen.dart:483` | `endTint` no `MoneyCountUp` do herói, em modo ao vivo (120ms) | `endTint` foi feito pro **nascimento** ("acende na chegada"). Em modo ao vivo ele roda um `Color.lerp` por frame **a cada tecla digitada** — e, pior, `style.color` e `endTint` são **a mesma cor** (`d.reserva`/`d.lucro`): é custo puro sem efeito visível. **Remover o parâmetro** desta chamada. |
| C6 | `pro_screen.dart:65-69` | `AnimatedScale(1.06)` no ícone Pro ao ativar | Terceira confirmação do mesmo evento (já há `Haptics.commit()`, snackbar e `AnimatedSwitcher` no botão). Ícone inchando é comemoração genérica de template. **Remover a escala**, manter as outras duas. |
| C7 | `pro_screen.dart:154-156` | `await Future.delayed(Motion.countUp)` (600ms) antes do `pop()` | Tela **parada** segurando quem acabou de pagar, só pra deixar a animação acontecer. Trocar por `Motion.base` (200ms) ou remover. Nunca faça o usuário esperar a sua animação terminar. |
| C8 | `splash_overlay.dart:26` | Brand reveal de **1500ms + 200ms de saída** em toda abertura | O item mais caro do app: 1,7s de imposto por sessão, num app local-first que abre instantâneo e cujo gesto recorrente dura 15s. **Rodar completo só na primeira abertura** (e talvez após update); nas seguintes, 300–400ms de fade do wordmark, ou nada. O reveal é uma peça de marca excelente — só não é uma peça diária. |
| C9 | `vitrine_card.dart:66-88` + `:168-182` | O `_CofrePainter` inteiro repinta a cada frame durante os 350ms do `highlight` — incluindo **grain determinístico** (~290 `drawPoints` num card 320×200), 2 shaders radiais e o gradiente do stroke | Não é corte de estética, é de **orçamento**: só o stroke muda com `highlightT`. Separar em duas camadas — base+aurora+grain num painter **sem** `highlightT` (pinta uma vez) e o fio-de-ouro num painter próprio por cima. A animação continua idêntica; o custo cai de ~21 repinturas completas pra 21 `drawRRect`. |
| C10 | `resultado_screen.dart` (todo) | — | **Não cortar** o `StaggerIn(index: 0)` e `(index: 1)`. Esses dois são a coreografia do clímax e ficam. O corte é só do índice 2 pra cima. |

Saldo: o Resultado sai de 6 blocos animados para 2. O Histórico e a aba Projetos param de fazer
cascata. O app abre 1,3s mais rápido. Nada de informação se perde — em nenhum dos cortes o
conteúdo deixa de existir, só deixa de chegar atrasado.

---

## 3. A microinteração-assinatura: **"O cofre fecha"**

A única coisa nova que este documento pede. É o momento P0-1, especificado frame a frame.

**Gatilho:** toque em *"Salvar no histórico"* / *"Separar o DAS do mês"*
(`reserva_screen.dart:561-632`). Uma vez por registro. Não dispara em digitação, em troca de
regime nem em troca de moeda.

**Timeline** (t=0 = o toque):

| t (ms) | O que acontece | Duração · curva | Técnica |
|---|---|---|---|
| 0 | `Haptics.commit()` (mediumImpact) | — | já existe (`:563`) |
| 0 | `announce(context, ...)` — texto abaixo | — | **novo** (`lib/core/ui/a11y.dart`) |
| 0 → 350 | **O fio-de-ouro fecha o cofre**: stroke 1,0 → 1,5px, alpha do ouro 0,35 → 0,80 | `Motion.emphasized` · `emphasizedDecel` | já existe — `VitrineCard(highlight: true)` (`:463`) |
| 120 → 600 | **Nasce uma linha nova dentro do mesmo card**, abaixo da legenda: fade 0→1 + sobe **8dp** | `Motion.emphasized` com `Interval(0.25, 1)` · `emphasizedDecel` | `TweenAnimationBuilder<double>` local (o mesmo padrão do `StaggerIn`, com delay) |
| 200 → 680 | **O total acumulado conta do valor anterior pro novo** | 350ms · `MotionCurves.landing` | `MoneyCountUp(totalNovo, from: totalAnterior, duration: Motion.emphasized, curve: MotionCurves.landing)` — ver §7 |
| 0 → 200 | O botão vira `✓ Guardado` | `Motion.base` · fade puro, **sem slide** | `AnimatedSwitcher` (hoje é troca seca de árvore por `if`, `:530`) |
| 680 | **Nada mais se move.** | — | — |

**O que fica absolutamente parado:** o número-herói (o valor da reserva), a `ReservaBar`, as
legendas "Pra usar / Reserva", o campo de valor, os chips de regime, o AppBar. Sem escala no
card, sem flash, sem partícula, sem confete, sem brilho passando. **O cofre não pula: ele
fecha.**

**A linha nova, exatamente:**
- Rótulo: `NO COFRE ESTE MÊS` — `labelLarge`, `onSurfaceVariant`, `letterSpacing: 0.5`
  (mesma tipografia dos rótulos de vitrine já usados em `SEU VALOR-HORA` / `GUARDADO ESTE MÊS`).
- Valor: `AppType.valueXl` na cor `d.reserva`, com `AppType.tnum`.
- Posição: dentro da **mesma** `VitrineCard`, logo abaixo do `Wrap` das legendas (`:508-525`),
  separada por `Space.x4`. Nunca num card novo — o ponto é que o prêmio aparece **onde o
  esforço foi feito**.
- Fonte do número: soma de `reserva` das `ReservaEntry` do mês corrente para o perfil ativo —
  o mesmo cálculo que `painel_screen.dart:150-159` já faz e que o Guardado exibe como
  `GUARDADO ESTE MÊS`.

**Por que a regra da casa se inverte aqui (e está certo):** o MOTION-SPEC diz *"o último pixel
a parar de se mover é o dinheiro"*. Aqui o último a parar é o **acumulado** (680ms), não o
valor da transação (parado desde sempre). A regra se refina: **o último a parar é o dinheiro
que FICA, não o que sai.** A última coisa que ela leva da tela precisa ser "eu tenho", não
"eu paguei".

**O que o leitor de tela ouve, no mesmo instante (t=0):**

- Caso geral:
  `'Guardado. R$ 68 separados do Leão. Você já tem R$ 412 no cofre este mês.'`
- Vindo de um projeto (quando `_projeto != null`):
  `'Guardado. R$ 68 separados do Leão. "Gustavo" em dia. Você já tem R$ 412 no cofre este mês.'`
- MEI (`res.isMei`):
  `'DAS de julho separado: R$ 75,60. Você já tem R$ 412 no cofre este mês.'`

Os valores em R$ vêm de `moneyBRL` / `moneyBRLCents` (nunca do frame intermediário do count-up —
o `MoneyCountUp` já garante isso internamente para o próprio label). A snackbar permanece: é
onde vive o **Desfazer**, que é funcional, não decorativo. **Sem haptic na snackbar** (o gesto
já vibrou uma vez — regra 5 da casa).

**Reduce-motion (`MediaQuery.disableAnimations`):** o fio-de-ouro pinta aceso no primeiro
frame (a `VitrineCard` já resolve via `Duration.zero`, `vitrine_card.dart:68-70`); a linha nova
aparece estática com o valor final; o `MoneyCountUp` já colapsa pro `Text`. **Haptic e
`announce` permanecem** — tato e voz não são movimento, e quem desligou animação não pediu pra
desligar o corpo nem o ouvido.

**Custo em aparelho fraco:** com o corte C9 aplicado, são 21 frames de um `drawRRect` + um
`Opacity` de uma linha de texto por ~480ms + rebuild de um `Text`. Cabe folgado nos 16,6ms.

**Por que isso não engorda o app:** é **uma linha de texto** dentro de um card que já existe.
Não é tela, não é aba, não é feature. E ela entrega o valor da aba Guardado **sem exigir a
viagem** — é, na prática, uma medida anti-inchaço.

---

## 4. O acúmulo: materialidade, não gráfico

A pergunta é *"como se mostra que os recebimentos estão se somando, de um jeito que dá vontade
de voltar?"*. Três decisões.

### 4.1 O número que só sobe é o **BRUTO**, não a reserva

A reserva é uma **obrigação** — sai do cofre quando a guia é paga. Somar reserva ao longo dos
meses vira "quanto imposto eu já paguei", que é exatamente o que o dono vetou.

O número que só sobe, que nunca é entregue a ninguém, e que um freelancer **não sabe de
cabeça** é: **quanto já passou pelas mãos dela desde que começou a usar o app.**

> `VOCÊ JÁ FATUROU, DESDE MARÇO`
> `R$ 38.400`

Um número, no topo do Guardado, acima do card do mês corrente. **Sem card** (é uma marca
d'água tipográfica, não uma vitrine — se tudo é vitrine, nada é). **Sem count-up ao abrir a
tela** — chegar ali é consulta, e consulta não faz espetáculo. Ele conta **só quando um
registro novo entra** (mesmo `from:` do §3), porque aí houve um evento.

Dado: soma de `valor` de todas as `ReservaEntry` com `!isDas`, com a data da primeira como
âncora do "desde {mês}". `ReservaHistoryRepository` já tem `brutoDoMes` e `mesesComReserva`
(`lib/core/data/reserva_history_repository.dart:39,62`) — a soma total é trivial e não pede
dado novo.

### 4.2 O ritmo: o presente tem luz, o passado é sedimento

Hoje todo mês do Histórico tem o mesmo tratamento visual e todos entram em cascata (C1).
O acúmulo se lê como **lista de eventos**, não como **pilha que cresce**.

- **Mês corrente:** a única `VitrineCard` da tela — aurora, fio-de-ouro, número em
  `MoneyCountUp` com `landing`. **Já é assim** (`historico_screen.dart:120-138`). Manter.
- **Meses anteriores:** linhas **finas, tipográficas, densas**, valores alinhados à direita em
  `tnum`, sem card, sem sombra, sem `StaggerIn`. Sedimento não brilha.

A pessoa percebe a diferença de **material** antes de ler qualquer número: o presente é vitrine,
o passado é papel. Isso é ritmo sem gráfico, sem barra e sem meta inventada.

### 4.3 O que NÃO fazer aqui (cortado do meu próprio rascunho)

- **Gráfico de barras por mês.** Feature nova, dado que já é legível em tipografia, e o app
  está tentando emagrecer. Fora.
- **Barra de progresso do mês.** Só faz sentido contra uma meta, e não existe meta. Inventar
  uma pra ter o que animar é o pecado clássico. Fora.
- **Streak / medalha / "3 meses seguidos".** O dono pediu isso explicitamente fora, e ele está
  certo: streak pune quem teve um mês ruim — exatamente a pessoa que mais precisa do app.
- **Contador animando ao abrir a aba.** Já é assim no mês corrente e está bom **na primeira
  montagem**; graças ao `IndexedStack` da casca, nas visitas seguintes o `MoneyCountUp`
  anima do valor exibido pro novo sozinho. Não adicionar lógica nenhuma aqui.

---

## 5. A transição entre os níveis: duas palavras, aprendidas uma vez

Hierarquia provável: **Área de trabalho → Freela ("com o Gustavo") → Entradas (recebimentos)**.
Hoje isso existe como: aba **Projetos** → **ProjetoDetalhe** → lista de recebimentos dentro do
detalhe.

**O problema atual:** `/projeto-detalhe` e `/reserva` usam **a mesma** transição
(`_toolPage`, 6% da direita — `router.dart:141-176`). Descer um nível e abrir uma ferramenta
se movem igual. O movimento não ensina nada porque diz a mesma coisa duas vezes.

**A gramática, com duas palavras só:**

| Verbo | Movimento | Duração | Curva | Rotas |
|---|---|---|---|---|
| **Descer na estrutura** (área → freela → entrada) | desliza **6%** da direita + fade | `Motion.base` (200) | `standard` | `/projeto-detalhe`, `/detalhe`, `/perfis`, `/config`, `/legal` |
| **Entrar num modo** (fazer algo, não olhar algo) | sobe **8%** do rodapé + fade | `Motion.emphasized` (350) | `emphasizedDecel` | `/calc`, `/resultado`, `/reserva` ⟵ **mudar**, `/proposta`, `/projeto-form`, `/pro` |
| **Trocar de irmão** (aba ↔ aba) | **nenhuma transição** | — | — | as 3 abas (já é assim, `IndexedStack`) |

Irmãos não têm direção — por isso aba não anima, e isso está certo hoje. A única mudança é
`/reserva`: `_toolPage` → `_flowPage` (`router.dart:144`). Uma linha, e as duas palavras passam
a ser consistentes em todo o app.

**O "onde estou" não é resolvido por animação — e isso é bom:**
- O AppBar da Reserva **já diz** `Recebi de {nome do projeto}` (`reserva_screen.dart:334-337`).
  É a melhor âncora de contexto do app inteiro. Proteger: nenhuma refatoração pode deixar isso
  cair pra "Recebi um pagamento" genérico.
- O eco de volta (P0-3, §1) é o que fecha o circuito: ela desceu, agiu, voltou, e **viu o nível
  de cima mudar por causa do que fez lá embaixo**. Movimento explicando estrutura com um
  `MoneyCountUp` de 350ms.

**O que eu cortei de mim mesmo aqui:** um `Hero` no nome do projeto, do card pro AppBar do
detalhe. É o exemplo de manual de "movimento ensina hierarquia", ficaria lindo em vídeo, e
custa: `Hero` com `CustomTransitionPage`, dois `TextStyle` que precisam casar, um voo por
navegação em GPU fraca. O deslize de 6% + o nome no AppBar entregam **a mesma informação** por
um décimo do preço. Fora.

**A regra de freio (contra o app inchar de novo):** a hierarquia **nunca passa de 3 níveis de
push**, e o 3º nível é **conteúdo, não tela**. Entrada/recebimento é uma linha dentro do detalhe
do freela — não ganha rota, não ganha AppBar, não ganha transição. No dia em que alguém propuser
"tela de detalhe do recebimento", a resposta é esta linha.

---

## 6. Orçamento de movimento (aparelho fraco, offline)

Alvo: Android Go / Moto G, 60Hz, **16,6ms por frame**. O app é local-first: não existe latência
de rede pra "esconder" com animação — toda animação aqui é **custo puro**, e precisa se pagar.

**A regra de orçamento, em uma frase:** *um app financeiro offline pode gastar movimento em, no
máximo, **3 momentos por sessão de 60 segundos**.* Fora disso é ruído.

**Cabe (barato, mantém):**

| Técnica | Custo | Onde |
|---|---|---|
| `MoneyCountUp` | troca de string; layout estável graças ao texto-fantasma (`hero_value_card.dart:122-127`) | herói do Resultado, Painel, Guardado, Reserva |
| `AnimatedContainer` de largura numa `Row` de 2–3 | layout barato, sem saveLayer | `DivisaoBar`, `ReservaBar` |
| `PressableScale` (`AnimatedScale` 0.98) | puro transform | `ToolActionCard`, opções de regime |
| `StaggerIn` de **até 3 blocos** | 3 saveLayers simultâneos por ~350ms | Painel (0/1/2), Resultado (0/1) |
| Transição de rota | 2 páginas compostas por 200–350ms | todas |
| Fio-de-ouro do cofre, **com C9 aplicado** | 1 `drawRRect` por frame | `VitrineCard(highlight:)` |

**Não cabe (luxo caro, não propor):**

- `BackdropFilter` **animado**. O vidro da navbar é estático e o fallback sólido em
  `accessibleNavigation` / `reduceTransparency` já existe (`nav_shell.dart:58-102`) — manter
  exatamente como está e nunca animar sigma.
- `CustomPainter` complexo repintando por frame — é o C9. Regra geral: se `shouldRepaint`
  retorna `true` durante uma animação, **o que muda tem que estar num painter separado do que
  não muda.**
- `StaggerIn` em lista de N itens (C1, C2). N saveLayers em cascata é o padrão mais caro e menos
  útil do app.
- `Hero` de texto entre `CustomTransitionPage` (§5).
- Qualquer `ImageFilter` novo, blur, sombra animada ou gradiente animado.
- Animação **durante scroll**. Nenhuma das propostas aqui roda com o dedo na tela.

**Reduce-motion — estado atual, auditado:** `MoneyCountUp` ✅ · `StaggerIn` ✅ · `PressableScale`
✅ · `DivisaoBar` ✅ · `ReservaBar` ✅ · `VitrineCard` ✅ · rotas `_toolPage`/`_flowPage` ✅ ·
`splash_overlay` ✅ · `onboarding` ✅ · `pro_screen` ✅. **Nenhum furo encontrado** — o gate
`reduceMotionOf()` está sendo respeitado em toda animação da árvore. Tudo que este documento
propõe passa pelo mesmo gate.

**O furo que existe é de outra natureza:** o momento mais importante do app (§3) **vibra e não
fala** — `Haptics.commit()` dispara em `reserva_screen.dart:563` sem `announce()` correspondente,
e a `SnackBar` do Flutter não é anunciada de forma confiável pelo TalkBack no Android. A regra
da casa (*"todo momento que vibra também fala"*, `lib/core/ui/a11y.dart:5-6`) está quebrada
exatamente ali. Corrigir junto com §3.

**Como medir (não confiar no emulador):** aparelho real de entrada, `flutter run --profile`,
DevTools → Performance. Roteiro: registrar 3 pagamentos seguidos + abrir Guardado + voltar.
Critério: nenhum frame acima de 16ms **fora** das transições de rota, e nenhum `saveLayer`
durante scroll.

---

## 7. A única API nova que peço

`lib/core/ui/money_count_up.dart:58-60` — hoje o tween sempre começa em `0`:

```
tween: Tween<double>(begin: 0, end: value.toDouble()),
```

**Adicionar `num? from`**, com `begin: (from ?? 0).toDouble()`. Default preserva 100% do
comportamento atual; nenhuma chamada existente muda.

**Justificativa (é semântica, não técnica):** `0 → 412` diz *"você tem 412"*. `344 → 412` diz
*"você acabou de crescer 68"*. A primeira frase é um saldo; a segunda é a razão de voltar mês
que vem. Sem `from`, a linha do §3 nasceria contando do zero toda vez e mentiria sobre o que
acabou de acontecer.

Onde é usada: só na linha `NO COFRE ESTE MÊS` (§3) e no total acumulado do Guardado quando um
registro novo entra (§4.1). Nos demais lugares (`ProjetoDetalhe`, aba Guardado nas visitas
seguintes) o widget **já continua montado** e anima do valor exibido pro novo sem parâmetro
nenhum.

Nenhum token novo de `Motion.*` nem curva nova de `MotionCurves.*` é necessário — tudo neste
documento usa `quick` (120), `base` (200), `emphasized` (350), `countUp` (600), `fill` (450) e
as curvas `standard` / `emphasizedDecel` / `landing` que já existem.

---

## 8. Ordem de implementação (retorno emocional por esforço)

Cada item é um PR pequeno e independente. Gate obrigatório em todos: `reduceMotionOf(context)`.

1. **Os cortes C1–C8** — `historico_screen`, `projetos_screen`, `resultado_screen`,
   `reserva_screen:483`, `pro_screen`, `splash_overlay`. Um PR de deleção. O app fica mais
   rápido e mais calmo antes de ganhar qualquer coisa nova. *Comece por aqui.*
2. **`announce()` no save da Reserva** (§3, texto exato) — bug de a11y, uma linha, P0.
3. **`/reserva` → `_flowPage`** (`router.dart:144`) — uma linha, conserta a gramática (§5).
4. **`MoneyCountUp.from`** (§7) — parâmetro opcional, sem quebrar chamada nenhuma.
5. **"O cofre fecha"** (§3) — a linha `NO COFRE ESTE MÊS` + o `AnimatedSwitcher` do botão.
   É a entrega principal.
6. **Eco no `ProjetoDetalhe`** (P0-3) — trocar um `Text` por `MoneyCountUp`.
7. **C9 — separar o `_CofrePainter` em duas camadas** — só depois do item 5, porque é ele que
   torna a assinatura barata em aparelho fraco.
8. **`VOCÊ JÁ FATUROU, DESDE {mês}`** (§4.1) + meses anteriores como sedimento (§4.2).

---

## 9. A resposta à pergunta do título

**Qual é a sensação de usar esse app hoje?** A de uma calculadora muito bem-vestida: a estreia
é memorável e o uso diário é correto, silencioso e um pouco frio. Ela faz o esforço numa tela e
o prêmio mora noutra.

**Qual deve ser?** A de um **cofre que fecha com você olhando**. Toda vez que ela registra um
pagamento, três coisas acontecem em menos de 700ms, no mesmo card, sem ela pedir: o corpo sente
(haptic), o fio-de-ouro fecha, e o número do que ela **tem** sobe. Nenhuma tela nova, nenhuma
viagem, nenhuma festa.

O "nossa, que interessante essa experiência" não vai vir do app fazer mais coisa. Vai vir de
ele responder **uma coisa a mais do que foi perguntado**, no instante exato, e depois **ficar
quieto**.

---

*Relacionado: [MOTION-SPEC](../../design-build/MOTION-SPEC.md) · [UX-SPEC](../../design-build/UX-SPEC.md) ·
[07 Proposta e Gestão](../07-PROPOSTA-E-GESTAO-DE-PROJETOS.md).*
