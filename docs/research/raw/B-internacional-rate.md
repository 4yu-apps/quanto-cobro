# FRENTE B — Concorrentes INTERNACIONAIS de cálculo de valor-hora / freelance rate

Pesquisa para "Quanto Cobro?" (app BR). Foco: apps mobile (Google Play + iOS) e web tools
internacionais (EN/ES) de "freelance rate calculator" / "hourly rate" / "how much to charge" /
"tax to set aside". Data da coleta: 2026-07-18.

> **Aviso de confiabilidade.** Muitos apps mobile do nicho são minúsculos e recém-lançados:
> quase sem reviews e com contagem de instalações ambígua no HTML do Google Play (a página lista
> apps relacionados, então o scraper capta números que podem não ser do app-alvo). Marquei
> **[não verificado]** onde o dado é frágil. Os web tools e blogs são mais ricos em conteúdo
> qualitativo e foi de lá que veio a maior parte da leitura.

---

## 1. Panorama do mercado MOBILE (a descoberta que já é uma tese)

O achado mais forte da frente: **não existe um líder mobile no nicho de "rate calculator"**. É um
long tail de apps solo, todos com tração baixíssima e praticamente sem reviews. O melhor avaliado
(FreelaCalc, 4.9) tinha **apenas ~100+ instalações** confirmadas na página. Isso é evidência
direta de que (a) a categoria mobile pura de "calculadora de valor-hora" é nascente/pouco
defensável e (b) o valor real mora nos web tools de blogs de invoicing/time-tracking, que usam a
calculadora como isca de lead-gen — não como produto.

### Apps Google Play

| App | Package | Nota | Instalações | Modelo | Posicionamento |
|---|---|---|---|---|---|
| **FreelaCalc – Freelance Pricing** | `com.abp.freelancer_calculator` | **4.9** ★ | **100+** (verificado) | grátis, offline | O mais polido. 4 modelos: hora / projeto / dia / mensal. Histórico completo, dark mode |
| **Freelancer Pay Calculator / "Calculations Tool"** | `com.freelance_pay` | **4.2** ★ | ~1k–10k [não verificado] | grátis (provável ads) | Hora + "smart project pricing", foco em "maximize profits" |
| **The Freelance Suite Calculator** | `com.tfs.thefreelancesuite_android` | s/nota visível | **1.000+** | grátis + IAP | Nicho beleza/cabeleireiro. Wages + product cost + overhead + margem |
| **Freelance Fee & Tax Calculator** | `app.freelancecalc` | s/nota | **10+** | grátis | Único que bota **imposto** no nome; ainda assim ~zero tração |
| **Freelance Rate Calculator** | `com.FreelanceRate.Calculator` | s/nota | **10+** | grátis | Hora/dia/semana/mês + meta anual + breakdown |
| **Freelancer Rate Calculator (bistronic)** | `com.bistronic.freelancerratecalculator` | s/nota | **10+** | grátis | Genérico |

### Apps iOS (App Store US)

| App | ID | Nota | Modelo | Notas |
|---|---|---|---|---|
| **Freelance Rate Calculator** (Blas Prieto) | `6759358903` | 5.0 (1 rating) | grátis, sem paywall, offline | Tagline: *"Stop undercharging."* Inputs: take-home, expenses, insurance, vacation weeks, billable hours, **tax rate** → hora/dia/semana + **effective tax rate**. Sem reviews escritos |
| **The Freelance Suite Calculator** | `1642351899` | 1 review 5★ | grátis + IAP | Nicho beleza. Review verbatim abaixo |
| **WorkWage – Daily Earn Tracker** | `1435529413` | (review 1★) | pago/IAP | Tracker de ganho diário, não calculadora de rate. Review 1★ verbatim abaixo |
| **Job Pricing** | `6746676465` | 5★ x2 | grátis | Trades (encanador/eletricista): labor+materials+taxes+profit |
| **Service Cost Calculator** | `6785008908` | s/reviews | grátis | Trades/serviço |

**Reviews iOS verbatim coletadas** (via RSS `itunes.apple.com/us/rss/customerreviews/...`):

