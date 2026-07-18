# Quanto Cobro? — Análise quantitativa de reviews (fase 2)

> **Data:** 2026-07-18 · **O que é:** mineração em escala das reviews reais dos
> concorrentes, categorizada por tema, para entender o mercado com número — não com
> achismo. Complementa a [síntese qualitativa (fase 1)](SINTESE-PESQUISA-CONCORRENTES.md).
> **Escopo (decidido com o Gabriel):** apps de **precificação** (nicho direto) +
> **imposto/MEI**. Amostra ampla cruzando BR·US·GB·ES·MX.

## Método & honestidade

- **Coleta:** `google-play-scraper`, até ~1.500 reviews recentes por app, 5 países.
- **Bruto capturado:** 24.414 reviews de 45 apps. Após remover ruído que a busca
  automática pescou (jogos "Impostor", app de SMS "Mei", apps de horas trabalhadas,
  tax-free de turista): **16.961 reviews limpos de 33 apps**.
- **Categorização:** cada review é classificado por **nota** (1–2★ = reclamação ·
  4–5★ = elogio · 3★ = neutro) e marcado por **tema** via léxico multilíngue
  (PT/EN/ES). É *marcação lexical* — dá o sinal quantitativo do tema, com alguma
  imprecisão de borda. Percentuais de reclamação são sobre o total de **negativos**;
  de elogio, sobre os **positivos**.
- **Viés:** 97% das reviews de imposto são BR (os grandes apps de MEI são nacionais);
  o eixo internacional entra via TurboTax/FlyFin/MyTax/Pie Tax/CloudTax.
- Dados agregados em [`data/categorization.json`](data/categorization.json) e
  [`data/inventory.csv`](data/inventory.csv); scripts em [`scripts/`](scripts/). O
  corpus bruto (24k reviews) fica local, não versionado.

---

## 1. O achado central: dois mundos opostos

| Categoria | Reviews | Nota média | % negativos | % positivos |
|---|---|---|---|---|
| **Precificação** (nicho direto) | 3.118 | **4,42★** | **11%** | **85%** |
| **Imposto / MEI** | 13.843 | **3,33★** | **40%** | 56% |

**Essa é a foto do mercado, e a tese da 4YU inteira cabe nela:**

- **Onde tem calculadora de preço, o povo AMA** (4,42★, só 11% de negativos) — mas o
  nicho é **minúsculo e mal servido** (poucos apps, quase todos de precificação de
  *produto/confeitaria*, não de freelancer de serviço).
- **Onde tem imposto/MEI, tem VOLUME e tem DOR** (3,33★, **40% de negativos**). É um
  mercado grande, disputado e **odiado** — cheio de bug, cobrança-surpresa e cadastro
  forçado.

**A oportunidade não é escolher um dos dois — é a ponte:** levar a **UX amada das
calculadoras de preço** para o **job mal servido do imposto**, sem cometer os pecados
que fazem os apps de MEI serem detestados. É exatamente o eixo estratégico→operacional
do blueprint, agora com evidência quantitativa.

---

## 2. O que o pessoal ODEIA (reclamações quantificadas)

Base: 5.829 reviews negativos (1–2★). % sobre os negativos.

| Tema | % dos negativos | Nº | Leitura |
|---|---|---|---|
| **Bug / trava / não abre** | **17,2%** | 1.003 | a reclamação nº1. App de dinheiro que trava = pânico |
| **Cobrança-surpresa / paywall** | **14,1%** | 820 | "cobraram sem avisar", "só tem suporte se pagar", "golpe" |
| Cadastro / login forçado | 5,4% | 313 | atrito com senha, gov.br, "sumiram meus dados após formatar" |
| Suporte ruim / inexistente | 4,9% | 287 | "suporte só se pagar mensalidade" |
| Anúncio intrusivo | 2,7% | 155 | "pela importância do app, anúncio atrapalha" |
| Cálculo/dado impreciso | 2,2% | 126 | boleto/código diferente do oficial, valor errado |
| Confuso / complexo | 1,9% | 108 | — |
| Confusão com app do governo | 1,4% | 83 | "pensei que era oficial" |

