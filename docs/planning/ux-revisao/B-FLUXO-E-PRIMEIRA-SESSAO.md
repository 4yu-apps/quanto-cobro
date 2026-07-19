# B — Qual é o fluxo?

> Tela a tela, da instalação até o hábito. Uma pergunta só: **o que a pessoa vê,
> em que ordem as coisas nascem, e onde cada número aparece.**
>
> Base: [02 Personas](../02-PERSONAS-E-JOBS.md) · [03 IA](../03-ARQUITETURA-DE-INFORMACAO.md) ·
> [05 Escopo](../05-ESCOPO-E-ROADMAP.md) · [07 Proposta e Gestão](../07-PROPOSTA-E-GESTAO-DE-PROJETOS.md) ·
> o app que existe hoje (`lib/features/*`) · o teste com 8 personas (Camila/gestão **4**,
> Marina/USD **3** — as duas piores notas, e as duas do uso recorrente).
>
> **Sem código.** Decisões tomadas, não opções listadas.

---

## 0. O diagnóstico em uma frase

O app já tem os três objetos certos no modelo (`Perfil` → `Projeto` → `ReservaEntry`
= **Trabalho → Freela → Recebimento**). O que quebrou foi a **ordem em que eles
nascem** e o **número de decisões que a pessoa toma antes de ganhar alguma coisa**.

Hoje:
- o objeto de nível 1 (Trabalho) **nasce anônimo e escondido** — salva como
  "Meu trabalho" e vive num chip;
- o objeto de nível 2 (Freela) **exige um formulário de 6 campos antes de existir**;
- e por cima disso foi empilhado um sistema de quitação de imposto
  (*"Paguei o Leão deste mês"*) que **o dono acabou de matar**.

O resto deste documento é o conserto: mesma modelagem, ordem invertida onde
importa, e menos números na cara.

---

## 1. As perguntas do dono, respondidas uma a uma

### 1.1 "Quando o usuário abre esse aplicativo, o que ele quer saber?"

Depende de **quantas vezes ele já abriu** — e essa é a coisa mais importante
deste documento inteiro.

| Abertura | A pergunta viva | O número que responde |
|---|---|---|
| **1ª** | *"Eu tô cobrando pouco?"* | **valor-hora** |
| **2ª–4ª** | *"Deixa eu ver de novo se aquilo é real"* | **valor-hora** |
| **5ª em diante** | *"Caiu dinheiro — quanto disso é meu?"* e *"quanto entrou este mês?"* | **quanto guardar** e **quanto entrou no mês** |

Um app que responde só a primeira pergunta é um app que se usa uma vez. Um app
que responde só a última não tem por que ser instalado. **A tela Início tem que
virar de uma pra outra — e virar sozinha**, sem a pessoa configurar nada.

### 1.2 "O que ele quer descobrir?"

Que ele **não está sendo roubado** — nem pelo cliente (cobrando pouco), nem pelo
Leão (sem separar imposto). É uma pergunta de ansiedade, não de contabilidade.

Consequência prática: cada número que não reduz ansiedade **aumenta** ansiedade.
"Lucro real estimado", "faturamento/mês", "alíquota efetiva", "teto do MEI" e
"valor/dia" não acalmam ninguém na tela inicial — eles são prova de que a conta
existe. Prova mora no **detalhamento**, não na porta de entrada.

### 1.3 "Qual é a primeira coisa que ele quer enxergar?"

**Um número grande em dinheiro, com um rótulo de três palavras.** Nunca um
formulário, nunca uma lista vazia, nunca uma pergunta.

Na 1ª sessão isso é impossível (o app ainda não sabe nada dele) — então a
primeira coisa que ele enxerga tem que ser uma **promessa curta e datada**:
*"Descubra seu valor-hora em 4 perguntas · 2 minutos"*. Da 2ª sessão em diante,
é o número de verdade.

### 1.4 "Ele quer já adicionar números e ter ideia de quanto vai receber?"

**Não.** Ele quer o contrário: quer que o app **diga** um número pra ele.

"Ter ideia de quanto vai receber" é o job de uma agenda de recebíveis — e é o
job de baixa frequência do power user (Camila com 10 clientes), não o de
entrada. Quem instala não quer projetar o futuro; quer parar de errar o presente.

Por isso a previsão ("Nos próximos 30 dias") continua sendo **Pro e secundária**,
e continua **abaixo** da lista, nunca acima dela.

### 1.5 "Ele quer salvar esse valor de hora?"

**Sim — e salvar é o que fecha a primeira sessão.** Mas hoje o salvar é um
anticlímax: o app grava em silêncio como *"Meu trabalho"* e volta pro Painel.

O salvar tem que **dar nome à coisa**. Não por burocracia: porque é o único
momento em que a pessoa está motivada o bastante pra nomear (acabou de ver
R$ 92/h) — e porque um objeto sem nome nunca vira um objeto na cabeça dela.

### 1.6 "Se quiser salvar, salvar como?"

**Como um Trabalho** — a "área de serviço" que o dono descreveu. Nome próprio,
dado por ela, com o valor-hora dentro.

Não como "perfil" (jargão de código), não como "cálculo" (some no tempo), não
como "cenário" (ninguém fala assim). **Trabalho** é a palavra do dono e é a
palavra do freelancer.

### 1.7 "Ele adiciona o projeto e depois o trabalho, ou o que ele faz de primeira já é o trabalho e depois ele adiciona entradas?"

**O que ele faz de primeira é o TRABALHO. Sempre.**

