# Frente A — Concorrentes BR de precificação / valor-hora / "quanto cobrar" (Play + App Store)

Pesquisa: 2026-07-18. Método: iTunes Search API + RSS de reviews (dado confiável e verificável), scraping do HTML server-rendered da Google Play (install count e descrição são extraíveis; **nota média e texto de review na Play NÃO** — renderizados via JS, não vêm no HTML). Onde não deu para verificar, está marcado como **não verificado**.

---

## Resumo executivo (o que importa)

1. **O nicho "valor-hora para freelancer de SERVIÇO com contexto tributário BR" está essencialmente vazio de tração.** Na App Store, todos os apps especificamente de freelancer/serviço (Pricemy, Freelance Reality, freelancalc, Kyrum, Freelo) têm **0 avaliações** — são lançamentos de 2026 sem traction. Na Play, os concorrentes diretos têm de **10+ a 1 mil+ instalações**. Ninguém consolidou o espaço.
2. **Quem tem tração de verdade em "precificação" no Brasil é o nicho de PRODUTO físico** — confeitaria e artesanato (Apreço, Peqart, Gestão Viver de Confeitaria, PrecifiCAR). São adjacentes, não concorrentes diretos, mas mostram o padrão de reclamação do mercado de "precificação" e servem de espelho.
3. **O concorrente mais próximo do blueprint é o FreelaCalc (Play, `com.abp.freelancer_calculator`)** — já fala "freelancers, autônomos e MEIs", "chega de cobrar no achômetro", 4 modelos de cálculo incluindo lucratividade. Mas: menciona "MEI" como keyword, **cita `Simples Nacional` zero vez**, é ad-supported e tem só **100+ instalações**.
4. **A melhor execução do "contexto tributário BR em linguagem humana" hoje é uma calculadora WEB, não um app** (calculadorabrasil.com.br) — faz gross-up com MEI/Simples Anexo III-V/IRPF/ISS/INSS. É o benchmark de profundidade fiscal a bater, e é web (sem app, sem offline).

---

## Apps concorrentes — fichas

### Google Play

#### 1. FreelaCalc: Calculadora Freela — `com.abp.freelancer_calculator`
- **Loja:** Google Play · **Instalações:** 100+ (verificado no HTML) · **Nota:** não verificado (Play não expõe no HTML; provavelmente poucas avaliações) · **Modelo:** grátis, **"Contém anúncios"** (verificado).
- **Posicionamento:** o concorrente mais direto. "FreelaCalc é a calculadora de precificação feita para freelancers, autônomos e MEIs que querem precificar seus serviços com segurança e clareza. Chega de cobrar no achômetro." (descrição da ficha).
- **Recursos (descrição):** 4 modelos — **Precificação por Hora** (custo de vida, horas trabalhadas, margem de lucro), **Precificação por Produção** (peça/unidade, custos fixos e variáveis, lucro), **Análise de Lucratividade** (receita bruta, custos totais, margem líquida), **Formação de Diária/Serviço** (despesas operacionais, impostos, remuneração desejada).
- **Tributário:** menciona "MEI" 14x e "INSS" 2x na página, mas **"Simples Nacional" 0x** (verificado por contagem). "Impostos" aparece como linha genérica de custo, não como lógica de regime.
- Fonte: https://play.google.com/store/apps/details?id=com.abp.freelancer_calculator

#### 2. Calculadora de Valor/Hora (B20 Robots) — `com.b20robots.calculadoravalorhora`
- **Loja:** Google Play · **Instalações:** 10+ (verificado) · **Nota:** não verificado · **Modelo:** grátis, **"Contém anúncios"** (verificado).
- **Posicionamento:** "Calculadora profissional para definir o valor da sua hora de trabalho" (para freelancers, consultores, autônomos).
- **Recursos (descrição):** Valor Ideal / Valor Mínimo ("limite para não trabalhar no prejuízo") / Valor Premium; meta de receita mensal; custos fixos e variáveis; **"Análise de impostos e margem de lucro"**; projeção de lucro líquido; histórico de simulações; exportação em JSON.
- **Tributário:** menciona "imposto" 5x, INSS 2x, Simples 0x — genérico, sem lógica de regime.
- Fonte: https://play.google.com/store/apps/details?id=com.b20robots.calculadoravalorhora

