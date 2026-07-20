# Quanto Cobro? — Tese, categoria e fronteira

> **Autor:** Tomás Reinhardt (dono de produto, software vertical para quem trabalha sozinho)
> **Data:** 2026-07-19 · **Pedido:** reler TODA a pesquisa de usuário e dizer o que ela
> realmente diz, antes da correção de rota.
> **Base:** os 16.961 reviews de `docs/research/data/`(cruzados por mim, não só os resumos),
> as 7 frentes em `docs/research/raw/`, os docs de planejamento 00–07 e o código em `lib/`.
> **Regra deste documento:** toda afirmação forte tem número, citação ou arquivo. Onde a
> pesquisa não responde, está escrito que não responde. Opinião minha vem marcada
> **julgamento:**.

---

## 0. Cinco coisas que a pesquisa diz e que os resumos não dizem

Antes de responder as perguntas, o que apareceu quando abri os dados brutos em vez de ler
o `.md`. Isso muda a leitura de tudo que vem depois.

**(a) O "4,42★ das calculadoras de preço" não é do nosso público.**
O bucket `PRICING` (3.118 reviews, 4,42★, 11% neg) é composto de **11 apps**, e nenhum é de
freelancer de serviço. São: PeqArt, Receitas–Quanto Cobrar, PrecifiCAR (preço de *veículo*,
tabela FIPE), Craft Pricing Calculator, Doce Lucro, PrecificAção, Calcular Preço de Venda,
Lucratividade, Precificador, Time rate calculator e Precificação Impressão 3D
(`data/inventory.csv`, `bucket=pricing`; seleção confirmada em `scripts/categorize.py`).
São confeitaria, artesanato e varejo. O `02-PERSONAS-E-JOBS.md` declara esse público
**anti-persona** ("fora de escopo, de propósito"). Ou seja: **a evidência-âncora da virada do
`00-PROPOSTA-DE-PRODUTO.md` mede a satisfação de um público que nós decidimos não servir.**
Não invalida o dado — invalida usá-lo como prova sobre nós.

**(b) "Organizar/controlar" é o elogio mais raro do corpus inteiro.**

| Tema de elogio | GERAL (n=10.455 pos) | PRICING (n=2.645) | TAX_MEI (n=7.810) |
|---|---|---|---|
| Útil / resolveu | **3.931 · 37,6%** | 1.215 · 45,9% | 2.716 · 34,8% |
| Fácil / simples | **2.060 · 19,7%** | 662 · 25,0% | 1.398 · 17,9% |
| Rápido | 354 · 3,4% | 46 · 1,7% | 308 · 3,9% |
| **Organiza / controle / lembrete** | **144 · 1,4%** | 74 · 2,8% | 70 · 0,9% |
| Grátis / sem anúncio | 58 · 0,6% | 24 · 0,9% | 34 · 0,4% |

Fonte: `data/categorization.json`, cruzado por mim. **"Fácil" é elogiado 14× mais que
"organizado".** Em 16.961 reviews, 144 pessoas elogiaram um app por organizar a vida delas.
Esse é o número mais importante deste documento.

**(c) O nosso nicho tem um perfil de reclamação diferente do mercado geral.**

| Reclamação (% dos negativos) | GERAL | **PRICING** | TAX_MEI |
|---|---|---|---|
| Bug / trava | 17,2% | **21,2%** ← a maior | 17,0% |
| Cobrança-surpresa / paywall | 14,1% | **5,8%** | 14,6% |
| **Cadastro forçado** | 5,4% | **9,9%** ← a 2ª | 5,1% |
| Anúncio | 2,7% | **6,7%** ← a 3ª | 2,4% |
| Suporte ruim | 4,9% | 1,2% | 5,2% |

Fonte: `data/categorization.json`. Leitura: no mundo de precificação, os pecados são
**bug, cadastro e anúncio** — não paywall. O paywall é dor do mundo MEI/fiscal (onde o app
cobra por serviço que o governo dá de graça). Isso importa pra calibrar onde gastar
paranoia: nosso risco nº1 de ★1 é **travar**, não cobrar.

**(d) "O mercado de imposto/MEI é odiado" é um artefato da amostra.**
Os 3,33★ do bucket TAX_MEI são puxados por 5 desastres que somam **4.480 dos 13.843
reviews (32%)**, com média ~1,80★: MEI Fácil (1.600 · 1,92★), TurboTax (1.606 · 1,95★),
MyTax/Malásia (983 · 1,30★), Emitir NF (142 · 1,91★), Meu MEI Digital (149 · 2,50★)
(`ANALISE-QUANTITATIVA-REVIEWS.md §4`). Tirando os cinco, os 9.363 reviews restantes ficam
em **≈4,06★** *(cálculo meu: (13.843×3,33 − 4.480×1,80) ÷ 9.363)*. E as notas vitalícias da
Play dos apps BR de MEI são altas: **MEI (oficial) 4,85★ com 306.056 avaliações e 10M+
instalações**, MaisMei 4,81★/156k, DAS MEI 4,74★, MEI Gratis 4,74★, MEI Digital 4,73★,
Mei em Foco 4,65★ (`data/inventory.csv`). Dos cinco desastres, **dois são estrangeiros** e
**um é um banco** (MEI Fácil/Neon, cujo problema foi migração de conta, não imposto).
**Não existe "brecha aberta por ódio" no imposto.** Existe um app oficial grátis, 4,85★,
com 10 milhões de instalações no slot vizinho.

**(e) A categoria de "documento pro cliente" nunca foi minerada — e é gigante.**
`ANALISE §8` registra que invoice/recibo ficou **fora do escopo** da mineração. Mas o
inventário tem **51 apps** nesse bucket, e eles são grandes e amados: Invoice Simple 5M+
**4,88★**, Fatura e Recibo 5M+ 4,56★, Recibo de Pagamento PDF Fácil 500k+ **4,90★**,
Gerador Recibo 100k+ 4,76★, Recibo para Clientes PDF 100k+ 4,83★, Invoice Fly 1M+ 4,75★
(`data/inventory.csv`). Isso é relevante justamente porque a **proposta em PDF** foi
construída sem que essa vizinhança fosse olhada. Volto nisso no §5.