```
   TRABALHO ────────► FREELA ────────► RECEBIMENTO
   "Design"           "Gustavo"        "R$ 400 · 10/jul · guardou R$ 64"
   nasce do CÁLCULO   nasce do 1º      nasce do toque em "Recebi"
   (1ª sessão)        PAGAMENTO        (o gesto do hábito)
```

Os três nascem em ordem cronológica natural, e **cada um nasce no momento em que
a informação dele já está na cabeça da pessoa**:

- o **Trabalho** nasce quando ela acabou de ver o próprio preço;
- o **Freela** nasce quando ela acabou de receber de alguém — o nome "Gustavo"
  é a coisa mais concreta no cérebro dela naquele segundo;
- o **Recebimento** nasce junto, no mesmo gesto.

**Nunca ao contrário.** Pedir "cadastre seus clientes" antes de qualquer dinheiro
existir é pedir trabalho administrativo a quem instalou um app pra fugir de
trabalho administrativo. É exatamente o que a aba Projetos faz hoje, e é por isso
que a persona de gestão tirou nota 4.

---

## 2. Calcula primeiro, ou cria o objeto primeiro? — a decisão

# **Calcula primeiro. O SALVAR é o parto do objeto.**

A pessoa entra na calculadora sem que nada exista. No fim, o botão não é
"Salvar" — é **"Salvar como…"**, com um campo de nome já preenchido. É esse
toque que cria o Trabalho.

### Por que essa e não a outra

**1. Não se cobra aluguel antes de mostrar o apartamento.** Criar objeto primeiro
significa: tela vazia → botão "+" → formulário → nomear uma coisa que ela ainda
não sabe o que é → *só então* calcular. São quatro atos de fé antes do primeiro
retorno. Todo fluxo "crie um objeto pra começar" tem um penhasco de abandono no
formulário vazio, e aqui ele fica no minuto 1.

**2. Nomear é fácil DEPOIS do número, e quase impossível antes.** "Como você
chama esse trabalho?" numa tela em branco é uma pergunta de prova. A mesma
pergunta embaixo de um **R$ 92/h** brilhando é uma comemoração — ela já sabe o
que aquilo é, porque acabou de construir.

**3. O número é o prêmio; o objeto é a prateleira.** Ninguém constrói a
prateleira antes de ganhar o troféu. Invertendo, a prateleira vira a tarefa, e o
troféu vira consequência de uma tarefa — o que mata a única emoção que esse app
tem pra oferecer.

**4. É o que o dono descreveu.** *"A ideia inicial era: a pessoa calcula o freela
dela, e consegue salvar esse freela."* A ordem está na frase.

**5. É o que o app já faz** — o conserto é pequeno e cirúrgico: o `Salvar este
trabalho` de `resultado_screen.dart` passa a pedir um nome antes de gravar.
Estrutura certa, ritual faltando.

### O corolário, que é onde está o dinheiro

Se o Trabalho nasce do cálculo, **o Freela tem que nascer do pagamento** — pela
mesma lógica, um nível abaixo. Não existe formulário "+ Novo projeto" no caminho
principal. Existe:

> **"Recebi um pagamento" → R$ 400 → De quem? [Gustavo] → Guardar**

e o Gustavo passa a existir. Um campo, no momento em que a resposta é óbvia.
`projeto_form_screen.dart` continua existindo, mas só como **"editar"**, alcançado
de dentro do freela — nunca como pedágio de entrada.

---

## 3. A PRIMEIRA sessão, tela a tela

**Meta:** do primeiro toque ao primeiro dado salvo em **menos de 2 minutos e 8
toques**, com um número na cara antes do 5º toque.

```
 ▸ instala e abre
   │
   ├─ 1. ONBOARDING (2 páginas)                    2 toques
   │      "Pare de trabalhar de graça"
   │      "100% no seu aparelho"
   │
   ├─ 2. CALCULADORA (4 passos)                    4 toques + digitação
   │      P1 renda · P2 rotina · P3 custos · P4 regime
   │      ── do P3 em diante, o valor-hora já aparece VIVO no topo ──
   │
   ├─ 3. RESULTADO                                 1 toque
   │      R$ 92/h  ← o clímax
   │      [Salvar como…]
   │
   ├─ 4. NOMEAR (sheet, 1 campo)                   1 toque
   │      "Como você chama esse trabalho?"  [Design ▾]
   │      → nasce o TRABALHO
   │
   ├─ 5. A PONTE (sheet, 1 pergunta, pulável)      1 toque
   │      "Já tem alguém te pagando?"  [Gustavo] [Agora não]
   │      → nasce o FREELA (ou não)
   │
   └─ 6. INÍCIO — estado A
          R$ 92/h grande + [Recebi um pagamento]
```

### 3.1 Onboarding — 2 páginas (hoje são 3)

Corta a página do meio (a aula sobre a Divisão) e **mata a pergunta
"No Brasil / No exterior"**. Motivo: essa pergunta é feita de novo, melhor e no
contexto certo, no passo 4 da calculadora (regime) — e fazer a mesma pergunta
duas vezes, a primeira antes de qualquer valor entregue, é o retrato do app que
cobra antes de dar.

