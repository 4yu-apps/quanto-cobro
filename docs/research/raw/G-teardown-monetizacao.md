# Teardown de features + Benchmarks de monetização

App-alvo: utilitário BR para freelancers (valor-hora + reserva de imposto + lucro de projeto).
Data: 2026-07-18. Método: WebSearch/WebFetch em fichas da Google Play (pt_BR/en), App Store, blogs de ASO/monetização, Reclame Aqui, relatórios de mercado. Estimativas frágeis marcadas **[não verificado]**.

**Nota de método:** as páginas do Google Play renderizam via JS e truncam para o fetcher — por isso a maioria dos **ratings/instalações do Play não pôde ser confirmada diretamente** e está marcada [não verificado]. Números exatos citados vêm da App Store (iOS) ou de agregadores/fontes secundárias, com a origem indicada.

---

## SEÇÃO 1 — TEARDOWN DE FEATURES

### 1A. Melhores avaliados

| App (package) | Telas / recursos | Monetização | Promessa da ficha | Estrutura bem | Rating/installs |
|---|---|---|---|---|---|
| **Doce Lucro – Precificação** (`com.jsl.profit`) | Fichas técnicas de receita; lista reutilizável de produtos/ingredientes; biblioteca de receitas; calculadora markup (custo + receita + margem desejada → preço sugerido); sugestão de precificação personalizada; backup em nuvem | Freemium (plano grátis + premium; tiers em R$ não expostos no site/loja) **[não verificado]** | Controle real de custos + fichas técnicas + precificar com lucro para quem trabalha com comida (doces, salgados, pães, marmitas) | Modelo de dados correto: ingredientes reutilizáveis → receitas → rollup de custo → margem. Ficha técnica como objeto de 1ª classe. Backup em nuvem ataca o medo nº1 (perder dados ao trocar de celular) | [não verificado] (não confundir com "Lucro na Confeitaria" `com.mayrinck.receitas`, app distinto) |
| **PeqArt – Precificação e muito +** (`com.pequenosencantos.peqartfinanceiro`) | Precificação (custos + custo de mão-de-obra por tempo baseado em salário-alvo + margem + taxa de maquininha → preço; trata rendimento por unidade); orçamentos PDF com logo (sinal, specs, prazo); catálogo online com venda direta; CRM de clientes (inclui aniversário de filhos, WhatsApp); IA gera descrição/imagem de produto; comparação de preços entre artesãos; gestão financeira (vendas, despesas, fluxo de caixa); iOS + Android + navegador | Assinatura (SaaS); tiers R$ não expostos publicamente **[não verificado]** | "O melhor app de gestão/precificação que aumenta suas vendas" — por artesãs, para artesãs | Escopo mais amplo: precificação é a porta de entrada para orçamento → catálogo/vendas → CRM → fluxo de caixa (um "OS" vertical). Diferenciais: custo de mão-de-obra atrelado a salário-alvo, taxa de cartão, benchmarking de preços, IA de listagem | [não verificado] |
| **Receitas – Quanto Cobrar** (`com.firebaseapp.recipecalculatorapp`) | Add receita → add materiais → margem desejada → rendimento (unidades); saída = custo total + preço sugerido; relatório de custo; auto-recalc (muda preço de 1 material → todas as receitas recalculam); listas de compra a partir das receitas; PT/ES/EN | Grátis com IAP. iOS mostra "Premium Recipes" a **R$ 12,90** e **R$ 29,90** (desbloqueio único, não assinatura). App leve (6,3 MB) | Saber exatamente quanto cobrar pelas receitas para lucrar de verdade; "fácil de usar" | O mais focado dos apps de precificação: 1 job (custo→preço) bem resolvido. Auto-recalc de ingrediente compartilhado é o gancho de retenção. Footprint mínimo | iOS **4,9/5** (314 avaliações); Play [não verificado] |
| **MEI Digital: DAS e Abrir MEI** (`com.meidigital.appmei`) | Abrir MEI (CNPJ); emitir/pagar DAS (boleto); consultar declarações (DASN-SIMEI); pendências/status; dados puxados de portais oficiais; regularização paga | Grátis com anúncios (iOS: "Grátis com anúncios"). Serviços pagos de formalização/regularização ~**R$ 149,90** (escala com anos em atraso) — serviços que são gratuitos no gov.br | Abrir MEI, emitir DAS, checar declarações — tudo do celular com dados oficiais | Consolida as tarefas recorrentes do MEI (DAS + declaração + status) num fluxo mobile com pagamento. Home orientada a tarefa | iOS **4,8/5** (270); Play [não verificado]. **Alerta de confiança:** reviews iOS chamam de "fake"/imitação de serviço do governo; fácil de confundir com o oficial "Meu MEI Digital" (`br.gov.memp.portaldoempreendedor`) [alegação de usuários, não verificado como fato] |
| **Mei em Foco: App para MEI** (`br.com.meiemfoco`) | Emitir DAS mensal (PIX/boleto); entregar DASN-SIMEI; fluxo de caixa; abrir MEI; parcelar DAS; encerrar MEI; atualizar CNPJ; recibos simples; certificado digital; certidão negativa (1ª grátis); emitir CCMEI; suporte humano WhatsApp/telefone | Freemium + serviços avulsos pagos. App/monitoramento grátis; recibos e CCMEI grátis; 1ª certidão grátis; regularização "baixo custo" parcelada em até 3x, com consultor cotando; R$ não publicados **[não verificado]** | "Tudo que você precisa para cuidar da sua empresa num único app" — monitoramento grátis, suporte humano que "entende de MEI" | Cardápio de serviços mais largo (11+ serviços incl. certidões e atualização de CNPJ). Split grátis-vs-pago claro; parcelamento reduz fricção; suporte humano diferencia vs. autoatendimento do governo; fluxo de caixa dá stickiness recorrente | Agregador cita média 7,9/10 (6 meses) [não verificado]; estrelas/installs Play [não verificado] |