---

## 1. O trabalho que a pessoa contratou o app pra fazer

### O trabalho principal (o que tem evidência de sobra)

> **"Um cliente está esperando minha resposta. Preciso dizer um número que eu consiga
> defender — sem passar vergonha por cima nem trabalhar de graça por baixo."**

Três características que definem a categoria, e todas vêm da evidência:

1. **Tem prazo e é um evento, não um estado.** O gatilho é sempre "me pediram um orçamento" /
   "vou mandar proposta hoje". Nunca "é terça-feira".
2. **A ansiedade não é aritmética, é de legitimidade.** A pessoa quase sempre já tem *um*
   número; ela não confia nele. *"Cobrei 6k do serviço... mostrei pros meus chefes e eles
   falaram que cobrariam 50k. Tomei um puta de um preju"* (142 upvotes, 80 comentários —
   `raw/D §DOR 1(b)`). *"720 reais por 40 horas"* → *"é uma piada de mau gosto"* (`raw/D`).
   *"Meu maior erro foi subestimar o valor do meu trabalho, cobrando apenas R$30 por artigo"*
   (`raw/D`).
3. **É um rito de passagem coletivo.** As respostas na thread: *"Bem vindo ao clube"*,
   *"Evento canônico. Semana que vem tua carteirinha de dev chega por correio"* (`raw/D`).
   Isso é ouro de marketing e é sinal de que a dor é universal no público.

`raw/D` é literal: precificação é *"provavelmente a dor mais discutida sobre freela no
Reddit BR"*.

### O concorrente real: não é app. É a conta de padaria e uma aba do Google.

A pesquisa é inequívoca aqui, e é a melhor notícia do dossiê:

| Concorrente | Evidência | Tração |
|---|---|---|
| **A conta mental** ("salário-hora × 2, +25–50% fora de horário, +100% fim de semana") | `raw/D §objeção 5`: *"Vários usuários já têm o próprio método mental"*; a gíria documentada é literalmente **"conta de padaria"** | ~100% do público |
| **Uma busca no Google → tabela de SEO** | FreelaSemCrise, freelanceronline, brfreelas, 99freelas publicam "tabela quanto cobrar 2026" (`raw/D §sinal de mercado`) | domina a query |
| **Calculadora web de uso único** | 99freelas (4 campos, sem imposto), calculadorabrasil (a mais profunda, e é web) (`raw/A`) | uso único, sem retorno |
| **Perguntar pro colega no WhatsApp/Reddit** | as próprias threads de `raw/D` são isso | — |
| Apps concorrentes diretos | **iOS: Pricemy, Freelance Reality, freelancalc, Kyrum, Freelo — todos com 0 avaliação.** Play: FreelaCalc 100+, B20 10+, aleckrh 1.000+ (`raw/A`, `raw/B`) | **irrelevante** |

**Não existe titular a derrubar neste nicho.** Existe um hábito a substituir. Isso muda
duas coisas: (1) o adversário do produto é o *improviso*, e improviso é grátis, instantâneo
e não pede cadastro — então nosso produto precisa ser mais rápido que improvisar, não mais
completo; (2) **o gargalo do nicho é distribuição, não recurso.** FreelaCalc é 4,9★ com
100 instalações (`raw/B §1`). Ninguém perdeu esse mercado por falta de feature; perderam por
ninguém achar o app.

### O trabalho secundário (real, mas com evidência muito mais fraca)

> **"Não me deixa tomar susto com o imposto."**

Real, com consequência de dinheiro concreta: multa isolada de **50%** sobre o carnê-leão não
recolhido; *"paguei os boletos gerados, com as multas por atraso"*; *"o Leão tá comendo muito
do que ganho... 714,10 é incabível pra mim"* (`raw/D §DOR 2`, `raw/C`). E o dado mais forte
de todos: o push de vencimento do app da Receita subiu pagamento em dia **+9%** e arrecadação
**+16%/mês (~R$49M)** (`raw/C`).

**Mas — e isso precisa ser dito com todas as letras — essa dor não tem um único verbatim de
review em 16.961 reviews.** Três frentes independentes registram isso:
- `raw/A`: *"Tese 2 — NÃO VERIFICADO / lacuna de evidência... é a hipótese menos comprovada."*
- `raw/C`: *"não achei um review dizendo textualmente 'tomei susto porque não guardei'."*
- `SINTESE §2`: *"Validada, porém silenciosa. Não aparece em review de app."*

Hoje a pessoa resolve isso com: nada, um contador, ou uma regra de bolso ("guardo 20%").

**Julgamento:** a dor de imposto é real e vale ser servida — mas o que a evidência apoia é
**um lembrete e um número mastigado**, que é exatamente o que a Receita provou funcionar. Ela
**não** apoia um livro-caixa. Reserva-como-cálculo tem evidência; reserva-como-contabilidade
não tem nenhuma.

---

## 2. Dores ranqueadas — dor real × pedido de feature

Regra da tabela: **pedido é sintoma**; a coluna da direita é a causa.

