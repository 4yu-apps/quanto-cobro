# Frente C — Ecossistema BR de apps MEI / Imposto / Reserva do Autônomo

Pesquisa para "Quanto Cobro?" — função central "recebi um pagamento, quanto reservo de imposto?"
Data: 2026-07-18. Fontes: Google Play, App Store (RSS reviews), Reclame Aqui, blogs comparativos, portais de contabilidade.

Nota de método: as páginas do Google Play e do Reclame Aqui são renderizadas por JS / bloqueiam fetch direto (403), então notas/instalações desses vêm de snippets de busca e de agregadores — marcados **[não verificado direto]**. Reviews verbatim do iOS vêm do feed RSS oficial da Apple (confiável). Reviews verbatim do Android não foram acessíveis diretamente.

---

## MAPA DOS APPS

### Bloco 1 — Gestão MEI / DAS / Contabilidade (o "core" do mercado)

| App | Loja | Nota | Instalações | Modelo | Posicionamento |
|---|---|---|---|---|---|
| **MaisMei (Mais MEI)** | Play + iOS (id 1437671032) | iOS ~mista, muitas 1★ recentes; Reclame Aqui 8,2/10 (390 reclam.) **[não verif. direto]** | 1M+ classe **[não verif.]** | Freemium — abertura grátis, serviços pagos (certificado, parcelamento, suporte) | "SuperApp do MEI": abre CNPJ, emite DAS, DASN, CND, benefícios INSS |
| **Qipu (ERP e Contabilidade)** | Play + iOS (id 970158643) | Play 4,0 / iOS 3,8 **[não verif. direto]**; Reclame Aqui 7,9/10 (109 reclam.) | 500k+ classe **[não verif.]** | Assinatura (ERP + contabilidade online) | ERP para MEI/ME/EPP: NFS-e, boletos, controle vendas/despesas, CND |
| **MEI no controle** | Play (com.openmei.meinocontrole) | **[não verif.]** | **[não verif.]** | Freemium | Contador online p/ MEI: notas de produto/serviço, envio de extrato |
| **Controlle (MEI e PME)** | Play (com.controlle.android) | **[não verif.]** | **[não verif.]** | Freemium | Controle de despesas + emissão NFS-e (500+ cidades) |
| **SOMEI** | Play (com.somei...) | **[não verif.]** | **[não verif.]** | Freemium | Controle de vendas/estoque p/ MEI e autônomo |
| **App MEI (Receita Federal — oficial)** | Play + iOS | Alta (oficial) **[não verif.]** | Milhões **[não verif.]** | Grátis (governo) | Emite DAS, DASN, e desde ago/2024 **manda push lembrando o vencimento** |

### Bloco 2 — Carnê-Leão / Imposto do autônomo-CPF (nicho pequeno, novo)

| App | Loja | Nota | Modelo | Posicionamento |
|---|---|---|---|---|
| **Leão Manso** | iOS only (id 6758678920) | 1 review (5★) — app **muito novo** | Freemium: grátis calcula carnê-leão mensal; Pro R$24,90 **vitalício** (MEI/ME, IRPF anual, Fator R, PDF) | "Carnê-Leão simplificado para freelancers": calcula, deduz (INSS/pensão), gera DARF; disclaimer explícito de ser "ferramenta de estimativa" |
| **Fiscalia** | Web/app (fiscalia.app) | **[não verif.]** | Freemium (chat IA + simulador + API) | "IA com evidências pra tributário BR"; guia carnê-leão em linguagem mastigada + simulador. Não confirma se manda lembrete ou reserva |
| **Prazo Certo: DAS MEI Lembrete** | Play (com.prazocerto.app) | **[não verif.]** | Grátis/freemium | App de UMA função: avisa antes do dia 20 pra não esquecer o DAS |
| Carnê-Leão Web / Sicalc (gov) | Web (e-CAC) | — | Grátis (governo) | Ferramenta oficial, exige login gov.br prata/ouro; burocrática |

### Bloco 3 — "Quanto cobrar" / Precificação (o outro lado, quase todo WEB, não app)

| Ferramenta | Formato | Posicionamento |
|---|---|---|
| Freelaz | Web | Calculadora de valor/hora do freelancer BR (considera custo de vida, impostos, cliente internacional) |
| Calculadora Brasil | Web | Valor-hora PJ/MEI/Freela; inclui Simples, DAS, margem |
| Contabilizei — Calculadora Freelancer | Web | Valor-hora com estrutura de custos (tecnologia, saúde, impostos) |
| 99Freelas — Calculadora | Web | Quanto cobrar por hora/projeto |