**Padrão dos "melhores":**
- Apps de precificação (Doce Lucro, PeqArt, Receitas) compartilham o mesmo loop-núcleo: **ingredientes/insumos reutilizáveis → receitas/produtos → rollup de custo → margem → preço sugerido**, com **auto-recalc ao mudar preço de insumo** como gancho de retenção. PeqArt é o mais expandido; Receitas o mais mínimo (IAP único, não assinatura); Doce Lucro no meio (freemium).
- Apps de MEI (MEI Digital, Mei em Foco) monetizam igual: **app grátis envelopando serviços gratuitos do governo, com regularização/formalização paga** como a receita real (~R$ 149,90 no MEI Digital; cotação parcelada no Mei em Foco). Ambos competem — e arriscam confusão — com o app oficial gratuito "Meu MEI Digital".

### 1B. Piores avaliados (o que evitar — padrão estrutural de falha)

| App (package) | Telas / recursos | Monetização | Promessa | O que estrutura MAL (o valioso) | Rating/installs |
|---|---|---|---|---|---|
| **MEI Fácil / Neon** (`com.appmei`) | Conta digital PJ para MEI (conta, PIX, boleto, cartão), "Área MEI" com docs/procedimentos + camada de contabilidade/emissão. Sendo **absorvido no app Neon** (Área MEI virou aba); conta PJ e cartão MEI Fácil com desligamento anunciado p/ 06/05/2026 | Conta grátis (banco digital; monetiza por intercâmbio/tarifas/crédito). Sem assinatura | "Descomplicar a burocracia" do MEI numa conta digital só | **~1,5/5 com 250k+ downloads.** Falhas estruturais de **migração e continuidade de conta**: migração força "conta cancelada / CPF já tem conta" (beco sem saída de identidade); **saldo preso/não migrado** (dinheiro "sumido"); perda de acesso ao cartão de crédito pós-migração; suporte inalcançável. **Lição: nunca force migração de conta/dados que deixe o usuário sem acesso ao próprio dinheiro/login sem rota de recuperação** | ~1,5/5; 250k+ [installs verificado via secundárias; rating [não verificado] direto no Play] |
| **TurboTax** (`com.intuit.turbotax.mobile`) | Interview guiado passo a passo (o mais polido); foto do W-2 → autofill; upload/import de formulários; import do ano anterior; login biométrico; tiers Free/Deluxe/Live; checkout com add-ons (audit defense) | Freemium em tiers: Free (só W-2), Deluxe ~US$59, até ~US$129 federal + US$39–69/estado; Live US$99–219; add-ons no checkout | Declarar imposto pelo celular, "30% mais rápido", foto do W-2 preenche tudo, forte associação a "grátis" | Volume pesado de 1-estrela: **bait-and-switch de preço**. Usuário começa no Free, investe 30–60 min de dados, e só então evento comum (1099, HSA, juros) dispara **upgrade obrigatório** — depois que os dados já foram digitados e travam a saída. Taxa estadual revelada tarde; upgrades automáticos sem consentimento; upsells pré-marcados. FTC condenou a Intuit por propaganda enganosa de "free". **Lição: revele preço e requisitos de tier ANTES do usuário investir trabalho, nunca depois** | 10M+ installs [não verificado exato] |
| **MyTax (LHDN Malásia)** (`com.lhdn.mytax`) | App oficial da autoridade tributária: login (senha/passaporte/2FA-OTP), portal one-stop e-Filing/ezHASiL, e-Daftar (registro), "Basic Information", conta fiscal | Grátis, governamental. Sem ads/assinatura | "One-stop portal" para declarar imposto com conveniência pelo celular | Notoriamente mal avaliado por **infra/confiabilidade e login**: login trava em **loading infinito** (mesmas credenciais funcionam na web → app é o defeito); login não confiável mesmo após reset; ezHASiL lento/inacessível; **botão "Submit" sem resposta**; quedas sazonais no pico de declaração (glitch mar/2026 travou app e web na splash). **Lição: (a) paridade e confiabilidade mobile↔web; (b) capacidade para picos previsíveis (deadline fiscal); (c) estados de erro reais, não spinner eterno/botão morto** | Mal avaliado [rating exato não verificado] |

