# Quanto Cobro? — Proposta de produto

> **Data:** 2026-07-18 · **Base:** [UX Blueprint](../UX-Blueprint.md) · [Design System](../Design-System.md) ·
> protótipo atual · [pesquisa fase 1](../research/SINTESE-PESQUISA-CONCORRENTES.md) ·
> [pesquisa fase 2 — 16,9k reviews](../research/ANALISE-QUANTITATIVA-REVIEWS.md).
> **Status:** proposta para decisão. Define o modelo que vence antes de qualquer cor/tela.

---

## 1. A decisão em uma página

O protótipo atual é forte e o Design System é maduro. Mas o **herói do modelo atual é o
cálculo do valor-hora** — e a pesquisa mostra que esse é um uso **raro e estratégico**
(coisa de quem está começando ou revisando preço a cada muitos meses). Isso limita o
alcance: pega bem o iniciante ansioso, mas **não retém** quem já trabalha.

**A virada proposta:** manter tudo que existe, mas **promover a assinatura "A Divisão"
de recurso visual a coração do produto**. O app deixa de ser "a calculadora que você abre
uma vez" e vira **"o app que mostra pra onde vai cada real que você recebe — toda vez"**.

- O **cálculo do valor-hora** continua existindo, mas como **setup estratégico** (feito
  no onboarding, revisado raramente).
- O **uso recorrente** — "recebi um pagamento → reserve isto, isto é lucro, isto é custo"
  — vira o **caminho de ouro**, o que traz o usuário de volta e constrói hábito.

Isso não joga fora nada do trabalho feito: o blueprint já previa os dois tools recorrentes
como protagonistas do Painel; a proposta só **inverte a ênfase** e assume a Divisão como a
promessa central. É uma correção de foco fundamentada em dados, não um recomeço.

---

## 2. Por que essa virada (a evidência)

Da [fase 2](../research/ANALISE-QUANTITATIVA-REVIEWS.md), 16.961 reviews reais:

> ⚠️ **CORREÇÃO (19/07/2026) — leia antes de usar a primeira linha da tabela.**
> O 4,42★ da categoria "precificação" **não é do nosso público**. Auditando o
> `inventory.csv`, os 11 apps desse balde são de **precificação de PRODUTO**:
> PeqArt (artesãos), Receitas – Quanto Cobrar (confeitaria), Doce Lucro, Craft
> Pricing Calculator, Precificação Impressão 3D. O único de hora de serviço é
> o *Time rate calculator*, com **5 reviews**.
>
> Precificar um bolo (custo de material + margem) é um trabalho diferente de
> precificar a própria hora (renda desejada + custo de vida + imposto). O
> [02](02-PERSONAS-E-JOBS.md) inclusive declara o artesão como anti-persona.
>
> **O que sobrevive:** o formato calculadora funciona, e ninguém consolidou o
> nicho. **O que NÃO se pode mais afirmar:** que "o nosso povo ama" — não há
> amostra do nosso povo. O balde `freelance` do inventário é quase todo
> marketplace (Fiverr, 99Freelas) e crédito (Zippi), não ferramenta de preço.
>
> Consequência prática registrada em [08](08-PLANO-OFICIAL.md): o comparável de
> preço muda, e a validação com usuário real vira mais urgente que mais análise.

| Sinal | Número | O que decide |
|---|---|---|
| Calculadora de preço é **amada** ⚠️ | 4,42★ · 11% neg | ⚠️ ver correção acima — amostra é de precificação de produto, não de hora |
| ...mas o **nicho é oco** | ~2,5k reviews totais | ninguém consolidou; e calc pura **não retém** (fase 1: melhor app gringo, 100+ instalações) |
| Imposto/MEI tem **volume e dor** | 13,8k reviews · 3,33★ · 40% neg | mercado grande, disputado e **odiado** — brecha aberta |
| A **ponte não existe** | 0 concorrentes | ninguém liga preço → reserva → lucro. É a nossa espinha |
| O que o povo **ama** | 57% dos elogios = "resolveu" + "fácil" | simplicidade + resolver a dor, não "mais recurso" |
| O que o povo **odeia** | 31% das queixas = bug + cobrança-surpresa | os dois pecados a nunca cometer |

**Leitura:** a calculadora amada + o job do imposto mal servido, unidos numa experiência
simples e confiável = espaço que ninguém ocupa. A Divisão é exatamente o que **materializa
essa ponte** numa linguagem visual que o usuário aprende uma vez e usa sempre.

---

## 3. O produto em uma frase (posicionamento)

> **Para** o freelancer/autônomo brasileiro que precifica no chute e se assusta com imposto,
> **o Quanto Cobro?** é o app de bolso que mostra **quanto cobrar, quanto guardar e quanto
> sobra** — e reparte cada pagamento na hora, em português de gente, 100% offline.
> **Diferente** das calculadoras rasas (que cospem um número sem contexto) e dos apps de MEI
> (cheios de bug, cadastro e cobrança escondida), ele **mostra a anatomia do seu dinheiro**
> com honestidade calma, sem cadastro e sem pegadinha.

