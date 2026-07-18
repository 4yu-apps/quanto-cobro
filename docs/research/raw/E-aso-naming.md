# Frente E — ASO / Keywords + Naming

App: calculadora BR para freelancer (valor-hora, imposto a reservar, lucro real, contexto tributário BR).
Nome provisório: **"Quanto Cobro?"** — ainda não decidido.

Método: Google Play (fetch/busca), WebSearch, buscas de homônimo/trademark. Volume de busca é **qualitativo** (Google não expõe número por keyword sem Keyword Planner logado). Itens marcados **[não verificado]** = inferência, precisa de confirmação manual.

---

## PARTE 1 — PAISAGEM ASO / KEYWORDS

### 1.1 O que o brasileiro provavelmente busca na Play

Agrupei por intenção. A coluna "sinal" é qualitativa, baseada em: quantidade de conteúdo/apps disputando o termo, naturalidade como query digitada, e alinhamento com a dor do usuário.

**Cluster A — a intenção pura (a pergunta que a pessoa faz):**
| Termo | Sinal de demanda | Concorrência | Nota |
|---|---|---|---|
| `quanto cobrar` | Alta — é a pergunta canônica; blogs/calculadoras web brigam por ela (99Freelas, Contabilizei, Workana, Exame, Banco Pan) | Alta em conteúdo web, **baixa em apps** | Infinitivo é como as pessoas escrevem ("quanto cobrar por hora", "quanto cobrar por um freela") |
| `quanto cobrar por hora` | Alta | Média (apps), alta (web) | Long-tail forte, casa com valor-hora |
| `quanto cobrar freelancer` | Alta | Média | |
| `quanto cobrar por um freela` | Média | Baixa | Gíria "freela" é muito BR |

**Cluster B — a ferramenta (o que a pessoa quer instalar):**
| Termo | Sinal | Concorrência (apps) | Nota |
|---|---|---|---|
| `calculadora freelancer` / `calculadora freela` | Alta | **Alta** — vários apps disputam (ver 1.3) | Termo mais "cravado" pelos concorrentes |
| `precificação` | Alta | Média-alta | Palavra técnica que o público de MEI/autônomo conhece bem |
| `precificar serviço` | Média | Média | |
| `valor hora` / `valor da hora` | Alta | Média | Mais genérico (colide com folha/CLT), mas muito buscado |
| `calcular preço serviço` | Média | Média | |
| `preço de venda` | Alta | Alta — dominado por apps de **produto/comércio** (não freela) | |

**Cluster C — o diferencial tributário BR (onde há gap):**
| Termo | Sinal | Concorrência (apps) | Nota |
|---|---|---|---|
| `MEI preço` / `precificação MEI` | Média-alta | Média | Apps de MEI existem, mas focam DAS/faturamento, não valor-hora |
| `imposto autônomo` / `quanto guardar de imposto` | Média | **Baixa** | Quase ninguém cruza isso com valor-hora — diferencial real |
| `lucro real` / `lucro do freelancer` | Média | Baixa | Cuidado: "lucro real" também é regime tributário — ambiguidade |
| `DAS MEI` | Alta | Alta (apps dedicados a MEI) | Fora do core, mas adjacente |

### 1.2 Demanda vs. concorrência — leitura qualitativa

- **Melhor relação (buscar muito, disputar pouco em app):** o **cluster tributário** (`imposto a reservar`, `quanto guardar de imposto`, `precificação MEI` cruzado com valor-hora). A web fala muito de "custos invisíveis, impostos, férias" (Calculadora Brasil, Contabilizei), mas os **apps** de calculadora freela em geral **não** modelam imposto BR — são genéricos/internacionais (FreelaCalc, Freelance Rate Calculator). É o diferencial defensável da 4YU.
- **Termo mais valioso e mais brigado:** `calculadora freelancer/freela`. Vários apps já o cravam no título. Dá pra competir, mas não dá pra vencer só com ele.
- **Termo de intenção com pouca disputa em app:** `quanto cobrar` (+ variações por hora / por freela). Muito conteúdo web, **poucos apps** com isso no título. Oportunidade de capturar a query exata que o iniciante digita.
- **Termos a usar com cautela:** `preço de venda` e `precificação de produtos` são dominados por apps de **comércio/varejo** (Precificação De Produtos, Apreço, Lucro Certo). Ranquear lá é brigar com outra categoria e atrair usuário errado.