### 1C. Calculadora freela direta (comparável)

| App (package) | Telas / recursos | Monetização | Promessa | Estrutura | Rating/installs |
|---|---|---|---|---|---|
| **FreelaCalc** (`com.abp.freelancer_calculator`) | **4 modelos de cálculo**: hora ideal (renda desejada + horas disponíveis + despesas + margem-alvo), por projeto, por dia; resultado em tempo real ao digitar; histórico salvo no device, editável; exportar resultado como imagem; tema claro/escuro; **100% offline**; PT/EN/ES. Público: designers, devs, fotógrafos, redatores, consultores | Aparenta grátis e offline, sem coleta de dados; sinais de ads/IAP não visíveis **[não verificado]** | "Calcular exatamente quanto cobrar" como freelancer — por hora, projeto ou dia, com clareza e confiança | O comparável direto (não caso cautelar). App pequeno/nicho; rating e installs não recuperáveis **[não verificado]**. Positivos a copiar: **offline-first** (privacidade, funciona sem rede), histórico local editável, **export como imagem** (compartilhável), i18n pt/en/es, foco em 1 job — oposto do escopo inchado dos MEI/tax apps | [não verificado] |

**Padrão transversal do que EVITAR:**
1. **Custo/requisito escondido revelado tarde**, após o usuário investir trabalho (TurboTax) → mostre preço/limites antes do esforço.
2. **Migração/continuidade de conta e saldo que falha sem rota de recuperação** (MEI Fácil) → nunca deixe o usuário sem acesso ao próprio dinheiro/login.
3. **Login não confiável + falta de paridade mobile↔web + loading infinito no lugar de erro real**, ainda pior sob pico sazonal (MyTax).
4. Contraponto positivo (FreelaCalc): **escopo único bem resolvido, offline-first, dados locais, i18n** — barato de manter e difícil de gerar 1-estrela.

---

## SEÇÃO 2 — BENCHMARKS DE MONETIZAÇÃO

### 2.1 AdMob no Brasil (eCPM/RPM — banner + intersticial)

Brasil é mercado Tier-2/emergente: eCPMs ~⅓ dos EUA e bem abaixo do Tier-1. Ordem de grandeza (USD):

