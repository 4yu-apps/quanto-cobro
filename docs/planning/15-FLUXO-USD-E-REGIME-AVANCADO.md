# 15 — Fluxo: módulo freela-pra-gringo (USD) e modo avançado por regime

> **O que é este doc:** o pensamento ANTES da UI. As duas features que a tela Pro
> lista como "chegando" (`pro_screen.dart` → `_chegando`). Aqui eu abro as duas,
> cruzo com a pesquisa de mercado e as personas, decido a linha grátis×Pro, e
> desenho o FLUXO — pra quem vai ter e pra quem não vai. **Não é spec de UI.** A
> UI a gente senta e desenha depois, com isto na mão.
>
> **Fontes que sustentam cada decisão daqui:**
> [`02-PERSONAS-E-JOBS`](02-PERSONAS-E-JOBS.md) (P3 Diego/MEI · P4 Marina/gringo),
> [`research/raw/B-internacional-rate`](../research/raw/B-internacional-rate.md),
> [`research/raw/C-br-mei-imposto`](../research/raw/C-br-mei-imposto.md),
> [`research/ANALISE-QUANTITATIVA-REVIEWS`](../research/ANALISE-QUANTITATIVA-REVIEWS.md).

---

## 0. TL;DR — a recomendação, com as decisões já tomadas

> **DECIDIDO com o Gabriel (23/07/2026)** — travado, não é mais hipótese:
> 1. **Câmbio automático é GRÁTIS.** Digitar em USD e converter pela cotação do
>    dia é do núcleo. Consequência: o **loop USD inteiro fica grátis** (converte +
>    reserva). USD vira **diferencial grátis de adoção** — Marina entra sem pagar,
>    vira Pro depois pelo PDF/múltiplos trabalhos.
> 2. **Entrada USD = opção A:** link "recebi em outra moeda" **por pagamento**, não
>    um modo global. A resposta "exterior" do onboarding vira default esperto.
> 3. **Detalhamento = bottom sheet** (folha de baixo), não tela cheia. Opt-in,
>    descartável, número continua herói.
> 4. **MEI avançado = rastreador de teto PRÓPRIO** (faturado no ano vs R$81k), não
>    detalhamento de faixa — porque MEI não tem faixa. Enquadrado como **checagem
>    de limite fiscal, não controle financeiro** (o app não é finanças).

Regra que restou governando o resto:

- **O número de reserva é sempre grátis.** Paywall no resultado do loop J2 é o
  pecado nº2 do mercado (14% das reclamações). Nunca esconder "quanto guardar".
- **Regime avançado:** a **alíquota efetiva** aparece grátis (isca de educação e
  diferenciação — "sua alíquota como MEI é X%"). O **detalhamento item a item**
  (faixa IRPF, INSS, deduções, gross-up) é a profundidade Pro — na bottom sheet.
- **O que falta de código é assimétrico:** USD precisa ligar o `FxService` (que já
  existe) numa entrada por pagamento; regime avançado precisa **expor** o que o
  motor já calcula; MEI teto precisa **somar o faturamento do ano** (dado já existe
  no histórico — é agregação, não cálculo novo).

---

## 1. Estado real hoje (medido no código, não no doc)

### 1.1 Módulo freela-pra-gringo (USD)
| Peça | Estado |
|---|---|
| Regime `intl` (reserva flat 25–30%) | ✅ selecionável hoje (`regime.dart`) |
| Regime `carneLeao` (IRPF progressivo, **sem INSS**) | ✅ selecionável hoje |
| Onboarding captura "No exterior" | ✅ `onboarding_screen.dart:272` |
| Câmbio (`FxService`, offline-first, open.er-api.com) | ✅ existe, testado |
| **Câmbio ligado em alguma tela** | ❌ **zero chamadas** fora de `providers.dart` |
| Digitar recebimento em USD e converter | ❌ não existe — hoje Marina converte na mão e digita BRL |

**Tradução:** o *imposto* do freela-pra-gringo está pronto e no ar. O que falta é
o **câmbio na entrada** — a ponte "recebi US$500 → em reais é R$Y → reserve R$Z".

### 1.2 Modo avançado por regime
| Peça | Estado |
|---|---|
| Motor: `impostoMensal`, `aliquotaEfetiva` por regime | ✅ `calc_engine.dart` |
| Faixas IRPF progressivas + dedução | ✅ `tax_tables.dart` (`FaixaIrpf`) |
| INSS (teto 2026), DAS MEI, Anexo III Simples | ✅ `tax_tables.dart` |
| Gross-up (cobre o imposto no preço) | ✅ `computeValorHora` |
| **Usuário VÊ o detalhamento** | ❌ vê só "reserve R$Y" + regime como frase |

