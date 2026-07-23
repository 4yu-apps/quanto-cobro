# 16 — Sitemap real + jornada por tipo de usuário (MEI · Simples · CPF · dólar)

> **O que é:** o mapa de telas COMO ESTÁ no código hoje (rotas reais), e a jornada
> de **cada tipo de usuário** por dentro dele — onde ele ganha, onde tem furo, onde
> dá pra cobrar, e qual o diferencial que só a gente entrega pra ele. Serve de base
> pra encaixar as duas features do [doc 15](15-FLUXO-USD-E-REGIME-AVANCADO.md) sem
> embananar os fluxos. Complementa a IA por job do [doc 03](03-ARQUITETURA-DE-INFORMACAO.md);
> aqui o corte é por **regime**, não por job.
>
> **Bases:** rotas em `app/routes.dart` · regimes em `core/model/regime.dart` +
> `core/calc/tax_tables.dart` · personas [02](02-PERSONAS-E-JOBS.md) · pesquisa
> [B](../research/raw/B-internacional-rate.md)/[C](../research/raw/C-br-mei-imposto.md).

---

## 1. Sitemap real (o que existe no código, hoje)

Rotas reais (`routes.dart`), agrupadas por função:

```
ONBOARDING (/onboarding)  ── 1ª abertura: dor + BR×exterior + privacidade + consentimento
        │
        ▼
PAINEL (/)  ◄──────────────── hub. Divisão + 3 respostas + 2 botões grandes
   ├─ CALC (/calc)  ─► RESULTADO (/resultado) ─► DETALHE (/detalhe)  "como cheguei"
   │                                                └─ imposto é UMA linha (~X% efetivo)
   ├─ ENTRADA (/entrada)  ── J2 reserva por pagamento  ◄── caminho de ouro
   ├─ SIMULADOR (/simulador)  ── J3 lucro do projeto
   ├─ TRABALHOS (/trabalhos)  ─► /trabalho, /trabalho/editar   (multi-trabalho = Pro)
   │      └─ PROPOSTA (/proposta) ─► /marca   (PDF pro cliente = Pro)
   ├─ HISTORICO (/historico)  ── reservas do mês
   ├─ AREAS (/areas)  ── perfis/áreas de preço (multi-área = Pro)
   ├─ CONFIG (/config)  ── tema · backup · apagar dados · regime · telemetria · restaurar
   │      └─ LEGAL (/legal)  ── privacidade/termos
   └─ PRO (/pro)  ── oferta, no momento de valor
```

**Onde as duas features novas encaixam (sem tela nova solta):**
- **USD** → dentro de **/entrada**: link "recebi em outra moeda" (por pagamento).
  Não é rota nova — é um estado da Entrada. Reaproveita `FxService`.
- **Regime avançado (não-MEI)** → **furar a linha de imposto** do /detalhe atual:
  toca "+ Imposto estimado (~X%)" → bottom sheet com faixa/INSS/dedução. Estende
  uma tela que já existe, não cria outra.
