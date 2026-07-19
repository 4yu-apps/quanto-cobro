# Quanto Cobro? — O que esse app é

> **Correção de rota.** Modelo mental, hierarquia de objetos, nomenclatura e régua de corte.
> Base: as palavras do dono + o código como está em 2026-07-19 + os docs 00/02/03/05/07.
> **Decisões tomadas, não opções.** Quem lê implementa exatamente isto.
> Ravi Okafor · revisão a nível de produto.

---

## 0. A frase

> **O Quanto Cobro? é onde o freelancer descobre quanto cobrar — e depois anota,
> freela por freela, quanto entrou e quanto ficou separado do imposto.**

Duas metades, nessa ordem, e **nada além disso**:

- **Descobrir** (raro, estratégico): a Calculadora chega num valor-hora e ele fica salvo.
- **Anotar** (recorrente, o hábito): "recebi 400 do Gustavo em maio, 600 em junho,
  200 em julho — e separei tanto de cada".

O que **não** é, e o código de hoje começou a virar: um sistema de gestão de
obrigações fiscais (paguei/não paguei o DAS), uma agenda de previsão de caixa,
um CRM com status e ciclo de vida. Isso é *administrar*. O dono pediu *anotar*.
São produtos diferentes e a diferença aparece em cada tela.

**A pergunta que decide tudo daqui pra frente:** *"essa pessoa termina de mexer
sabendo quanto cobrar e quanto já recebeu — sem ter que manter nada?"* Se um
campo exige manutenção (uma data que envelhece, um status que precisa ser
mudado, um checkbox que precisa ser marcado), ele está do lado errado da linha.

---

## 1. Diagnóstico — onde a confiança quebra hoje

### 1.1 O erro grave: para MEI, o caso do Gustavo é **impossível hoje**

Não é uma questão de ênfase. É um bug funcional, na configuração **padrão** do app
(`Perfil.padrao` nasce com `regime: RegimeId.mei`).

Em `lib/features/reserva/reserva_screen.dart`:

```dart
projetoId: mei ? null : _projeto?.id,
tipo: mei ? 'das' : 'pct',
...
if (projeto != null && !mei) { ...registrarRecebimento... }
```

E na renderização do botão:

```dart
if (_saved || (res.isMei && dasSeparado))   // botão desabilitado "DAS separado"
```

Consequências encadeadas, todas reais hoje:

1. **O recebimento de um MEI nunca fica ligado ao freela.** `projetoId` é jogado
   fora. `recebidoPorProjeto()` ainda filtra `if (id == null || e.isDas) continue`.
   Resultado: "Já recebeu R$ X" **nunca** aparece, o selo "Leão em dia" **nunca**
   acende, o ciclo **nunca** avança, e o nudge cutuca pra sempre um projeto que
   já foi pago.
2. **O MEI só consegue registrar UM pagamento por mês.** Registrou o Gustavo dia
   5; no dia 12 chega a Loja da Ana, ele digita 600 e o botão está desabilitado
   escrito "DAS separado". "Registrar outro" só limpa o campo e cai no mesmo
   estado. **Não existe caminho** pra anotar o segundo pagamento do mês.
3. Ou seja: a persona-título do app (Diego, recém-MEI) **não consegue fazer a
   única coisa que o dono descreveu**.

**A raiz não é descuido — é o modelo.** O app modelou *reserva de imposto* como
protagonista e *recebimento* como acompanhante. Quando o regime é um em que o
imposto não é uma fatia do pagamento (MEI = boleto fixo), o protagonista some —
e leva o acompanhante junto, porque o acompanhante não tinha existência própria.

Isso valida o instinto do dono no nível mais profundo: o rastreio de imposto
pago não é só entulho de tela. **Ele comeu o objeto que importa.**

### 1.2 Os outros pontos de quebra