```
┌──────────────────────────────────┐   ┌──────────────────────────────────┐
│                          Pular   │   │                          Pular   │
│                                  │   │                                  │
│         ( 🐖 )                   │   │         ( 🔒 )                   │
│                                  │   │                                  │
│  Pare de trabalhar               │   │  100% no seu                     │
│  de graça.                       │   │  aparelho.                       │
│                                  │   │                                  │
│  Descubra quanto cobrar por      │   │  Sem cadastro, sem login, sem    │
│  hora e quanto guardar pro       │   │  enviar seus dados pra ninguém.  │
│  Leão.                           │   │  Funciona offline.               │
│                                  │   │                                  │
│            ●━━ ○                 │   │            ○ ━━●                 │
│  ┌────────────────────────────┐  │   │  ┌────────────────────────────┐  │
│  │        Continuar           │  │   │  │  Começar · 2 minutos       │  │
│  └────────────────────────────┘  │   │  └────────────────────────────┘  │
└──────────────────────────────────┘   └──────────────────────────────────┘
```

### 3.2 Calculadora — 4 passos (hoje são 5), com o número vivo a partir do 3º

Duas mudanças, uma que corta e uma que segura:

**Corta o passo 5 (férias/13º).** É uma pergunta de provisão de longo prazo feita
a alguém que ainda não sabe quanto cobra por hora. Vira um **toggle dentro do
Detalhamento** ("guardar 1 mês por ano pra férias e 13º"), ligado por default,
onde já existe todo o contexto pra entender o que é.

**Segura com o número vivo.** Do passo 3 em diante o valor-hora **já é
calculável** (renda ÷ horas + carga). Então ele aparece, pequeno, fixo no topo,
mudando enquanto ela mexe:

```
┌──────────────────────────────────┐
│  ←            Passo 3 de 4       │
│  ●━━●━━●━━○                      │
│ ┌──────────────────────────────┐ │
│ │ até aqui:  R$ 87/h      ↗    │ │  ← nasce no passo 3, muda ao vivo
│ └──────────────────────────────┘ │
│                                  │
│  O que você paga todo mês        │
│  pra conseguir trabalhar?        │
│                                  │
│  ☑ Software/ferramentas   120,00 │
│  ☑ Internet/telefone      100,00 │
│  ☑ Equipamento            150,00 │
│  ☐ Contador                      │
│  ☐ Coworking                     │
│                                  │
│  + Adicionar um custo meu        │
│                                  │
│  ┌────────────────────────────┐  │
│  │        Continuar           │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

Por quê: hoje são **cinco telas de investimento com zero retorno** antes do
Resultado. Isso transforma os passos 3, 4 e 5 numa prova. Com o número vivo, eles
viram **ajuste fino de uma coisa que já é dela** — e a diferença de sensação
entre "responder" e "ajustar" é a diferença entre abandonar e terminar.

### 3.3 Resultado — o clímax, com um botão só

```
┌──────────────────────────────────┐
│  ←         Seu resultado         │
│                                  │
│ ┌──────────────────────────────┐ │
│ │  COBRE POR HORA              │ │
│ │                              │ │
│ │  R$ 92    /hora              │ │  ◄── HERÓI
│ │                              │ │
│ │  Esse é o seu piso. Cobre    │ │
│ │  mais quando o trabalho      │ │
│ │  valer mais.                 │ │
│ └──────────────────────────────┘ │
│                                  │
│ ┌──────────────────────────────┐ │
│ │  DE CADA PAGAMENTO, GUARDE   │ │
│ │  ~16%                        │ │  ◄── apoio 1
│ │  Já é a sua faixa real,      │ │
│ │  não a cheia.                │ │
│ │  ──────────────────────────  │ │
│ │  ▓▓▓▓▓▓▓▓▓▓▒▒▒▒░░░░  A       │ │  ◄── a Divisão vive AQUI
│ │  seu R$5.000 · Leão R$1.600  │ │       (onde ela explica o número)
│ │  · custos R$850              │ │
│ └──────────────────────────────┘ │
│                                  │
│  Ver detalhamento                │
│  ⓘ estimativa, não vale como     │
│    orientação contábil           │
│                                  │
│ ┌──────────────────────────────┐ │
│ │      Salvar como…            │ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

**O que sai desta tela:** "≈ R$ 736/dia · R$ 7.450/mês faturados" (equivalências
que ninguém usa e que competem com o herói), o aviso de teto do MEI e o aviso de
custo-maior-que-renda (viram linha no Detalhamento), e o botão "Fazer proposta"
(o momento de propor não é o momento de descobrir o próprio preço — ele vive no
fluxo Orçar, §5.4).

### 3.4 Nomear — o parto do Trabalho

