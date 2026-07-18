# Dimensionamento de mercado — App BR de precificação p/ freelancers/autônomos

Pesquisa de mercado para calculadora de valor-hora + reserva de imposto + lucro de projeto (MEI/CPF/Simples).
Data da pesquisa: julho/2026. Fontes primárias priorizadas (IBGE, Sebrae/DataSebrae, Receita, Bacen, Deel/Payoneer).

---

## TL;DR — os 6 números que importam

1. **26,1 milhões** de trabalhadores por conta própria no Brasil (recorde histórico, 2025; ~25% da população ocupada). [IBGE/PNAD Contínua, 2025]
2. **~16,3 milhões** de MEIs no registro federal (Sinac/gov, 2025) — mas apenas **~11,5 mi com registro ativo** pelo recorte do Sebrae, dos quais 90% de fato operando. A base "endereçável com CNPJ" é da ordem de **12–16 mi**; o resto dos 26 mi de conta-própria **não tem CNPJ**. [gov.br; DataSebrae, 2024]
3. **37,5%–38,1%** de taxa de informalidade (2025) = **~38,5 milhões** de trabalhadores informais. O conta-própria é o coração da informalidade — dor central de "não sei quanto cobrar nem separar imposto". [IBGE/PNAD, 2025]
4. **Renda média do conta-própria ≈ R$ 2.682–2.955/mês**; **85% ganham até 3 salários mínimos**. Orçamento apertado → preço do app precisa ser baixo e/ou modelo grátis+ads. [IPEA/PNAD 2º tri 2025]
5. **"Freela pra gringo": +53% de contratações remotas por empresas estrangeiras (2023→2024, Deel); Brasil é o 5º país** que mais exporta mão de obra remota. Exportação de serviços somou **US$ 51,8 bi em 2024** (Bacen). Nicho de alta dor tributária (carnê-leão mensal obrigatório, até 27,5%).
6. **~92,5% do mercado mobile BR é Android**; iOS concentrado na renda alta. Para público C/D o app **tem que nascer Android-first**. [Statista/Statcounter, 2025]

**Leitura estratégica:** o TAM bruto (26 mi conta-própria + assalariados que "fazem bico") é enorme mas pobre e sensível a preço → monetização por ads/freemium. O nicho **premium-pagante** de verdade é o "freela pra gringo"/dev/design que recebe em USD: menor em volume, mas com a dor de carnê-leão mais aguda e capacidade de pagar assinatura. Estratégia de dois públicos no mesmo app.

---

## 1. Tamanho do mercado BR

### Trabalhadores por conta própria (o núcleo do TAM)
- **26,1 milhões** em 2025 — **recorde da série histórica**, estável no 4º tri e +2,5% no ano (+638 mil pessoas). Representam **~25,3% da população ocupada** (102,4 mi no 3º tri/2025). [IBGE/PNAD Contínua]
  - https://agenciadenoticias.ibge.gov.br/agencia-sala-de-imprensa/2013-agencia-de-noticias/releases/45759-pnad-continua-em-2025-taxa-anual-de-desocupacao-foi-de-5-6-enquanto-taxa-de-subutilizacao-foi-14-5 (2025)
  - https://agenciadenoticias.ibge.gov.br/agencia-noticias/2012-agencia-de-noticias/noticias/45761-desocupacao-cai-para-5-1-em-dezembro-e-2025-tem-melhores-resultados-da-serie-historica (2025)
- **Crescimento:** de 20 mi (2012, início da série) para 26,1 mi (2025) = **+30,4%** em 13 anos. Dado mais recente (tri nov/25–jan/26): **26,2 mi**, +3,7% no ano.
- Payoneer também referencia "mais de 25 milhões de autônomos no Brasil". https://www.payoneer.com/resources/country-guides/brazilian-freelancers-rise-up/