**Falas (as mais votadas):**
- 💸 *"Venho aqui avisar q isso é golpe... foi cobrado e não foi avisado que era taxa do aplicativo"* (👍143)
- 💸 *"Lixo de aplicativo onde você só tem suporte se pagar, mesmo que o problema seja duplicidade na cobrança do serviço no seu cartão"* (👍111)
- 🐛 *"Dá até medo de usar o cartão e não conseguir pagar porque não gera boleto, dá problema no cadastro de chave pix, trava, tudo é lento"* (👍154)
- ⚠️ *"CUIDADO! Número do código de barras gerado por este app é DIFERENTE do que consta no site da Receita"* (👍153) — **erro fiscal destrói confiança na hora**
- 🏛️ *"O governo adiou os pagamentos de DAS e esse aplicativo está dizendo que está em atraso"* (👍74)

> **31% de todas as reclamações são bug + cobrança-surpresa.** São os dois pecados
> capitais do setor. Um app que simplesmente **não trava** e **não cobra escondido**
> já larga na frente da maioria.

---

## 3. O que o pessoal AMA (elogios quantificados)

Base: 10.455 reviews positivos (4–5★). % sobre os positivos.

| Tema | % dos positivos | Nº | Leitura |
|---|---|---|---|
| **Útil / resolveu / recomendo** | **37,6%** | 3.931 | o app tira uma dor real da frente |
| **Fácil / simples / intuitivo** | **19,7%** | 2.060 | simplicidade é o elogio nº2, disparado |
| Rápido | 3,4% | 354 | resolve em segundos |
| Organiza / controle / lembrete | 1,4% | 144 | sensação de estar "em dia" |
| Grátis / sem anúncio | 0,6% | 58 | valorizado quando existe |

**Falas:**
- ⭐ *"Achei o app bastante prático e muito fácil de usar. Os desenvolvedores estão de parabéns!"* (👍113, Receitas–Quanto Cobrar)
- ⭐ *"App muito intuitivo e o melhor, sem propagandas. Amei o fluxo de caixa, isso ajuda muito quem quer começar a separar as finanças"* (👍66)
- 🧑‍💼 *"Quero expressar minha gratidão à Cristiane do 'MEI em Foco' pelo atendimento excepcional..."* (👍243) — **atenção: no MEI, atendimento humano vira 5★**. É um caminho que a gente NÃO vai seguir (não somos contabilidade), mas explica notas altas de alguns concorrentes

> **Simplicidade + resolver a dor = 57% dos elogios.** Não é "mais recurso". O povo
> ama o app que é fácil e resolve. Casa 1:1 com o princípio "uma pergunta por vez" do
> blueprint.

---

## 4. Ranking de reputação (aprender com os extremos)

**Piores (o que NÃO fazer) — minas de reclamação:**

| Nota | % neg | Reviews | App |
|---|---|---|---|
| 1,30★ | 92% | 983 | MyTax (gov. Malásia) |
| 1,91★ | 77% | 142 | Emitir Nota Fiscal Serviço MEI |
| **1,92★** | 76% | 1.600 | **MEI Fácil (Neon)** — o líder de instalações é um desastre |
| **1,95★** | 75% | 1.606 | **TurboTax** — gigante dos EUA, odiado (paywall + upsell) |
| 2,50★ | 61% | 149 | Meu MEI Digital |

**Melhores (o que copiar):**

| Nota | % neg | Reviews | App |
|---|---|---|---|
| 4,76★ | 3% | 256 | Doce Lucro – Precificação |
| 4,71★ | 4% | 1.384 | PeqArt – Precificação |
| 4,67★ | 4% | 694 | Receitas – Quanto Cobrar |
| 4,65★ | 8% | 551 | MEI Digital: DAS e Abrir MEI |
| 4,53★ | 11% | 845 | Mei em Foco (atendimento humano) |