```
┌──────────────────────────────────┐
│              ───                 │
│  Salvar esse cálculo como…       │
│                                  │
│  ┌────────────────────────────┐  │
│  │ Design                     │  │  ← já preenchido, editável
│  └────────────────────────────┘  │
│                                  │
│  É o tipo de trabalho que você   │
│  faz por esse preço. Dá pra ter  │
│  mais de um depois.              │
│                                  │
│  ┌────────────────────────────┐  │
│  │      Salvar · R$ 92/h      │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

Um campo, pré-preenchido (nunca em branco — campo em branco é um pedido de
esforço; campo preenchido é um convite a corrigir), e o valor-hora **no rótulo do
botão** pra que o gesto de salvar e o número salvo sejam a mesma coisa na
memória dela.

### 3.5 A ponte — a pergunta que decide se existe uma 2ª sessão

Logo depois de salvar, **uma** pergunta, pulável em um toque:

```
┌──────────────────────────────────┐
│              ───                 │
│  Já tem alguém te pagando        │
│  por isso?                       │
│                                  │
│  ┌────────────────────────────┐  │
│  │ Ex.: Gustavo, Loja da Ana  │  │
│  └────────────────────────────┘  │
│                                  │
│  Quando o dinheiro dele cair,    │
│  você registra em 2 toques.      │
│                                  │
│  ┌────────────────────────────┐  │
│  │        Adicionar           │  │
│  └────────────────────────────┘  │
│           Agora não              │
└──────────────────────────────────┘
```

Por que vale um passo a mais num fluxo que eu estou encurtando: entre "salvei meu
preço" e "caiu meu primeiro pagamento" existe uma **vala de 2 a 4 semanas** em
que o app não tem absolutamente nada a oferecer — e é nela que ele sai da tela
inicial do celular. Essa pergunta compra três coisas por um toque:

1. a aba Trabalhos **nunca nasce vazia** (o vazio é o pior estado de qualquer
   lista, e o desta é o mais caro do app);
2. o app ganha **um nome próprio** pra usar no lembrete do mês seguinte —
   *"o Gustavo já te pagou?"* funciona; *"você recebeu algo este mês?"* não;
3. ela já viu, sem esforço, que o app guarda gente — o que é metade da
   explicação do que o app faz.

---

## 4. A SEGUNDA sessão em diante — o hábito

Ela abriu pela 5ª vez. Caiu um PIX. **O gesto é de dois toques:**

> **toque 1:** "Recebi um pagamento" · **toque 2:** "Guardar"
> *(digitar o valor não é toque — é o único trabalho que ela aceita fazer)*

### 4.1 Início — estado B (depois do 1º recebimento)

O cartão-herói **vira uma vez, para sempre**, no primeiro recebimento registrado.
Não é uma tela nova nem um modo: é o **mesmo cartão respondendo a pergunta que
ficou viva**. O valor-hora não some — ele desce pro chip do canto, onde continua
sendo a identidade do app e a porta pro preço.

```
┌──────────────────────────────────┐
│  Quanto Cobro?              ⚙    │
│                                  │
│ ┌──────────────────────────────┐ │
│ │  ESTE MÊS         R$ 92/h ›  │ │  ← chip: o preço, sempre a 1 toque
│ │                              │ │
│ │  R$ 3.400        entrou      │ │  ◄── HERÓI
│ │                              │ │
│ │  🔒 guarde R$ 544 pro Leão   │ │  ◄── apoio 1 (o único que importa)
│ │                              │ │
│ │  Todos os meses          ›   │ │  ← "ver detalhamento" do mês
│ └──────────────────────────────┘ │
│                                  │
│ ┌──────────────────────────────┐ │
│ │  💰  Recebi um pagamento     │ │  ◄── UM botão, largura inteira
│ │      separa o do Leão na hora│ │
│ └──────────────────────────────┘ │
│                                  │
│  ── se houver freela atrasado ── │
│ ┌──────────────────────────────┐ │
│ │ O "Gustavo" (todo mês) já te │ │
│ │ pagou?      Registrar   ✕    │ │
│ └──────────────────────────────┘ │
│                                  │
│  Vou orçar um projeto        ›   │  ← texto, não card
│                                  │
├──────────────────────────────────┤
│      ◉ Início    ○ Trabalhos     │
└──────────────────────────────────┘
```

**O que saiu do Início e por quê:**

| Sai | Motivo |
|---|---|
| Barra da Divisão (Lucro/Reserva/Custos) | É um gráfico de uma média mensal que não muda de um dia pro outro. Na porta de entrada vira móvel. Ela é **resposta** em dois lugares — no Resultado (explica o valor-hora) e na tela Recebi (divide o dinheiro que acabou de cair) — e é **decoração** aqui. |
| Card "O DAS de julho vence dia 20" + "Já paguei" | **Ordem do dono:** não é gestão de "paguei o DAS". O app diz quanto guardar; quem paga é ela, e o app não é o cobrador dela. |
| Botão "Recalcular" | Refazer 4 passos é sempre pior que corrigir a linha errada. Vira "refazer do zero" **dentro** do Detalhamento. |
| Card "Vou orçar um projeto" (metade da linha de ação) | Vira link de texto. Orçar é semanal; receber é o motor. Dois cards de peso igual dizem que as duas coisas importam igual — e não importam. |
| Texto "Seu DAS: R$ 76,90/mês, já dentro da conta…" | Detalhamento. |

### 4.2 Recebi um pagamento — o caminho de ouro

```
┌──────────────────────────────────┐
│  ←     Recebi um pagamento       │
│                                  │
│  Quanto você recebeu?            │
│  ┌────────────────────────────┐  │
│  │ R$  400,00              ⌫  │  │  ← autofocus, teclado numérico
│  └────────────────────────────┘  │
│                                  │
│  De quem?                        │
│  ( Gustavo ) ( Loja da Ana )     │  ← chips dos freelas existentes
│  ( + outro )                     │  ← digita um nome novo → nasce o freela
│                                  │
│ ┌──────────────────────────────┐ │
│ │  GUARDE PRO LEÃO             │ │
│ │                              │ │
│ │  R$ 64                       │ │  ◄── HERÓI (conta ao vivo)
│ │                              │ │
│ │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒         │ │
│ │  pra usar R$ 336 · Leão R$64 │ │  ◄── apoio 1
│ └──────────────────────────────┘ │
│                                  │
│  como MEI · em reais   ajustar › │  ◄── FRASE, não controle
│                                  │
│ ┌──────────────────────────────┐ │
│ │          Guardar             │ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

**A mudança de fundo:** hoje esta tela mostra, antes de qualquer resposta,
**um campo + 3 botões de moeda + 5 chips de regime** (+ 2 links de cotação
quando a moeda não é BRL). São até **11 controles** competindo com o número que
a pessoa veio buscar. É a soma exata das duas piores notas do teste de personas
(Marina/USD **3** e Marta/leiga **6**).