| # | Dor real | Força da evidência | O pedido que ela vira | A causa (o que atacar) |
|---|---|---|---|---|
| 1 | **"Cobrei barato e me arrependi"** | ★★★★★ — thread de 142 upvotes, verbatims em dev/design/foto/redação, "evento canônico" (`raw/D`) | "mais campos", "modificadores", "benchmark" | **Falta de referência externa**, não de fórmula. A pessoa já tem um número; ela não tem autoridade pra defendê-lo. |
| 2 | **"Não sei se sobra alguma coisa"** (custos invisíveis) | ★★★★☆ — *"tive prejuízo até usar o app"* (Peqart ★5); *"parei de ter prejuízo"*; gringos: 30–50% de undercharge por esquecer imposto + 30–40% de horas não-faturáveis (`raw/A`, `raw/B`) | "incluir depreciação, energia, rateio de despesas", "cronômetro" | Trata receita como lucro porque o custo é invisível. Didática > campos. |
| 3 | **App trava / é lento** | ★★★★★ — **21,2% dos negativos do bucket precificação** (a maior lá), 17,2% no geral | — | Execução pura. |
| 4 | **"Me obrigaram a criar conta"** | ★★★★☆ — **9,9% dos negativos do bucket precificação** (a 2ª maior). *"Só usa se cadastrar o e-mail pra ficar recebendo propaganda. Sem chance!"* (`raw/A`) | *"pode incluir vários MEIs numa tela rápida sem cadastro de login, interessante"* (👍257 — o pedido mais votado do corpus) | É o nosso fosso, e é de graça. |
| 5 | **"Vou trocar de celular e perder tudo"** | ★★★☆☆ — só 0,3% dos negativos, **mas é o pedido nº1 dos apps de precificação**: *"seria interessante poder salvar os dados (backup) caso precisasse formatar o aparelho"* (👍143, Receitas–Quanto Cobrar) | "backup", "sincronizar entre celulares" | Dado local sem porta de saída vira ansiedade. Barato de resolver. |
| 6 | **"Cobraram escondido"** | ★★★★★ no mercado geral (14,1%) — **★★☆☆☆ no nosso nicho (5,8%)** | — | Execução/política. Importante, mas não é o nosso campo de batalha. |
| 7 | **Susto de imposto** | ★★☆☆☆ — **zero verbatim de review**; validado só por comunidade (2 posts), multa de 50% e o +9% da Receita | "lembrete", "quanto guardar" | Esquecimento e desorganização. Remédio testado: **lembrete**. |
| 8 | **"Preciso parecer profissional na hora H"** | ★★★★☆ — *"perdi projetos simplesmente por insegurança... medo de como enviar propostas"* (`raw/D`); *"não dá pra tirar o boleto em pdf nem compartilhar"* (👍257); PeqArt usa "orçamento PDF com logo" como o degrau que vira ferramenta de negócio (`raw/G`) | "exportar PDF", "compartilhar" | Job real — **mas já servido à exaustão** (51 apps de fatura/recibo, vários 1M–10M+ com 4,5–4,9★). |
| 9 | **"Perdi o fio de quem me paga quando"** | ☆☆☆☆☆ — **nenhuma evidência no corpus.** organiza_controle = 1,4% dos elogios. Origem: uma persona de teste interno (Camila, nota 4/10) | "gestão de projetos", "previsão de caixa" | **É pedido de feature sem dor de mercado documentada por trás.** Ver §5. |

**A leitura de conjunto que importa:** os pedidos mais votados do nosso nicho — backup,
exportar/compartilhar PDF, rodar sem login — são todos sobre **tirar a resposta do app** e
**não perder a resposta**. Nenhum é sobre morar mais tempo dentro do app. Isso é um sinal de
categoria, não uma lista de backlog.

---

## 3. Onde os concorrentes MAIS acertam (e por que funciona)

| O que acertam | Quem | Número | Por que funciona |
|---|---|---|---|
| **Um job só, resolvido até o fim** | Receitas–Quanto Cobrar | Play **4,73★** (1.091 aval.), 100.000+ inst.; iOS 4,89★ (314). App de **6,3 MB**. IAP **único** de R$12,90/29,90 (`inventory.csv`, `raw/A`, `raw/G`) | O teardown descreve como *"o mais focado: 1 job (custo→preço) bem resolvido"*. Menos conceitos = menos chance de errar = 4,7★. |
| **Idem** | Doce Lucro | **4,92★** (788 aval.), 50.000+ | — |
| **Auto-recalc como gancho de retenção** | Receitas, Doce Lucro, PeqArt | `raw/G §Padrão dos melhores`: muda o preço de 1 insumo → **todas** as receitas recalculam | **Retenção sem módulo de gestão.** A pessoa volta porque o *modelo de preço dela* mora ali e precisa de ajuste — não porque ela precisa dar baixa em recebimento. É o único padrão de retenção validado no nicho, e é o que nós não copiamos. |
| **Expandir dentro do mesmo job** | PeqArt | 4,75★ (3.185 aval.), 100.000+ — o mais instalado do bucket, **e o mais amplo** (orçamento PDF, catálogo, CRM, fluxo de caixa) | Contra-exemplo honesto à minha própria tese: dá pra expandir e ganhar. Mas note *no que*: artesã **vende produto**, então estoque/pedido/catálogo **é o job dela**. Não é escopo extra; é o mesmo trabalho, mais fundo. |
| **Offline + dado local** | FreelaCalc | 100% offline, histórico local, exporta imagem | `raw/G`: *"barato de manter e difícil de gerar 1-estrela"*. |
| **Didática embutida** | Harvest, calculadorabrasil, GetHoldings | Harvest pré-preenche **60% de horas faturáveis** com explicação; calculadorabrasil: *"Ninguém produz 8h por dia"* (`raw/B`, `raw/A`) | Não pede pro usuário adivinhar o parâmetro difícil — dá o default e ensina. |
| **Alíquota efetiva como saída visível** | iOS Freelance Rate Calculator | mostra o *effective tax rate* (`raw/B §6.3`) | Transforma labirinto em um número que ancora. Barato e diferencia do "chute 30%". |
| **Referência de mercado** | Bonsai Rate Explorer; extensão Chrome (percentil + script de negociação) | banco de rates por skill/experiência/geografia (`raw/B §2`) | **Ataca a causa da dor nº1** (falta de legitimidade), não o sintoma. **Não existe pro Brasil.** |
| **Atendimento humano** | Mei em Foco | 4,65★; o elogio mais votado do corpus inteiro é um agradecimento nominal a uma atendente (👍243) | Funciona e não é caminho nosso — não somos contabilidade. Vale registrar que é assim que se faz 5★ nesse mercado, pra não invejarmos nota alheia por motivo errado. |