| # | Onde | O que quebra |
|---|---|---|
| B1 | `projeto_card.dart` | O número grande do card é `projeto.valor` — o **combinado**, uma promessa. O dono pediu o **recebido**, um fato. Card mostra R$ 2.000 de um cliente que nunca pagou. |
| B2 | `painel_screen.dart` | Banner "O DAS de julho vence dia 20 · Já paguei · Separar agora" — exatamente a gestão que ele disse não ser o ideal, e no lugar mais nobre do app. |
| B3 | `historico_screen.dart` | O número herói é **GUARDADO ESTE MÊS**. Ele foi explícito: *"quanto que eu tenho recebido"*. O número principal está errado, e a aba se chama pelo número secundário. |
| B4 | `perfil.dart` + `projeto.dart` | Recorrência existe **duas vezes**: `Perfil.tipoContrato` (mensal/avulso) e `Projeto.recorrencia` (4 tipos). Por isso o Painel tem **dois nudges concorrentes** (`mostrarNudgeProjeto` × `mostrarNudgeMensal`) com uma trava manual entre eles. Modelagem duplicada vira código defensivo. |
| B5 | nomenclatura | Um objeto, quatro nomes: `Perfil` (código) · "trabalho" (switcher, dialog, chips do Guardado, AppBar "Meus trabalhos") · "preço" (Config: "Meus preços") · "preset" (docs). O usuário não tem como formar um modelo mental de algo que muda de nome a cada tela. |
| B6 | `projeto_form_screen.dart` | 8 campos pra cadastrar um freela: nome, valor, recorrência, intervalo-N, próximo recebimento, status, quem paga, anotações. Ele disse *"a ideia realmente é simples"*. |
| B7 | `reserva_screen.dart` | No caminho de ouro, **acima** do número herói: 4 chips de regime + seletor de moeda + linha de cotação + 2 botões de câmbio. Configuração fiscal e financeira empilhada na tela que devia ter um campo e um número. |
| B8 | hierarquia | O nível 1 do modelo mental dele ("área/tipo de trabalho") está escondido em Configurações e num bottom-sheet. O nível 2 ocupa uma aba. **A hierarquia está de cabeça pra baixo.** |

---

## 2. O modelo de objetos

### 2.1 As hipóteses, testadas

| Hipótese | Veredito |
|---|---|
| **1.** "freela" = o trampo, não a pessoa; "Gustavo" é quem paga | ✅ **Confirmada.** Ele usa três vezes como gig: *"tenho um freela com o Gustavo"*, *"pode ter mais freelas"*, *"acompanhamento dos freelas"*. Em português BR "um freela" é inequivocamente o trabalho. |
| **2.** "área de serviço" ≈ o `Perfil` de hoje; a hierarquia é Área → Freela → Entradas | ✅ **Confirmada, e mais forte do que você supôs.** Ele tateou a palavra em voz alta: *"tipo de freela… **trabalhos**… áreas de serviço, áreas de trabalho"*. "Trabalho" é **exatamente** a palavra que a UI já usa pro `Perfil`. O vocabulário dele e o do app já concordam — só que o app põe esse conceito em Configurações. |
| **3.** O `Projeto` é o "freela" dele, com campos demais | ✅ **Confirmada.** Corta 4 dos 8 campos (§3). |

Uma correção à hipótese 2: **`Perfil` não vira "área" inteiro.** Ele carrega hoje
um campo que não pertence a esse nível — o `regime`. Ver §2.4.

### 2.2 Três objetos. Nem mais, nem menos.

```
VOCÊ                                    (Configurações — não é objeto, é ajuste)
 │   como você recebe (MEI/CPF/Simples) · moeda · tema · backup
 │
 ├── ÁREA · "Design"                                        R$ 92/hora
 │    │   o cálculo mora aqui: renda-alvo, horas, custos → valor-hora
 │    │
 │    ├── FREELA · "Gustavo"                                todo mês
 │    │    ├── RECEBIMENTO  maio     R$ 400    separou R$ 45
 │    │    ├── RECEBIMENTO  junho    R$ 600    separou R$ 67
 │    │    └── RECEBIMENTO  julho    R$ 200    separou R$ 22
 │    │
 │    └── FREELA · "Site da padaria"                        uma vez
 │         └── RECEBIMENTO  julho    R$ 1.800  separou R$ 200
 │
 └── ÁREA · "Hora extra"                                    R$ 60/hora
      └── FREELA · "Plantão sábado"                         uma vez
```

| Nível | Nome na UI | Nome no código | O que é | Frequência |
|---|---|---|---|---|
| 1 | **Área** | `Area` (era `Perfil`) | Um tipo de trabalho com o **seu preço**. "Design", "Consultoria", "Hora extra". | Raríssima (cria uma vez, revisa a cada meses) |
| 2 | **Freela** | `Freela` (era `Projeto`) | Um trampo com alguém. "Gustavo", "Site da padaria". | Rara (cadastra quando fecha) |
| 3 | **Recebimento** | `Recebimento` (era `ReservaEntry`) | Entrou tanto, separei tanto, nesta data. | **Toda semana — é o hábito** |

**Não existe um quarto objeto.** Proposta não é objeto (§3.8). Status não é
objeto. Previsão não é objeto.

### 2.3 "Três níveis não é complexo demais?" — Não, porque só o Pro vê três.

Essa é a decisão que salva a simplicidade, e ela vale mais que a hierarquia em si:

> **A hierarquia existe nos dados. Ela não existe na navegação.**

A Área **não é uma pasta em que se entra**. Ela é um agrupador e um rótulo. A
lista de freelas é **plana**, com cabeçalho de seção por área. E:

- **1 área (o caso de 90%, e o único do grátis):** nenhum cabeçalho aparece,
  o chip de área some do herói do Painel, a palavra "área" **nunca é escrita em
  lugar nenhum do app**. O modelo mental que o usuário forma tem **dois níveis**:
  meus freelas → o que recebi de cada um.
- **2+ áreas (Pro):** a lista ganha cabeçalhos ("DESIGN" / "HORA EXTRA"), o chip
  volta ao herói, e o formulário do freela ganha **um** campo a mais. A palavra
  "área" nasce no momento exato em que ela passa a significar algo.

```
GRÁTIS — o que existe na cabeça dele        PRO — o que existe na cabeça dele
──────────────────────────────────          ──────────────────────────────────
  Meus freelas                                DESIGN
   ├ Gustavo         R$ 1.200                  ├ Gustavo         R$ 1.200
   └ Site da padaria R$ 1.800                  └ Site da padaria R$ 1.800
                                              HORA EXTRA
                                               └ Plantão sábado  R$   320
```

Zero toque a mais. Zero palavra a mais. A complexidade só aparece pra quem a
comprou de propósito.

### 2.4 O regime sobe pra pessoa (e sai da Área)

Hoje `regime` é campo de `Perfil`. Isso é errado e **produz número errado**: com
duas áreas em regimes diferentes, o app calcula dois DAS pra um CNPJ só. O
próprio app já admite isso em copy no Guardado — *"O imposto do mês é um só, pra
você — vale pros seus trabalhos todos"* — e depois modela ao contrário.

**Decisão:** `regime` sai de `Area` e vira ajuste da pessoa, em Configurações
("Como você recebe hoje"). O Passo 4 da Calculadora continua perguntando (é onde
faz sentido perguntar pela primeira vez), mas grava no lugar único.

**O que NÃO sobe:** renda-alvo, horas e custos ficam na Área. Regime per-área
gera número *errado*; renda/horas/custos per-área gera número *aproximado* — e
esse app já se vende como estimativa, com selo e tudo. Conserta o que mente, não
o que arredonda.

### 2.5 Os três objetos, campo a campo

**`Area`** — *era `Perfil`*
```
id · nome · rendaAlvo · horas · diasSemana? · horasDia? · provisao* · custos[]
```
- **Sai:** `regime` (sobe pra pessoa) · `tipoContrato` (recorrência é do freela).
- Fica tudo o mais como está. A Calculadora não muda.

**`Freela`** — *era `Projeto`*
```
id · nome · areaId · valorTipico? · todoMes (bool) · encerrado (bool) · criadoEm
```
- **Sai:** `status` (4 estados) → vira o booleano `encerrado`, e ele **não é
  campo de formulário**: é a ação "Encerrar" no menu ⋮.
- **Sai:** `recorrencia` (4 tipos) + `intervaloMeses` → vira o booleano `todoMes`.
- **Sai:** `proximoRecebimento` (§3.4) · `cliente` (§3.5) · `observacoes` (§3.6).
- **Muda de sentido:** `valor` (combinado, obrigatório) → `valorTipico`
  (**opcional**, só serve pra pré-preencher a Reserva; nunca é exibido como o
  número do freela).

**`Recebimento`** — *era `ReservaEntry`*
```
id · freelaId · areaId · valor · separado · at
```
- **Sai:** `tipo` ('pct'/'das') — não existe mais fork (§3.1).
- **Sai:** `regimeTag` como dado do registro — o regime é da pessoa e do momento;
  guardá-lo por linha só servia pra imprimir na lista. Se quiser rastro, guarde
  a taxa aplicada (`taxa`), que é o que de fato reconstrói a conta.
- **Renomeia:** `reserva` → `separado`. O verbo dele é "separar", e é o rótulo
  que já está em toda a copy.
- `freelaId` passa a ser preenchido **sempre** que o registro nasceu de um freela
  — inclusive MEI. Registro avulso (não veio de freela) continua com `null`.

---

## 3. A régua de corte

Nominalmente, sem dó. Prioridade entre colchetes.

### 3.1 [P0] O fork MEI na Reserva — **morre inteiro**

Uma conta só, pra todo regime: **`separado = valor × taxa`**.

Para MEI, `taxa` = a fatia do DAS dentro do faturamento que a área precisa por
mês (tipicamente 1–3%). Não é zero e não é o DAS inteiro. Somando os
recebimentos do mês, dá aproximadamente o DAS — que é a verdade.