#### 3. Calculadora Freelance (aleckrh) — `com.aleckrh.freelancecalculator`
- **Loja:** Google Play · **Instalações:** 1 mil+ (verificado — o mais instalado dos diretos) · **Nota:** não verificado · **Modelo:** grátis, sem flag de anúncios detectada.
- **Posicionamento:** "Uma ferramenta simples para você saber quanto cobrar como freelancer." Assumidamente **raso/simples**.
- **Tributário:** MEI 1x, imposto 2x, INSS/Simples 0x. Praticamente sem contexto fiscal.
- Fonte: https://play.google.com/store/apps/details?id=com.aleckrh.freelancecalculator

#### 4. Calculadora Freelance (Ionic / `com.ionicframework.freelacalc136053`)
- Aparece na busca da Play, mas a ficha retornou **404 / "Não encontrado"** no acesso direto (verificado) — provavelmente despublicado. Calcula valor de projeto, renda mensal, valor-hora (descrição da busca). Fonte da listagem: https://play.google.com/store/apps/details?id=com.ionicframework.freelacalc136053

#### Outros na Play (adjacentes)
- **MoneyTime** (`com.androloloid.moneytime`) — calcula salário/hora, sem anúncios; foco em salário CLT/jornada, não em precificação de freela. Ficha retornou 404 no acesso direto (não verificado).

### App Store (iOS)

#### Concorrentes diretos de freelancer/serviço — TODOS com 0 avaliação (verificado via RSS)
| App | trackId | Avaliações | Preço |
|---|---|---|---|
| Pricemy (Andriel Ferreira) | 6758759959 | **0** | Grátis |
| Freelance Reality (Daijiro Tanaka) | 6759823422 | **0** | Grátis |
| freelancalc (DML WEB SL) | 1002455444 | **0** | Grátis |
| Kyrum (HOGRID Serviços) | 6767259321 | **0** | Grátis |
| Freelo (Freelo SAS) | 6739509014 | **0** | Grátis |
| Calculadora Autónomo 2026 (Iván Boban) | 6761021311 | 0 | Grátis (mercado ES) |

Leitura: o espaço de app iOS de precificação de freela é **greenfield** — muitos entrantes novos (2026), nenhum com avaliação/tração. Não consegui comparar qualidade por review porque não existe review.

#### Adjacentes de precificação com tração real (nicho PRODUTO físico)
| App | trackId | Nota | Nº aval. | Preço/modelo |
|---|---|---|---|---|
| **PrecifiCAR** (itaquera tech) | 857096045 | 4,80 | **43.091** | Grátis (precificação de veículos/FIPE — não é freela) |
| **Peqart** — Gestão Artesanal | 1594656704 | 4,83 | 403 | Grátis + PRO |
| **Apreço** (Apreco Soluções) | 1511299559 | **3,47** | 102 | Grátis + PRO (R$400/ano) |
| DBL — Precificação e Orçamento | 6743377408 | 4,78 | 73 | Grátis + assinatura |
| Gestão Viver de Confeitaria | 1636351373 | 4,35 | 60 | Grátis |
| Calculadora Margem de Lucro | 1536072363 | 4,61 | 46 | Grátis |
| Contabilidade de negócios (Monelyze) | 1550552151 | 4,61 | 36 | Grátis |
| Receitas - Quanto Cobrar | 6747908579 | 4,89 | 314 | Grátis (precificação de receitas) |

(nota/nº de avaliações verificados via iTunes Search API, país BR)

---

## Reclamações recorrentes (VERBATIM, com fonte)

Como os concorrentes diretos de freela não têm review, as reclamações abaixo vêm dos **apps adjacentes de precificação** (RSS público da App Store) — são o retrato mais fiel de por que usuários brasileiros abandonam um app de "precificação". Padrões:

**A) Paywall agressivo / caro / sem parcelamento** (dominante no Apreço)
- ★1 "Quem é que assina um aplicativo tão caro? [...] só tem opção de pacote anual e por 400 reais. Sem condições isso. Mais caro que o Canva, CapCut, Lightroom" — https://itunes.apple.com/br/rss/customerreviews/id=1511299559/sortBy=mostRecent/json
- ★1 "O app custa 400,00 por ano, e na versão grátis não dá para usar nada!" — mesma fonte.
- ★1 "Eu amava o aplicativo e indicava para todas as empresárias (MEI) que conheço. Após as últimas atualizações ele veio extremamente limitado [...] custa QUATROCENTOS REAIS [...] isso é muito elevado, ainda mais que precisa ser pago à vista." — mesma fonte.
- ★2 "Restringiram demais a quantidade de materiais ou precificação de peças na versão gratuita e o valor anual para PRO não parcela." — mesma fonte.