---

## 4. Onde MAIS erram — e se é execução ou categoria

A distinção importa porque **erro de execução é oportunidade barata** (basta não cometer);
**erro de categoria é aviso** (não repita a decisão que os levou lá).

| Erro | Tamanho | Tipo | O que fazemos com a informação |
|---|---|---|---|
| **Travar / lentidão** | 17,2% geral · **21,2% no nosso bucket** | **Execução** | Estabilidade é feature nº0. Já é a regra R1. Confirmada e agravada: no nosso nicho é a maior de todas. |
| **Cobrança-surpresa / paywall opaco** | 14,1% (820) | **Execução** (política de preço) | TurboTax é o manual: 1,95★, 75% neg, condenado pela FTC — o crime é revelar o preço **depois** do trabalho investido (`raw/G §1B`). Regra R2 já cobre. |
| **Cadastro forçado** | 5,4% · **9,9% no nosso bucket** | **Execução** | É onde o contraste é mais barato e mais visível pra nós. |
| **Suporte só pra quem paga** | 4,9% (287) | **Categoria** | MaisMei/Qipu/Mei em Foco vendem **serviço** (regularização a ~R$149,90), então o suporte vira produto pago. Nós não temos esse erro porque não somos dessa categoria — e também não temos o 5★ de 243 votos que vem dele. Trade-off, não vitória. |
| **MEI Fácil / Neon: 2,91★ vitalício com 10M+ instalações; 1,92★ e 76% neg na amostra recente** | o maior desastre do corpus | **CATEGORIA — e é o nosso espelho** | Começou como utilitário do MEI e virou **conta bancária**. O que quebrou não foi cálculo: foi migração de conta, saldo preso, usuário sem acesso ao próprio dinheiro (`raw/G §1B`). É a história completa de uma ferramenta que atravessou a fronteira da própria categoria e morreu do outro lado. |
| **Apreço: R$400/ano à vista, iOS 3,47★ (102 aval.)** | o pior do bucket de precificação | **CATEGORIA + preço** | *"na versão grátis não dá para usar nada"*, *"restringiram demais a quantidade... e o valor anual para PRO não parcela"* (`raw/A`). Um app de precificação que virou gestão e passou a **precisar cobrar como ERP**. Enquanto isso, os focados do mesmo bucket estão em 4,73–4,92★. **Este é o precedente exato do que a correção de rota está prestes a fazer com "gestão = tier pago".** |
| **Emitir guia oficial** | `raw/C §5`: *"é onde os concorrentes têm bugs e reclamação"*; erro fiscal vira ★1 imediato (*"código de barras DIFERENTE do que consta no site da Receita"*, 👍153) | **Categoria** | Nunca entrar. Linkar o oficial. Regra R4/R5, confirmadas. |
| **Confundir-se com o app do governo** | 1,4% (83) — mas é o tema dominante das ★1 de MaisMei/MEI Digital | **Categoria** | Reforço: o app oficial **MEI** é 4,85★ com 10M+ instalações. Não competir de frente com ele. |

---

## 5. Onde NÓS acertamos — e onde estamos diluindo a tese

### O que está certo, e vale defender

1. **Offline, sem cadastro, sem pegadinha.** É o fosso mais barato que existe e ele endereça
   a 2ª maior reclamação do nosso bucket (9,9%) e o pedido mais votado do corpus (👍257).
2. **A Divisão.** É a coisa mais bem-feita do produto conceitualmente, porque **é um conceito
   só que carrega a tese inteira** e reaparece em todas as telas. É exatamente o oposto de
   "esconder complexidade num menu". Mantém.
3. **Regras da casa R1–R7 escritas como requisito de produto**, com o % de queixa ao lado.
   Poucos times fazem isso. Não é burocracia — é o que evita rediscutir cada decisão.
4. **Recusar precificação de produto físico** (`02`, anti-persona) — foco correto, mesmo
   sendo o único subnicho com tração. Foi um "não" bem dado.
5. **Recusar a aba "Recebidos" e tirar "Leão" do app.** Os dois são a mesma intuição, e é a
   intuição certa: **o nome anuncia o modelo mental.** Guarde essa régua, ela vai ser útil.

### Onde estamos diluindo — sem cortesia

**(A) O custo em conceitos triplicou.** Simples de verdade é ter menos *conceitos*, não menos
botões. Inventário do que o app hoje pede pra pessoa aprender (`lib/core/model/`):
valor-hora · trabalho/perfil · regime (5 opções) · custos · provisão · a Divisão · reserva ·
Guardado · projeto (status ×4, recorrência ×4) · recebimento · proposta (11 campos) ·
marca · moeda/câmbio. **13 conceitos** — o núcleo original tinha ~5.

E o preço disso já apareceu medido: no teste de 8 personas, **as duas piores notas foram
Camila 4/10 (gestão recorrente) e Marina 3/10 (moeda estrangeira)** — os dois blocos de
conceito mais novos (`docs/superpowers/plans/2026-07-19-melhorias-personas.md`). Média 6,4.
Não é coincidência: é o custo de conceito aparecendo como número.

**(B) Onde foram as semanas.** Linhas de código por feature (`lib/features/`):

| Feature | LOC | |
|---|---|---|
| **projetos** | 1.229 | ← construído por último |
| **proposta** | 1.108 | ← construído por último |
| calc | 1.061 | ← *"o objetivo principal do app"* |
| reserva | 818 | |
| painel · resultado · histórico · simulador | 565 · 521 · 502 · 420 | |

Projetos + Proposta = **2.337 LOC**, mais que o dobro da calculadora. O objetivo principal
declarado é hoje **~13% do código de features**. LOC não mede qualidade — mede pra onde a
atenção foi.