| Formato | Brasil | EUA/Tier-1 | Média global |
|---|---|---|---|
| **Banner** | ~**$0,10–$0,40** típico; pico ~**$1,10** (dez) | $0,50–$1,50 | $0,20–$0,80 |
| **Intersticial** | ~**$2,15 (out) → $3,67 (dez)**; ~$1,10 pico citado em outra fonte | $5,00–$8,00 | $2,50–$5,00 |
| **Rewarded video** | LatAm ~**$2–$4** | $15–$30 | $8–$18 |
| **Blended AdMob (todos formatos, BR)** | ~**$0,53** [não verificado — agregador] | ~$1,62 (US) | — |

**Implicação prática:** app *utilitário* tem frequência/duração de sessão muito menor que jogo → receita de ad por usuário é pequena. eCPM blended realista a modelar: **~$0,30–$1,00 [não verificado — estimativa para utilitário BR de baixa frequência, majoritariamente banner + intersticial ocasional]**. A ~3 impressões/sessão e poucas sessões/semana, o ARPU de ads fica na casa de **centavos por usuário/mês** — **ads sozinho não sustenta o app.**

Fontes: Playwire (https://www.playwire.com/blog/admob-ecpm-benchmarks-what-publishers-should-expect) · MonetizeMore (https://www.monetizemore.com/blog/admob-monetization/) · The SR Zone eCPM por país (https://www.thesrzone.com/2024/01/admob-ecpm-rates-by-country.html) [não verificado] · Business of Apps (https://www.businessofapps.com/ads/research/mobile-app-advertising-cpm-rates/)

### 2.2 Compra única "Pro" vs assinatura — normas de conversão (utilitários)

De RevenueCat State of Subscription Apps 2025:
- **Conversão download→pago:** paywall "hard" mediana **12,1%** vs freemium mediana **2,2%** (D35). Freemium é a norma mas converte 1 ordem de grandeza menos.
- **Utilitários lideram retenção de 1ª renovação: 58,1%** (Health & Fitness o menor, ~30%) — utilitário retém pagante uma vez convertido.
- **Retenção ano-1 por plano: anual 44,1% vs mensal 17,0% vs semanal 3,4%** — anual retém receita muito melhor.
- **Trial:** 17–32 dias converte melhor (~45,7% mediana); trials muito curtos (<4 dias) convertem menos (~25%). **Exceção:** utilitários/foto — trial curto de 3 dias pode converter **10–15% melhor**.
- **~35% dos apps já misturam assinatura com consumível ou lifetime/compra única** — mercado migrando de assinatura pura para híbrido.

Interpretação:
- **Assinatura → maior LTV** e é o padrão medido, mas exige valor recorrente contínuo (os 58% de renovação dos utilitários seguram *se* houver motivo recorrente de abrir o app — uma calc de imposto/DAS tem gatilho mensal forte).
- **"Pro" vitalício (compra única)** converte a fatia avessa a assinatura (culturalmente forte no BR) e reduz fricção de churn, ao custo de zero receita recorrente. Melhor prática 2025 = **oferecer os dois** (tendência híbrida de 35%).

Fontes: RevenueCat 2025 (https://www.revenuecat.com/state-of-subscription-apps-2025) · RocketShip HQ (https://www.rocketshiphq.com/revenuecat-state-of-subscription-apps-2025-summary/)

### 2.3 Preços que convertem — autônomo BR

Preços reais de nichos adjacentes (MEI/finanças/precificação):

| App | Modelo | Preço (R$) | Fonte |
|---|---|---|---|
| **Precifica.app** (calc de precificação — análogo mais próximo) | Assinatura, trial 7 dias | **R$ 9/mês intro, R$ 12,90/mês, ou R$ 97,80/ano** [não verificado — não confirmado direto na página] | https://precifica.app/ |
| **Apreço** (precificação p/ autônomos) | "PRO" remove ads + libera features | valor do Pro não confirmado | https://play.google.com/store/apps/details?id=com.aszudev.preocerto |
| **Organizze** (finanças pessoais) | Assinatura, trial 7d, sem tier grátis | **R$ 20,83/mês (anual) – R$ 32,90/mês (mensal)** | https://www.finvibe.app/blog/mobills-x-organizze-x-finvibe-x-minhas-economias-qual-o-melhor-app-de-financas |
| **Minhas Economias** | Grátis + premium/remoção de ads | a partir de ~**R$ 15,90/ano** (remoção ads) [não verificado] | (mesmo link FinVibe) |
| **Somei** (gestão MEI) | Trial grátis 30d → assinatura | valor não exposto | https://www.somei.com.vc/ |
| **Finlancer** (finanças MEI/freela) | Trial grátis 3d → pago | valor não exposto | https://www.finlancer.com.br/ |
| **Meli+** (benchmark de assinatura mass-market BR) | Assinatura | **R$ 9,90/mês** (tier entrada) | https://www.techtudo.com.br/guia/2026/03/planos-do-meli-veja-precos-e-diferencas-entre-essencial-total-e-mega-streaming.ghtml |

**Padrão:** teto de "impulso"/baixa fricção para utilitário single-purpose no BR fica em **R$ 9,90–14,90/mês**, com anual em torno de **R$ 90–100/ano** (Precifica R$ 97,80/ano é a âncora de nicho mais clara). Apps de finanças mais amplos (Organizze) sobem para R$ 20–33/mês, mas embutem sincronização bancária. R$ 9,90 é preço psicológico reconhecido no BR (Meli+).

### 2.4 Recomendação de modelo

**Modelo: Freemium com paywall híbrido — núcleo grátis + "Pro" oferecido como assinatura ANUAL e também compra única vitalícia. Não depender de ads.**

Razões:
1. **Ads não pagam a conta.** eCPM blended BR ~$0,53 + baixa frequência de utilitário → ARPU de ads em centavos/mês/usuário (§2.1). Use ad só como empurrão suave para o Pro (banner no tier grátis), não como motor de receita.
2. **Utilitários retêm pagante melhor (58% 1ª renovação)** e uma ferramenta de imposto/DAS + precificação tem **motivo mensal recorrente de abrir** — é exatamente onde o LTV de assinatura funciona (§2.2). Lidere com **anual** (44% retenção ano-1 vs 17% mensal).
3. **Ofereça vitalício ao lado** para capturar o autônomo BR avesso a assinatura e pegar a tendência híbrida de 35%.

**Preços sugeridos (R$):**
- **Pro Anual: R$ 89,90/ano** (≈ R$ 7,49/mês efetivo) — logo abaixo da âncora Precifica (R$ 97,80) e lido como o default "esperto".
- **Pro Mensal: R$ 12,90/mês** — casa com o mensal da Precifica; serve de âncora para fazer o anual parecer barato.
- **Lifetime "Pro Vitalício": R$ 129–149 (única)** **[não verificado — recomendação, sem comp direto de lifetime para app de precificação/imposto BR]** — ~1,5× o anual, atrativo para o avesso a compromisso sem canibalizar recorrência.
- Âncora opcional de entrada: tier **R$ 9,90/mês** se quiser bater o preço psicológico do Meli+; mas direcione ao anual.

**Mecânica de paywall:** paywall "hard-ish" nas saídas de maior valor (projeção de reserva de imposto, histórico salvo, export) com **trial curto de 3–7 dias** — utilitário é a categoria onde trial curto converte *melhor* (§2.2). Mantenha a calculadora básica grátis para sempre para puxar instalação e boca-a-boca na comunidade MEI/freela.

**Confiança:** faixas de eCPM e benchmarks RevenueCat bem fundamentados; preços de nicho BR (Precifica, Minhas Economias) vêm de artigos comparativos/snippets, não de páginas de IAP ao vivo — trate como direcionais **[não verificado]**. Preço lifetime é recomendação fundamentada, não comp observado.

Fontes §2: Playwire · MonetizeMore · The SR Zone · Business of Apps · RevenueCat 2025 · RocketShip HQ · Precifica.app · FinVibe · Somei · Finlancer · Meli+ (TechTudo). URLs completas nas seções acima.