### Bloco 4 — Controle financeiro genérico (usado por autônomo, mas sem imposto)

Organizze, Mobills, Minhas Economias, Wisecash, Monefy, Money Manager, Meu Caixa MEI, Bling, MoneyWise. Todos rastreiam entrada/saída e separam PF/PJ — **nenhum estima ou reserva imposto**.

---

## RECLAMAÇÕES VERBATIM (evidência)

### MaisMei — iOS (feed RSS, verbatim, mais recentes)
Fonte: `https://itunes.apple.com/br/rss/customerreviews/id=1437671032/sortBy=mostRecent/json`
Padrão dominante nas 1★: acham que é golpe / confundem com app do governo / pagamento "não consta".
- "Golpe" — cobram R$70 por serviço gratuito do governo (DASN MEI) — *João Vitor Santos 97* (1★)
- "É GOLPE!" — PIX pra app não-oficial, ameaça de ação judicial — *MariaF.Andrade* (1★)
- "Pagamento não consta" — pagou com comprovante, não creditou, ainda cobra juros — *thamires_galvao* (1★)
- "Quase caí" — CNPJ mostrado falsamente como inativo, quase pagou R$70 — *Microempreendedor2026* (1★)
- "Tudo tem que pagar no app" — tudo atrás de paywall, inclusive suporte — *123chrias2* (1★)
- "Suporte pago!" — precisa de premium pra falar com suporte — *Sá Macedo* (1★)
- 5★ existem e elogiam o oposto: "app excelente, fácil de fazer os pagamentos" — *Eder Klucek*; "extremamente prático e ajuda muito" (DAS) — *Layza Alves*

### Qipu — iOS (feed RSS, verbatim)
Fonte: `https://itunes.apple.com/br/rss/customerreviews/id=970158643/sortBy=mostRecent/json`
Distribuição no feed: 30×1★, 6×2★, 3×3★, 3×4★, 8×5★ (fortemente polarizado).
- "Péssimo atendimento" / "Atendimento da empresa está lamentável! Simplesmente não há!" (suporte)
- Falha na emissão de NFe; notificação de DAS persiste depois de pago; cobrança duplicada
- "não contabilizaram as vendas" — vendas não entram na contabilidade
- App fecha sozinho, trava ao enviar foto no chat, login falha
- Pedidos de feature: ordem de serviço, campo de descrição no orçamento, lançamento recorrente/fixo, relatório de fluxo de caixa exportável
- 5★: "Aplicativo é muito bom", "Fácil de entender"

### Reclame Aqui (resumos, **[não verif. direto — 403]**)
- **Mais MEI** 8,2/10, 390 reclam., 85,5% resolvidas. Tema recorrente: cobrar pelo que é grátis, confusão com app do governo, pagamento que não registra no sistema federal.
- **Qipu** 7,9/10, 109 reclam., 83,6% resolvidas, resposta média lenta (17 dias). Tema: falhas no início do mês (justo quando mais se usa), NFe/NFSe que não emite, suporte.

---

## RESPOSTAS ÀS TESES

### 1. A dor de "não reservar pro imposto e tomar susto" é real? — **VALIDA (forte, mas indireta)**
A dor é documentada pela consequência, não tanto por review de app (porque quase nenhum app trata reserva — não há onde reclamar disso ainda). Evidências:
- Contadores recomendam **reservar 15%–30% do faturamento** (ou 10–15% da receita bruta) pra imposto — existe regra de bolso justamente porque as pessoas *não fazem* naturalmente. (iure.digital, mercadopago blog)
- Carnê-leão não pago no mês vira **multa de 50% + juros** e cai na malha fina — o "susto" tem preço concreto. (Contabilizei, CartaCapital: "25 milhões de autônomos")
- MEI que estoura R$81k/ano sem reservar leva **DAS complementar retroativo + juros/multa** e pode ser desenquadrado retroativamente. (Contabilizei, 99app)
- A Receita passou a mandar push de vencimento do DAS e isso sozinho subiu pagamento em dia **+9%** e arrecadação **+16%/mês (~R$49M)** — prova de que uma fatia grande simplesmente esquece/não se organiza. (Receita Federal / mixvale / contabeis)

Ressalva honesta: não achei um review dizendo textualmente "tomei susto porque não guardei". A dor aparece nos artigos de contabilidade e nas consequências, não na voz do usuário de app — provavelmente porque **o produto que endereçaria essa dor ainda não existe direito**.