**(C) Gestão de projetos: DILUI.** Sem rodeio, e com o número na mão:

- **`organiza_controle` = 144 de 10.455 elogios (1,4%)** no corpus inteiro; 0,9% no bucket
  fiscal. As pessoas não elogiam apps por organizá-las.
- **A dor não aparece em nenhum review.** Ela veio de uma persona de teste interno.
  Persona de teste é hipótese; 16.961 reviews são evidência. Nós tratamos a hipótese como se
  fosse a evidência.
- **Gestão financeira no BR é ancorada em grátis:** Organizze, Balancinho ("100% grátis"),
  apps de banco, e o app oficial do MEI que já emite DAS e já manda push (`raw/F §4`;
  `inventory.csv`: MEI oficial 4,85★, 10M+). Entrar aí é entrar num mercado onde o preço de
  referência é zero e o titular tem 10 milhões de instalações.
- **Custou o slot de aba do meio**, que é o imóvel mais caro do app. O diagnóstico do `07 §B.2`
  estava certo (presets de preço não merecem uma aba); a conclusão não. A correção de um slot
  mal usado é **devolver o slot**, não preenchê-lo com algo maior.

*Auditando meu próprio viés (sou conservador demais e já barrei coisa boa por medo de
inchaço): aqui é **rigor, não medo.** Eu tenho o número — 1,4% — e tenho a ausência de
verbatim. Se o número fosse 15% eu diria o contrário.*

**(D) Proposta em PDF: NÃO dilui a tese — mas não é fosso, e precisa ser congelada.**

A favor (é o último metro do job): *"perdi projetos simplesmente por insegurança... medo de
como enviar propostas"* (`raw/D`); PeqArt mostra que "orçamento PDF com logo" é o degrau que
transforma precificação em ferramenta de negócio (`raw/G`); "exportar/compartilhar em PDF" é
pedido recorrente (`ANALISE §5`).

Contra (o que ninguém olhou): a mineração **excluiu invoice/recibo do escopo**
(`ANALISE §8`) — e é justamente a vizinhança dessa feature. O inventário mostra **51 apps**
lá, vários com **1M–10M+ instalações e 4,5–4,9★**, grátis. Nós seríamos o 52º, e a nossa
versão é objetivamente mais pobre que a deles em tudo que não seja o número que veio da
nossa calculadora.

**Julgamento:** manter, porque é a **saída** do cálculo e a âncora de conversão mais plausível
— mas exatamente do tamanho que tem hoje. **No minuto em que ela ganhar uma lista de
propostas, um status "aceita/recusada" ou um cadastro de cliente, ela deixou de ser a saída
do nosso app e virou um app de fatura ruim.** Isso é regra, está no §6.

*Auditando meu viés outra vez (subestimo deleite e estética): aqui eu **não** vou barrar.
Um documento bonito com a marca da pessoa é o único momento em que o produto dela encosta no
cliente dela — é a coisa de maior potencial de boca-a-boca do app inteiro. Barrar isso seria
medo, não rigor. Pela mesma razão, a trilha de redesign premium **não é decoração**: "fácil"
é 19,7% dos elogios do mercado e a percepção de "fácil" é produzida por clareza visual. Num
nicho onde o melhor app tem 100 instalações, parecer um produto de verdade **é** distribuição.*

**(E) Câmbio/FX: caso limítrofe.** A favor: `raw/F §3` é o material mais forte do dossiê sobre
**disposição a pagar** — exportação de serviços US$51,8 bi (2024), Brasil 5º no ranking Deel,
+53% de contratação remota estrangeira, carnê-leão mensal obrigatório de 7,5–27,5% com
conversão pela cotação do dia. Contra: virou um subsistema (moeda, serviço de cotação, cache,
banner de "cotação velha", permissão INTERNET, override manual) pra servir a persona que tirou
**3/10**. **Julgamento:** "recebi em dólar, converta e me diga quanto reservar" é **um regime
a mais dentro da calculadora** — isso entra. Um **subsistema de câmbio** com estado próprio é
outra coisa. Reduzir ao regime; manter a cotação como um campo com default e edição manual.

**(F) A contradição interna que ninguém notou.** O `00-PROPOSTA-DE-PRODUTO.md` justifica a
virada dizendo que "a calculadora é uso raro" e cita como prova que "calc pura não retém —
melhor app gringo, 100+ instalações". Duas correções:
- FreelaCalc tem 100 instalações porque **ninguém o acha** (é 4,9★ — o problema é ASO, não
  retenção). Concluir "calculadora não retém" a partir de um app mal distribuído é ler o
  gráfico errado.
- No mesmo dado, apps que **são** calculadoras focadas batem 50k–100k+ instalações com
  4,73–4,92★ (Doce Lucro, Receitas). **A pesquisa não mostra que calculadora não retém.
  Ela mostra que calculadora mal distribuída não é encontrada.**

---

## 6. A fronteira do produto — escrita como regra aplicável

Uma fronteira só serve se conseguir recusar uma feature daqui a seis meses **sem rediscutir a
estratégia**. Estas quatro perguntas fazem isso. A feature precisa passar em **todas**.

### A frase de fronteira

> **O Quanto Cobro? decide preços. Ele não administra negócios.**
> Tudo que responde **"quanto?"** entra. Tudo que responde **"e aí, como foi?"** fica de fora.

### Teste 1 — A regra do app frio *(a mais poderosa; use primeiro)*

> **Se, pra ter valor, a feature exigir que a pessoa já tenha alimentado o app antes, ela é
> gestão — e gestão não é nosso.**

Uma calculadora funciona **frio**: instalo agora, uso agora, saio com a resposta. Uma
ferramenta de gestão só funciona pra quem vem alimentando ela há três meses — ou seja, só
serve o público que já está retido, que é sempre o menor. Aplicação:

| Feature | Precisa de alimentação prévia? | Veredito |
|---|---|---|
| Calcular valor-hora | não | ✅ entra |
| Modificadores de preço (urgência, cliente difícil) | não | ✅ entra |
| Benchmark de mercado por profissão | não | ✅ entra |
| Proposta em PDF | não (usa o número que acabou de sair) | ✅ entra |
| "Quanto reservar deste pagamento" | não | ✅ entra |
| Lembrete mensal | não | ✅ entra |
| Lista de projetos com status | **sim** | ❌ fica de fora |
| "Próximos recebimentos" / previsão de caixa | **sim** | ❌ fica de fora |
| Proposta marcada como aceita/recusada | **sim** | ❌ fica de fora |
| Guardado como razão filtrável | **sim** | ⚠️ reduzir a recibo mínimo |

### Teste 2 — Onde isso é feito hoje?

> **Se hoje a pessoa faz isso na cabeça, num rascunho ou num print — é nosso: a gente
> substitui o improviso. Se ela já faz num app grátis e bom (banco, planilha, app oficial do
> MEI 4,85★/10M+), não é nosso — a gente perde de graça.**

Essa é a pergunta jobs-to-be-done literal, e ela sozinha teria barrado a aba Projetos.

### Teste 3 — Orçamento de conceitos

> **Teto: 7 conceitos na cabeça do usuário. Feature que traz um conceito novo precisa dizer
> qual conceito SAI no lugar.**

Estamos em 13. Não é uma meta simbólica: "fácil/simples" é 19,7% dos elogios do mercado e
25,0% no nosso bucket — é o segundo maior motivo pelo qual as pessoas amam um app nessa
categoria, e é o que estamos gastando.

### Teste 4 — O gate de Pro não pode ser quantidade

> **Cobra-se por uma resposta melhor, nunca por permissão de existir.** Nada de "só 1
> trabalho", "só 3 clientes", "só 5 cálculos".