**Morre:** `ReservaResult.isMei` como bifurcação de tela · `tipo: 'das'` ·
`ReservaEntry.isDas` · o botão "Separar o DAS do mês" · o estado "DAS separado" ·
a trava `dasSeparado` · o herói alternativo "ESSE DINHEIRO É SEU" ·
`if (id == null || e.isDas) continue` em `recebidoPorProjeto`.

**Sobrevive:** o DAS como **número dentro do cálculo** (`kDasMensalMei` em
`computeValorHora`) e como frase no detalhamento — *"seu DAS de R$ 76/mês já
está dentro desse preço"*. Essa é a leitura fina que você pediu: **o app continua
sabendo que você é MEI; ele para de te dar tarefa por causa disso.**

Alvo: `lib/features/reserva/reserva_screen.dart`, `lib/core/calc/calc_engine.dart`,
`lib/core/model/reserva_entry.dart`, `lib/core/projetos/agenda.dart`.

### 3.2 [P0] Todo o rastreio de "paguei o imposto" — **morre**

- `leaoPagoProvider` · botão "Paguei o Leão deste mês" · "Desfazer quitação" ·
  a frase "Leão de julho: pago. Guia quitada. Mês limpo."
  → `historico_screen.dart`
- Banner "O DAS de julho vence dia 20" + "Já paguei" + "Separar agora"
  → `painel_screen.dart`
- `kDasVencimentoDia` e o cálculo `lembrarDas`.

Ele foi literal: *"NÃO é uma gestão de 'paguei o DAS, não paguei o DAS'."*

### 3.3 [P0] Status de 4 estados — **morre**

`ProjetoStatus.orcamento/ativo/concluido/pausado`, `esperaRecebimento`, o
`PopupMenuButton` de "Marcar como…", os chips de status no formulário.

**Vira:** um booleano `encerrado`, acionado por **uma** entrada de menu:
"Encerrar freela" / "Reabrir". Freela encerrado sai da lista principal e vive
atrás de "Ver encerrados". "Orçamento" como estado só existia pra servir a
integração com a Proposta — que também morre (§3.8).

### 3.4 [P0] `proximoRecebimento`, "Nos próximos 30 dias" e a agenda — **morrem**

Isso inclui: o `showDatePicker` do formulário · "Próximo: 10/ago" e "Era 03/jul"
no card · o cálculo `atrasado` · o selo "falta separar" · `_ProximosRecebimentos`
(com o gate Pro dentro) · `proximosRecebimentos()` e `RecebimentoPrevisto` em
`agenda.dart` · `avancarCiclo()` e `proximoApos()` em `projeto.dart`.

**Por quê:** é uma data que o usuário tem que **manter na mão**, e metade do card
depende dela — quem não preencher (a maioria) vê um card oco. É previsão de
caixa, um produto diferente do que ele pediu ("quanto eu recebi"). E colocar
paywall numa previsão dentro de uma tela que ele acha extensa demais é o pior dos
dois mundos. Volta em P2 se alguém pedir.

### 3.5 [P0] Recorrência de 4 tipos → **2**

`Recorrencia.{avulso, mensal, trimestral, custom}` + `intervaloMeses` + o stepper
"A cada N meses" → **`todoMes: bool`**, um switch: *"Esse cliente paga todo mês"*.

Mata junto: o `intervalo`/`meses`/`recorrente`, o caso especial do trimestral em
`projetosParaCutucar`, e a aritmética de grampear dia-do-mês. Quem tem um
trimestral marca "uma vez" e registra quando cai — **nada quebra**, e ele deixou
de configurar um cron.

### 3.6 [P0] Campos do formulário do freela: 8 → **3**