### 2. Como tratam a estimativa de imposto por regime? — **Burocrático/fragmentado; simples é raro e novo**
- Apps de MEI (MaisMei, Qipu) tratam DAS como **boleto a emitir**, não como "quanto reservar" — o valor do DAS é fixo/tabelado, então nem calculam.
- Autônomo-CPF (carnê-leão) é onde há estimativa real: **Leão Manso** e **Fiscalia** fazem em linguagem mastigada — mas são apps novos, minúsculos (Leão Manso tem 1 review), iOS-first.
- O canônico oficial (Carnê-Leão Web / Sicalc) é burocrático: exige gov.br prata/ouro, jargão, DARF código 0190.
- Simples Nacional / Fator R aparece só em nichos (Leão Manso Pro) e em calculadoras web.

### 3. Alguém já une "quanto cobrar" + "quanto reservar de imposto"? — **NÃO. Mercado fragmentado. (VALIDA a tese central)**
Isto é o achado mais importante da frente:
- **Lado "quanto cobrar"**: quase tudo é **calculadora web** (Freelaz, Calculadora Brasil, Contabilizei, 99Freelas), de uso único — você calcula o valor-hora uma vez e vai embora. Elas *incluem* imposto no cálculo do preço (fórmula gross-up, "cobra R$1.111 pra receber R$1.000 limpo"), mas **não acompanham** os recebimentos nem mandam reservar depois.
- **Lado "quanto reservar / DAS"**: apps de gestão (MaisMei, Qipu, Prazo Certo) e de carnê-leão (Leão Manso) — tratam obrigação e boleto, **não** ajudam a precificar.
- **Ninguém liga os dois num fluxo contínuo** "recebi X → do preço que cobrei, reserve Y de imposto → aqui está a guia/lembrete". A ponte entre precificar e reservar está vazia.

### 4. Reclamações recorrentes — **VALIDA + ACRESCENTA**
Ranking das dores nos apps existentes (verbatim acima):
1. **Cobrança escondida / "cobram o que é de graça"** — dor nº1 do MaisMei; confusão com o app do governo é um padrão de mercado.
2. **Suporte pago / inexistente** — Qipu e MaisMei; "pra falar com suporte tem que ser premium".
3. **Pagamento que não registra no sistema federal** — gera pânico de "estou devendo/golpe".
4. **Bugs justamente no começo do mês** (Qipu) — quando mais se precisa.
5. **Tudo atrás de paywall**; **exigir cadastro/gov.br** e falhar na autenticação.
Implicação pro Quanto Cobro?: **transparência de preço** e **não se passar por/atritar com o governo** são diferenciais baratos e imediatos.

### 5. Expectativa de UX do brasileiro sobre imposto — **Quer o número mastigado + lembrete; emitir guia é bônus**
- **Número mastigado**: as regras de bolso ("guarde 20%") e o sucesso de calculadoras de uma tela mostram que o usuário quer *um número*, não uma planilha de regime.
- **Lembrete é expectativa consolidada**: a própria Receita validou que push de vencimento move a agulha (+9% em dia). Existe até app de função única só pra isso (Prazo Certo). Lembrete não é diferencial — é **table stakes**.
- **Emitir a guia** (DAS/DARF) é desejado mas secundário e tecnicamente pesado; muitos preferem só saber quanto e quando. Leão Manso trata "gerar DARF" como feature Pro.
- Aversão a burocracia/jargão e a cadastro pesado (gov.br) é clara nas reclamações.

---

## SÍNTESE

### A DOR DO IMPOSTO É REAL? (evidência)
Sim, mas é uma **dor silenciosa**: não aparece como review raivoso porque o produto que a resolveria mal existe. Ela aparece (a) nas regras de bolso que os contadores repetem (reserve 15–30%), (b) nas penalidades concretas (multa de 50% do carnê-leão, DAS complementar retroativo do MEI que estoura limite), e (c) no dado da Receita de que um simples lembrete de DAS aumentou arrecadação em ~R$49M/mês — ou seja, muita gente só não paga/não se organiza por esquecimento e desorganização, não por falta de dinheiro. A dor de "reservar" e a de "não esquecer" são o mesmo problema.

### O MERCADO É FRAGMENTADO? (preço vs imposto separados)
Totalmente. Três silos que não conversam:
1. **Calculadoras de preço** (web, uso único) — incluem imposto no preço mas não acompanham.
2. **Apps de DAS/gestão MEI** (MaisMei, Qipu) — obrigação e boleto, sem precificação, reputação manchada por cobrança escondida.
3. **Apps de carnê-leão** (Leão Manso, Fiscalia) — novos, minúsculos, iOS-first, só imposto do CPF.
E o controle financeiro genérico (Organizze, Mobills) ignora imposto por completo. **Ninguém percorre "cobrei → recebi → reserve isto → não esqueça a guia".**