**Tradução:** o motor já faz faixas, INSS e deduções. Falta **mostrar**. É trabalho
de *exposição*, não de cálculo.

---

## 2. O que a pesquisa diz sobre cada frente

### 2.1 USD / internacional (frente B + persona P4 Marina)
- **Nicho mobile gringo é oco:** o melhor app (FreelaCalc, 4.9★) tem ~100 instalações.
  "A calculadora pura não retém nem monetiza — todos viraram isca de outro produto."
  → Se a gente fizer USD, tem que ser **dentro do loop recorrente**, não como
  calculadora avulsa.
- **O buraco brasileiro é total:** nenhuma ferramenta gringa trata carnê-leão/INSS/
  Fator R. Quem "trata imposto" chuta 25–30% genérico (errado pro BR) ou calcula o
  sistema US literal (inútil aqui). **Marina recebe em USD mas paga imposto BR** —
  esse cruzamento não existe pronto em lugar nenhum.
- **Roubar dos gringos (frente B §6):** "effective tax rate como output visível" e
  "stop undercharging" como tom. Alíquota efetiva visível "vira ouro no BR".
- **P4 Marina** (`02` §2): recebe em dólar via Fiverr/Deel/Wise, dor = "o Leão tá
  comendo muito", quer "reservar certo em modo internacional, com moeda". Job
  primário = **J2 (reserva), modo intl**. Sucesso = "recebe em dólar e já sabe, em
  segundos, quanto é dela".

### 2.2 Regime / imposto avançado (frente C + persona P3 Diego)
- **Dor silenciosa, real:** ninguém reclama de "reserva" em review porque o produto
  que a resolveria mal existe. A dor aparece na consequência: multa de 50% do
  carnê-leão, DAS complementar retroativo do MEI que estoura teto, +R$49M/mês de
  arrecadação quando a Receita passou a mandar **um lembrete**.
- **Número mastigado > planilha (frente C §5):** "o usuário quer *um número*, não
  uma planilha de regime." → O avançado é **opcional, escondido atrás de um toque**,
  nunca o default.
- **Erro fiscal destrói confiança na hora (análise reviews §2):** "código diferente
  do da Receita" = ★1 imediato. → Todo detalhamento tem que vir com o selo de
  **estimativa**, nunca como valor oficial.
- **P3 Diego** (recém-MEI): quer "entender o impacto do regime sem jargão". **Não**
  quer virar contador. O avançado serve o Diego que *pergunta* "por que esse valor?",
  não empurra pra quem não perguntou.
- **Nuance por regime** (o avançado não é igual pra todos):
  - **MEI:** DAS é fixo (~R$86/mês), não %. O "avançado" aqui é **teto anual (R$81k)
    e quanto falta pra estourar**, não faixa de imposto.
  - **CPF / carnê-leão:** aqui sim há faixa progressiva + INSS + dedução — é o
    regime onde o detalhamento tem mais o que mostrar.
  - **Simples:** alíquota efetiva por faixa do Anexo III.

---

## 3. O princípio que decide grátis × Pro

Uma regra, tirada direto da análise de reviews, resolve 90% das dúvidas:

> **O JOB é grátis. A PROFUNDIDADE e a CONVENIÊNCIA são Pro.**
> Nunca esconder o resultado do loop de reserva atrás de pagamento (pecado nº2,
> 14% das reclamações). Cobrar pelo que aprofunda ou poupa trabalho — nunca pelo
> que a promessa do app diz entregar.

Aplicando:

| Feature | Grátis (o job) | Pro (profundidade / conveniência) |
|---|---|---|
| **USD** | **Tudo do loop:** digita em USD, o app converte pela cotação do dia e reserva. Alíquota efetiva do regime intl/carnê-leão visível. | Só o que encosta: **PDF de orçamento** em USD, **múltiplos trabalhos**. Não há Pro *dentro* do loop USD. |
| **Regime avançado** | O número da reserva + **a alíquota efetiva visível** ("como MEI: X%") + o selo de estimativa. | **O detalhamento item a item** (bottom sheet): faixa IRPF aplicada, INSS, dedução, gross-up passo a passo. Para MEI: o **rastreador de teto**. |