**Morrem:** `status` · `proximoRecebimento` · `intervaloMeses` ·
`observacoes` ("Anotações — o que só você precisa lembrar": é feature de app de
notas) · `cliente` ("Quem paga (opcional) — só se for diferente do nome acima":
pedir dois nomes pro mesmo ente é atrito puro; ele diz *"um freela com o
Gustavo"* — **o nome do freela é o cliente**).

**Ficam:** nome · quanto costuma receber (opcional) · paga todo mês (switch).
E um 4º campo, **área**, que só aparece com 2+ áreas.

### 3.7 [P0] `Perfil.tipoContrato` e o nudge duplicado — **morrem**

`TipoContrato`, `shouldNudge()`, `mostrarNudgeMensal`, `temProjetosRecorrentes`,
e o `if/else if` que arbitra entre dois nudges. **Sobra um nudge só**, por
freela, com a regra mais simples que existe: *freela com `todoMes` e sem
recebimento neste mês → cutuca*.

### 3.8 [P1] Proposta em PDF — **fica, mas sai do modelo de objetos**

Ela não some. Ela **para de reivindicar espaço estrutural**. Concretamente:

| Morre | Fica |
|---|---|
| "Salvar como projeto" (proposta → objeto) | O fluxo inteiro: marca → formulário → preview → PDF → share |
| O status "Orçamento" e "Reenviar proposta" | O gate Pro no export (a âncora de conversão de 05 §6) |
| Qualquer histórico/rastro de proposta no app | Duas portas: fim do resultado do Simulador, e o ⋮ do freela |
| Presença em card, lista ou Painel | "Minha marca" em Configurações |

**Por quê fica:** é o motor de receita da tese de monetização, está construída, é
isolada (rota de fluxo, não aba) e é o único momento em que o app protege o
freelancer na frente de quem paga. **Por quê demove:** ela introduz uma segunda
audiência (o cliente) num app cuja promessa é confiança interna, e o loop
proposta↔projeto era a peça que mais inchava o modelo. Nada volta da proposta
pro app. Ela sai, entrega o PDF, e acabou.

### 3.9 [P1] Câmbio: a feature fica, a **presença** sai

Não corto trabalho recém-entregue e testado por pureza. Mas hoje o
`SegmentedButton` de moeda + a linha de cotação + "Atualizar" + "Digitar a minha"
ficam **acima do número herói** do caminho de ouro, pra 95% de gente que só usa
real.

**Decisão:** por padrão a Reserva tem **um campo e um número**. Abaixo do campo,
um link discreto: *"Recebi em outra moeda"*. Tocou, aparece tudo que existe hoje.
Quem já usou uma vez, o app lembra e mostra direto.

### 3.10 [P1] Reserva: chips de regime — **saem da tela**

Com o regime sendo da pessoa, um override por pagamento é incoerente. Saem os 4
`ChoiceChip` e o `setReservaRegime` por perfil. Regime errado se conserta onde
foi definido: Configurações.

### 3.11 [P1] Painel: some o entulho

**Morrem:** o botão full-width "Recalcular" (ação rara ocupando peso de CTA →
vai pro detalhamento e pra tela da Área) · a linha "Você já guardou R$ X este
mês" (é substituída pelo bloco ESTE MÊS, §5) · o banner do DAS (§3.2).

### 3.12 [P1] Guardado: chips de filtro por trabalho — **morrem**

Filtrar o histórico por área é uma pergunta que ninguém faz. A pergunta que se
faz é "quanto entrou este mês" e "quanto o Gustavo já me pagou" — e as duas têm
tela própria agora.

### 3.13 [P2] Volta pra fila (não morre, adia)

Previsão de próximos recebimentos · anotações por freela · trimestral/custom ·
histórico de propostas · lembrete por notificação nativa · relatório por área.

---

## 4. Navegação — o de-para

```
HOJE                                    PROPOSTO
────────────────────────────            ────────────────────────────
[Início]  painel                        [Início]      painel
[Projetos] gestão de clientes    ──►    [Meus freelas] lista plana + lente
[Guardado] reservas de imposto   ──►    [Recebido]     o mês, todos os freelas
```

**As três abas continuam.** Cada uma responde uma pergunta que as outras não
respondem:

| Aba | Pergunta | Ícone |
|---|---|---|
| **Início** | "quanto eu cobro?" | `home` (mantém) |
| **Meus freelas** | "quem me pagou o quê?" | `work` (mantém) |
| **Recebido** | "como está indo meu mês?" | `savings` (mantém — o cofre) |

Rótulo da aba do meio: **"Freelas"** (o slot é estreito; o AppBar dentro dela diz
"Meus freelas"). Rótulo da terceira: **"Recebido"**.

**Por que não 2 abas:** `NavigationBar` do Material espera 3–5 destinos; duas
lêem como bug. E existe mesmo uma terceira pergunta — a visão por tempo, que é
diferente da visão por freela.

**Por que "Recebido" e não "Guardado":** a aba passa a nomear o número principal
dela, e o número principal virou o recebido (§5). A linguagem visual do cofre
("Cofre Aberto", `VitrineCard`, o fio-de-ouro ao travar) **fica inteira** — o
cofre agora guarda o que entrou e mostra, dentro, o que ficou separado. O redesign
não perde nada; ganha um nome honesto.

**Rotas** (`lib/app/routes.dart`):

| Hoje | Proposto |
|---|---|
| `/projetos` | `/freelas` |
| `/projeto` (detalhe) | `/freela` |
| `/projeto/editar` | `/freela/editar` |
| `/historico` | `/recebido` |
| `/perfis` | `/areas` |

---

## 5. A hierarquia de números

Ele foi enfático: **um número grande por tela, o resto no detalhamento.**

| Tela | **Número principal** | Secundário (mesma tela, menor) | Escondido no detalhamento |
|---|---|---|---|
| **Início** | `R$ 92/hora` — o que você cobra | "pra ganhar R$ 5.000/mês" · o bloco ESTE MÊS (recebeu / separou) | a Divisão, custos, provisão, imposto, o DAS, horas |
| **Meus freelas** (topo) | `R$ 3.400` — recebido este mês | "separou R$ 380" | — |
| **Meus freelas** (card) | `R$ 1.200` — **já recebeu deste freela** | "3 pagamentos · separou R$ 134" | valor típico, área, todo-mês |
| **Freela (Gustavo)** | `R$ 1.200` — total já recebido | "em 3 pagamentos · separou R$ 134" | valor típico, área, todo-mês (rodapé) |
| **Recebido** | `R$ 3.400` — recebido em julho | "separou R$ 380" | por-freela dentro de cada mês |
| **Reserva** | `R$ 45` — separe isto | "sobram R$ 355 pra usar" + a barra | taxa, regime, moeda |
| **Resultado** | `R$ 92/hora` | reserva % · lucro real | a Divisão + a conta linha a linha |

**A inversão que mais importa:** hoje o card de projeto mostra grande o
**combinado** (`projeto.valor`) — uma promessa. Passa a mostrar grande o
**recebido** — um fato. O combinado vira `valorTipico`, invisível, servindo só
pra pré-preencher a Reserva.

**Regra geral que vale pra tela nova:** o número grande é sempre **dinheiro que
já aconteceu**, exceto no Início, onde é **o preço** (a única coisa que o app
afirma, e a razão de ele existir).

---

## 6. O caso do Gustavo

A tela: **`/freela` — detalhe do freela.** Mora um toque abaixo da aba "Freelas".
Ela é a resposta literal ao que ele descreveu.

```
┌─────────────────────────────────────────────┐
│  ←   Gustavo                            ⋮   │
├─────────────────────────────────────────────┤
│                                             │
│   JÁ RECEBEU                                │
│   R$ 1.200                    ← valueXl     │
│   em 3 pagamentos · separou R$ 134          │
│                                             │
│   ┌───────────────────────────────────────┐ │
│   │  +  Recebi um pagamento               │ │ ← única ação primária
│   └───────────────────────────────────────┘ │
│                                             │
│   JULHO                                     │
│     R$ 200          separou R$ 22           │
│                                             │
│   JUNHO                                     │
│     R$ 600          separou R$ 67           │
│                                             │
│   MAIO                                      │
│     R$ 400          separou R$ 45           │
│                                             │
│   ─────────────────────────────────────     │
│   Design · paga todo mês                    │ ← rodapé, cinza, pequeno
└─────────────────────────────────────────────┘
```

**O que ela mostra:** o total recebido (grande), a contagem e o total separado
(pequeno), um botão, e a lista mês a mês com o par recebido/separado. Mais de um
pagamento no mesmo mês? O mês vira cabeçalho com subtotal e as linhas caem
embaixo, com a data.

**O que ela NÃO mostra:** status · valor combinado · próximo recebimento ·
"atrasado" · selo "Leão em dia" / "falta separar" · anotações · barra de
progresso · quem paga (é o próprio nome) · a Divisão · qualquer botão de imposto.

**No ⋮:** "Mandar orçamento pro cliente" · "Editar" · "Encerrar freela" ·
"Apagar freela".

**Toque em "Recebi um pagamento":** abre a Reserva já sabendo de quem é o
dinheiro, com `valorTipico` pré-preenchido e **editável** (o Gustavo paga 400,
depois 600, depois 200 — a variação é o caso normal, não a exceção). Salvar
grava o `Recebimento` com `freelaId`, e o total desta tela sobe na frente dele.
**Sem fork por regime.**

---

## 7. Nomenclatura — um dicionário, e só ele

Escreva isto uma vez e não deixe ninguém desviar. Um objeto = um nome, em
código, em UI e em conversa.

| Conceito | **Nome único** | Nomes proibidos daqui pra frente |
|---|---|---|
| Nível 1 | **Área** | perfil, trabalho, preço, preset, cenário |
| Nível 2 | **Freela** | projeto, cliente, engajamento, job, trampo |
| Nível 3 | **Recebimento** | reserva, entrada, registro, lançamento |
| A parte do imposto | **o que você separou** | reserva do Leão, provisão, guardado |
| O ato | **registrar** um recebimento | salvar no histórico, lançar, dar baixa |

Notas de decisão:

- **"Freela"** é a palavra dele e é a palavra do público. Risco de ler como
  "freelancer (pessoa)" existe no papel e some no contexto: numa aba do app de
  um freelancer, "Freelas" é "meus trampos". Ele usou três vezes assim.
- **"Área"** só aparece pra quem tem 2+ (§2.3). "Qual sua área?" é como o
  brasileiro pergunta o que você faz — a palavra chega pronta.
- **"Separou"** vence "reservou" por ser o verbo que ele usou (*"eu tenho que
  guardar tanto"* / *"quanto que eu tive que separar"*) e por ser mais concreto.
- O **"Leão"** continua vivo como personagem de copy em momentos pontuais. Ele
  não é mais nome de tela, nem de botão, nem de estado.

---

## 8. UX writing — textos exatos

**Navegação**
- Abas: `Início` · `Freelas` · `Recebido`
- AppBar da aba do meio: `Meus freelas` · da terceira: `Recebido`

**Início — bloco ESTE MÊS** (substitui "Você já guardou…")
- Rótulo: `ESTE MÊS`
- Linha: `Você recebeu R$ 3.400 · separou R$ 380`  → toca e vai pra aba Recebido
- Sem nada este mês: `Nada registrado ainda este mês.` + link `Registrar um recebimento`

**Meus freelas — vazio**
- Título: `Seus freelas ficam aqui.`
- Apoio: `Anote quanto cada um te paga, mês a mês — e quanto você separou do imposto. Leva 10 segundos por pagamento.`
- CTA: `+ Novo freela`

**Meus freelas — topo da lista**
- Rótulo: `RECEBIDO EM JULHO` · número · abaixo: `separou R$ 380`

**Card do freela**
- Título: nome
- Número: `R$ 1.200`
- Linha: `3 pagamentos · separou R$ 134`
- Sem nenhum ainda: `Nenhum pagamento registrado`
- Botão: `Recebi`

**Novo freela — formulário (3 campos + 1 condicional)**
- Título da tela: `Novo freela`
- `Nome do freela` — dica: `Ex.: Gustavo, Site da padaria`
- `Quanto costuma receber (opcional)` — ajuda: `Só pra já vir preenchido quando você registrar. Dá pra mudar sempre.`
- Switch: `Paga todo mês` — ajuda: `Te lembro no começo do mês se ainda não entrou.`
- *(só com 2+ áreas)* `Área` — chips com os nomes
- Botão: `Criar freela`
- Erro de nome vazio: `Dá um nome pro freela pra eu continuar.`

**Freela — detalhe**
- Rótulo do herói: `JÁ RECEBEU`
- Sublinha: `em 3 pagamentos · separou R$ 134`
- Sem nada: `Nada registrado ainda. Quando o dinheiro cair, toque em "Recebi um pagamento".`
- Botão: `Recebi um pagamento`
- Rodapé: `Design · paga todo mês`
- Menu ⋮: `Mandar orçamento pro cliente` · `Editar` · `Encerrar freela` · `Apagar freela`
- Confirmar apagar: `Apagar "Gustavo"?` / `O freela sai da lista. Os recebimentos que você já anotou continuam no Recebido.`
- Encerrar: `Encerrar "Gustavo"?` / `Ele sai da lista principal. Dá pra reabrir quando quiser.`

**Reserva (o caminho de ouro) — enxuta**
- Título: `Recebi um pagamento` / vindo de um freela: `Recebi de Gustavo`
- Campo: `Quanto você recebeu?`
- Link abaixo do campo: `Recebi em outra moeda`
- Rótulo do herói: `SEPARE`
- Sublinha: `Sobram R$ 355 pra usar.`
- MEI, mesma tela: `São ~2% — a fatia do seu DAS neste pagamento.`
- Botão: `Registrar`
- Confirmação (snack): `R$ 45 separados. Gustavo em dia.` / sem freela: `R$ 45 separados.` · ação `Desfazer`

**Recebido (3ª aba)**
- Herói: `RECEBIDO EM JULHO` → `R$ 3.400` → `separou R$ 380`
- Cabeçalho de mês passado: `JUNHO` → `R$ 4.100 · separou R$ 458`
- Linha: `Gustavo` … `R$ 600`
- Vazio: `Nada registrado ainda. Cada vez que um PIX cair, anote aqui — em 10 segundos você sabe quanto é seu.` + `Registrar um recebimento`
- ⋮: `Exportar CSV` (Pro)

**Nudge (um só, por freela)**
- Título: `Novo mês começou`
- Corpo: `O "Gustavo" já te pagou este mês?`
- 2+: `3 freelas mensais ainda não registraram este mês.`
- Ação: `Registrar` · X pra dispensar

**Área — só aparece pra quem tem 2+**
- Tela: `Minhas áreas` · item: nome + `R$ 92/h`
- Ajuda: `Cada área tem o seu preço. Design não custa o mesmo que hora extra.`
- Switcher do herói: `Qual área você quer ver?`
- Parede Pro: `Ter mais de uma área é do Pro.` / `No Pro você separa Design de Hora extra — cada um com o seu preço por hora — e continua vendo tudo numa lista só.`

**Configurações — o que muda de rótulo**
- `Meus preços` → `Minhas áreas`
- Novo item: `Como você recebe` — subtítulo com o regime atual (`MEI`)

---

## 9. Onde você errou

Direto, como pedido. Nada disso é caro agora.

1. **Você modelou o imposto como protagonista e o recebimento como acompanhante.**
   É a origem de tudo: do fork MEI, do `tipo: 'das'`, do "Paguei o Leão", do nome
   `ReservaEntry`, do número herói errado no Guardado. O dono te disse pela porta
   da frente ("não é gestão de paguei/não paguei") o que o código já tinha
   mostrado pela porta dos fundos: **quando o imposto não é uma fatia do
   pagamento, o pagamento deixa de existir no app.**

2. **Você deixou o nível 1 do modelo escondido e deu uma aba ao nível 2.** O doc
   07 §B.2 argumentou bem e decidiu errado — trocou "baixa frequência × alta
   frequência" quando o problema não era frequência, era **hierarquia**. A Área
   não precisa de aba; precisa de existir como o guarda-chuva sob o qual o freela
   nasce. Você tirou o guarda-chuva de vista e depois teve que reintroduzi-lo por
   `perfilId` em três lugares.

3. **Você construiu previsão de futuro num app que ele quer de registro de
   passado.** `proximoRecebimento`, "atrasado", "Nos próximos 30 dias",
   `avancarCiclo`, `RecebimentoPrevisto`, o selo "falta separar" — é uma agenda
   inteira, que só funciona se o usuário mantiver datas na mão, e ainda com
   paywall em cima. Esse é o "muito extenso de gerir" ao qual ele deu nome.

4. **Você duplicou a recorrência** (`Perfil.tipoContrato` e `Projeto.recorrencia`)
   e depois escreveu código de arbitragem entre dois nudges pra conviver com a
   duplicata. Sempre que aparecer um `if/else if` decidindo qual de dois avisos
   mostrar, o bug é de modelo, não de tela.

5. **Você deixou um objeto com quatro nomes.** Perfil/trabalho/preço/preset. Um
   usuário não constrói modelo mental de algo que troca de nome entre a
   Configuração e o bottom-sheet. Isso não é detalhe de copy — é arquitetura de
   informação, e é o item mais barato de consertar da lista inteira.

6. **Você pôs a promessa no lugar do fato.** O número grande do card é o valor
   combinado. Ele pediu, com todas as letras, *"quanto que eu tenho recebido"*.

**O que você acertou e não deve desfazer:** freelas ilimitados no grátis (07
§B.6 está certo, e é o que constrói o hábito e o dado); a Reserva como tela de
um campo e um número; a decisão de não virar Trello; o cofre visual; e a
Proposta em si — ela só estava no lugar errado da hierarquia, não no app errado.

---

## 10. Sequência

**P0 — o modelo.** Nada faz sentido antes disto.
`3.1` fork MEI · `3.2` rastreio de imposto · `3.3` status · `3.4` datas/agenda ·
`3.5` recorrência binária · `3.6` formulário 8→3 · `3.7` nudge único ·
renomear os três objetos · inverter o número herói do card e do Guardado ·
a tela do Gustavo (§6).

**P1 — a hierarquia e o silêncio.**
Área agrupando a lista plana (§2.3) · regime sobe pra pessoa (§2.4) ·
bloco ESTE MÊS no Início · Reserva enxuta (§3.9, §3.10) · Proposta demovida (§3.8) ·
dicionário de nomes aplicado em toda a UI (§7).

**P2 — depois, e só se pedirem.** §3.13.

---

*Régua pra qualquer coisa nova, a partir de hoje:* **se um campo precisa ser
mantido pelo usuário pra continuar verdadeiro, ele não entra.** Nome, valor e
"paga todo mês" passam. Data, status e checkbox de obrigação, não.