### 1.3 Como os concorrentes montam TÍTULO + descrição curta

Padrões observados nas listagens da Play (títulos verbatim onde consegui confirmar):

| App (package) | Título na Play | Padrão | Ângulo |
|---|---|---|---|
| `com.abp.freelancer_calculator` | **"FreelaCalc: Calculadora Freela"** (PT) / "FreelaCalc - Freelance Pricing" (EN) | **Marca + descritor keyword** | 4 modelos de preço (hora/projeto/dia), offline, PT/ES/EN, exporta imagem p/ cliente |
| `com.ionicframework.freelacalc136053` | **"Calculadora Freelance"** | **Descritivo puro** | valor de projeto, recebível mensal, tempo de trabalho |
| `com.aleckrh.freelancecalculator` | "Calculadora Freelance" (homônimo) | Descritivo puro | pricing tool |
| `app.freelancecalc` | "Freelance Fee & Tax Calculator" (EN) | Descritivo + **tax** | inclui imposto (internacional, não BR) |
| `com.FreelanceRate.Calculator` | "Freelance Rate Calculator" (EN) | Descritivo puro | taxa real por hora/dia/semana/mês |
| `com.aszudev.preocerto` | **"Apreço"** | **Marca pura** (trocadilho a-preço) | precificação/gestão (foco produto) |
| `br.com.precificacaodeprodutos...` | "Precificação De Produtos" | Descritivo puro | varejo/MEI, produto |
| PrecificAção.app / Lucro Certo | marca+descritor | Marca | custo fixo, preço de venda (produto) |

Leituras:
1. **Ninguém dominou "quanto cobrar" como marca de app.** O espaço da *pergunta* está livre; o espaço da *ferramenta genérica* ("calculadora freelance") está lotado de homônimos.
2. O concorrente mais bem estruturado em ASO é o **FreelaCalc**: marca curta memorável **+** dois-pontos **+** keywords ("Calculadora Freela"). É exatamente o modelo "marca forte + subtítulo ASO".
3. **Ninguém no nicho freela-hora modela imposto BR de verdade.** O único "tax" é internacional. Gap confirmado.
4. Play permite ~30 caracteres de título; todos usam o formato `Marca: keyword keyword` ou `Keyword Keyword` para caber termo de busca no título (o campo de maior peso ASO).

### 1.4 Conjunto de keywords-alvo recomendado

**Para o TÍTULO (≤30 char, campo de maior peso — cravar 1 marca + 1-2 keywords):**
- Prioridade máxima no título: **calculadora** + **freelancer/freela** OU **quanto cobrar** + **precificação**.
- Ex.: `Marca: Calculadora Freela` ou `Marca: Quanto Cobrar Freela`.

**Para a DESCRIÇÃO CURTA (≤80 char — segundo campo de maior peso):**
Empacotar a intenção + diferencial. Ex.:
> "Calcule quanto cobrar por hora como freelancer: preço, imposto e lucro real."

**Pool de keywords para descrição longa (indexação semântica):**
`quanto cobrar` · `quanto cobrar por hora` · `calculadora freelancer` · `calculadora freela` · `precificação` · `precificar serviço` · `valor hora` · `valor da hora de trabalho` · `preço freelancer` · `MEI` · `precificação MEI` · `imposto` · `quanto guardar de imposto` · `imposto a reservar` · `lucro` · `lucro real` · `autônomo` · `PJ` · `orçamento freela` · `diária` · `preço de projeto`

**Não perseguir no título:** `preço de venda`, `precificação de produtos` (categoria varejo, atrai público errado).

---

## PARTE 2 — NAMING

### 2.1 Avaliação crítica de "Quanto Cobro?"

**Prós:**
- **PT-BR nativo, tom de voz na 1ª pessoa** — "quanto (eu) cobro?" é literalmente a dúvida do usuário se perguntando. Empático, coloquial, memorável.
- **Contém a raiz da intenção de busca** (cobrar/cobro), então tem alguma afinidade ASO com o cluster "quanto cobrar".
- Curto, fácil de falar, bom para boca a boca.