**B) Bugs / travamento após atualização**
- ★3 "Era ótimo na versão anterior. Agora com essa atualização não consigo mais precificar produto. Fora que fica lento e aquece o celular. Por favor, voltem com a versão anterior!" — id=1511299559.
- ★1 "App não abre / Gostei do aplicativo mas simplesmente não abre mais." — https://itunes.apple.com/br/rss/customerreviews/id=1636351373/sortBy=mostRecent/json

**C) Cadastro obrigatório / fluxo de conta quebrado** (relevante para a tese de "sem cadastro")
- ★1 "Só consegue usar o aplicativo se cadastrar o e-mail para ficar recebendo propaganda e novidades. Sem chance! Se não cadastrar, não tem acesso. Uma pena." — id=1511299559.
- ★1 "Não deixa eu criar uma conta, na hora de verificar o número o código nunca aparece." — id=1511299559.
- ★1 "Entrei no aplicativo para ver como funciona, e ele simplesmente entrou no meu iCloud e faturou no meu cartão. Mas em momento algum apareceu forma de pagamento." — https://itunes.apple.com/br/rss/customerreviews/id=1594656704/sortBy=mostRecent/json
- ★3 "Segundo os termos temos 7 dias para cancelamento, porém não existe nenhum e-mail ou canal de atendimento para solicitar." — id=1594656704.

---

## Elogios recorrentes (VERBATIM)

- ★5 "Antes eu não sabia precificar meu trabalho e por muitas vezes tive inclusive prejuízo, quando comecei a usar o app [...] consegui ter uma visão muito mais detalhada de todos os meus custos." — id=1594656704 (Peqart).
- ★5 "Consigo saber exatamente quanto eu gastei de material, mão de obra, quanto que tô ganhando de lucro. O valor da minha hora de trabalho." — id=1511299559 (Apreço).
- ★5 "Muito fácil de precificar / Parei de ter prejuízo com a produção." — id=1636351373.
- Padrão de elogio: **"fácil de mexer", "intuitivo", "simples", "sem pegadinhas e propagandas chatas"** aparece dezenas de vezes (Peqart id=1594656704). Simplicidade e ausência de anúncio são elogiados explicitamente.

## Pedidos de recurso (VERBATIM) — pistas de roadmap

- Custos invisíveis que os usuários **pedem para incluir**: "no custo precisaria entrar parte de energia, depreciação de equipamentos, entre outros" (id=1594656704); "calcular depreciação de maquinário e a possibilidade de ratear as despesas mensais nas peças" (id=1511299559).
- Medir tempo real: "Ainda tenho dificuldade é mensurar meu tempo trabalhando [...] seria interessante um cronômetro" (id=1511299559).
- Meta de retirada: "poderia existir dentro do faturamento uma linha da quantidade de produtos que necessito vender para chegar ao Pró-labore" (id=1636351373).
- Relatórios/fluxo de caixa: "um relatório por período e não só mês a mês [...] controle de fluxo de caixa dentro do próprio app" (id=1511299559).

---

## Calculadoras WEB (não-app) — benchmark de profundidade fiscal