Regime e moeda **já são conhecidos** — vieram do Trabalho. Então eles não são
perguntas: são uma **frase de confirmação** com um "ajustar" que abre um sheet.
Quem recebe em dólar toca uma vez e o app lembra. Quem não recebe nunca vê
câmbio na vida.

**O campo "De quem?" é o coração desta revisão.** Ele é o que faz a gestão
existir **sem existir gestão**: nenhuma tela de cadastro, nenhum formulário,
nenhum status — só um nome digitado no segundo em que ele é a coisa mais óbvia
do mundo.

### 4.3 Trabalhos — a lista

**Regra da hierarquia:** com **um** Trabalho (o caso de 99%), a aba mostra
**direto os freelas**, lista plana, e a palavra "Trabalho" nunca aparece. Com
dois ou mais (Pro), aparece o nível de cima. A hierarquia que o dono descreveu
existe no modelo desde sempre e só **se revela quando faz falta** — custo zero
pra quem não precisa, e a linha do Pro não se mexe.

```
      1 TRABALHO (grátis)                 2+ TRABALHOS (Pro)
┌──────────────────────────────┐   ┌──────────────────────────────┐
│  Trabalhos               +   │   │  Trabalhos               +   │
│                              │   │                              │
│ ┌──────────────────────────┐ │   │  DESIGN · R$ 92/h        ›   │
│ │ Gustavo                  │ │   │ ┌──────────────────────────┐ │
│ │ R$ 1.200  já recebeu     │ │   │ │ Gustavo      R$ 1.200 ▸  │ │
│ │ R$ 400 em 10/jul         │ │   │ │ Loja da Ana  R$ 2.400 ▸  │ │
│ │            [ Recebi ]    │ │   │ └──────────────────────────┘ │
│ └──────────────────────────┘ │   │                              │
│ ┌──────────────────────────┐ │   │  SOCIAL MEDIA · R$ 70/h  ›   │
│ │ Loja da Ana   todo mês   │ │   │ ┌──────────────────────────┐ │
│ │ R$ 2.400  já recebeu     │ │   │ │ Padaria      R$ 800   ▸  │ │
│ │ ⚠ esperado dia 10        │ │   │ └──────────────────────────┘ │
│ │            [ Recebi ]    │ │   │                              │
│ └──────────────────────────┘ │   │                              │
├──────────────────────────────┤   ├──────────────────────────────┤
│   ○ Início    ◉ Trabalhos    │   │   ○ Início    ◉ Trabalhos    │
└──────────────────────────────┘   └──────────────────────────────┘
```

### 4.4 Dentro de um freela — **a tela que o dono pediu literalmente**

> *"Tenho um freela com o Gustavo. Ele me paga 400 num mês, 600 no outro, 200 no
> outro — e quanto eu tive que separar em cada."*

Isso é uma tela, e ela é essa. A diferença crítica pro que existe hoje: os
recebimentos são **agrupados por mês**, não listados por data. O dono pensa em
meses; a tela tem que pensar em meses.

```
┌──────────────────────────────────┐
│  ←        Gustavo         ✎  ⋮   │
│                                  │
│ ┌──────────────────────────────┐ │
│ │  JÁ RECEBEU                  │ │
│ │  R$ 1.200                    │ │  ◄── HERÓI
│ │  guardou R$ 192 pro Leão     │ │  ◄── apoio 1
│ └──────────────────────────────┘ │
│                                  │
│  julho                           │
│    R$ 400          guardou R$ 64 │
│  junho                           │
│    R$ 600          guardou R$ 96 │
│  maio                            │
│    R$ 200          guardou R$ 32 │
│                                  │
│ ┌──────────────────────────────┐ │
│ │        Recebi de novo        │ │
│ └──────────────────────────────┘ │
│                                  │
│  Fazer uma proposta          ›   │
└──────────────────────────────────┘
```

**Escondido no ✎ (editar):** valor combinado, "ele te paga todo mês?",
data do próximo, anotações, apagar. Nada disso é pedido pra criar o freela — o
freela nasce só com um nome.

### 4.5 Todos os meses (o antigo "Guardado")

**Deixa de ser aba** e passa a ser o detalhamento do cartão do mês no Início.
Motivo: "Início" e "Guardado" são **o mesmo balde em dois zooms** — este mês e
todos os meses. Dois slots de navegação pro mesmo dado é o oposto de simples.

```
┌──────────────────────────────────┐
│  ←       Todos os meses    ⇪     │
│                                  │
│  JULHO                           │
│  entrou R$ 3.400  guardou R$ 544 │
│    Gustavo         400  →   64   │
│    Loja da Ana   2.400  →  384   │
│    Padaria         600  →   96   │
│                                  │
│  JUNHO                           │
│  entrou R$ 2.100  guardou R$ 336 │
│    Gustavo         600  →   96   │
│    Loja da Ana   1.500  →  240   │
│                                  │
│  MAIO                            │
│  entrou R$ 1.900  guardou R$ 304 │
│    …                             │
└──────────────────────────────────┘
```

**Sai daqui:** o botão "Paguei o Leão deste mês", o estado "Leão de julho: pago.
Guia quitada. Mês limpo." e os registros do tipo `das`. Ordem direta do dono:
*"NÃO é gestão de 'paguei o DAS / não paguei imposto'."* O app **conta**; não
**cobra**.

---

## 5. Mapa de telas final e o de-para

### 5.1 A hierarquia