**Tagline (marketing):** *"Pare de trabalhar de graça."* · **Assinatura funcional:**
*"Quanto cobrar, quanto guardar, quanto sobra."*

---

## 4. Quem o app pega — e quem não pega (alcance)

Você intuiu certo que o modelo atual "não pega 100%". Mapeando o alcance real:

| Segmento | Dor dominante | O modelo atual pega? | A virada pega? |
|---|---|---|---|
| **Iniciante ansioso** (vai virar freela) | "não sei quanto cobrar" | ✅ sim (calc) | ✅ sim (calc no onboarding) |
| **Freela em atividade** (já cobra) | "será que tô no lucro? e o imposto?" | ⚠️ fraco (calc é raro) | ✅ **sim** (Divisão recorrente) |
| **Recém-MEI / formalizou** | "quanto guardar pro DAS?" | ⚠️ parcial | ✅ sim (reserva + regime) |
| **Freela pra gringo** (recebe USD) | "carnê-leão come demais, esqueci de guardar" | ⚠️ parcial (modo intl) | ✅ sim (reserva intl recorrente) |
| **Precificador de produto** (confeitaria etc.) | "quanto vendo?" | ❌ não (é outro job) | ❌ não — **fora de escopo, de propósito** |

> **Decisão de escopo:** NÃO perseguir o mundo de precificação de **produto físico**
> (confeitaria/artesanato) — é o único nicho de precificação com tração hoje (PeqArt, Doce
> Lucro), mas é **outro job** (custo de matéria-prima, markup de varejo). Diluiria o foco.
> Nós somos de **serviço/tempo**. Foco vence.

---

## 5. Por que vence (os cinco motivos)

1. **Ocupa a ponte vazia** — preço → reserva → lucro num app só. Nenhum concorrente faz.
2. **Rouba a simplicidade amada** e evita os pecados odiados (bug, cobrança-surpresa,
   cadastro forçado) — 31% das queixas do mercado desaparecem só por não cometê-las.
3. **Contexto tributário BR feito certo** — onde o gringo chuta 25–30% (errado pro MEI) e o
   app de MEI é burocrático. Falar MEI/CPF/Simples em português é defensável.
4. **Confiança como fosso barato** — offline, sem cadastro, sem se passar por app do governo.
   O mercado está queimado exatamente nisso.
5. **A Divisão como âncora anti-clone** — qualquer um cospe um número; só nós mostramos a
   **anatomia** do número, e isso vira hábito a cada pagamento.

---

## 6. Modelo de negócio (resumo — detalhe em [05](05-ESCOPO-E-ROADMAP.md))

- **Núcleo grátis pra sempre** (calculadora + Divisão + reserva básica) — motor de volume e
  boca-a-boca, coerente com o público Android de orçamento apertado.
- **Pro freemium híbrido e transparente** — o usuário **escolhe**: compra única vitalícia
  (pra quem odeia assinatura) OU anual/mensal (pra quem prefere). O mercado não odeia
  "assinatura"; odeia assinatura **escondida e revelada tarde**. Desbloqueia: PDF de orçamento,
  vários perfis, modo avançado por regime, módulo "freela pra gringo", remover anúncios.
- **Ads é secundário** — no BR rende centavos; o **Pro é o motor de receita**.
- O **PDF de orçamento** é a âncora de conversão mais forte (cara de ferramenta de trabalho).
- *Preços, benchmarks e regras anti-★1 da monetização: [05](05-ESCOPO-E-ROADMAP.md).*

---

## 7. O que muda no que já existe (impacto no protótipo)

Nada é descartado; muda a **ênfase e a hierarquia**:

- **Painel:** deixa de ser "card-herói do valor-hora + tools embaixo" e passa a dar **peso
  igual ou maior à Divisão e à ação "Recebi um pagamento"** (o uso recorrente).
- **Onboarding:** posiciona o cálculo do valor-hora como "vamos te configurar uma vez", não
  como a função-título.
- **Novo no backlog** (pedidos recorrentes da fase 2): **backup/restore** e **exportar PDF**
  sobem de prioridade; **histórico de reservas** entra como gancho de hábito (v2).
- **Regras da casa** (anti-★1): estabilidade e transparência de preço viram requisitos de
  produto, não detalhes — ver [04](04-DIFERENCIAIS-E-REGRAS.md).

Os detalhes de tela estão em [03 — Arquitetura de Informação](03-ARQUITETURA-DE-INFORMACAO.md).

---

*Próximo: valide esta proposta. Os documentos 01–05 detalham oportunidades, personas,
estrutura de telas, diferenciais e escopo. Cor/layout só depois de tudo isso fechado.*