- **MEI teto** → cartão/linha no **/painel** ou topo da **/entrada** ("R$68,6k de
  R$81k"), com bottom sheet de detalhe. Mora perto de onde o MEI registra receita.

> **Regra pra não embananar:** nenhuma das features vira destino novo no hub. USD é
> estado da Entrada; avançado é drill do Detalhe; teto é cartão no Painel. O
> sitemap **não cresce** — ganha profundidade nos nós que já existem.

---

## 2. A tabela dos regimes (o que muda de verdade entre eles)

Do `regime.dart` + `tax_tables.dart`. Isto é o que faz a jornada de cada um ser
diferente — não é cosmético, é a mecânica fiscal:

| Regime (`RegimeId`) | Como paga | Reserva é… | O que aperta |
|---|---|---|---|
| **MEI** (`mei`) | DAS **fixo** ~R$86/mês | quase nada (boleto fixo) | **estourar o teto R$81k/ano** |
| **Autônomo CPF** (`cpf`) | carnê-leão IRPF progressivo **+ INSS** | **variável, alta** | faixa sobe rápido; INSS pesa |
| **Simples** (`simples`) | alíquota efetiva Anexo III | variável por faixa | entender a alíquota real |
| **CPF exterior** (`carneLeao`) | IRPF progressivo, **sem INSS** | variável | câmbio + carnê-leão mensal |
| **Não sei/exterior** (`intl`) | flat 25–30% (regra de bolso) | segurança | não é cálculo, é colchão |

**Leitura:** o "quanto reservar" só é uma pergunta *difícil e valiosa* pra **CPF,
carnê-leão e Simples**. Pro **MEI** o valor é trivial (fixo) — o valor dele está no
**teto**. Pro **intl** é um colchão de segurança até a pessoa saber o regime real.

---

## 3. Jornada por tipo de usuário

Para cada: **quem · caminho no app · realidade da reserva · 🕳️ furo hoje · 💰
receita · ⭐ diferencial**.

### 3.1 MEI — "Diego, o recém-MEI" (P3)
- **Caminho:** Onboarding (BR) → Calc (regime "Sou MEI") → Painel → a cada PIX,
  Entrada mostra "reserve o DAS: R$86 fixo".
- **Realidade da reserva:** trivial. O DAS não varia. O que importa é **não estourar
  R$81k/ano** — a dor real e silenciosa (multa + desenquadramento retroativo).
- **🕳️ Furo hoje:** o app trata MEI como os outros ("reserve X%"), mas pro MEI isso
  quase não faz sentido. **Não existe** acompanhamento de teto — a única coisa que o
  MEI de verdade precisa. Também não há lembrete do dia 20 (table-stakes, frente C).
- **💰 Receita:** o **rastreador de teto** é o gancho Pro natural do MEI (agrega o
  ano, projeta o estouro). PDF de orçamento também serve o MEI que fecha trabalho.
- **⭐ Diferencial:** ninguém une "quanto cobrar" + "quanto já faturei do teto" num
  app leve. Os apps de MEI (MaisMei, Qipu) são pesados, queimados por cobrança
  escondida. A gente entra limpo e com o número que ele teme (o teto) na cara.

### 3.2 Autônomo CPF — carnê-leão + INSS (dentro de "Camila"/"Diego")
- **Caminho:** Calc (regime "Autônomo CPF") → Painel → Entrada a cada recebimento →
  "reserve R$Y" (faixa progressiva + INSS embutidos).
- **Realidade da reserva:** **é aqui que o número vale ouro.** Varia com a renda do
  mês, sobe de faixa, tem INSS. Errar pra menos = malha fina + multa de 50%.
- **🕳️ Furo hoje:** o número sai certo, mas **fechado** — o usuário vê "~18% efetivo"
  e não sabe de onde veio. Sem o "por quê", a confiança fica frágil (e confiança é o
  ativo nº1 num app de imposto). É exatamente o que o **avançado** resolve.
- **💰 Receita:** o **detalhamento de imposto** (faixa aplicada, INSS, dedução) é o
  Pro mais defensável — profundidade real, não conveniência. Casa com quem tem renda
  alta o suficiente pra se preocupar com faixa.
- **⭐ Diferencial:** o carnê-leão oficial (Sicalc) é burocrático e exige gov.br. Os
  apps de carnê-leão (Leão Manso) são novos, minúsculos, iOS-first. A gente entrega o
  número mastigado **grátis** + o raio-x didático **Pro**, offline, sem login.

### 3.3 Simples Nacional (Anexo III)
- **Caminho:** Calc (regime "Tenho empresa no Simples") → mesma jornada de reserva.
- **Realidade da reserva:** alíquota efetiva por faixa do Anexo III. Variável, mas
  mais estável que carnê-leão.
- **🕳️ Furo hoje:** mesmo do CPF — alíquota efetiva mostrada como número solto, sem
  explicar a faixa. Menos aguda (a pessoa do Simples costuma ter contador), mas o
  "por quê" ainda educa. **Fator R** (que muda o anexo) não é tratado — pode ser furo
  ou escopo deliberado a decidir.
- **💰 Receita:** detalhamento Pro (mesma folha do CPF, conteúdo Anexo III). Público
  do Simples fatura mais → menos atrito com Pro.
- **⭐ Diferencial:** calculadoras web (Contabilizei, Calculadora Brasil) fazem valor-
  hora com Simples, mas **uso único, não acompanham**. A gente fecha o loop recorrente.

### 3.4 Dólar / freela-pra-gringo — "Marina" (P4)
- **Caminho:** Onboarding (marca "No exterior") → Calc (regime "CPF exterior" ou "Não
  sei") → Entrada → **"recebi em outra moeda"** → digita US$, app converte → reserva.
- **Realidade da reserva:** carnê-leão (IRPF progressivo, sem INSS) sobre o valor
  **convertido**. Renda variável + câmbio = dor tributária mais forte (persona: "o
  Leão tá comendo muito").
- **🕳️ Furo hoje:** **o maior furo do app.** Marina recebe em dólar e o app não
  aceita dólar — ela converte na mão antes de digitar. O `FxService` existe e está
  **desligado**. O regime dela existe, mas a porta de entrada não.
- **💰 Receita:** o câmbio é **grátis** (decisão do doc 15 — adoção). A receita da
  Marina vem do **PDF em USD** pro cliente gringo e de **múltiplos trabalhos** (ela
  tem vários clientes). Entra grátis pelo diferencial, paga pelo orçamento.
- **⭐ Diferencial:** **inédito.** Nenhuma ferramenta gringa trata imposto BR;
  nenhuma brasileira aceita dólar no loop de reserva. "Recebi US$500 → em reais é
  R$2.750 → como CPF-exterior, reserve R$X" não existe em lugar nenhum. É o fosso.

---

## 4. Matriz-resumo (furo · receita · diferencial por regime)

| Regime | Furo hoje | Gancho de receita | Diferencial nosso | Prioridade |
|---|---|---|---|---|
| **MEI** | sem rastreador de teto; sem lembrete dia 20 | teto (Pro) + PDF | teto leve, sem app fiscal pesado | **alta** (dor real) |
| **CPF/carnê-leão** | número de imposto fechado, sem "por quê" | detalhamento (Pro) | número mastigado grátis + raio-x offline | **alta** (número vale ouro) |
| **Simples** | alíquota sem explicação; Fator R ausente | detalhamento (Pro) | loop recorrente vs calc web de uso único | média |
| **Dólar/intl** | **app não aceita dólar** (FxService desligado) | PDF USD + multi-trabalho | único no mundo: USD-in, imposto-BR | **alta** (fosso + furo grande) |

**Furos transversais (valem pra vários):**
- **Lembrete de vencimento** (dia 20 do MEI, mensal do carnê-leão): table-stakes da
  frente C, ausente. Encosta em MEI e CPF. Decidir se entra agora.
- **Alíquota efetiva visível**: hoje aparece no /detalhe como uma linha; vale expor
  antes, no Painel/Entrada, como educação grátis (decisão aberta, doc 15 §7.5).

---

## 5. O que isso trava pra sessão de UI

1. **Nenhuma tela nova no hub.** USD = estado da Entrada; avançado = drill do
   Detalhe; teto = cartão no Painel. Confirmar que a UI respeita isso.
2. **A folha de imposto (avançado) é a MESMA** pra CPF/carnê-leão/Simples — muda só
   o conteúdo por regime. MEI tem folha própria (teto). Dois moldes de bottom sheet,
   não cinco.
3. **O default esperto do onboarding** ("exterior") liga o dólar pré-selecionado na
   Entrada — mas cada pagamento continua podendo ser BRL.
4. **Prioridade sugerida de construção:** (1) USD na Entrada — é furo + fosso + código
   já existe; (2) detalhamento CPF/Simples — é só expor; (3) MEI teto — agrega o ano;
   (4) lembrete — se decidirmos que entra.

---

## 6. Ainda em aberto (herda do doc 15 §7 + novos)
- Alíquota efetiva sempre-visível vs on-tap.
- Lembrete de vencimento: entra agora ou frente própria?
- Teto do MEI é Pro ou grátis? (dano real vs agregação de valor.)
- **Fator R do Simples:** tratar ou declarar fora de escopo?
- Múltiplas moedas no histórico: escopo do USD grátis ou já é "organização" Pro?

---

## 7. Voz de gente — dúvidas reais (varredura de fóruns/FAQ, 23/07)

> WebSearch é US-only (reddit BR não veio direto); puxei artigos-guia e FAQ
> brasileiros que espelham as dúvidas mais repetidas. Fontes no fim.

### 7.1 MEI e o teto — o achado que AFIA a feature
Não é um limite, são **dois**, com consequências diferentes — e a nossa UI de teto
tem que refletir isso, senão dá um susto errado:
- **Até 20% de excesso (faturou ≤ R$97.200):** continua MEI até dezembro, paga **DAS
  complementar** sobre o excedente em janeiro, e vira ME no ano seguinte.
- **Acima de 20% (> R$97.200):** **desenquadramento retroativo a 1º de janeiro** —
  vira Simples desde o início do ano, recolhe tudo em atraso com juros e multa.
- **Não comunicar** → Receita faz desenquadramento **de ofício**, com multa punitiva.

> 🔧 **Implicação de produto:** o rastreador de teto não é uma barra só até R$81k. São
> **três zonas**: verde (< R$81k) · amarela (R$81k–97,2k, "excesso tolerado, DAS
> complementar") · vermelha (> R$97,2k, "desenquadramento retroativo"). Isso torna a
> feature muito mais útil — e é exatamente o que os artigos explicam que ninguém
> entende. Diego não tem medo de um número; tem medo de **não saber em qual zona
> está**.

### 7.2 Dólar / carnê-leão — as três dúvidas da Marina, confirmadas
Verbatim dos guias (higlobe/Fiverr):
- **"Quando pago?"** — carnê-leão vence **último dia útil do mês seguinte** ao
  recebimento. (→ gancho pro lembrete.)
- **"Qual cotação?"** — **cotação oficial do Banco Central do dia ANTERIOR** ao
  recebimento. ⚠️ **O app usa open.er-api.com (taxa de mercado), não a PTAX do BCB.**
  Pra estimativa está ok (o selo cobre), mas pra bater com o carnê-leão real o certo
  é PTAX D-1. **Decisão de precisão pra sessão:** trocar a fonte por BCB/PTAX, ou
  manter market-rate e ser explícito ("estimativa; o oficial é a PTAX do dia anterior").
- **"Quanto reservo?"** — faixa **7,5% a 27,5%** progressiva. É o que o regime
  `carneLeao` já calcula.
- **Erro comum #1:** achar que "só declara se transferir pro Brasil" — **falso**, o
  imposto é devido onde o dinheiro estiver. (→ micro-didática no modo dólar.)
- **Erro comum #2:** omitir e cair na malha (IR anual < carnê-leão declarado).

### 7.3 Preço — a dor do Bruno/Camila, confirmada verbatim
- *"Se cobramos muito, vem o medo de perder o cliente."*
- *"Se cobramos pouco, nos comparamos com outros designers que cobram 3x mais."*
- *"Qual seria um preço justo? Como saber se cobrei muito ou pouco?"*
- → Valida o **aviso do Simulador** ("abaixo do seu alvo, cobre ~R$X") — o app que
  *defende* o freelancer é resposta direta a essa angústia. E valida a alíquota
  efetiva visível: dá um chão objetivo pra quem não tem referência.

### 7.4 Autônomo/reserva — dor silenciosa, de novo confirmada
Regra de bolso repetida ("guarde 15–30%") existe justamente porque as pessoas **não
fazem** naturalmente. A dor é desorganização/esquecimento, não falta de dinheiro
(Receita provou: um lembrete de DAS moveu +R$49M/mês). → **Lembrete deixa de ser
"nice to have": é resposta à causa-raiz.** Reforça subir o lembrete de prioridade.

### 7.5 O que a varredura muda nos docs
1. **Teto MEI vira três zonas** (não uma barra) — some no doc 15 §4.3 quando desenhar.
2. **Câmbio: decidir PTAX vs market-rate** — nova questão de precisão (§8 abaixo).
3. **Lembrete sobe de prioridade** — é causa-raiz, não enfeite. Rever se entra já.
4. Confirma tudo o mais: os furos do §3 têm voz de gente por trás, não só código.

---

## 8. Decisões — TODAS travadas (23/07/2026, com o Gabriel)

| # | Tema | Decisão |
|---|---|---|
| 1 | Alíquota efetiva | **Sempre visível SEM o termo técnico** + "o que é?". Selinho "≈12% vira imposto"; o help ensina a palavra "alíquota efetiva". |
| 2 | Lembrete | **Notificação real** (chega com app fechado), **agendamento inexato** (sem permissão de alarme exato, sem risco Play). **Frente própria**, logo depois do USD/regime — build nativo distinto, não misturar. A versão só-in-app foi descartada (não alcança quem esqueceu de abrir). |
| 3 | Teto MEI | **Alerta grátis, projeção Pro.** Saber a zona (verde/amarela/vermelha) e quanto falta = grátis (perigo real). "Nesse ritmo estoura em outubro" = Pro. |
| 4 | Câmbio | **PTAX do BCB primária + open.er-api fallback + "o que é PTAX?"**. Precisa quando dá, resiliente quando não dá, jargão morto pelo help. |
| 5 | Fator R Simples | **Tratar completo, SÓ no fluxo do Simples.** MEI/CPF/dólar nunca veem. Simples → pergunta humana ("tira pró-labore? quanto?") → calcula Fator R nos bastidores → escolhe anexo. Corrige o erro atual (app assume sempre Anexo III/barato). Precisa: tabela Anexo V + lógica + **revisitar/retestar** o cálculo. |
| 6 | Multimoeda histórico | **Registro grátis, relatório Pro.** Ver cada recebimento em USD = grátis (é o loop). "Quanto recebi em dólar no ano" = Pro. |

### 8.1 🔴 Achado que virou correção: o app subestima o Simples solo
`aliquotaEfetivaSimples` ([tax_tables.dart:141](../../lib/core/calc/tax_tables.dart#L141))
**sempre assume Anexo III** (o mais barato). Freelancer solo do Simples, sem
pró-labore ≥28% do faturamento, cai no **Anexo V (mais caro)** pelo Fator R — então
hoje o app **reserva de menos** pra ele. Num app fiscal, subestimar é o pior erro
(a pessoa guarda pouco e toma susto). A decisão 5 conserta isso.

---

## 9. Princípios de UX (as diretrizes do Gabriel, pra valer em toda tela nova)

Regras que governam o desenho das features daqui pra frente:

1. **Fácil de verdade, sem jargão na cara.** Nenhum termo técnico solto na tela.
   Quando o conceito for inevitável (PTAX, alíquota, carnê-leão, teto, Fator R),
   ele aparece com um **"o que é XXX?"** do lado → bottom-sheet de baixo pra cima,
   linguagem humana, **com exemplo**. Reusa o que já existe: `help_dot.dart` +
   `glossario.dart`.
2. **Fluxo linear e imaginável.** A pessoa consegue prever o caminho: "quero
   calcular um freela → anoto isso, isso e isso → pronto, aqui está". "Recebi um
   valor → quanto foi meu? → vem por aqui." Sem labirinto, sem decisão que trava.
   Um objetivo por tela.
3. **Sem número estourando.** Um herói por tela; o resto é apoio discreto. Números
   complexos ficam atrás de um toque ("como cheguei"), nunca despejados de uma vez.
4. **Motion que faz o app sentir vivo/rápido.** Transições com significado, número
   que conta pra cima, card que sobe. Motion de *entrada/transição*, não decoração.
5. **Skeleton só onde há espera real.** App é offline: dado local é instantâneo,
   skeleton ali seria atraso falso (ruim). O **único** lugar com skeleton/shimmer é
   a **busca de câmbio** (a única chamada de rede). No resto, motion de entrada.

> Estes cinco valem como checklist de aceite de qualquer tela nova das features
> USD, regime avançado, teto e lembrete.

---

## 10. Ainda 100% aberto (nada trava a UI)
- Nada. As seis decisões estão fechadas. O que sobra é desenho de tela — a próxima
  sessão — e o sequenciamento de build (sugestão em §5: USD → detalhamento →
  teto → Fator R/revisão do Simples → lembrete como frente própria).

---

**Fontes da varredura:**
[Contabilizei — ultrapassei o limite do MEI](https://www.contabilizei.com.br/contabilidade-online/ultrapassei-o-limite-do-mei/) ·
[InfoMoney — faturamento do MEI se ultrapassar](https://www.infomoney.com.br/minhas-financas/faturamento-do-mei-o-que-acontece-se-limite-anual-for-ultrapassado-veja-exemplos/) ·
[Higlobe — recebe em dólar como PF, IRPF](https://higlobe.com/pt-br/articles-pt/recebe-em-dolar-como-pf-saiba-como-declarar-seu-irpf-sem-erros) ·
[Fiverr — impostos do freelancer](https://help.fiverr.com/hc/pt/articles/360010561178) ·
[Fala Bondioli — em busca do duplo obrigado (precificação)](https://falabondioli.substack.com/p/em-busca-do-duplo-obrigado) ·
[UX Design BR — quanto cobrar pelo meu design](https://brasil.uxdesign.cc/quanto-cobrar-pelo-meu-design-dicas-para-freelancer-b0e926d2b35c)

---

*Próximo: sentar e desenhar a UI, com os docs 15 e 16 na mão. Nada de UI ainda —
de propósito. As decisões abertas do §8 são a pauta da sessão de design.*
