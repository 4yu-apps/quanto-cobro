# Quanto Cobro? — Proposta pro cliente + Gestão de projetos

> Planejamento de produto/UX de duas funcionalidades e de como elas se costuram
> ao app que já existe (3 abas · Início · Guardado · Trabalhos). Base: personas
> ([02](02-PERSONAS-E-JOBS.md)), IA ([03](03-ARQUITETURA-DE-INFORMACAO.md)),
> escopo/monetização ([05](05-ESCOPO-E-ROADMAP.md)) e a pesquisa de 16,9k reviews.
> **Sem código.** Decisões tomadas, não listadas.

---

## 0. A tese: de calculadora a ferramenta de negócio (sem virar ERP)

A jornada-guia do produto é **"freelancer inseguro → freelancer confiante"**. Hoje
o app já leva o usuário de *"quanto cobro?"* (Calculadora) até *"quanto guardo?"*
(Reserva → Guardado). Isso é confiança **interna** — números que só ele vê.

As duas features pedidas fecham o arco em duas direções que faltam:

- **Proposta** leva a confiança pra **fora**: o número vira um documento que ele
  põe **na frente do cliente**. É o salto de *"me diz um número"* → *"me faz
  parecer profissional na hora H"*. É o momento em que o app deixa de ser uma
  calculadora e vira parte do **trabalho** dele.
- **Gestão** leva a confiança pro **tempo**: de *"acabei de receber"* (um evento)
  para *"tenho 10 projetos e sei de todos"* (um sistema). É o que transforma o
  app de "abri pra fazer uma conta" em "abro toda semana pra me organizar".

O fio que costura as duas — e que **defende o app de virar um Trello/ERP genérico**
(o inchaço que afunda os concorrentes, [05 §1](05-ESCOPO-E-ROADMAP.md)) — é o
**ciclo de vida do projeto ancorado na reserva**:

```
Calcular preço → PROPOSTA pro cliente → Projeto ATIVO → recebimento →
                  RESERVA (o do Leão) → Guardado → (nudge mensal) → repete
   (feature A)          (feature B)         (o coração que já existe)
```

Nada aqui é "tarefa/kanban/timesheet". Cada peça de gestão existe **porque
alimenta a reserva de imposto** — a alma do produto e o único loop que nenhum
concorrente tem ([research: reservar por pagamento não existe em ninguém](../research/SINTESE-PESQUISA-CONCORRENTES.md)).
Essa é a régua pra dizer "sim" e "não" a tudo que vier depois.

---

## A) PROPOSTA / ORÇAMENTO PRO CLIENTE

### A.1 — Job-to-be-done

> **"Preciso mandar um orçamento que me faça parecer profissional, sem parecer
> amador nem improvisado — e rápido, antes de o cliente esfriar."**