### MEIs ativos (a base formalizada, com CNPJ)
Atenção: **as fontes divergem por definição** (total no registro vs. "ativo" vs. "em operação"). Reportar como faixa:
- **~16,3 milhões** de MEIs no total, segundo o Sinac do governo federal (2025); comunicação oficial cita "16 milhões de microempreendedores". https://agenciagov.ebc.com.br/noticias/202512/governo-federal-lanca-pacote-201cmei-em-acao201d-com-novo-app-rede-integrada-e-solucoes-digitais-para-fortalecer-16-milhoes-de-microempreendedores (2025)
- **~11,5 milhões com registro ativo** pelo recorte do Sebrae, dos quais **90% de fato operando** (vs. 77% em 2022, 72% em 2019). https://agenciasebrae.com.br/dados/brasil-bate-recorde-de-microempreendedores-individuais-em-atividade/ (out/2024)
- Perfil/renda: DataSebrae — https://datasebrae.com.br/perfil-do-microempreendedor-individual/ e https://datasebrae.com.br/mei/
- **Crescimento:** **+3 milhões de novos MEIs formalizados só até jul/2025** (recorde de aberturas). https://www.poder360.com.br/poder-economia/abertura-de-meis-bate-recorde-no-brasil-em-2025/ · https://istoedinheiro.com.br/mais-de-3-milhoes-de-meis-em-2025 (2025)
- Limite de faturamento MEI: **R$ 81 mil/ano** (teto que empurra os de maior renda para Simples/ME).
- **[não verificado]** Alguns portais citam 12,9 mi (out/2025) ou 13,1 mi (mar/2026) de "MEIs ativos" — provavelmente recortes intermediários da Receita entre "total registrado" e "operando". Tratar 12–16 mi como faixa.

### Informalidade / sem CNPJ
- **Taxa de informalidade: 38,1% (média anual 2025)**, caindo para **37,5% no tri nov/25–jan/26 = ~38,5 milhões de trabalhadores informais**. Em queda desde 2022. [IBGE/PNAD]
  - https://agenciabrasil.ebc.com.br/economia/noticia/2026-03/taxa-de-informalidade-cai-no-mercado-de-trabalho-mostra-ibge (2026)
  - https://agenciadenoticias.ibge.gov.br/agencia-sala-de-imprensa/2013-agencia-de-noticias/releases/45908-pnad-continua-trimestral-desocupacao-recua-em-seis-das-27-ufs-no-4-trimestre-de-2025 (2025)
- **Implicação p/ o app:** a diferença entre 26 mi (conta-própria) e ~12–16 mi (MEIs) sugere que **uma grande fatia dos autônomos atua sem CNPJ / como PF** — exatamente o público que não separa imposto e não sabe precificar. Forte variação regional (informalidade 57% no MA vs. 26% em SC).

---

## 2. Segmentos que mais sofrem com precificação

Não há um censo único por profissão de freelancer; combino registros MEI (beleza), estudos setoriais (TI) e bases de plataforma (design/redação/social).

| Segmento | Dado de tamanho | Fonte / ano |
|---|---|---|
| **Beleza** (cabeleireiro, manicure, estética) | **+1 milhão de CNPJs MEI**: cabeleireiros/manicure/pedicure 735.940 + estética 282.288. Maior categoria isolada de MEI. | DataSebrae via Sebrae, 2025 — https://sebrae.com.br/sites/PortalSebrae/artigos/brasil-tem-quase-15-milhoes-de-microempreendedores-individuais,e538151eea156810VgnVCM1000001b00320aRCRD |
| **Dev / TI** | Déficit de **~530 mil–800 mil** profissionais até 2025 (demanda 797 mil/5 anos; forma-se só 53 mil/ano vs. demanda 159 mil/ano). Setor com maior fuga p/ contratos em USD/EUR ("brain drain"). | Brasscom — https://brasscom.org.br/estudo-da-brasscom-aponta-demanda-de-797-mil-profissionais-de-tecnologia-ate-2025/ |
| **Design, redação, social media/marketing, foto** | Concentrados nas plataformas de freela (ver §3). Sem CNAE isolado confiável; muitos operam como PF/MEI "serviços de publicidade" e "design". | — |