**Por que essa linha e não outra:**
- Não paywalla nenhuma persona pra fora do núcleo. Marina (P4) reserva em dólar
  grátis — de propósito: o nicho gringo é pouco atendido e grátis puxa instalação.
  Diego (P3) vê sua alíquota grátis; o que ele paga é o raio-x completo.
- Casa com "cobrar é seguro no nosso nicho, anunciar não" (`ads.dart`: paywall dói
  5,8% vs média 14,1% no nicho de precificação). O Pro fica em cima de
  conveniência/profundidade (PDF, múltiplos trabalhos, detalhamento) — não da dor.
- **USD grátis é aposta de adoção, não de receita:** Marina entra pelo diferencial
  (converte + reserva sem pagar) e converte pra Pro pelo PDF quando vai mandar
  orçamento pro cliente gringo. O upsell existe, só não está no câmbio.

---

## 4. Os fluxos

Notação: 🆓 = grátis · 💜 = Pro · ⛔→💜 = gate (com caminho grátis ao lado).

### 4.1 USD — o fluxo (grátis pra todos; opção A, por pagamento)
```
Painel → "Recebi um pagamento" → tela de Entrada
   → toca em "Recebi em outra moeda"        🆓
       (default esperto: se marcou "exterior" no onboarding, o dólar já vem
        pré-selecionado — mas cada pagamento pode ser BRL ou USD, à vontade)
       → escolhe moeda (USD/EUR/…) + digita o valor em USD
       → app busca cotação (FxService, offline-first)
          · online:  "US$ 500 ≈ R$ 2.750 (cotação de hoje, 1 USD = 5,50)"
          · offline: usa última cotação salva, marca "cotação de <data>" (stale)
       → segue o loop normal: Divisão (lucro · reserva · custo)
          usando o regime intl/carnê-leão que ela já escolheu
   → "Guardar"  (registro fica em BRL, com nota da moeda de origem + taxa usada)
```
Pontos de projeto:
- **Por pagamento, não modo global (decisão A):** a vida da Marina é mista (cliente
  BR em real + cliente gringo em dólar). O link por recebimento respeita isso; um
  "modo internacional" travaria quem tem os dois. O onboarding só pré-seleciona.
- A cotação **nunca** é a estrela — linha de apoio embaixo do valor. O herói
  continua "reserve R$Z".
- Registro guardado em **BRL** (moeda base do imposto), com `moedaOrigem` e `taxa`
  pra rastreabilidade e histórico.
- `stale` **visível e honesto** ("cotação de terça") — esconder câmbio velho vira
  "valor errado" = ★1.
- **Onde o Pro aparece nesse fluxo:** só no fim, se ela quiser **mandar orçamento
  em PDF** pro cliente gringo. O loop de reserva é 100% grátis.

### 4.2 Regime avançado (não-MEI) — CPF · carnê-leão · Simples
```
Entrada/Resultado:  "Reserve R$ 340  ·  como Autônomo · 12,4% efetivo"   🆓
   → toca em "como cheguei nesse número"
       · Pro:    💜  bottom sheet sobe com o detalhamento:
                     base R$ X → faixa IRPF 15% − dedução R$ Y = IRPF R$ …
                     + INSS R$ … = imposto R$ …  → efetivo Z%
                     (cada linha: selo "estimativa, confira na Receita" + link)
       · grátis: ⛔→💜  bottom sheet curta:
                     "O passo a passo — faixa, INSS, dedução — é do Pro.
                      O valor que você guarda continua grátis, sempre."
                     [Ver o Pro]   [Fechar]
```
A **alíquota efetiva fica grátis** de propósito: educa e diferencia (frente B), e é
a isca honesta que faz o Diego querer o raio-x.

### 4.3 MEI avançado — rastreador de teto (não é detalhamento de faixa)
MEI não tem faixa progressiva: o DAS é boleto fixo (~R$86/mês). Detalhar "faixa
IRPF" pro MEI seria errado. O avançado do MEI é **outra coisa** — a dor real dele
(P3: "medo de estourar o teto").
```
Entrada/Resultado (MEI):  "Reserve o DAS: R$ 86 fixo · vence dia 20"   🆓
   → toca em "como estou no teto"
       · Pro:    💜  bottom sheet:
                     Faturou R$ 68.600 dos R$ 81.000 este ano
                     [████████████░░░]  faltam R$ 12.400
                     Nesse ritmo, encosta no teto ~outubro
       · grátis: ⛔→💜  "O acompanhamento do teto do MEI é do Pro.
                          O DAS do mês e o lembrete continuam grátis."
                         [Ver o Pro]   [Fechar]
```
⚠️ **Escopo (a preocupação do Gabriel):** isto NÃO é controle financeiro. É uma
checagem de **limite fiscal** — só soma o que já entrou no ano e mostra a distância
do teto. Sem categoria de gasto, sem meta, sem gráfico de fluxo. Um número e uma
barra. Se começar a virar "app de finanças", passou do escopo.