- **99freelas** (https://www.99freelas.com.br/apps/calculadora-freelancer): 4 campos apenas (renda desejada, horas/dia, dias/semana, semanas de férias). **Aritmética rasa, sem imposto, sem 13º, sem ferramentas.** É exatamente a "calculadora de 1 campo" do blueprint.
- **calculadorafreela.com**: não verificado (página não carregou conteúdo no fetch).
- **calculadorabrasil.com.br/simulador-precificacao-freelance** (https://calculadorabrasil.com.br/simulador-precificacao-freelance/): **o benchmark forte.** Faz gross-up ("Preço Final = Preço Base ÷ (1 – Carga Tributária Total%)") com **MEI (~R$75/mês), Simples Nacional Anexo III/V (6–15,5%), IRPF 0–27,5%, ISS municipal 2–5%, INSS 11–20%**. Cita custos invisíveis (briefing, revisões, assinaturas Adobe/Canva, dias improdutivos, taxas bancárias) e uma margem de segurança de 20%. Frase-chave: **"Ninguém produz 8h por dia"**, recomenda 4–5 h faturáveis. É web, sem offline, sem app — o contexto tributário existe aqui, mas fora de um app mobile.

---

## LEITURA vs BLUEPRINT

**Tese 1 — Freelancer cobra de menos por ignorar custos invisíveis. → VALIDA (forte).**
Evidência direta em review: "por muitas vezes tive inclusive prejuízo [...] até usar o app" (Peqart, id=1594656704); "Parei de ter prejuízo com a produção" (id=1636351373). E usuários **pedem espontaneamente** para incluir depreciação, energia, rateio de despesas — ou seja, sabem que faltam custos invisíveis. A calculadorabrasil reforça ("Ninguém produz 8h por dia").

**Tese 2 — Freelancer não reserva imposto e toma susto com DAS/IR. → NÃO VERIFICADO / lacuna de evidência.**
Não encontrei review verbatim de alguém tomando susto com DAS/IR, nem app que ofereça "reservar imposto por pagamento". A ausência é dupla: nem os apps tratam disso, nem consegui evidência direta da dor. É a hipótese **menos comprovada** por review — mas também é a **maior lacuna de produto** (nenhum concorrente resolve). Sugiro validar com entrevista/comunidade MEI.

**Tese 3 — Diferencial = contexto tributário BR (MEI/CPF/Simples) em linguagem humana. → VALIDA como oportunidade, com ressalva.**
Nos apps, o contexto fiscal é **raso**: FreelaCalc cita "MEI" mas **Simples Nacional 0x**; os demais tratam "imposto" como uma linha genérica. Nenhum app faz lógica de regime. PORÉM o benchmark existe **na web** (calculadorabrasil faz MEI/Simples/IRPF/ISS/INSS com gross-up). Conclusão: o contexto tributário é diferencial real **no formato app/offline**, mas não é território virgem — já foi provado que dá para fazer em linguagem de calculadora; falta alguém empacotar num app bom.

**Tese 4 — Concorrentes são calculadoras rasas de 1 campo, sem contexto/didática. → VALIDA (com nuance).**
Verdadeiro para os diretos: 99freelas = 4 campos sem imposto; aleckrh se autodescreve "ferramenta simples". A **nuance**: FreelaCalc já tem 4 modelos e fala a linguagem certa ("chega de cobrar no achômetro") — então "rasa de 1 campo" não vale para 100% do campo. O diferencial não é "ter mais campos", é **profundidade fiscal + didática + execução (offline, sem ads, sem cadastro)**.

**Tese 5 — Retenção via tools recorrentes (reservar imposto por pagamento; simular lucro de projeto). → PARCIALMENTE VALIDA / campo aberto.**
"Simular lucro de projeto" já existe parcialmente (FreelaCalc "Análise de Lucratividade"; B20 "projeção de lucro líquido") — logo é desejável, mas commoditizado como cálculo único. **"Reservar imposto por pagamento" não existe em nenhum concorrente** — é o loop de retenção mais defensável e vago no mercado. Reviews mostram apetite por recorrência/gestão contínua (pedidos de fluxo de caixa, relatórios por período, cronômetro), o que apoia a tese de que uma tool recorrente retém melhor que uma calculadora one-shot.

**Tese 6 — Confiança: 100% offline, sem cadastro, privacidade como argumento. → VALIDA (forte).**
Este é o achado mais acionável dos reviews. Cadastro obrigatório e cobrança-surpresa geram ★1 explícitos: "Só consegue usar se cadastrar o e-mail para ficar recebendo propaganda [...] Sem chance!" (id=1511299559); "entrou no meu iCloud e faturou no meu cartão [...] em momento algum apareceu forma de pagamento" (id=1594656704). E "sem pegadinhas e propagandas chatas" é elogio recorrente. Além disso, os 2 principais concorrentes de freela na Play (FreelaCalc, B20) são **ad-supported** — "sem anúncios / sem cadastro / offline" é um contraste de posicionamento imediato e crível.

---

## Lacunas óbvias do mercado (onde "Quanto Cobro?" ganha)

1. **Reserva de imposto por pagamento** — inexistente em qualquer concorrente. Loop de retenção único.
2. **Lógica real de regime BR (MEI vs CPF/autônomo vs Simples Anexo III/V) dentro de um app** — só existe na web hoje.
3. **Offline + sem cadastro + sem anúncio** — os diretos são ad-supported ou exigem conta; é dor documentada em review.
4. **Não obrigar assinatura cara à vista** — o ódio ao "R$400/ano sem parcelar" do Apreço é um manual do que não fazer no pricing.
5. **iOS é greenfield** para freela — zero apps com tração; janela aberta.

## O que NÃO consegui verificar (honestidade)
- **Nota média e texto de review da Google Play**: não vêm no HTML server-rendered (renderizados por JS). Consegui só install count e descrição. Notas dos apps Play = **não verificado**.
- **calculadorafreela.com**: página não retornou conteúdo.
- **Tese 2 (susto com DAS/IR)**: sem evidência verbatim direta; recomendo pesquisa qualitativa (Reddit r/investimentos, grupos MEI, entrevistas).
- Fichas `com.ionicframework.freelacalc136053` e MoneyTime: 404 no acesso direto — status atual incerto.