- **Renda:** dev/TI é o segmento de maior renda e maior capacidade de pagar assinatura; beleza é altíssimo volume mas baixa renda e alta informalidade — bom para freemium+ads.
- **Base de freelancers cadastrados (proxy de tamanho dos criativos/digitais):**
  - **99Freelas: 1.883.433 freelancers cadastrados** (maior plataforma 100% BR). https://www.99freelas.com.br/ (2026)
  - **Workana: +2 milhões** de profissionais (LatAm, não só BR). https://www.freelanceronline.com.br/blog/plataformas-de-freelancer-no-brasil/
  - **[não verificado]** Blogs citam "mais de 13 milhões de brasileiros já trabalham como autônomos ou freelancers" — número frouxo, provavelmente confunde com o conta-própria do IBGE. Não usar como dado de freelancer digital.

---

## 3. "Freela pra gringo" (recebe em USD — Fiverr/Deel/Wise/Upwork)

### Quantos são / crescimento
- **+53% de crescimento** de profissionais brasileiros contratados por empresas estrangeiras entre 2023 e 2024; **Brasil é o 5º país** do mundo em nº de trabalhadores contratados por empresas internacionais ("global workers"). [Relatório Deel, via imprensa]
  - https://forbes.com.br/carreira/2025/02/profissionais-brasileiros-atraem-empresas-internacionais/ (2025)
  - https://jornal.usp.br/campus-ribeirao-preto/contratacoes-internacionais-remotas-crescem-mais-de-50-no-brasil/ (2025)
  - https://cndl.org.br/varejosa/profissionais-brasileiros-estao-cada-vez-mais-no-alvo-de-empresas-estrangeiras/
- **Exportação de serviços do Brasil: US$ 51,83 bilhões em 2024** (Bacen). Ainda subpenetrado: BR exporta ~2% em serviços vs. 4% média LatAm → espaço de crescimento. https://www.terra.com.br/economia/2025-e-o-ano-para-o-brasil-focar-na-exportacao-de-servicos,030984d0d7ff5bf89e48122489f346e0a8fsibct.html (2025)
- Ilustrativo (dev): de 1.428 devs BR atuando p/ exterior pesquisados, 1.220 trabalhavam p/ empresas americanas, salário médio até **US$ 110 mil/ano**. [via reportagem; amostra, não universo — **[não verificado]** como total de mercado]
- **[não verificado]** Não achei uma estimativa oficial única do "nº total de brasileiros que recebem do exterior". O melhor proxy duro é a combinação: exportação de serviços (US$ 51,8 bi), ranking Deel (5º) e o crescimento de 53%.
- Payoneer: **83% dos freelancers BR já oferecem ou planejam oferecer serviços a novos países** (Portugal, França, Alemanha à frente). https://www.payoneer.com/resources/country-guides/brazilian-freelancers-rise-up/

### Por que a dor tributária é mais aguda aqui
- Quem recebe do exterior **como PF (sem CNPJ)** deve recolher **carnê-leão MENSALMENTE** (Receita), tabela progressiva do IRPF **7,5% a 27,5%**, convertendo cada recebimento pela cotação do Bacen na data. Vencimento: último dia útil do mês seguinte. É obrigação recorrente, com risco de multa — diferente do freela nacional que muitas vezes ignora.
  - https://www.infomoney.com.br/minhas-financas/sou-freelancer-no-brasil-e-recebo-em-dolar-como-declarar-meu-salario-no-ir/
  - https://www.contabilizei.com.br/contabilidade-online/carne-leao/
  - https://pec.cnt.br/qual-a-tributacao-para-quem-recebe-em-dolar-por-servicos-prestados-para-empresas-fora-do-brasil/
- Camadas extras de dor: conversão de moeda (cotação do dia), possível INSS como contribuinte individual (20%), decisão MEI/PF/PJ. **Exatamente o que uma "reserva de imposto + valor-hora em USD" resolve.** Este é o público disposto a pagar.

---