```
                    ┌─────────────────────────────┐
   [1ª vez]         │           INÍCIO            │
   ONBOARDING ────► │  o mês · um botão · o preço │ ──► ⚙ CONFIGURAÇÕES
    (2 págs)        └──┬──────────┬──────────┬────┘         └─ backup · tema
                       │          │          │                 · apagar dados
       ┌───────────────┘          │          └──────────┐      · legal · Pro
       ▼                          ▼                     ▼
  ┌──────────┐          ┌──────────────────┐    ┌───────────────┐
  │ RECEBI   │          │ TODOS OS MESES   │    │ MEU PREÇO     │
  │ um pgto  │          │ (ex-Guardado)    │    │ = Detalhamento│
  └──────────┘          └──────────────────┘    │   editável    │
   ▲  ▲                                          └───────┬───────┘
   │  │                                                  │ refazer
   │  │        ┌──────────────────────────┐              ▼
   │  └────────┤ TRABALHOS (aba)          │      ┌───────────────┐
   │           │  1 trabalho → freelas    │      │ CALCULADORA   │
   │           │  2+        → áreas       │      │  4 passos     │
   │           └────────────┬─────────────┘      └───────┬───────┘
   │                        ▼                            ▼
   │              ┌──────────────────┐           ┌───────────────┐
   └──────────────┤ FREELA (detalhe) │           │ RESULTADO     │
      "Recebi"    │  mês a mês       │           │ → Salvar como │
                  └────────┬─────────┘           └───────────────┘
                           │ "Fazer proposta"
                           ▼
                  ┌──────────────────────────┐
                  │ ORÇAR → PROPOSTA         │  (Simulador fundido aqui)
                  │  valor → vale a pena? →  │
                  │  documento → PDF (Pro)   │
                  └──────────────────────────┘
```

**Duas abas: Início · Trabalhos.**

### 5.2 De-para

| Hoje (`lib/features/`) | Vira | Decisão |
|---|---|---|
| `onboarding/` (3 págs + modo BR/intl) | Onboarding (2 págs) | **Encolhe.** A pág. da Divisão e a pergunta BR/exterior morrem (redundante com o passo de regime). |
| `calc/` (5 passos) | Calculadora (4 passos) | **Encolhe.** Passo 5 (férias/13º) vira toggle no Detalhamento. Valor-hora ao vivo a partir do passo 3. |
| `resultado/` | Resultado + sheet "Salvar como…" + sheet "a ponte" | **Ganha o ritual.** Perde equivalências, avisos de teto/custo e o botão de proposta. |
| `painel/` | **Início** | **Vira de estado A pra B** no 1º recebimento. Perde a Divisão, o card do DAS, o Recalcular e o 2º card de ação. |
| `reserva/` | **Recebi um pagamento** | **Ganha "De quem?"** (o campo que faz a gestão existir). Regime/moeda/câmbio saem da tela e viram frase + sheet. |
| `projetos/projetos_screen` | **Trabalhos (aba)** | Renomeia; ganha o nível 1 latente; o vazio deixa de ser bloqueio. |
| `projetos/projeto_detalhe_screen` | **Freela** | **Agrupa por mês.** Perde status como conceito de primeira classe. |
| `projetos/projeto_form_screen` | Editar freela | **Deixa de ser porta de entrada.** Só alcançável do ✎. Campo obrigatório: 1 (nome). |
| `historico/` (aba Guardado) | **Todos os meses** | **Deixa de ser aba.** Empilha do cartão do mês. Perde a quitação do Leão. |
| `perfis/perfis_screen` | — | **Morre.** A lista de Trabalhos é a aba. |
| `perfis/trabalho_switcher` (sheet) | — | **Morre.** Trocar de Trabalho = tocar nele na aba. |
| `simulador/` | Passo 1 do fluxo Orçar | **Funde com a Proposta.** |
| `proposta/` | Fluxo Orçar → Proposta | Mantém (é a âncora Pro). Ganha o simulador como 1º passo. |
| `detalhe/` | **Meu preço** | Mantém e **engorda**: recebe tudo o que saiu do Início e do Resultado. É o "ver detalhamento" do dono. |
| `pro/`, `config/`, `legal/` | iguais | Mantêm. |
| `leaoPagoProvider` + entradas `tipo:'das'` | — | **Morrem.** Ordem do dono. |

**Saldo: 3 telas a menos, 1 aba a menos, 1 sheet a menos, 1 subsistema a menos**
— e uma tela nova (nenhuma): as duas "novas" (nomear, a ponte) são sheets de um
campo dentro de um fluxo que já existe.

---

## 6. A distribuição dos números, tela a tela

Regra da casa, na formulação do dono: **um número herói por tela, no máximo dois
de apoio, e todo o resto atrás de "ver detalhamento".** Se uma tela tem dois
números disputando o tamanho, ela não decidiu o que é.