**Contras (relevantes):**
1. **A query real é "quanto cobrAR" (infinitivo), não "quanto cobrO" (1ª pessoa).** As pessoas digitam "quanto cobrar por hora". O nome usa a flexão que **não** é a mais buscada. Perde-se o match exato justamente na keyword que motivou o nome. **[não verificado quantitativamente, mas consistente com todos os títulos de blog/calculadora que usam "cobrar"]**
2. **Ambiguidade "cobro" = cobrança/coleta.** "Cobro" também é substantivo ("ato de cobrar", associado a **cobrança de dívida**). Risco de o app ser confundido com cobrança/recebimento (contas a receber), não precificação. Enfraquece a clareza do ícone/store.
3. **A "?" não ajuda ASO e some.** Play tende a normalizar/ignorar pontuação no título e na URL; o "?" vira ruído — não indexa, e complica handles/domínio.
4. **Marca fraca/genérica → difícil de proteger.** Frase descritiva-comum é **difícil de registrar no INPI** (marcas descritivas têm baixa distintividade). E é conceitualmente colada em dezenas de conteúdos "Quanto Cobrar?" (99Freelas, Exame, Calculadora Brasil) — você compete com SEO alheio, não constrói território próprio.
5. **Confusão com "quanto CUSTA".** Existe uma família grande de apps/sites "Quanto Custa..." (quanto custa um app, etc.). "Quanto Cobro" fica perto demais dessa vizinhança.

**Homônimos / trademark:**
- **Nenhum app chamado exatamente "Quanto Cobro" apareceu** na Play/App Store nas buscas feitas. **[não verificado exaustivamente]**
- Existe conteúdo web "Quanto Cobrar?" (ex.: calculadorabrasil.com.br/…precificacao-freelance) — não é app, mas ocupa o SEO da frase.
- INPI (registro de marca BR): **não verificado** — recomendo busca em busca.inpi.gov.br pela classe 09 (software) antes de decidir. Expectativa: como frase descritiva, registro puro-nominativo é frágil; registro **misto** (logo+nome) é mais viável.

**Veredito:** nome simpático e com intenção embutida, mas **paga o pedágio na keyword errada (cobro≠cobrar)**, carrega ambiguidade de cobrança, e é marca fraca. Serve como *tagline/descritor*, não é a aposta ideal de marca-mãe.

### 2.2 Alternativas de nome (6-10)

Domínios/handles marcados **[não verificado]** — checagem rápida qualitativa; confirmar em registro.br / lojas antes de fechar.

**(a) Descritivos-ASO — fáceis de achar, marca fraca:**

| Nome | Prós | Contras | Domínio/handle |
|---|---|---|---|
| **Quanto Cobrar** (sem "?") | Casa com a query exata mais buscada; máxima afinidade ASO | Marca fraca; compete com SEO de blogs; genérico | `quantocobrar.com.br` provavelmente **ocupado/disputado** [não verificado] |
| **Calculadora Freela** | Termo que o público digita; instantaneamente claro | Homônimos já existem na Play; marca inexistente | `.com.br` provável livre; handle disputado [não verificado] |
| **Precifica Freela** | Une "precificação" (técnica) + "freela" (público); descritivo e específico | Ainda descritivo; menos memorável | `precificafreela.com.br` provável **livre** [não verificado] |
| **Valor da Hora** | Cobre keyword "valor hora"; claro | Genérico demais; colide com CLT/folha | `.com.br` provável ocupado [não verificado] |

**(b) Marcas — fortes, exigem keyword no subtítulo:**

| Nome | Prós | Contras | Domínio/handle |
|---|---|---|---|
| **Cobra Certo** | Trocadilho BR ("cobrar certo"), memorável, tom de confiança; registrável | "Cobra" (o animal) pode gerar ruído visual/busca | `cobracerto.com.br` [não verificado, checar] |
| **Cobro Justo** | Posicionamento (preço justo), curto, distinto; bom p/ identidade | "Cobro" mantém leve ambiguidade cobrança | `cobrojusto.com.br` provável livre [não verificado] |
| **Freela Certo** | "Certo" transmite segurança na decisão; casa com "freela"; extensível a outras ferramentas do público | Família "…Certo" já povoada (Lucro Certo, Preço Certo) — risco de diluição/confusão | `freelacerto.com.br` [checar] |
| **Precifá** / **Precifa** | Marca curta derivada de "precificar"; brandável e registrável; escalável | Precisa ASO no subtítulo; pode soar abstrato p/ leigo | `precifa.com.br` [checar; nomes curtos costumam estar tomados] |
| **Horário** (jogo hora+valor)** ou **HoraFreela** | Conecta hora+freela; brandável | Mais fraco que os acima | [checar] |
| **Justa** (a hora justa / o preço justo) | Curtíssimo, emocional, forte p/ marca-mãe | Muito abstrato sem subtítulo; genérico como palavra | `.com.br` provável ocupado [não verificado] |