### OPORTUNIDADE PARA O QUANTO COBRO?
1. **Ser a ponte que ninguém construiu**: o mesmo app que diz "cobre R$X" já sabe a margem de imposto embutida — fechar o loop mostrando "deste recebimento, separe R$Y" é natural e único no mercado.
2. **Número mastigado > planilha**: entregar um valor único de reserva por regime (MEI/CPF-carnê-leão/Simples), escondendo o jargão, ataca direto a dor da tese #2 e #5.
3. **Lembrete é obrigatório, não diferencial** — precisa ter, mas não vende sozinho (a Receita e o Prazo Certo já fazem).
4. **Ganhar na confiança**: o mercado MEI está queimado por cobrança escondida e apps que se confundem com o governo. Preço transparente, sem se passar por Receita, sem paywall no suporte — é diferencial reputacional barato.
5. **Cuidado de escopo**: emitir DAS/DARF de verdade é caro e é onde os concorrentes têm bugs e reclamação. Talvez começar por "quanto reservar + quando + lembrete", e deixar a emissão como link pro app oficial, evita a maior fonte de 1★ do setor.
6. **Público-alvo do loop**: autônomo-CPF (carnê-leão) é o mais mal atendido e onde a estimativa de imposto é variável (logo, valiosa). MEI tem DAS fixo — pra ele o valor está mais no "não estourar o limite" e no lembrete do que no cálculo.

---

## FONTES
- Play — MaisMei: https://play.google.com/store/apps/details?id=com.supermei.supermei
- Play — MEI no controle: https://play.google.com/store/apps/details?id=com.openmei.meinocontrole
- Play — Controlle: https://play.google.com/store/apps/details?id=com.controlle.android
- Play — SOMEI: https://play.google.com/store/apps/details?id=com.somei.mei.financeiro.facil
- Play — Qipu: https://play.google.com/store/apps/details?id=br.com.qipu.app
- Play — Prazo Certo (DAS MEI Lembrete): https://play.google.com/store/apps/details?id=com.prazocerto.app
- iOS — MaisMei (id 1437671032): https://apps.apple.com/br/app/meu-mei-das-e-abertura-mei/id1437671032
- iOS — Qipu (id 970158643): https://apps.apple.com/us/app/qipu-erp-e-contabilidade/id970158643
- iOS — Leão Manso (id 6758678920): https://leaomanso.xk2.com.br/
- iOS reviews RSS — MaisMei: https://itunes.apple.com/br/rss/customerreviews/id=1437671032/sortBy=mostRecent/json
- iOS reviews RSS — Qipu: https://itunes.apple.com/br/rss/customerreviews/id=970158643/sortBy=mostRecent/json
- iOS reviews RSS — Leão Manso: https://itunes.apple.com/br/rss/customerreviews/id=6758678920/sortBy=mostRecent/json
- Reclame Aqui — Mais MEI: https://www.reclameaqui.com.br/empresa/mais-mei/
- Reclame Aqui — Qipu: https://www.reclameaqui.com.br/empresa/qipu/
- Neon — 11 apps de finanças do MEI: https://neon.com.br/aprenda/mei/aplicativos-de-financas-do-mei/
- Finanças pro Autônomo — 10 apps: https://www.financasproautonomo.com.br/financas-para-autonomos/10-melhores-aplicativos-para-controle-financeiro-pessoal-e-profissional/
- Fiscalia — guia carnê-leão 2026: https://fiscalia.app/blog/carne-leao-2026-guia-autonomos
- Contabilizei — Carnê-Leão: https://www.contabilizei.com.br/contabilidade-online/carne-leao/
- CartaCapital — 25 milhões de autônomos: https://www.cartacapital.com.br/do-micro-ao-macro/carne-leao-autonomos-imposto-de-renda/
- Contabilizei — Ultrapassei o limite do MEI: https://www.contabilizei.com.br/contabilidade-online/ultrapassei-o-limite-do-mei/
- iure.digital — Tributação para autônomos (reserva 15–30%): https://iure.digital/blog/tributacao-para-autonomos-guia-pratico-de-obrigacoes-fiscais/
- Receita Federal — notificações do app MEI (+R$49M/mês): https://calderoncontabilidade.com.br/notificacoes-do-app-mei-impulsionam-r49m-mes-e-evitam-multas/
- Freelaz (calc. preço freelancer): https://freelaz.com/
- Calculadora Brasil (valor-hora): https://calculadorabrasil.com.br/calculadora-de-custo-da-hora-de-trabalho/
- Contabilizei — Calculadora Freelancer: https://www.contabilizei.com.br/contabilidade-online/materiais/calculadora-freelancer/