| Tela | HERÓI | Apoio (máx. 2) | Escondido |
|---|---|---|---|
| **Onboarding** | *nenhum* | — | tudo |
| **Calculadora P1–P2** | *nenhum* | — | — |
| **Calculadora P3–P4** | *nenhum* | **valor-hora parcial** (topo, pequeno, vivo) | o resto |
| **Resultado** | **valor-hora** `R$ 92/h` | **% a guardar** `~16%` · **a Divisão** (barra) | valor/dia · faturamento/mês · lucro real · custos totais · provisão · alíquota · teto MEI |
| **Nomear (sheet)** | *nenhum* | valor-hora no rótulo do botão | — |
| **Início — estado A** | **valor-hora** `R$ 92/h` | renda-alvo `pra ganhar R$ 5.000/mês` | tudo o resto |
| **Início — estado B** | **entrou no mês** `R$ 3.400` | **a guardar no mês** `R$ 544` · valor-hora no chip | lucro real · custos · Divisão · alíquota · DAS · faturamento |
| **Recebi** | **quanto guardar** `R$ 64` | **sobra pra usar** `R$ 336` (barra) | % · regime · moeda · cotação · data |
| **Trabalhos — card** | **já recebeu** `R$ 1.200` | última entrada `R$ 400 em 10/jul` **ou** aviso de atraso | valor combinado · recorrência · status · anotações |
| **Trabalhos — cabeçalho de área** (Pro) | **valor-hora da área** `R$ 92/h` | — | — |
| **Freela (detalhe)** | **já recebeu** `R$ 1.200` | **guardou** `R$ 192` | valor combinado · recorrência · próximo · anotações |
| **Freela — linha do mês** | `R$ 400` | `guardou R$ 64` | regime da época · dia exato |
| **Todos os meses — mês** | **entrou** `R$ 3.400` | **guardou** `R$ 544` | — |
| **Meu preço (Detalhamento)** | **valor-hora** `R$ 92/h` | — | **aqui é onde tudo mora**, em linhas editáveis: renda + custos + provisão + imposto = faturamento ÷ horas |
| **Orçar (passo 1)** | **lucro real do projeto** `R$ 1.840` | valor-hora efetivo `R$ 61/h` + aviso se abaixo do alvo | Divisão do projeto |
| **Próximos 30 dias** (Pro) | **total a receber** `R$ 4.200` | **a reservar** `R$ 672` | linha por cliente (é o que o Pro abre) |

**Números que hoje aparecem e que eu tiro do caminho principal, nominalmente:**
`≈ R$ 736/dia` · `R$ 7.450/mês faturados` · `LUCRO REAL ESTIMADO R$ 5.000/mês`
(no Início) · `Seu DAS: R$ 76,90/mês` (no Início) · a barra da Divisão no Início ·
`~16%` na tela Recebi (vira o rodapé da barra) · o aviso de teto do MEI ·
`custos R$ 850` solto.

Nenhum deles é apagado. Todos vivem no **Meu preço**, que passa a ser a única
tela do app onde é legítimo ter muitos números — porque é a tela onde a pessoa
foi **procurar** por eles.

---

## 7. Os três momentos de maior risco de abandono

### R1 — Os passos 3, 4 e 5 da calculadora *(o penhasco da 1ª sessão)*

**Por que é risco:** são três telas seguidas de perguntas cada vez mais difíceis
(custos → regime tributário → provisão de férias) com **retorno zero até o fim**.
Quem instala um app pra ter um número não assina cinco formulários por ele. É a
métrica nº 1 de 05 §7 ("% que chega ao Resultado") e a que o próprio doc suspeita
que cai.

**O que fazer:**
1. **Valor-hora vivo no topo a partir do passo 3.** Vira ajuste, não prova.
2. **Corta o passo 5.** Provisão de férias vira toggle no Detalhamento.
3. **Todos os campos já preenchidos com defaults dignos** — nunca em branco.
   Quem só quer "continuar, continuar" chega ao Resultado com um número honesto.
4. **"Não sei qual sou eu"** no regime já existe e é a melhor coisa da
   calculadora hoje. Replicar o padrão nos custos ("estimar pra mim").

### R2 — A vala entre "salvei meu preço" e "caiu meu primeiro pagamento"

**Por que é risco:** é o maior buraco do produto e o mais invisível. A pessoa
termina a 1ª sessão satisfeita e **não tem motivo nenhum pra voltar por 2 a 4
semanas** — tempo mais que suficiente pro app sair da tela inicial e da memória.
O lembrete que existe hoje só dispara pra quem marcou `tipoContrato == mensal`,
o que é uma minoria e uma configuração que ninguém faz de propósito.

**O que fazer:**
1. **A ponte (§3.5):** terminar a 1ª sessão com um nome de cliente salvo. Custa
   um toque e transforma o app de "calculadora usada" em "lugar onde tem gente".
2. **Nudge no dia 1 de todo mês, pra todo mundo** — não só pra quem é mensal.
   "Novo mês. Recebeu alguma coisa em julho?" é verdadeiro pra 100% dos
   freelancers e é o gatilho natural do nicho (o mês é a unidade mental de quem
   vive de freela).
3. **A frase certa no fim da 1ª sessão:** não "Trabalho salvo", e sim
   *"Pronto. Quando o dinheiro cair, volta aqui — a gente separa o do Leão em 2
   toques."* Um contrato explícito sobre a próxima visita.

### R3 — A tela Recebi virar formulário

