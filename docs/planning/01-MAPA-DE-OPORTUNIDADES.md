# Quanto Cobro? — Mapa de oportunidades

> Todas as oportunidades que dá pra atacar, priorizadas por **impacto × defensibilidade ×
> esforço**. Base: [pesquisa fase 1 e 2](../research/) + [sizing de mercado](../research/raw/F-mercado-sizing.md).

---

## 1. O tamanho do prato (por que vale a pena)

| Número | Valor | Fonte |
|---|---|---|
| Trabalhadores por conta própria no BR | **26,1 milhões** (2025, recorde) | IBGE/PNAD |
| MEIs (registro ativo, endereçável com CNPJ) | **~12–16 milhões** | Sinac / Sebrae |
| Informais (atuam como PF, não separam imposto) | **~38,5 milhões** | IBGE/PNAD |
| Renda média do conta-própria | **~R$ 2,7–3,0 mil/mês** (85% até 3 SM) | IPEA/PNAD |
| Mercado mobile BR | **~92,5% Android** | Statcounter |
| Freela pra gringo (contratações externas) | **+53% em 1 ano; BR é 5º do mundo** | Deel/Forbes |

**Leitura:** TAM gigante e sensível a preço (→ grátis+ads na base). O bolso pagante é o
**premium doloroso**: dev/design e **freela pra gringo** (recebe USD, carnê-leão mensal).
**Estratégia de dois públicos no mesmo app:** massa monetiza por ads; premium por Pro.

---

## 2. Oportunidades priorizadas

Escala: **Impacto** (quanto move o produto) · **Defensa** (difícil de copiar) · **Esforço**.

### 🟢 Fazer já (MVP) — alto impacto, alta defensa

| # | Oportunidade | Por quê (evidência) | Defensa | Esforço |
|---|---|---|---|---|
| O1 | **A ponte preço→reserva→lucro (a Divisão recorrente)** | ninguém liga os 3; 57% dos elogios = "resolveu+fácil" | 🟢 alta | médio |
| O2 | **Reserva por pagamento como caminho de ouro** | job recorrente inexistente no mercado; motor de hábito | 🟢 alta | baixo |
| O3 | **Contexto tributário BR certo (MEI/CPF/Simples)** | gringo chuta errado; app MEI é burocrático | 🟢 alta | médio* |
| O4 | **Confiança: offline, sem cadastro, sem pegadinha** | elimina ~20% das ★1 do mercado | 🟡 média | baixo |
| O5 | **Estabilidade + transparência de preço** | bug+cobrança = 31% das queixas | 🟡 média | contínuo |

\* O3 exige validar tabelas na Receita (pré-requisito de publicação — ver regra R5).

### 🟡 Fazer cedo (v1.1 / Pro) — monetização e retenção

| # | Oportunidade | Por quê | Tipo |
|---|---|---|---|
| O6 | **Exportar orçamento em PDF** | pedido recorrente; cara de ferramenta; âncora de conversão | Pro |
| O7 | **Backup / restore de dados** | pedido recorrente ("vou trocar de celular") | grátis (confiança) |
| O8 | **Vários perfis** (cliente × avulso) | preço varia por cliente; público profissional converte | Pro |
| O9 | **Módulo "freela pra gringo" (USD, carnê-leão)** | nicho premium, dor aguda, dispõe a pagar | Pro/nicho |
| O10 | **Lembrete de vencimento/guardar** | virou table-stakes (Receita já faz push) | grátis |

### 🔵 Futuro (v2+) — aprofundar o hábito

| # | Oportunidade | Por quê |
|---|---|---|
| O11 | **Histórico de reservas** ("quanto já guardei no mês") | fecha o loop de hábito |
| O12 | **Benchmark de mercado por senioridade/profissão** | inédito no BR (Bonsai faz lá fora); "cobro na média?" |
| O13 | **Alíquota efetiva visível** ("sua alíquota como MEI é X%") | traduz o labirinto; ideia roubada dos gringos |
| O14 | **Modificadores de preço** (urgência, cliente difícil, revisão) | responde à objeção "cada caso é um caso" |
| O15 | **Comparador antes×depois** ("quanto eu cobrava × devia") | prova de valor, gera compartilhamento |

---

## 3. Oportunidade de ASO / descoberta

- **Cluster tributário tem demanda e pouca disputa em app** (`precificação MEI`, `imposto a
  reservar`, `quanto guardar de imposto`) — é o gap defensável no ranqueamento.
- **Espaço da "pergunta" livre como marca de app**: ninguém dominou "quanto cobrar".
- **iOS é greenfield** (concorrentes diretos com 0 avaliação) — mas o mercado é **92,5%
  Android**, então **Android-first** com iOS como expansão barata.
- Título Play recomendado: `Marca: Calculadora Freela · Quanto Cobrar` (marca + keywords).

---

## 4. Onde NÃO ir (anti-oportunidades — foco vence)

- ❌ **Precificação de produto físico** (confeitaria/artesanato) — outro job, já servido; dilui.
- ❌ **Emitir DAS/DARF/nota oficial** — caro, e é a **maior fonte de ★1** do setor. Linkar o
  oficial em vez de imitar.
- ❌ **Virar ERP/gestão financeira completa** (Organizze/Mobills) — mercado grátis e lotado;
  âncora preço em zero. Nosso valor é o **específico e doloroso**, não o "controle geral".
- ❌ **Assinatura escondida / forçada / revelada tarde** — o crime do TurboTax/MEI Fácil (★1).
  Assinatura *transparente* é ok; o modelo é **híbrido** (vitalício + anual opcional), com o
  cálculo básico sempre grátis. Ver [05 §6](05-ESCOPO-E-ROADMAP.md).

---

## 5. Matriz de decisão (resumo visual)

```
      ALTO IMPACTO
          ▲
   O1 ·   │   · O2        (fazer já — núcleo)
   O3 ·   │   · O6·O9     (Pro cedo)
──────────┼──────────►  ALTA DEFENSA
   O4·O5 ·│   · O11·O12
          │   · O13·O14   (futuro)
      BAIXO IMPACTO
```

---

*Próximo: [05 — Escopo e Roadmap](05-ESCOPO-E-ROADMAP.md) transforma este mapa em versões.*