Evidência: Apreço (*"restringiram demais a quantidade... na versão grátis não dá para usar
nada"* → 3,47★) e TurboTax (paywall revelado depois do trabalho investido → 1,95★, FTC).
O próprio `07 §B.6` já chegou nessa conclusão pra projetos ("não capar quantidade") — mas o
app mantém **multi-trabalho como gate Pro**, que é gate de quantidade. Incoerência interna a
resolver: o Pro deve gatear **saídas de alto valor** (PDF, benchmark, modo avançado por
regime), não multiplicidade.

---

## 7. Veredicto sobre a correção de rota

**"Calculadora primeiro, gestão como extra pago" — a pesquisa APOIA, com uma ressalva grave
na segunda metade da frase.**

**O que a pesquisa apoia (com força):**
1. A dor de precificação é a mais documentada do dossiê — thread canônica de 142 upvotes,
   verbatims em cinco profissões, e `raw/D` a chama de *"provavelmente a dor mais discutida
   sobre freela no Reddit BR"*. A dor de reserva tem **zero verbatim de review** em 16.961.
2. O mercado elogia **"fácil" (19,7%) + "resolveu" (37,6%) = 57%** e elogia "organiza" em
   **1,4%**. A tese "menos, mais bem resolvido" tem 40× mais evidência que a tese oposta.
3. Os melhores do nicho adjacente são os mais focados (Doce Lucro 4,92★, Receitas 4,73★ com
   IAP único e 6,3 MB). O único caso de expansão bem-sucedida (PeqArt 4,75★) expandiu
   **dentro do mesmo job** — o contra-exemplo tem essa condição embutida.
4. A "brecha aberta no imposto" é bem menor do que o `00` afirma: 32% do corpus fiscal são 5
   desastres (2 estrangeiros, 1 banco); sem eles a média vai a ≈4,06★ *(cálculo meu)*, e o
   app oficial grátis está em 4,85★ com 10M+ instalações.

**Onde ela CONTRARIA — e isto precisa ser dito com todas as letras:**

> **"Aí o app fica mais complexo pra essa pessoa e faz mais sentido ela poder pagar" é
> exatamente o raciocínio que produziu os piores apps do corpus.**

Apreço fez isso: virou gestão, passou a precisar cobrar R$400/ano à vista, e está em **3,47★**
enquanto os focados do mesmo bucket estão em 4,73–4,92★. TurboTax fez isso: o tier caro é
disparado por complexidade que o próprio produto introduz, e são **1,95★ com 75% de
negativos** e uma condenação da FTC. **Complexidade não é uma escada de valor — é um custo
que o usuário paga.** Ninguém abre a carteira porque o app ficou mais complicado; abre porque
a resposta ficou mais certa.

E há um problema comercial em cima do conceitual: **`raw/F §4` mostra que gestão financeira no
BR está ancorada em zero** (Organizze, Balancinho, apps de banco, app oficial do MEI). Montar
o tier pago em cima justamente da camada que o mercado já dá de graça é a pior das três
opções de monetização disponíveis.

**Correção de rota: certa. Justificativa de monetização: errada.** Cobra-se pela resposta
melhor, não pelo app maior.

**Consequência que ninguém tirou ainda:** o preço do `05 §6` (R$89,90/ano · R$12,90/mês ·
vitalício R$129–149) foi calibrado pro produto do `00` — recorrente, de hábito, com gatilho
mensal. Se o produto passa a ser "calculadora que decide preços", **o comp honesto deixa de
ser Precifica.app (R$97,80/ano, que é SaaS de gestão) e passa a ser Receitas–Quanto Cobrar:
desbloqueio único de R$12,90/R$29,90, 100.000+ instalações, 4,73★** (`raw/A`, `raw/G`,
`inventory.csv`). Se o produto muda, o preço muda com ele.

---

## 8. Fazer / não fazer

### FAZER — em ordem

| # | O quê | Porquê estratégico | Evidência |
|---|---|---|---|
| 1 | **Nome, ASO e distribuição — antes de qualquer feature** | O gargalo do nicho é achabilidade, não recurso: o melhor app do mundo aqui é 4,9★ com **100 instalações**. Nenhuma feature conserta um app que ninguém acha. E "Quanto Cobro?" perde a keyword que o inspirou ("cobr**ar**", não "cob**ro**"). | `raw/B §1`, `raw/E §2.1`; Android = 92,5% do BR (`raw/F`) |
| 2 | **Não travar + backup/restore visível** | A maior reclamação do nosso bucket **e** o pedido nº1 dele, na mesma linha de defesa. Barato. | bug 21,2% dos negativos PRICING; 👍143 "salvar os dados caso precisasse formatar" |
| 3 | **Autoridade externa pro número** (referência de mercado por profissão/senioridade) | Ataca a **causa** da dor nº1, não o sintoma. É o único fosso real que a pesquisa aponta e que não estamos construindo. Não existe pro Brasil. Começa com tabela embarcada (as tabelas de SEO 2026 já existem publicamente); submissão anônima opt-in só depois, se vier. | `raw/B §2` (Bonsai Rate Explorer, US/UK/CA); `raw/D` (Freelaz quer ser "o Glassdoor dos freelas BR" e ainda não é) |
| 4 | **Modificadores de preço** (urgência, fim de semana, cliente difícil, revisões, risco de calote) | Responde à objeção documentada nº1 ("cada caso é um caso") e **melhora a resposta** — passa nos 4 testes de fronteira. Freelaz já tem: é table stakes. | `raw/D §objeção 4` |
| 5 | **Auto-recalc explícito** (mudou um custo → tudo se move, com o "antes × depois") | É o único padrão de retenção **validado** no nicho, e ele retém sem exigir gestão: a pessoa volta porque o modelo de preço dela mora aqui. | `raw/G §Padrão dos melhores` (Receitas, Doce Lucro, PeqArt) |
| 6 | **Alíquota efetiva visível + didática das horas faturáveis** | Transforma o labirinto fiscal num número que ancora, e resolve o parâmetro que o usuário não sabe estimar (default explicado, à la Harvest 60%). | `raw/B §6.2–6.3`; calculadorabrasil: *"Ninguém produz 8h por dia"* |
| 7 | **Proposta em PDF — congelada no tamanho atual** | É o último metro do job e a âncora de conversão mais plausível. Um template, sem lista, sem status, sem cliente cadastrado. | `raw/D`, `raw/G` (PeqArt); e §5(D) pra o porquê do congelamento |
| 8 | **Reserva = resultado do cálculo + lembrete. Guardado = recibo mínimo.** | O que a evidência apoia é o lembrete (Receita: **+9%** em dia, +R$49M/mês), não o livro-caixa. Mantém a ponte que é nosso diferencial, sem a contabilidade que ninguém pediu. | `raw/C`; ausência total de verbatim para a reserva |

### NÃO FAZER

| # | O quê | Porquê | Rigor ou medo? |
|---|---|---|---|
| 1 | **Aba de gestão de projetos / clientes** | 1,4% dos elogios do corpus; zero evidência de dor em review; grátis-ancorado no BR; titular oficial 4,85★/10M+ ao lado. Falha nos testes 1, 2 e 3. | **Rigor** — tenho o número. |
| 2 | **"Próximos recebimentos" / previsão de caixa** | É a fronteira do ERP e o pico da violação do app frio: só vale pra quem alimentou o app por meses. | **Rigor.** |
| 3 | **Histórico de propostas, status aceita/recusada, cadastro de cliente** | Cada um desses é o primeiro degrau de um CRM. É como o Apreço começou. | **Rigor.** |
| 4 | **Emitir DAS/DARF** | Maior fonte de ★1 do setor; erro fiscal vira ★1 na hora (👍153); o oficial é grátis e 4,85★. Linkar, nunca imitar. | **Rigor.** |
| 5 | **Cobrar pela gestão** | Ver §7. É cobrar pela camada que o mercado dá de graça, usando a lógica que afundou Apreço e TurboTax. | **Rigor.** |
| 6 | **Gate de Pro por quantidade** (incl. revisar "multi-trabalho é Pro") | O gate mais odiado do corpus. Gatear saídas de alto valor, não permissão de existir. | **Rigor** — mas registro que é uma decisão já tomada pelo fundador; trago a evidência, não a ordem. |
| 7 | **Subsistema de câmbio** (manter só o regime "recebi em moeda estrangeira") | Muito conceito, pouca gente, nota 3/10. O *job* fica; o subsistema sai. | Metade rigor, metade medo — **assumo**: `raw/F §3` é a evidência mais forte de disposição a pagar do dossiê inteiro, e eu estaria confortável sendo voto vencido aqui. |
| 8 | **Link hospedado / conta / nuvem pra proposta** | Quebra o único fosso barato que temos. | **Rigor.** |
| 9 | **Perseguir precificação de produto físico** | Job diferente, bem servido. Decisão já tomada e correta. | **Rigor.** |

---

## 9. Poder de preço — o que faz alguém pagar

Poder de preço vem de indispensabilidade, não de quantidade. Avaliando os três candidatos:

### A gestão paga a conta? **Não.**
- Gestão financeira no BR é ancorada em **zero** (`raw/F §4`).
- O corpus não a valoriza: 1,4% dos elogios.
- Ela só tem valor pra quem já alimentou o app — ou seja, pro público já retido, que é sempre
  o menor. **Você estaria cobrando do usuário que menos precisa ser convencido.**
- E o gate natural dela (quantidade de projetos/trabalhos) é o gate mais odiado do mercado.

### A proposta paga a conta? **Em parte — mas não constrói fosso.**
- É a melhor das três em disposição a pagar **imediata**: o freelancer paga pra não parecer
  amador na frente de quem vai pagar ele. O momento psicológico é perfeito (logo depois de
  validar o preço).
- Mas é a mais clonável do produto inteiro: 51 apps de fatura/recibo no inventário, vários
  com 1M–10M+ instalações e 4,5–4,9★, grátis.
- **Julgamento:** ela é o **gatilho** de conversão (o momento em que se cobra). Ela não é a
  **razão** da conversão. Não confundir os dois — é o erro clássico de ler bem o funil e mal
  o produto.

### Então o que faz virar indispensável?

> **O número ficar mais certo do que a pessoa consegue chegar sozinha.**

Só isso paga preço nesta categoria, e a pesquisa aponta três camadas, em ordem de fosso:

| Camada | Fosso | Estado |
|---|---|---|
| **Regime tributário BR feito certo** | médio — copiável, mas trabalhoso e ninguém fez em app (gringos chutam 25–30%, errado por ~5× pro MEI) | ✅ já temos — é o que temos de melhor |
| **Modificadores + didática dos custos invisíveis** | baixo — mas é o que responde à objeção nº1 | ⬜ falta |
| **Referência de mercado brasileira** ("o que outros designers do teu nível cobram") | **alto — o único com efeito de rede no dossiê** | ⬜ ninguém tem |

A referência de mercado é o único item que: (a) tem demanda em verbatim — *"cobrei 6k, meus
chefes cobrariam 50k"* é um pedido de referência, não de calculadora; (b) não existe no
Brasil (Bonsai só cobre US/UK/CA — `raw/B §2`); (c) **melhora a resposta em vez de administrar
o negócio**, então passa nos quatro testes de fronteira; e (d) **fica melhor com o tempo e com
mais usuários**. Uma calculadora se clona num fim de semana. Uma referência de mercado, não.

**Risco a registrar, porque é real:** amostra pequena gera número não-crível, e número
não-crível destrói exatamente a credibilidade que é o nosso trunfo — o mesmo erro do "8 USD/h
que revoltou a comunidade" (`raw/D §objeção 2`, regra R7). Por isso: nasce com **tabela
embarcada e curada**, apresentada como faixa de mercado, e só vira dado coletivo depois, se
virar.

### Estrutura de preço, reconciliada com o produto real

Se o produto é "decide preços" e não "administra o mês", o modelo recorrente perde a perna
que o sustentava (o gatilho mensal de reserva). O comp honesto muda:

| | Comp usado no `05` | Comp honesto pro produto pós-correção |
|---|---|---|
| Referência | Precifica.app — R$97,80/ano (**é SaaS de gestão**) | **Receitas–Quanto Cobrar** — desbloqueio único **R$12,90 / R$29,90**, 100.000+ inst., 4,73★ |
| Modelo | anual/mensal + vitalício R$129–149 | **compra única** como caminho principal, preço muito mais baixo |

`raw/G §2.2` mostra que ~35% dos apps já misturam assinatura com compra única, e que o BR é
culturalmente avesso a assinatura. O híbrido continua certo — o que muda é **qual das duas é
o default e a que preço**. Vender assinatura de gestão para um produto que decidiu não ser de
gestão é a incoerência mais cara que este planejamento ainda carrega.

---

## 10. O que a pesquisa NÃO responde (não invente)

Registro honesto, porque metade do valor de um dossiê é saber onde ele acaba:

1. **Se uma calculadora de preço para freelancer de SERVIÇO retém.** Não há um único app do
   nicho com tração suficiente pra gerar dado (iOS: todos com 0 avaliação; Play: 10+ a 1.000+).
   O bucket PRICING mede confeitaria e artesanato. **Nada no dossiê responde essa pergunta —
   nem a favor nem contra.** Quem disser que responde está lendo o dado errado.
2. **Willingness-to-pay do autônomo BR.** `raw/F §4` é explícito: não encontrado em fonte
   primária. Todos os preços em `05` são hipótese.
3. **A dor de reserva de imposto na voz do usuário.** Zero verbatim em 16.961 reviews.
   Validada só por comunidade, por penalidade e pelo +9% da Receita.
4. **Se gestão de projetos retém freelancer BR.** Nunca foi minerada — as categorias
   invoice, freelance, time-tracking ficaram **fora do escopo** (`ANALISE §8`), e são
   justamente as adjacências das features novas.
5. **Notas da Play na amostra vs. vitalícias.** As duas populações discordam muito (MEI Fácil:
   1,92★ na amostra recente × 2,91★ vitalício). Comparações finas entre buckets devem ser
   tratadas como direcionais.
6. **iOS.** Não entrou nesta rodada de mineração. `raw/A` sinaliza greenfield.

---

## 11. Resumo executivo

**O trabalho:** a pessoa contrata o app pra **encerrar uma discussão com ela mesma antes de
responder um cliente que está esperando**. Ela não quer um sistema; quer uma resposta que
consiga defender. O concorrente é a **conta de padaria e uma aba do Google** — não outro app.

**Veredito:** a correção de rota está certa e é sustentada pela pesquisa. A justificativa de
monetização ("mais complexo → mais razão pra pagar") está errada e é o padrão que afundou
Apreço (3,47★) e TurboTax (1,95★). Cobra-se pela resposta mais certa, não pelo app maior — e
gestão financeira no BR já é grátis. **Gestão de projetos dilui: corte.** **Proposta em PDF
não dilui, mas congele o tamanho dela.** O que compra poder de preço não é nenhuma das duas:
é a **referência de mercado brasileira** que não existe em lugar nenhum e que ataca a causa da
dor nº1 — falta de legitimidade, não falta de fórmula.

**A fronteira:**
> **O Quanto Cobro? decide preços. Ele não administra negócios.**
> **Se, pra ter valor, a feature exigir que a pessoa já tenha alimentado o app antes, ela é
> gestão — e gestão não é nosso.**

---

*Documento de produto. Todas as afirmações rastreiam para `docs/research/` e `lib/`. Os dois
cálculos derivados por mim (≈4,06★ do bucket fiscal sem os 5 desastres; LOC por feature) estão
marcados no corpo do texto.*