- The Freelance Suite (`1642351899`), 5★, *"worth it!"*, autor **Aidesuperstar**:
  > "Great for freelance/independent hairstylists/service providers. It take the guess work and
  > charge accordingly this app does it for you! Easy auto calculations to get you to hit your
  > desired income goals."
- WorkWage (`1435529413`), 1★, autor **Wayne Greenland**:
  > "Waste of money. I purchased app and App keep crashing when trying to edit something. SMH. Not good"
- Job Pricing (`6746676465`), 5★, **Nirvaan11**: *"Best free app available. It has lot of features to quickly calculate cost. Easy to use."*
- Job Pricing (`6746676465`), 5★, **Geosabajan**: *"help me a lot with on my business estimates fast and easy to use"*

> **Leitura das reviews:** volume ridiculamente baixo — a "voz do cliente" mobile praticamente não
> existe nesse nicho em inglês. O único negativo real é operacional (crash), não conceitual. Isso
> significa que a validação das dores do blueprint precisa vir dos **web tools e blogs**, não das
> lojas.

Fontes: [Google Play – FreelaCalc](https://play.google.com/store/apps/details?id=com.abp.freelancer_calculator&hl=en_US) ·
[Freelancer Pay](https://play.google.com/store/apps/details?id=com.freelance_pay&hl=en_US) ·
[The Freelance Suite](https://play.google.com/store/apps/details?id=com.tfs.thefreelancesuite_android&hl=en_US) ·
[Freelance Fee & Tax](https://play.google.com/store/apps/details?id=app.freelancecalc&hl=en) ·
[iOS – Freelance Rate Calculator](https://apps.apple.com/us/app/freelance-rate-calculator/id6759358903) ·
[iOS – The Freelance Suite](https://apps.apple.com/us/app/the-freelance-suite-calculator/id1642351899) ·
[iOS – Job Pricing](https://apps.apple.com/us/app/job-pricing/id6746676465)

---

## 2. Panorama WEB TOOLS (onde a briga de verdade acontece)

Aqui a categoria é madura. Praticamente todo web tool sério de rate é **isca de lead-gen** para um
SaaS de invoicing/time-tracking. Poucos são produto por si só.

| Tool | URL | Modelo | O que faz de diferente | Trata imposto? |
|---|---|---|---|---|
| **Harvest Rate Calculator** | getharvest.com/calculators/... | Grátis, lead-gen p/ Harvest ($12/mo) | Backward-from-income. Default **60% billable**, campo de overhead, **+20% buffer** e "set aside **25-30%**" | Genérico (regra 25-30%), NÃO calcula |
| **Bonsai Rate Explorer** | hellobonsai.com/rates/freelance | Grátis, lead-gen p/ Bonsai ($24/mo) | **Banco de dados de rates de MERCADO** por skill/experiência/geografia. Diferencial forte | Não — é comparação de mercado |
| **Bonsai Rate Calculator** (outro) | hellobonsai.com | Grátis | Backward-from-costs. Crítica citada: *"doesn't account for market rates — just your costs"* | Não |
| **Pinebill** | pinebill.app/tools/... | Freemium, lead-gen p/ invoicing | FAQ 10 perguntas + 8 dicas, overhead no cálculo | Imposto só no FAQ, **não** entra na fórmula |
| **PlutioRate/TaxCalc** | plutio.com/tools/... | Grátis, lead-gen | Rate calc + **tax calc separado** (SE tax 15.3% + federal + estadual) | Sim, mas 100% US (1099) |
| **AND CO / Fiverr Workspace calc** | via review | Grátis | Breakdown detalhado de despesas (assinaturas, dev profissional) | Crítica: *"doesn't indicate if rates are competitive"* |
| **GetHoldings** | getholdings.com/tools/... | Grátis, lead-gen | Texto didático forte sobre custos escondidos | Educacional, US-cêntrico |
| **FreelancerRatesCalculator.com** | freelancerratescalculator.com | Grátis | Backward-from-need; ensina % de horas faturáveis por senioridade | Menciona |
| **Chrome extension "Freelance Rate Calculator"** | Chrome Web Store | Grátis | **20+ tech stacks, 30+ países, ranking percentil + script de negociação** | Foco mercado, não imposto |
| **Infucial** | infucial.com | AI/freemium | "what clients actually pay" — recomendação por dados de mercado | Não |
| **FairPrice** | via DEV.to | **$50 one-time** | Alinhamento **anônimo** de orçamento freela↔cliente (sem negociação) | Não |

### Ferramentas de "imposto a reservar" (categoria adjacente, 100% US)

Categoria separada e madura, mas **inteiramente amarrada ao sistema tributário americano (1099 /
Self-Employment tax 15.3% / estados)**: **Keeper (keepertax)**, **Everlance**, **FlyFin**,
**TurboTax Self-Employed**, **Bench**, **Lunafi**, **SelfPaidCalc**, **1800accountant**.

- Regra genérica repetida em toda parte: *"set aside **25–30%** of your self-employed income"*;
  high earners / estados caros (CA, NY, OR) → **35–40%**.
- **Keeper** é o que mais se aproxima do "reservar por pagamento": conecta contas, categoriza
  despesas o ano todo e calcula **pagamento trimestral estimado**. Reclamações recorrentes: cobrança
  após trial de 14 dias (*"scam"* no Trustpilot/BBB), erros de filing multi-estado, suporte só por
  email. Preço: $20/mo (deduções) a $399/ano (premium).

Fontes: [Harvest](https://www.getharvest.com/calculators/freelance-rate-calculator) ·
[Bonsai Rate Explorer](https://www.hellobonsai.com/rates/freelance) ·
[Pinebill](https://www.pinebill.app/tools/freelance-rate-calculator) ·
[DEV.to – Best Freelance Pricing Tools 2025](https://dev.to/fairpricework/best-freelance-pricing-tools-in-2025-budget-calculators-negotiation-software-23k0) ·
[GetHoldings](https://getholdings.com/tools/freelancer-rate-calculator) ·
[FreelancerRatesCalculator](https://www.freelancerratescalculator.com/) ·
[Chrome extension](https://chromewebstore.google.com/detail/freelance-rate-calculator/ofmocfkagkdpbkapmjmobbnomjkiphlf) ·
[Keeper review](https://financebuzz.com/keeper-tax-review) ·
[Keeper set-aside](https://www.keepertax.com/self-employment-tax-rate-calculator) ·
[Everlance](https://www.everlance.com/tax-calculator) ·
[FlyFin](https://flyfin.tax/1099-tax-calculator)

---

## 3. Dores universais — evidência VERBATIM (com URL)

Isso valida as teses 1-2 do blueprint com fonte:

- **Undercharging é a dor #1, quantificada:**
  > "67% of freelancers undercharge for their services, leaving potentially **$15,000–50,000+
  > annually** on the table"
  — contexto agregado das buscas (freelancehourlyrate.com / infucial). *[fonte secundária, número
  redondo — tratar como marketing, não dado auditado]*

- **A causa mecânica do undercharge (ótimo para didática do app BR):**
  > "Most freelancers undercharge — sometimes by **30-50%** — because they only account for their
  > desired salary and forget about **taxes (15.3% SE tax alone), health insurance, retirement,
  > software, and the 30-40% of their time that isn't billable**"
  — [GetHoldings](https://getholdings.com/tools/freelancer-rate-calculator)

- **Horas não-faturáveis, com número por senioridade:**
  > "New freelancers typically bill **50–60%** of their working hours; experienced freelancers with
  > steady clients might reach **70–80%**"
  — [FreelancerRatesCalculator](https://www.freelancerratescalculator.com/)
  > Harvest: o resto "goes to admin, marketing, proposals, and learning" (default 60% billable)

- **Imposto tratado como afterthought genérico** (valida tese 3):
  > Harvest: "set aside **25-30%** of their income for taxes" + "+20% buffer for taxes and
  > contingencies" — [Harvest](https://www.getharvest.com/calculators/freelance-rate-calculator)
  > Pinebill: imposto só aparece no FAQ ("account for taxes... separately"), **não entra na fórmula**
  > — [Pinebill](https://www.pinebill.app/tools/freelance-rate-calculator)

- **Arrependimento de rate baixo (imposter syndrome):**
  > "A 2019 study by AND CO found that **77% of freelancers wish they had started with higher
  > rates** due to imposter syndrome, fear of losing clients, and incorrect math"
  — citado por [Plutio](https://www.plutio.com/tools/rate-calculator). *[não verifiquei o estudo
  original AND CO; é citação de terceiro]*

---

## 4. (a) O que falta pro caso BRASILEIRO · (b) quem resolve imposto/simulador

**(a) O buraco brasileiro é total.** Nenhuma ferramenta internacional encontrada trata:
- MEI / DAS / Simples Nacional / anexos / fator R;
- INSS do autônomo / carnê-leão / DARF mensal;
- a lógica de "pró-labore" vs. distribuição de lucro.

Quando um gringo "trata imposto", ele faz **uma de duas coisas**: (1) chuta um **percentual
genérico 25-30%** (Harvest, blogs); ou (2) calcula o **sistema americano** literal — 1099, SE tax
15.3%, imposto estadual (Keeper, Everlance, FlyFin, Plutio, Bench). **Ambos são inúteis para o
brasileiro** e, pior, o segundo caso *parece* preciso mas está simplesmente errado no contexto BR.
Isso é a evidência que o blueprint pedia: **o contexto tributário é local e não sobrevive à
fronteira.** Um MEI que reservasse "30%" estaria reservando ~5x demais; um que aplicasse SE tax
15.3% estaria calculando um imposto que nem existe aqui.

**(b) Quem resolve bem cada peça (para roubar UX, não conteúdo):**
- **Imposto a reservar recorrente:** ninguém no nicho de *rate calculator*. Quem chega perto é
  **Keeper** — mas é um app de **contabilidade/filing** (conecta banco, categoriza despesa, estima
  trimestre), não uma calculadora. O padrão "reserva por pagamento" que o blueprint quer **não
  existe pronto** internacionalmente para freelancer — há espaço claro.
- **Simulador de projeto / lucro real:** o mais perto é **FairPrice** (alinhamento de orçamento
  anônimo) e os "job pricing" de trades (**Job Pricing**, **Service Cost Calculator**) que somam
  labor+materiais+imposto+margem por job. Nenhum faz "lucro real depois do imposto" de forma
  didática para conhecimento intelectual/freela digital.
- **Benchmark de mercado:** **Bonsai Rate Explorer** é o melhor (banco de rates por skill/geo) e a
  **Chrome extension** (percentil + script de negociação) é a execução mais esperta. Nada disso
  existe para o Brasil.

---

## 5. LEITURA vs BLUEPRINT (tese a tese)

| # | Tese do blueprint | Veredito | Evidência |
|---|---|---|---|
| 1 | Concorrentes são "calculadoras rasas de 1 campo", sem contexto/didática | **PARCIALMENTE CONTRADIZ / ACRESCENTA** | Os **apps mobile** sim são rasos e sem tração. Mas os **web tools de blog** (Harvest, Pinebill, GetHoldings) têm didática robusta (FAQ 7-10 perguntas, dicas, explicação de horas não-faturáveis). O que falta neles não é didática — é (a) mobile-first e (b) contexto tributário local. Rasgue "eles não ensinam"; a lacuna real é "ensinam genérico e são web/EN" |
| 2 | Dores universais: cobrar de menos (ignorar não-faturáveis/férias/custos) + não reservar imposto | **VALIDA (forte)** | Verbatim GetHoldings/Harvest/FreelancerRates acima. 30-40% do tempo não-faturável e "esquecer taxes" são citados literalmente como a causa mecânica do undercharge |
| 3 | Contexto tributário é local; app gringo NÃO serve o BR; gringos ignoram ou tratam genérico (25-30%) | **VALIDA (forte)** | Confirmado nos dois padrões: percentual genérico "25-30%" (Harvest/blogs) OU sistema US literal 1099/SE-tax/estadual (Keeper/Everlance/FlyFin/Plutio). Zero menção a MEI/DAS/Simples. Bonsai só cobre US/UK/Canadá |
| 4 | Retenção via tools recorrentes (reserva por pagamento, simulador) — algum gringo faz bem? | **ACRESCENTA (oportunidade aberta)** | Nenhum *rate calculator* faz. **Keeper** faz reserva/estimativa recorrente mas é app de contabilidade caro e 100% US. O padrão "reservar imposto por pagamento recebido" não existe pronto para freela — espaço claro para o app BR |
| 5 | Modelo de negócio dos gringos | **VALIDA/ACRESCENTA** | Três padrões: (1) **calculadora grátis como isca de lead-gen** para SaaS de invoicing/time-tracking ($12-39/mo: Harvest, Bonsai, Pinebill, HoneyBook) — o mais comum; (2) **app mobile grátis** com ads/IAP e tração baixíssima; (3) **assinatura de tax/contabilidade** (Keeper $20-399/ano). Ninguém monetiza a calculadora em si — ela é sempre porta de entrada |

---

## 6. O QUE O BRASIL PODE ROUBAR DOS GRINGOS (UX/features)

1. **"Stop undercharging" como headline** (iOS Blas Prieto). O gancho emocional funciona e é o
   mesmo do blueprint BR. Roubar o tom.
2. **Backward-from-income com default de horas faturáveis** (Harvest: 60% pré-preenchido). Não peça
   ao usuário adivinhar — dê o default e explique. Adaptar % por senioridade (50-60% novato /
   70-80% experiente — FreelancerRatesCalculator).
3. **Effective tax rate como output visível** (iOS Blas Prieto mostra a alíquota efetiva). No BR
   isso vira ouro: mostrar "sua alíquota efetiva como MEI é X%" educa e diferencia do "chute 30%".
4. **4 modelos numa tela** (FreelaCalc: hora/projeto/dia/mensal) — cobre os formatos reais de
   cobrança sem virar app complexo. É o app mobile mais bem avaliado (4.9) do nicho por isso.
5. **Rate Explorer / benchmark de mercado** (Bonsai) + **percentil + script de negociação**
   (Chrome extension). Um "quanto cobram outros [designers/devs] no Brasil" seria feature matadora e
   inédita localmente. Começar com dados próprios (submissões de usuários) como o Bonsai fez.
6. **FAQ/didática embutida** (Pinebill 10 perguntas, Harvest 7). Transformar o "porquê" de cada
   número em micro-conteúdo dentro do app — os gringos provam que isso converte.
7. **Reserva de imposto recorrente por pagamento** (inspirado em Keeper, mas simplificado e
   MEI-nativo). Nenhum rate calculator faz; é o gancho de retenção que o blueprint pede e que
   ninguém ocupou lá fora.
8. **Job pricing = labor + custos + imposto + margem** (Job Pricing, Service Cost Calculator) como
   base do "simulador de lucro real do projeto" — mas fechando com **lucro líquido pós-DAS**, que
   nenhum gringo faz.
9. **Offline + sem cadastro + sem paywall** (FreelaCalc, iOS Blas Prieto) como padrão de entrada.
   Fricção zero é norma no nicho; cobrar cadastro na porta seria desvantagem competitiva.

### Armadilhas a evitar (o que os gringos erram)
- **Calculadora pura não retém nem monetiza** — todos viraram isca de outro produto. O app BR
  precisa nascer com a *tool recorrente* (reserva/simulador) como núcleo, não como calculadora avulsa.
- **Nicho mobile tem tração baixíssima** — descoberta e didática precisam ser o diferencial, senão
  vira mais um app de 100 instalações.
- **Não copiar o "25-30%"** — no BR isso está errado e destrói a credibilidade que é justamente o
  diferencial do produto.

---

### Notas de método / limites
- Reviews iOS coletadas via RSS `itunes.apple.com/us/rss/customerreviews/id=APPID/sortBy=mostRecent/json`.
  Volume real de reviews no nicho é quase nulo — conclusões qualitativas vêm sobretudo de web tools/blogs.
- Contagens de instalação do Google Play: só **FreelaCalc (100+)**, **The Freelance Suite (1.000+)**,
  **Freelance Fee & Tax (10+)** e outras "10+" são confiáveis; onde apareceu faixa ampla marquei
  **[não verificado]** (HTML da página mistura apps relacionados).
- Buscas WebSearch são US-only; cobertura de ferramentas em **espanhol** ficou fraca — não encontrei
  player hispano relevante distinto dos acima. Registrar como **lacuna não coberta** desta rodada.
- Estatísticas "67% undercharge / $15-50k" e "77% AND CO 2019" são citações de marketing de terceiros,
  **não auditadas na fonte primária**.