---

## 5. Como isso aparece pra quem não vai ter (resumo transversal)

O usuário grátis precisa sentir três coisas, nunca uma parede:
1. **O núcleo funciona inteiro.** Reserva, divisão, valor-hora, regime, **conversão
   de dólar** — tudo grátis, pra toda persona. Marina converte e reserva; Diego
   reserva. O app não "quebra" sem Pro.
2. **O gate está no lugar certo:** dentro do fluxo, no momento em que a profundidade
   apareceria (o "como cheguei", o detalhamento) — nunca antes de deixar usar. E
   sempre com o caminho grátis ao lado ("o valor continua grátis, sempre").
3. **O grátis já entrega um sinal do Pro:** a alíquota efetiva visível, o regime
   certo aplicado, o dólar convertido. Prova competência antes de pedir dinheiro —
   o oposto do paywall opaco que o mercado odeia.

Anti-padrões que a pesquisa manda evitar (viram ★1):
- ❌ Esconder o número de reserva atrás do Pro (pecado nº2, 14%).
- ❌ Cotação velha sem avisar / número que não bate (erro fiscal = ★1 na hora).
- ❌ Gate como parede antes do fluxo ("assine pra usar").
- ❌ Jargão empurrado (o avançado é opt-in, nunca o default — "número mastigado").

---

## 6. O que falta de código (dimensiona o trabalho, não implementa)

**USD (o maior dos dois — precisa de fluxo novo):**
- Ligar `FxService` numa entrada de recebimento em moeda estrangeira.
- Campo de moeda + valor; estado de cotação (fresca/stale/indisponível).
- Persistir `moedaOrigem` + `taxa` no registro (modelo `Entrada`/`Trabalho`).
- Gate Pro no link "outra moeda"; caminho grátis (BRL manual) intacto.

**Regime avançado não-MEI (menor — é exposição):**
- Bottom sheet read-only que lê o que `calc_engine`/`tax_tables` já produzem.
- Expor `aliquotaEfetiva` no resultado (grátis); detalhamento na folha atrás do gate.
- Copy do selo estimativa + link Receita por regime.

**MEI teto (agregação nova, mas dado já existe):**
- Somar faturamento do ano corrente (do histórico de recebimentos).
- Barra de progresso vs R$81k + projeção simples de quando encosta.
- Bottom sheet atrás do gate. **Sem** categoria/meta/gráfico — só limite fiscal.

**Comum:**
- Gate reutilizável (a folha "isso é Pro, o núcleo continua grátis").
- Quando USD entrar: sai de `_chegando` (é grátis, vira parte do fluxo, não item de
  venda). Detalhamento/teto entram na lista de valor do Pro.

---

## 7. Decisões — travadas e ainda abertas

**✅ Travadas (23/07/2026, com o Gabriel):**
1. Câmbio automático → **grátis**. Loop USD inteiro grátis.
2. Entrada USD → **opção A** (link por pagamento; onboarding pré-seleciona).
3. Detalhamento → **bottom sheet**, opt-in.
4. MEI avançado → **rastreador de teto próprio**, escopo "limite fiscal, não finanças".

**🔲 Ainda abertas (pra sessão de UI):**
5. **Alíquota efetiva grátis:** aparece sempre, ou só quando a pessoa toca? (Inclino
   a sempre — é barato e educa. Confirmar.)
6. **Lembrete de vencimento** (table-stakes da frente C) — entra junto com o teto do
   MEI ou é frente própria? Encosta no Diego, mas não é destas duas features.
7. **Selo Pro no MEI-teto:** o rastreador de teto é Pro (como o detalhamento) ou
   grátis (por ser "segurança", não "profundidade")? Argumento pra grátis: estourar
   o teto é dano real, não conveniência. Argumento pra Pro: é agregação/valor extra.
   **A decidir na sessão.**

---

*Próximo (nesta sessão, já pedido): sitemap + arquitetura de informação com os
fluxos por tipo de usuário (MEI · Simples · CPF · dólar) — furos, oportunidade de
receita e diferencial de cada — em doc próprio. Depois, varredura de fóruns
(dúvidas frequentes reais). Só então, sentar e desenhar a UI. Nada de UI ainda.*