### 2.3 Recomendação de direção

**Recomendo: MARCA FORTE (registrável) + SUBTÍTULO ASO no título da Play** — modelo do FreelaCalc.

Racional para uma fábrica de apps (4YU) que quer **volume orgânico**:
1. **ASO real mora no subtítulo, não no nome.** O algoritmo indexa o campo de título inteiro. `Marca: Calculadora Freela · Quanto Cobrar` entrega **todas** as keywords **e** um nome próprio. Você não precisa sacrificar a marca para ranquear — o formato `Marca: keywords` te dá os dois.
2. **Marca descritiva não constrói ativo.** "Quanto Cobrar/Cobro" te faz competir eternamente com blogs e homônimos; nunca vira território seu, é difícil de registrar no INPI e impossível de defender. Numa fábrica de apps, marca própria é o que permite **cross-promo entre apps** e reuso de reputação — descritivo puro não acumula.
3. **O diferencial (imposto/lucro BR) deve aparecer no subtítulo/descrição curta, não no nome** — é onde converte e ranqueia, sem engessar a marca.

**Aposta concreta sugerida:**
- Marca-mãe registrável e brandável: **"Cobro Justo"** ou **"Cobra Certo"** (posicionamento = cobrar o preço certo/justo, que é a promessa do app). Se preferir menos ambiguidade de cobrança, **"Precifica Freela"** como meio-termo (mais descritivo, ainda distinto).
- Título na Play (formato ASO): `Cobro Justo: Calculadora Freela` ou `Cobro Justo — Quanto Cobrar por Hora`.
- Descrição curta (≤80): "Calcule quanto cobrar por hora: preço, imposto a reservar e lucro real."
- Guardar **"Quanto Cobro?"** como **tagline/claim de marketing**, não como nome de loja — ali a 1ª pessoa e o "?" funcionam bem (voz do usuário), sem custar ASO.

**Se o objetivo for puro volume rápido e a marca não importar** (tese de fábrica descartável): então **"Calculadora Freela"** ou **"Quanto Cobrar"** (sem "?") maximizam match de busca no curto prazo — ao custo de zero defensabilidade e brigar com homônimos.

### 2.4 Checagens que faltam (fazer manualmente antes de fechar)
- INPI classe 09 (busca.inpi.gov.br) para o nome final escolhido — **[não verificado]**.
- Busca exata na Play **e** App Store pelo nome final (não só WebSearch) — **[não verificado exaustivamente]**.
- registro.br para `.com.br` e disponibilidade de @handle Instagram/TikTok do nome final — **[não verificado]**.
- Google Keyword Planner / ferramenta ASO (AppTweak, Sensor Tower) para volume real das keywords do cluster — aqui só há sinal qualitativo.

---

## Fontes principais
- FreelaCalc — https://play.google.com/store/apps/details?id=com.abp.freelancer_calculator&hl=pt_BR
- Calculadora Freelance — https://play.google.com/store/apps/details?hl=pt_BR&id=com.ionicframework.freelacalc136053
- Apreço — https://play.google.com/store/apps/details?id=com.aszudev.preocerto
- Freelance Fee & Tax Calculator — https://play.google.com/store/apps/details?id=app.freelancecalc
- PrecificAção.app — https://precificacao.app/
- Calculadora Brasil (valor-hora/precificação freela 2026) — https://calculadorabrasil.com.br/simulador-precificacao-freelance/
- Contabilizei calculadora freelancer — https://www.contabilizei.com.br/contabilidade-online/materiais/calculadora-freelancer/
- 99Freelas calculadora — https://www.99freelas.com.br/apps/calculadora-freelancer
- Guia do Freela (métodos de precificação) — https://guiadofreela.com.br/quanto-cobrar-como-freelancer-5-metodos-de-precificacao/
- Sentido de "cobro" (cobrança) — Reverso/Linguee espanhol-português