**Por que é risco:** é o **caminho de ouro** (02 §3: *"se esse fluxo não for
instantâneo, o app vira 'abri uma vez'"*) e hoje ele abre com até **11 controles
antes da resposta**: campo, 3 moedas, 5 regimes, 2 links de cotação. Perguntar
"você é MEI ou Simples?" a alguém que acabou de receber um PIX é responder a uma
emoção com uma prova de contabilidade. Foi exatamente aqui que Marina tirou **3**
e Marta tirou **6** no teste.

**O que fazer:**
1. **Regime e moeda saem da tela.** Viram a frase *"como MEI · em reais ·
   ajustar ›"*. Já são conhecidos do Trabalho — não são perguntas, são
   confirmação.
2. **O número aparece com o primeiro dígito digitado**, e a barra desenha junto.
   Nada de esperar o campo perder foco.
3. **"De quem?" é opcional de fato** — dá pra tocar Guardar sem responder. O
   recebimento entra sem dono, e o app não briga. Um campo obrigatório no
   caminho de ouro é um caminho de ouro quebrado.
4. **Câmbio nunca aparece pra quem recebe em reais.** Zero pixels gastos com uma
   feature de nicho no caminho de 90% das pessoas.

---

## 8. Onde há tela demais — as fusões e os cortes

Sete cortes concretos, do mais valioso pro menos.

**1. Aba "Guardado" → detalhamento do cartão do mês.** `−1 aba`
"Este mês" e "todos os meses" são o mesmo dado em dois zooms. Um slot de
navegação pra cada é o retrato do app que cresceu por adição.

**2. `perfis_screen` + `trabalho_switcher` + chip do herói → a aba Trabalhos.** `−1 tela, −1 sheet`
Hoje há **três superfícies** pro mesmo objeto: uma tela de gerenciar, um
bottom-sheet de trocar, e um chip que abre o sheet. Com o Trabalho sendo o nível
1 da aba, trocar de trabalho é **tocar nele**. Nem tela, nem sheet, nem chip.

**3. Simulador → passo 1 do fluxo Orçar/Proposta.** `−1 tela, −1 card no Início`
"Esse preço vale a pena?" e "manda pro cliente" são **um pensamento só**, e
separá-los cria dois destinos pra uma pergunta. Fundido: valor + horas → veredito
→ *"Manda bonito"* → documento. E o Início recupera a linha inteira pro botão que
importa.

**4. `projeto_form_screen` sai do caminho principal.** `−1 formulário obrigatório`
O freela nasce de um nome digitado na tela Recebi. O formulário de 6 campos
continua existindo atrás do ✎, pra quem quiser marcar recorrência e data — e não
atravessa mais a estrada de ninguém.

**5. Passo 5 da calculadora (férias/13º) → toggle no Detalhamento.** `−1 passo`
É a pergunta mais abstrata do fluxo, feita no pior momento (antes do número
existir), sobre um dinheiro que ela vai usar daqui a 11 meses.

**6. Onboarding 3 → 2 páginas, e morre a pergunta BR/exterior.** `−1 página, −1 decisão`
A escolha de modo é feita de novo, melhor, no passo de regime. Perguntar duas
vezes — a primeira antes de entregar qualquer coisa — é o comportamento que os
reviews punem.

**7. Todo o subsistema de quitação do imposto.** `−1 card, −1 botão, −1 estado, −1 tipo de registro`
Card do DAS no Início, botão "Paguei o Leão deste mês", o estado "Guia quitada.
Mês limpo", o `leaoPagoProvider` e os registros `tipo:'das'`. Ordem direta do
dono, e ela está certa: no minuto em que o app vira o cobrador dela, ele vira uma
obrigação — e obrigação se desinstala.

### O que eu decidi NÃO cortar (e por quê)

- **A Divisão.** Ela é o coração conceitual do produto (00, 03). Só perde o
  lugar de móvel no Início e fica onde é resposta: Resultado e Recebi.
- **A Proposta em PDF.** É a âncora de conversão Pro (05 §3, 07 §A) e a única
  feature com boca-a-boca embutido. Fica, fundida com o simulador.
- **"Próximos 30 dias" (Pro).** É o único motivo real de alguém pagar pela
  gestão. Fica na aba Trabalhos, **abaixo** da lista, e só aparece quando existe
  pelo menos uma data marcada.
- **Câmbio/multi-moeda.** Fica — mas invisível pra quem recebe em reais.
- **A hierarquia de dois níveis.** É a descrição literal do dono e já está no
  modelo. Só passa a ser **latente**: some pra quem tem um trabalho só.

---

## 9. Resumo executivo

**O que ele vê ao abrir** — na 1ª vez, uma promessa de 2 minutos; na 2ª à 4ª, o
valor-hora dele grande; da 5ª em diante, **quanto entrou este mês e quanto disso
é do Leão**, com um botão só embaixo: *Recebi um pagamento*. O mesmo cartão vira
de um pro outro sozinho, no primeiro recebimento registrado.

**Calcula primeiro** — e o **Salvar é o parto do objeto**: o botão vira "Salvar
como…", pede um nome pré-preenchido, e é aí que o Trabalho nasce. Criar o objeto
antes seria cobrar quatro atos de fé antes do primeiro retorno, e nomear uma
coisa vazia é uma prova; nomear embaixo de um R$ 92/h é uma comemoração. Um nível
abaixo vale a mesma regra invertida no tempo: **o freela nasce do primeiro
pagamento**, de um campo "De quem?" na tela Recebi — nunca de um formulário.

**Os cortes:** aba Guardado (vira detalhamento do mês) · `perfis_screen` +
`trabalho_switcher` (viram a aba Trabalhos) · Simulador (funde na Proposta) ·
`projeto_form` sai do caminho principal · passo 5 da calculadora · 1 página do
onboarding + a pergunta BR/exterior · e todo o subsistema "paguei o DAS".
**Saldo: 3 telas, 1 aba, 1 sheet e 1 subsistema a menos — nenhuma tela nova.**

---

*Relacionado: [02 Personas](../02-PERSONAS-E-JOBS.md) · [03 IA](../03-ARQUITETURA-DE-INFORMACAO.md) ·
[05 Escopo](../05-ESCOPO-E-ROADMAP.md) · [07 Proposta e Gestão](../07-PROPOSTA-E-GESTAO-DE-PROJETOS.md).*