## 4. Disposição a pagar / comportamento

- **Mercado mobile = Android dominante: ~92,5% de share de receita/OS em 2025**; iOS concentrado na renda alta. Samsung 34–39%, Motorola 20–30%, Xiaomi puxando o "budget". Público C/D = Android barato. **App deve nascer Android-first.**
  - https://www.statista.com/statistics/262167/market-share-held-by-mobile-operating-systems-in-brazil/ (2025)
  - https://gs.statcounter.com/os-market-share/mobile/brazil
- **Concorrência de apps de gestão p/ MEI/autônomo já é intensa e majoritariamente GRÁTIS** (Organizze, Balancinho 100% grátis, Neon, apps de banco, app oficial do MEI que já paga DAS). Isso **ancora a expectativa de preço perto de zero** para gestão financeira genérica.
  - https://blog.balancinho.com.br/gestao-financeira/contas-a-pagar-e-receber-gratuito/
  - https://neon.com.br/aprenda/mei/aplicativos-de-financas-do-mei/
- **Implicação:** monetizar "controle financeiro" puro é difícil (grátis é o default). O **valor pago está no específico e doloroso**: cálculo de valor-hora correto, reserva de imposto automatizada, carnê-leão/USD. YNAB (assinatura) prova que existe nicho disposto a pagar por método disciplinado — mas é minoria de alta renda.
- **[não verificado]** Não encontrei survey brasileiro com ticket médio de assinatura de app financeiro por autônomos. Recomendo tratar preço como hipótese a testar (freemium com paywall no imposto/USD), não como dado.

---

## 5. Renda e precariedade (baliza para preço e modelo)

- **Renda média do trabalhador por conta própria: ~R$ 2.682/mês** (4º tri/2024) a **~R$ 2.955** (recorte 2025); informais R$ 2.213; celetistas R$ 3.171. [IPEA/PNAD]
  - https://www.ipea.gov.br/cartadeconjuntura/index.php/2025/09/retrato-dos-rendimentos-do-trabalho-resultados-da-pnad-continua-do-segundo-trimestre-de-2025/ (2025)
  - https://www.gazetadopovo.com.br/economia/renda-de-autonomos-esta-crescendo-mais-que-a-de-trabalhadores-com-carteira-assinada/
- **85% dos autônomos ganham até 3 salários mínimos**; parcela pequena acima de 10 SM. Renda de autônomo **cresceu mais** que a do CLT (+5,6% interanual no 2º tri/2025) — sinal positivo de poder de compra marginal.
- **MEI:** 42% têm renda familiar de até 4 SM (DataSebrae). Teto de faturamento R$ 81 mil/ano.
- **Precariedade de jornada:** conta-própria trabalha **45,3 h/semana** vs. média nacional 39,1 h — mais horas para ganhar menos, reforçando a dor de "não sei se estou cobrando certo". https://agenciabrasil.ebc.com.br/economia/noticia/2025-02/trabalhar-por-conta-propria-exige-mais-horas-de-servico-diz-ibge (2025)

**Conclusão de pricing:** orçamento apertado + concorrência grátis ⇒ **freemium com ads no público massa (beleza, conta-própria C/D)** e **assinatura barata (R$/mês baixo) desbloqueando os módulos de imposto/USD para o público premium (dev/design/freela-gringo)**. Preço exato é hipótese a validar, não há dado duro de willingness-to-pay BR encontrado.

---

## Lacunas / ressalvas
- **MEIs "ativos":** faixa 12–16 mi por divergência de definição (Sinac vs. Sebrae vs. Receita). Sem número único canônico verificado.
- **Nº total de "freelas pra gringo":** não existe estatística oficial direta; usar proxies (exportação de serviços US$ 51,8 bi, ranking Deel 5º, +53% a.a.).
- **Willingness-to-pay / ticket de app financeiro por autônomo BR:** não encontrado em fonte primária — tratar como hipótese.
- "13 mi de freelancers" de blogs = **[não verificado]**, provável confusão com conta-própria do IBGE.