> Os **melhores são calculadoras de preço simples** (Doce Lucro, PeqArt, Quanto
> Cobrar). Os **piores são apps fiscais** pesados, com paywall e dependência de login/gov.
> A receita é clara: **a leveza da calculadora + o job do imposto, sem o peso fiscal.**

---

## 5. Pedidos de recurso recorrentes (310 reviews)

O que os usuários pedem espontaneamente — insumo direto de backlog:
- **Backup / restaurar dados** ("caso eu formate o aparelho, não perder tudo").
- **Exportar/compartilhar em PDF** (boleto, recibo, cálculo).
- **Rodar sem cadastro/login** ("incluir vários MEIs sem login, interessante").
- **Tirar/parcelar** e **totalizações** (mundo confeitaria/PeqArt).
- **Sem anúncio no caminho crítico** ("pela importância do app, anúncio atrapalha").

---

## 6. Tradução em regras da casa para o Quanto Cobro?

**Fazer (validado por elogio):**
1. **Simplicidade acima de tudo** — é 20% dos elogios e o 2º maior. "Uma pergunta por vez" está certo.
2. **Resolver a dor de forma visível** — 38% dos elogios são "resolveu". O número-herói entrega isso.
3. **Offline / sem cadastro** — remove de uma vez os temas cadastro-forçado (5%) e perda-de-dados. E o povo pede.
4. **Backup + exportar PDF** — pedido recorrente e âncora natural de Pro (já no blueprint).

**Evitar (os pecados que geram ★1):**
1. 🔴 **Bug em app de dinheiro** — 17% das reclamações. Estabilidade é feature nº0.
2. 🔴 **Cobrança-surpresa / paywall opaco** — 14%. Preço transparente; nunca cobrar escondido; nunca esconder o resultado atrás de pagamento.
3. 🔴 **Erro fiscal** — "código diferente do da Receita" vira ★1 imediato. Validar tabelas na Receita; posicionar como **estimativa/piso**, não boleto oficial.
4. 🟡 **Anúncio no caminho crítico** — some com o resultado = quebra de confiança (regra do blueprint confirmada).
5. 🟡 **Se passar por / depender do app do governo** — confusão gera raiva. Deixar explícito que é ferramenta de planejamento, e **linkar** o oficial em vez de imitar.

---

## 7. Cruzamento com o blueprint (o que muda)

- ✅ **Reforça:** "uma pergunta por vez", número-herói, offline/sem cadastro, anúncio
  fora do resultado — tudo aparece na evidência como amado ou como dor evitável.
- 🔧 **Ajusta a ênfase:** o diferencial não é profundidade de cálculo — é **leveza +
  confiança + o job do imposto que ninguém serve bem**. O blueprint deve priorizar
  estabilidade e transparência de preço como *features de produto*, não detalhes.
- ➕ **Acrescenta ao backlog:** backup/restore e export PDF (pedidos recorrentes);
  "alíquota efetiva visível" (da fase 1) casa com o desejo de clareza fiscal.

---

## 8. O que ficou fora / a fazer

- **Categorias não mineradas** (decisão de escopo): invoice/recibo, freelance/gig
  marketplace, time-tracking. Ficam para uma fase 3 se quisermos.
- **Sub-temas do imposto** (carnê-leão × DAS × Simples) não foram separados no léxico.
- **Reviews iOS** não entraram nesta rodada (só Google Play); a App Store tem o feed
  RSS se quisermos cruzar.
- **Nota:** marcação lexical tem imprecisão de borda; para decisões finas vale reler
  os verbatims em `data/`.

---

*Fase 2 — quantitativa. 16.961 reviews, 33 apps, 5 países. Próximo: sentar com o
Gabriel, olhar os números e decidir o rumo do produto (estrutura, usabilidade, escopo).*