- **Persona primária — Bruno (iniciante ansioso):** o sucesso dele já é definido
  como *"sair com um número que ele confia o bastante pra mandar na proposta"*
  ([02 §P1](02-PERSONAS-E-JOBS.md)). A proposta é literalmente o último metro
  dessa jornada — e o momento de maior medo do impostor ("vão ver que sou
  amador"). Um documento limpo com a marca dele **compra confiança** que ele não
  tem.
- **Persona secundária — Camila (freela em atividade):** manda orçamento
  toda semana; valoriza *"PDF de orçamento"* explicitamente ([02 §4](02-PERSONAS-E-JOBS.md)).
  É a âncora de conversão Pro (O6, já prevista em [05 §3](05-ESCOPO-E-ROADMAP.md)).
- **Sinal de mercado:** export/compartilhar em PDF é **pedido recorrente** nos
  reviews ([análise §PDF](../research/ANALISE-QUANTITATIVA-REVIEWS.md)); apps de
  fatura/orçamento têm 500k–1M+ instalações; o teardown do PeqArt mostra
  "orçamento PDF com logo" como o degrau que vira precificação em **ferramenta de
  negócio**. Há queixa literal de review: *"não dá pra tirar em PDF nem
  compartilhar"*.

**Por que importa pro nosso app especificamente:** é o gatilho de valor que
**mais reforça a percepção de profissionalismo** (willingness-to-pay direta:
parecer bom na frente de quem paga) e o de **maior potencial de boca-a-boca** —
o cliente do freelancer vê a marca dele num doc que saiu do nosso app.

### A.2 — Onde mora na IA/navegação

**Decisão: a proposta é uma AÇÃO/fluxo, não uma tela-destino nem uma aba.** Ela
empilha acima da casca (como Reserva/Simulador). Tem **três portas de entrada**,
todas no momento psicológico certo — logo depois de o usuário *validar um preço*:

1. **Do Simulador** ("Vou orçar um projeto") — a porta principal. Ele acabou de
   confirmar que o projeto dá lucro; a próxima pergunta natural é *"então mando
   pro cliente"*. Botão no rodapé do resultado do Simulador.
2. **Do Resultado da Calculadora** — quando o preço é por hora/pacote fechado.
3. **De um Projeto** (feature B) — "gerar/reenviar proposta deste projeto". É
   aqui que A e B se encontram (§C).

**A marca do freelancer** (logo + nome + contato) mora em **Configurações →
"Minha marca"**, mas nunca é pedida de cara: na **primeira** vez que ele gera uma
proposta, um passo curto de setup aparece inline ("capriche na sua marca — só uma
vez"). Progressive disclosure: não se cobra setup de quem ainda não viu o valor.

### A.3 — Fluxo principal (passo a passo)

**Primeira vez (com setup de marca):**
1. No resultado do Simulador, toca **"Fazer proposta pro cliente"**.
2. (Só a 1ª vez) Mini-setup **"Sua marca"**: nome/negócio, logo (opcional, "pode
   pular"), 1 contato (WhatsApp ou e-mail). → "Pronto, isso fica salvo."
3. **Formulário da proposta** (curto, tudo pré-preenchido do que dá):
   - *Serviço* (título + descrição livre) — pré-preenchido em branco com dica.
   - *Valor* — já vem o número do Simulador/Calculadora; editável.
   - *Prazo de entrega* — texto livre.
   - *Validade da proposta* — default **"7 dias"** (protege o freelancer, cria
     leve urgência).
   - *Forma de pagamento* — default "PIX · 50% de sinal, 50% na entrega"
     (editável; sinal é padrão de mercado — PeqArt).
   - *Cliente* (nome) — opcional.
   - *Observações* — opcional.
4. **Pré-visualização** do documento (rola e vê exatamente o que o cliente
   receberá, com a marca dele). — **isto é grátis.**
5. Toca **"Enviar / Baixar PDF"** → *(gatilho Pro se ainda não for)* → gera o PDF
   no aparelho → abre o **share nativo** (WhatsApp/e-mail).
6. Microcopy de confiança ao fechar: *"Pronto. Isso tem cara de profissional."*

**Vezes seguintes:** pula o passo 2; e se veio de um Projeto, o formulário já
chega preenchido com serviço/valor/recorrência daquele projeto.

### A.4 — Escopo: MVP vs. depois

**MVP (o menor recorte que já entrega valor):**
- 1 template bem-desenhado (não uma galeria).
- Setup "Minha marca": nome, logo opcional, 1 contato.
- Campos: serviço, valor, prazo, validade, forma de pagamento, cliente (opc.),
  observações.
- Saída **PDF gerado no aparelho → share nativo**.
- Pré-visualização grátis; **export/compartilhar é Pro**.

**Depois (v2):**
- 2–3 templates + cor de destaque da marca.
- Itens de linha (escopo em bullets/tabela).
- Guardar histórico de propostas por projeto; marcar "aceita/recusada".
- Contrato simples de 1 página / termos.
- Compartilhar como **imagem** (preview rápido de WhatsApp) além do PDF.

**O que NÃO fazer nunca:** link hospedado da proposta (exige backend/conta e
**quebra o fosso "100% offline, sem cadastro"** — [04](04-DIFERENCIAIS-E-REGRAS.md)).
Aceite/assinatura digital rastreada também não: é outro produto.

### A.5 — Grátis vs. Pro

| Etapa | Grátis | Pro |
|---|---|---|
| Montar a proposta + **pré-visualizar** | ✅ (vê o valor inteiro) | ✅ |
| **Exportar/compartilhar o PDF** | — | ✅ **(âncora de conversão)** |
| Templates extras / cor da marca (v2) | — | ✅ |

**Por que gatear o export e não a montagem:** respeita a regra anti-★1 (*"o
preço aparece ANTES do usuário investir trabalho"*, [05 §6](05-ESCOPO-E-ROADMAP.md)) —
ele **vê** o documento pronto, entende exatamente o que compra, e a parede
aparece só na saída de alto valor. **Sem marca d'água no PDF** de propósito: um
"feito com Quanto Cobro?" no documento do freelancer envergonha a marca DELE — o
oposto do que essa feature vende. Atribuição, se existir, é **opt-in e default
OFF**.

### A.6 — A regra de ouro do conteúdo: o cliente NÃO vê os internos

O documento é **voltado pro cliente**. Ele mostra **só preço, serviço, prazo,
condições e marca**. A **Divisão, a reserva, o imposto, o custo e o lucro NUNCA
aparecem** — são a confiança interna do freelancer, não negociação do cliente.
O detalhamento por hora (`X horas × valor`) fica **oculto por default**, com um
toggle "mostrar as horas" pra quem quiser — porque cliente ancora em horas e
usa isso pra pechinchar. Preço por **valor**, não por hora exposta. (Psicologia
do freelancer inseguro: proteger ele de si mesmo.)

---

## B) GESTÃO DE PROJETOS

### B.1 — Job-to-be-done

> **"Tenho vários clientes rodando ao mesmo tempo — uns mensais, uns avulsos, um
> a cada 3 meses. Quero saber quem me paga quando, quanto já recebi de cada, e se
> tô reservando o imposto de todos — sem me perder."**

- **Persona primária — Camila (a da virada, a de maior retenção):** o modelo
  antigo a retinha mal justamente porque não dava um lugar pro *sistema* dela.
  A dor não é "preciso de um kanban"; é **ansiedade de perder o fio** e, com
  isso, não reservar → tomar susto de imposto. Essa dor é **exatamente** a alma
  do app.
- **Diego (recém-MEI):** *"paguei os boletos com multa por atraso"* — o medo é
  esquecer. Ver os recebimentos esperados e o imposto por mês mata esse medo.
- **É a feature de RETENÇÃO** (o coração), enquanto a Proposta é a de
  percepção/conversão. Juntas cobrem os dois motores do negócio.

**O enquadramento que salva o app do inchaço:** gestão aqui **não** é "gerenciar
tarefas". É um **razão leve de clientes/recebimentos pendurado no loop de
reserva**. Cada campo existe porque responde a *"quanto vem, quando, e quanto
disso é do Leão?"*.

### B.2 — Onde mora na IA/navegação (a decisão estrutural)

**Decisão: a aba "Trabalhos" EVOLUI para "Projetos". Continuam 3 abas.**

```
HOJE:      Início (hub)  ·  Guardado (imposto)  ·  Trabalhos (presets de preço)
PROPOSTO:  Início (hub)  ·  Projetos (gestão)   ·  Guardado (imposto)
```

Três razões pra evoluir a aba em vez de criar uma 4ª:

1. **Um freelancer que abre uma aba chamada "Trabalhos" espera ver os
   gigs/clientes dele — não presets de cálculo.** A aba atual surface um conceito
   interno (`Perfil`) num slot nobre. "Projetos" finalmente diz a verdade do que
   um leigo procura ali.
2. **Orçamento de abas é escasso.** 4 abas num utilitário pesa a carga cognitiva
   (Ravi: 3 é o número). E o preset de preço é **baixa frequência** (você define
   seu preço raramente — a Calculadora é "satélite", [03 §1](03-ARQUITETURA-DE-INFORMACAO.md)),
   enquanto clientes/projetos é **alta frequência** pro power user. Trocar o slot
   de baixa-freq pelo de alta-freq é a realocação certa.
3. Cada aba vira um balde mental limpo: **Início = meu preço + ações · Projetos =
   meus clientes · Guardado = meu imposto.**

**Onde vai o preset de preço (multi-`Perfil`, Pro), que hoje é a aba "Trabalhos"?**
Ele **desce pro switcher que já existe** no chip do herói do Painel
(`showTrabalhoSwitcher`) — que já troca o preset ativo — com o "Gerenciar"
levando a uma tela de presets (a atual `PerfisScreen`, agora alcançada dali +
de Configurações). Não se perde nada: só se tira um conceito de plumbing do slot
de aba e se devolve ele ao lugar de baixa frequência que merece.

> **Colisão de nomes — a armadilha a evitar:** "trabalho" (preset de preço) vs
> "projeto" (cliente) confundiria o leigo. **Mitigação:** pra 99% (1 preset,
> grátis) o preset é **invisível** — a pessoa só vê "Projetos". O conceito
> "trabalho/preço" só reaparece pro power user Pro que tem >1 preset, e aí faz
> sentido ("este projeto usa meu preço de *Freela design*"). Mantemos `Perfil`
> no código; no UI o preset é "seu preço" e o protagonista é o **Projeto**.

### B.3 — O objeto novo: `Projeto` (o que é e o que se vê)

Um **Projeto** é um cliente/engajamento. Campos:

- **Nome** (cliente ou projeto): "Loja da Ana", "Site Padaria".
- **Recorrência:** *avulso (uma vez)* · *mensal* · *trimestral* · *personalizado
  (a cada N meses)*. Herda/conversa com o `tipoContrato` que você já adicionou.
- **Valor combinado** (por ciclo).
- **Status:** um punhado só — **Orçamento** (proposta enviada) · **Ativo** ·
  **Concluído** · **Pausado**. (Nunca vira board com 12 colunas.)
- **Próximo recebimento esperado** (data) — o campo que mata a ansiedade do
  power user.
- **Preço/regime:** aponta pro preset ativo (`Perfil`) — daí sai a % de reserva.
  O imposto continua **por-pessoa**, não por-projeto (o Guardado já diz isso:
  *"o imposto do mês é um só, vale pros seus trabalhos todos"*).
- **Recebimentos:** os `ReservaEntry` do histórico, agora com `projetoId`.

**O que se vê por projeto (card na lista):** nome · status · valor · **próximo
recebimento** · **quanto já recebeu** (soma do histórico) · um selo discreto de
*"reserva em dia?"* (verde se o do Leão daquele recebimento já foi separado).
Toque abre o detalhe do projeto (recebimentos, botão "recebi", "fazer
proposta").

### B.4 — Fluxos principais

**Cadastrar/acompanhar (o setup, raro):**
1. Aba **Projetos** → "+ Novo projeto".
2. Nome → recorrência → valor → (opc.) próximo recebimento → salva.
3. Lista mostra os projetos, ordenados por **próximo recebimento** (o que importa
   primeiro).

**Registrar um recebimento (o recorrente, o ouro — 2–3 toques):**
1. No card do projeto (ou no nudge), toca **"Recebi"**.
2. Abre a **Reserva** já pré-preenchida com o valor do ciclo e o regime → mostra
   "reserve X do Leão, Y é seu" (fluxo que já existe).
3. Confirma → o recebimento entra no **Guardado** com o `projetoId` → o projeto
   avança o "próximo recebimento" (se recorrente) e atualiza "já recebeu".

**O nudge mensal (evoluído):** hoje ele dispara por `perfil.tipoContrato ==
mensal`. Passa a disparar **por projeto**: "o *Loja da Ana* (mensal) já te pagou
este mês?" — e o trimestral cutuca no ciclo dele. Fica preciso e vira o motor de
retorno do power user.

### B.5 — Escopo: MVP vs. depois

**MVP:**
- Aba **Projetos** (evolução do slot "Trabalhos"); relocação do switcher de
  preços pro chip do Painel + Config.
- Objeto `Projeto` com nome, recorrência, valor, status, próximo recebimento.
- Lista + detalhe do projeto; criar/editar/apagar.
- "Recebi" → pré-preenche a Reserva → alimenta o Guardado com `projetoId`.
- Nudge mensal **por-projeto** (evolui o que já existe).

**Depois (v2):**
- **"Próximos recebimentos"** — a agenda/previsão de caixa que soma todos os
  projetos ("nos próximos 30 dias você recebe R$ X de 4 clientes; reserve R$ Y").
  É o **surface premium** que o juggler de 10 projetos implora. **Pro.**
- Relatório por projeto; anotações; histórico de propostas anexado.
- Lembretes locais (notificação) de recebimento/vencimento.
- Regras de recorrência custom mais ricas.

### B.6 — Grátis vs. Pro

| Item | Grátis | Pro |
|---|---|---|
| Criar/acompanhar projetos (sem limite) | ✅ | ✅ |
| "Recebi" → Reserva → Guardado | ✅ | ✅ |
| Nudge mensal por-projeto | ✅ | ✅ |
| **"Próximos recebimentos"** (agenda/previsão) | — | ✅ |
| Vários **presets de preço** (multi-`Perfil`) | — | ✅ *(gate que já existe)* |
| Exportar CSV do Guardado | — | ✅ *(já existe)* |

**Decisão deliberada: NÃO capar a quantidade de projetos no grátis.** Gestão
financeira genérica é **ancorada em grátis** no BR (Organizze, Balancinho, apps
de banco — [research F](../research/raw/F-mercado-sizing.md)); capar "cadastre só
3 clientes" gera ressentimento e ★1, e não diferencia. Rastrear clientes **é o
que constrói o hábito e o dado** (o moat). A conversão vem de outro lugar: do
**power user com 10 projetos que precisa da previsão de caixa** ("Próximos
recebimentos", Pro) e da **proposta profissional** (Pro). Gateamos
**sofisticação e visão de futuro**, não o direito de existir na lista.

*(Coerência com "multi-trabalho é Pro": o gate de multiplicidade continua sendo
o **preset de preço**, um recurso avançado de precificação — não o número de
clientes.)*

---

## C) COMO AS DUAS SE CONECTAM (e como reaproveitam o que já existe)

O elo é o **ciclo de vida do projeto**, e ele reusa tudo que já foi construído:

```
 Calculadora/Simulador ──► PROPOSTA ──► "salvar como projeto" (status: Orçamento)
   (preço já existe)      (feature A)              │
                                                   ▼  cliente aceita → "Ativo"
                          nudge por-projeto ◄── Projeto (feature B)
                                  │                │  "Recebi"
                                  ▼                ▼
                             RESERVA (já existe) ──► GUARDADO (já existe)
```

- **A proposta é o nascimento de um projeto.** Ao gerar uma proposta, oferecer
  *"Salvar como projeto"* → cria um `Projeto` em status **Orçamento** com
  serviço/valor/recorrência já preenchidos. Quando o cliente aceita, um toque leva
  de **Orçamento → Ativo**. Zero re-digitação.
- **Reaproveita `tipoContrato`:** o enum mensal/avulso recém-adicionado é o
  embrião da recorrência do Projeto — estende pra incluir trimestral/personalizado.
- **Reaproveita o histórico/Guardado:** `ReservaEntry` ganha `projetoId`
  (já tem `perfilId`) — o Guardado passa a poder filtrar/creditar por projeto,
  sem tela nova. "Já recebeu" e "reserva em dia" saem daí, não de dado novo.
- **Reaproveita o nudge:** de "trabalho mensal" para "projeto mensal/trimestral"
  — mais preciso, mesmo mecanismo.
- **Reaproveita o switcher de preset:** vira a casa do multi-`Perfil` que saiu da
  aba.
- **Reaproveita a Reserva e o Simulador:** são as ferramentas de sempre, agora
  alcançáveis também **a partir do projeto** (contexto pré-preenchido).

Resultado: nenhuma das duas features é um silo. Elas **fecham o loop** que já
gira, e o app inteiro passa a contar uma história só — do primeiro *"quanto
cobro?"* ao *"tenho tudo sob controle"*.

---

## D) Riscos, armadilhas e o que NÃO fazer

1. **Virar Trello/ERP (o risco nº1).** Sem tarefas, subtarefas, kanban,
   timesheet, checklist, membros de time. Status = 4 estados, ponto. **Régua:**
   se um campo não ajuda a responder "quanto vem, quando, quanto é do Leão?", ele
   não entra. O inchaço é o que afunda os concorrentes ([05 §1](05-ESCOPO-E-ROADMAP.md)).
2. **Expor os internos na proposta.** Divisão/reserva/imposto/lucro **jamais** no
   documento do cliente. Horas ocultas por default.
3. **Quebrar o fosso offline/sem-cadastro.** Nada de link hospedado, conta ou
   nuvem pra proposta. PDF é gerado e compartilhado **no aparelho**.
4. **Marca d'água no PDF do freelancer.** Não. Envergonha a marca dele e mata o
   valor da feature.
5. **Over-gating → ★1.** Núcleo (calcular, reservar, acompanhar projetos) sempre
   grátis. Pro só nas saídas de alto valor (proposta, previsão de caixa).
6. **Colisão "trabalho" × "projeto".** Manter o preset invisível pro usuário de 1
   preset; só nomear pro power user Pro.
7. **Setup de marca na cara.** Nunca pedir logo/contato antes de a pessoa ver o
   valor — lazy prompt na 1ª proposta.
8. **Complexidade de recorrência.** 4 opções (avulso/mensal/trimestral/custom-N),
   não um motor de cron. O leigo não configura RRULE.
9. **Encher o app.** Cada tela nova precisa ganhar seu lugar. A aba nova é uma
   **troca** (Trabalhos→Projetos), não uma adição — o número de abas não cresce.

---

## E) Sequência recomendada de produto (só a ordem/prioridade)

**P0 — Proposta MVP.** Rápida, auto-contida (não depende do objeto Projeto),
âncora de conversão Pro e o maior "wow" de reframe ("virou ferramenta de
negócio"). Entra pelo Simulador/Resultado + setup "Minha marca". Front-load de
valor e receita, menor risco.

**P0 — Gestão MVP (Projetos).** A mudança estrutural de IA: Trabalhos→Projetos,
objeto `Projeto`, relocação do switcher de presets, "Recebi"→Reserva→Guardado,
nudge por-projeto. Serve a persona de maior retenção e arruma o slot de aba
esquisito.

**P1 — Integração A×B.** Proposta "salva como projeto"; projeto abre a proposta
pré-preenchida; ciclo Orçamento→Ativo→Concluído. É o que faz as duas virarem uma
história só.

**P1 — "Próximos recebimentos" (Pro).** A previsão de caixa com o do-Leão
embutido — o surface premium do power user, o motor de conversão da gestão.

**P2 — Polimento.** Templates/cor de marca na proposta; relatórios por projeto;
lembretes locais; histórico de propostas.

> **Por que Proposta antes de Gestão, se Gestão é o coração?** Porque Proposta é
> menor, monetiza na hora e independe do objeto novo — entrega valor e receita
> cedo enquanto a reestruturação de IA (maior) é feita com calma. A hook de
> integração é aditiva: entra depois sem retrabalho.

---

## F) UX writing — textos exatos propostos

**Aba / navegação**
- Rótulo da aba: **"Projetos"** (ícone: pasta/maleta — `work` já em uso serve).

**Projetos — estado vazio**
- Título: *"Seus projetos, num lugar só."*
- Apoio: *"Cliente fixo, freela avulso, aquele a cada 3 meses. Cadastre e nunca
  mais perca o fio de quem te paga quando — e de quanto é do Leão."*
- CTA: *"+ Novo projeto"*

**Projeto — card (rótulos)**
- Status: *Orçamento* · *Ativo* · *Concluído* · *Pausado*.
- Recorrência: *Uma vez* · *Todo mês* · *A cada 3 meses* · *A cada N meses*.
- Linha de recebimento: *"Próximo: 10/ago"* · *"Já recebeu R$ 4.200"*
- Selo reserva: *"Leão em dia"* / *"falta separar"*.

**Registrar recebimento**
- Botão no card: *"Recebi"*
- Ao abrir a Reserva pré-preenchida (reusa copy da Reserva).

**Nudge mensal (evoluído, por-projeto)**
- Título: *"Novo mês começou"*
- Corpo: *"O \"{nome do projeto}\" (todo mês) já te pagou? Registra pra manter
  sua reserva em dia."*
- Ação: *"Registrar agora"*

**Proposta — porta de entrada (Simulador/Resultado)**
- Botão: *"Fazer proposta pro cliente"*
- Subtexto (Simulador, quando dá lucro): *"Esse preço fecha. Manda bonito."*

**Proposta — setup de marca (1ª vez)**
- Título: *"Sua marca — só uma vez"*
- Apoio: *"Isso aparece no topo de toda proposta que você mandar. Capriche; dá
  pra mudar depois."*
- Campos: *"Seu nome ou do negócio"* · *"Sua logo (opcional)"* · *"Contato
  (WhatsApp ou e-mail)"*
- Botão pular logo: *"Pular por enquanto"*

**Proposta — formulário (labels + defaults)**
- *"O que você vai entregar"* (dica: *"Ex.: Identidade visual completa — logo,
  cores e manual de marca"*)
- *"Valor"* (pré-preenchido)
- *"Prazo de entrega"* (dica: *"Ex.: 15 dias úteis"*)
- *"Validade da proposta"* — default *"7 dias"*
- *"Forma de pagamento"* — default *"PIX · 50% de sinal, 50% na entrega"*
- *"Para (cliente)"* — opcional
- *"Observações"* — opcional
- Toggle: *"Mostrar as horas no orçamento"* — **desligado por default**

**Proposta — parede Pro (no export)**
- *"Baixar e enviar em PDF é um recurso Pro. Você já montou a proposta inteira —
  o Pro libera o envio com a sua marca, sem marca d'água."*
- CTA: *"Ver o Pro"* · secundário: *"Voltar"*

**Proposta — confirmação de valor**
- Ao voltar do share: *"Proposta enviada. Quer acompanhar como projeto?"* →
  *"Salvar como projeto"* / *"Agora não"*

**Proposta — rodapé do PDF**
- *"Proposta gerada em {data} · válida por {validade}."* (sem menção ao app, a
  não ser que o freelancer opte por incluir.)

**Microcopy de confiança (o antídoto do impostor)**
- Após gerar: *"Pronto. Isso tem cara de profissional."*
- No Simulador abaixo do alvo (já existe) permanece defendendo o preço.

**"Próximos recebimentos" (Pro, v2) — cabeçalho**
- *"Nos próximos 30 dias"* · linha: *"{cliente} · {data} · R$ {valor} — reserve
  R$ {do Leão}"* · rodapé: *"Total a receber: R$ X · a reservar: R$ Y."*

---

*Relacionado: [02 Personas](02-PERSONAS-E-JOBS.md) · [03 IA](03-ARQUITETURA-DE-INFORMACAO.md) ·
[05 Escopo/Monetização](05-ESCOPO-E-ROADMAP.md).*
