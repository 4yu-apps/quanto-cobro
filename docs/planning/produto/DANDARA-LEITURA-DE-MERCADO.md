# Quanto Cobro? — Leitura de mercado antes da correção de rota

> **Quem escreve:** Dandara Vieira, produto de consumo (carteira digital 200k→6M usuários,
> app de organização financeira pra autônomo, marketplace de serviços).
> **Data:** 2026-07-19 · **Pedido:** reler TODA a pesquisa existente e dizer o que ela
> realmente diz, antes de gastar semanas construindo.
> **Base:** 16.961 reviews limpos / 33 apps / 5 países ([análise quantitativa](../../research/ANALISE-QUANTITATIVA-REVIEWS.md)),
> `data/categorization.json` e `data/inventory.csv` reprocessados por mim,
> as 7 frentes em [`research/raw/`](../../research/raw/), e o código do app hoje.

**Convenção:** toda afirmação forte leva número + arquivo. Onde a pesquisa **não**
responde, está escrito que não responde. Opinião minha vai marcada com **palpite:**.

---

## 0. O que eu fiz que a síntese não tinha feito

A `ANALISE-QUANTITATIVA-REVIEWS.md` reporta os temas **só no agregado (GERAL)**. Abri o
`categorization.json` e recortei **por segmento**. A diferença muda decisão:

| Tema (queixa) | GERAL — n (% dos neg.) | **PRICING — n (% dos neg.)** | TAX_MEI — n (% dos neg.) | Índice PRICING/GERAL |
|---|---|---|---|---|
| Bug / trava | 1.003 (17,2%) | **73 (21,2%)** | 930 (17,0%) | 1,23× |
| Cadastro forçado | 313 (5,4%) | **34 (9,9%)** | 279 (5,1%) | **1,83×** |
| Anúncio intrusivo | 155 (2,7%) | **23 (6,7%)** | 132 (2,4%) | **2,48×** |
| Cobrança-surpresa / paywall | 820 (14,1%) | **20 (5,8%)** | 800 (14,6%) | **0,41× (sub-indexa)** |
| Confuso / complexo | 108 (1,9%) | 8 (2,3%) | 100 (1,8%) | 1,21× |
| Suporte ruim | 287 (4,9%) | 4 (1,2%) | 283 (5,2%) | 0,24× |
| Impreciso | 126 (2,2%) | 4 (1,2%) | 122 (2,2%) | 0,55× |
| Confusão com gov | 83 (1,4%) | 1 (0,3%) | 82 (1,5%) | 0,21× |
| Perda de dados | 19 (0,3%) | 2 (0,6%) | 17 (0,3%) | 2,00× (n minúsculo) |

*Bases: GERAL 5.829 negativos · PRICING 344 · TAX_MEI 5.485. Fonte: `data/categorization.json`.*

**Três leituras que só aparecem no recorte:**

1. **No nosso nicho, anúncio é 2,5× mais odiado que na média do mercado** (6,7% vs 2,7%).
2. **No nosso nicho, paywall é 2,4× MENOS odiado que na média** (5,8% vs 14,1%). Quem
   usa calculadora de preço aceita pagar. O ódio a paywall é um fenômeno do mundo
   **MEI/imposto**, não do nosso.
3. **Cadastro forçado quase dobra de peso** no nosso nicho (9,9% vs 5,4%).

Ou seja: o roteiro anti-★1 do [04](../04-DIFERENCIAIS-E-REGRAS.md) está calibrado pela
média do mercado inteiro — que é 82% imposto/MEI. **Recalibrado pro nicho onde vamos
realmente jogar, a ordem de perigo muda: bug > cadastro > anúncio > paywall.**

---

## 1. Dores reais, ranqueadas por tamanho

Separo em duas camadas, porque são coisas diferentes e o planejamento às vezes mistura:
a **dor do trabalho** (o job) e a **dor do produto** (o que quebra nos apps existentes).

### 1.A — Dor do produto (o que faz o usuário dar ★1 hoje)

Base: 5.829 reviews negativos de 16.961 (34,4% do corpus). Média do corpus: 3,53★.

| # | Dor | n | % dos negativos | % do corpus | Onde dói mais |
|---|---|---|---|---|---|
| 1 | **Bug / trava / não abre** | **1.003** | **17,2%** | 5,9% | universal (21,2% no nosso nicho) |
| 2 | **Cobrança-surpresa / paywall opaco** | **820** | **14,1%** | 4,8% | quase só imposto/MEI (800 de 820) |
| 3 | **Cadastro / login forçado** | **313** | **5,4%** | 1,8% | super-indexa no nosso nicho |
| 4 | Suporte ruim / pago | 287 | 4,9% | 1,7% | imposto/MEI (283 de 287) |
| 5 | Anúncio intrusivo | 155 | 2,7% | 0,9% | **super-indexa 2,48× no nosso nicho** |
| 6 | Cálculo / dado impreciso | 126 | 2,2% | 0,7% | imposto/MEI |
| 7 | Confuso / complexo | 108 | 1,9% | 0,6% | universal |
| 8 | Confusão com app do governo | 83 | 1,4% | 0,5% | imposto/MEI |
| 9 | Perda de dados | 19 | 0,3% | 0,1% | (mas ver §1.C — o pedido é muito maior que a queixa) |

**Bug + cobrança-surpresa = 1.823 reviews = 31,3% de todas as reclamações do mercado.**

Verbatims mais votados (`categorization.json → complaint_verbatims`):

- 🐛 *"Não consigo acessar o app que está dando erro de senha sempre, mesmo usando a
  digital... já..."* — MEI Fácil/Neon, ★1, **233 👍**
- 🐛 *"Dá até medo de usar o cartão e não conseguir pagar porque não gera boleto, dá
  problema no cadastro de chave pix, trava, tudo é lento"* — MEI Fácil/Neon, ★1, **154 👍**
- ⚠️ *"CUIDADO! Número do código de barras gerado por este aplicativo é DIFERENTE do que
  consta no site da Receita. O boleto parece igual, mas não é. Fora os 30 segundos de cada
  propaganda!"* — DAS MEI, ★1, **153 👍**
- 💸 *"Venho aqui avisar q isso é golpe... foi cobrado e não foi avisado que era taxa do
  aplicativo"* — Mei em Foco, ★1, **143 👍**
- 💸 *"Lixo de aplicativo onde você só tem suporte se pagar, mesmo que o problema seja
  duplicidade na cobrança"* — Total MEI, ★1, **111 👍**

### 1.B — Dor do trabalho (o job, fora das lojas)

Aqui a pesquisa é **qualitativa**, não tem n. Digo isso na cara: não existe número de
tamanho para estas dores no material.

| Dor | Evidência | Força |
|---|---|---|
| **Cobrei barato e me arrependi** | r/brdev: *"cobrei 6k do serviço... meus chefes falaram que cobrariam 50k... tomei um puta de um preju"* — **142 upvotes, 80 comentários**; respostas tratam como rito de passagem (*"Evento canônico"*, *"Bem vindo ao clube"*, 186 upvotes) — [D §DOR 1](../../research/raw/D-demanda-voz-real.md) | **A mais forte e mais vocal.** É a dor nº1 documentada |
| **Não sei quanto cobrar (iniciante travado)** | r/brdev: *"não sei por quanto cobrar"*; *"perdi projetos simplesmente por insegurança... não era falta de skill, era medo do que vem 'fora do código'"* — [D](../../research/raw/D-demanda-voz-real.md) | Forte |
| **Choque de valor-hora indigno** | Proposta de *"720 reais por 40 horas (R$18/h)"* → resposta top: *"é uma piada de mau gosto"* — [D](../../research/raw/D-demanda-voz-real.md) | Forte |
| **Não reservei imposto e tomei susto** | **Dor silenciosa.** [A §Tese 2](../../research/raw/A-br-precificacao.md) marca **NÃO VERIFICADO**: *"não encontrei review verbatim de alguém tomando susto com DAS/IR"*. [C §85](../../research/raw/C-br-mei-imposto.md) idem. Existe pela **consequência**: multa isolada de **50%** do carnê-leão; push de vencimento da Receita subiu pagamento em dia **+9%** e arrecadação **+R$49M/mês** | **Real, mas NÃO comprovada por voz de usuário.** É a hipótese mais frágil de todo o pacote |
| **Medo de mandar a proposta / parecer amador** | r/brdev: *"Medo de como enviar propostas · Insegurança com escopo mal definido... Resultado: perdi projetos"* — [D](../../research/raw/D-demanda-voz-real.md) | Forte e **subestimada no planejamento** (ver §6) |

> **Honestidade obrigatória:** a tese fundadora do produto ("as pessoas sofrem por não
> reservar imposto") é a **única** das grandes que a pesquisa **não conseguiu comprovar
> na voz do usuário**. Duas frentes independentes registram a lacuna. Isso não a torna
> falsa — torna-a **cara de apostar**.

### 1.C — Pedidos espontâneos (310 reviews)

O que o usuário pede sem ser perguntado (`stats.requests_n = 310`; 135 no nosso nicho):

- **Backup / restaurar** — *"seria interessante poder salvar os dados (backup) caso
  precisasse formatar o aparelho"* (Receitas–Quanto Cobrar, ★5, **143 👍**)
- **Exportar / compartilhar em PDF** — *"Nota baixa pq não dá pra tirar o boleto em pdf
  nem compartilhar"* (DAS MEI, ★2, **257 👍** — **o pedido mais votado do corpus inteiro**)
- **Rodar sem cadastro** — *"O ponto legal é que se pode incluir vários MEIs numa tela
  rápida sem cadastro de login, interessante"* (mesmo review, 257 👍)
- **Mais gestão em volta do preço** — no PeqArt: *"Senti falta do espaço para inserir
  redes sociais no cadastro de clientes... No PDF do orçamento não tem..."* (★4, 85 👍);
  *"a possibilidade de parcelamento, melhor as entradas, e uma totalização"* (★4, 80 👍)

**Repare no último item.** Guarde-o para o §7 — ele contraria parte da correção de rota.

---

## 2. Onde os concorrentes MAIS acertam (o que temos obrigação de igualar)

Base: 10.455 reviews positivos.

| Elogio | GERAL n (%) | **PRICING n (%)** | Índice |
|---|---|---|---|
| **Útil / resolveu / recomendo** | 3.931 (37,6%) | **1.215 (45,9%)** | 1,22× |
| **Fácil / simples / intuitivo** | 2.060 (19,7%) | **662 (25,0%)** | 1,27× |
| Organiza / controle / lembrete | 144 (1,4%) | 74 (2,8%) | 2,00× |
| Rápido | 354 (3,4%) | 46 (1,7%) | 0,50× |
| Grátis / sem anúncio | 58 (0,6%) | 24 (0,9%) | 1,50× |

> **No nosso nicho, "resolveu" + "fácil" = 70,9% de TODOS os elogios** (vs 57,3% na média
> do mercado). Não é "tem muito recurso". É **resolveu, e foi fácil.**

### As 5 coisas que são table stakes — igualar ANTES de inovar

| # | O que | Evidência |
|---|---|---|
| 1 | **Não travar** | 21,2% dos negativos do nosso nicho. É a feature nº0 |
| 2 | **Resolver em poucos toques, com o número na cara** | 45,9% dos elogios do nicho |
| 3 | **Objeto salvo que se recalcula sozinho** | Os 3 melhores apps do corpus têm o mesmo loop: insumo reutilizável → item → rollup → margem, **com auto-recalc ao mudar um insumo**. [G §1A](../../research/raw/G-teardown-monetizacao.md) chama isso de *"o gancho de retenção"*. Receitas–Quanto Cobrar: *"muda preço de 1 material → todas as receitas recalculam"* |
| 4 | **Exportar / compartilhar em PDF** | Pedido mais votado do corpus (257 👍); categoria `invoice` tem **35,5M instalações** e média ponderada **4,73★** (`inventory.csv`) |
| 5 | **Backup / não perder tudo ao trocar de celular** | 143 👍 num único pedido; Doce Lucro (4,76★) resolve com backup em nuvem — [G §1A](../../research/raw/G-teardown-monetizacao.md) |

### Ranking de reputação — os extremos

| Nota | % neg | Reviews | App | O que é |
|---|---|---|---|---|
| 4,76★ | 3% | 256 | Doce Lucro | precificação + fichas + **backup nuvem** |
| 4,71★ | 4% | 1.384 | PeqArt | precificação + **orçamento PDF** + CRM + fluxo de caixa |
| 4,67★ | 4% | 694 | Receitas–Quanto Cobrar | precificação + **auto-recalc** |
| … | | | | |
| 1,95★ | 75% | 1.606 | TurboTax | paywall revelado tarde |
| 1,92★ | 76% | 1.600 | MEI Fácil (Neon) | bug + migração que prende dinheiro |
| 1,30★ | 92% | 983 | MyTax (gov. Malásia) | login que trava |

**Nota metodológica que vale ouro:** o `inventory.csv` mostra TurboTax com nota agregada
**5,0** na Play e MEI Fácil com **2,91** — enquanto a amostra de reviews recentes dá
**1,95★** e **1,92★**. A nota agregada da loja é lagged e mente. **A tendência recente é o
que importa.** Vale para nós no lançamento: 30 reviews ruins na primeira semana definem o
app por meses.

---

## 3. Onde MAIS erram — ranqueado por tamanho (é aí que a gente bate)

| # | Pecado | Tamanho | Como a gente bate |
|---|---|---|---|
| 1 | **Instabilidade** | 1.003 reviews · 17,2% dos negativos (21,2% no nicho) | App pequeno, offline, sem backend, sem login. **Não temos as causas de crash deles** (rede, auth, sync). É vitória de graça — desde que a gente **meça** (ver §5, risco nº2) |
| 2 | **Cobrança-surpresa** | 820 · 14,1% | Preço na cara antes do esforço. O padrão que já existe no código (*"Montar e ver é grátis. Enviar em PDF é Pro."*) é textbook — ver §5 |
| 3 | **Cadastro forçado** | 313 · 5,4% (9,9% no nicho) | Sem cadastro. É o fosso mais barato que existe |
| 4 | **Suporte pago** | 287 · 4,9% | Não vender suporte. *"Lixo de aplicativo onde você só tem suporte se pagar"* (111 👍) |
| 5 | **Anúncio no caminho crítico** | 155 · 2,7% (**6,7% no nicho**) | Ver §5 — **estamos prestes a cometer este** |
| 6 | **Erro fiscal** | 126 · 2,2% | ★1 imediato: *"código de barras DIFERENTE do que consta no site da Receita"* (153 👍). Posicionar como **estimativa/piso** |
| 7 | **Se passar por app do governo** | 83 · 1,4% | Não imitar, **linkar** o oficial |

### O padrão estrutural de falha (de [G §1B](../../research/raw/G-teardown-monetizacao.md))

1. **TurboTax:** revela o preço **depois** que o usuário digitou 30–60 min de dados. A FTC
   condenou a Intuit por propaganda enganosa de "free". → *revele preço ANTES do esforço.*
2. **MEI Fácil:** migração que deixa o usuário **sem acesso ao próprio dinheiro/login**,
   sem rota de recuperação. → *nunca prenda dado do usuário.*
3. **MyTax:** login em loading infinito, botão "Submit" que não responde. → *estado de erro
   real, nunca spinner eterno.*
4. **Apreço (iOS 3,47★):** *"O app custa 400,00 por ano, e na versão grátis não dá para
   usar nada!"* · *"só tem opção de pacote anual e por 400 reais... Mais caro que o Canva,
   CapCut, Lightroom"* — [A §Reclamações](../../research/raw/A-br-precificacao.md). → *o
   crime não é cobrar; é cobrar caro, à vista, com um grátis inútil.*

---

## 4. Onde NÓS já acertamos

| O que o app faz hoje | Dor comprovada que responde | Tamanho da dor |
|---|---|---|
| **100% offline, sem cadastro, sem login** | cadastro forçado + perda de dados | 313 + 19 reviews; **9,9% dos negativos do nosso nicho** |
| **Sem backend, sem sync, sem auth** | bug/trava | 1.003 reviews · 17,2% — removemos as causas, não só o sintoma |
| **"Uma pergunta por vez", linguagem sem jargão** | fácil/simples | 25,0% dos elogios do nicho |
| **Número-herói (valor-hora) como saída** | "resolveu" | 45,9% dos elogios do nicho |
| **Jargão "Leão" removido → "imposto"** | aversão a jargão fiscal ([C §5](../../research/raw/C-br-mei-imposto.md): *"quer o número mastigado, não a planilha de regime"*) | qualitativo |
| **Proposta em PDF com a marca do freelancer** | pedido nº1 do corpus (257 👍) + categoria `invoice` = 35,5M instalações, 4,73★ | **a maior oportunidade medida do material** |
| **Paywall do PDF: "Montar e ver é grátis. Enviar em PDF é Pro."** (`lib/features/proposta/proposta_preview_screen.dart:266-269`) | cobrança-surpresa | 820 reviews · 14,1%. **Este padrão é exemplar** — o usuário vê o valor inteiro antes da parede, o oposto do crime do TurboTax |
| **Continuar a ação depois da compra** (`proposta_preview_screen.dart:82-88`, `trabalho_switcher.dart:152-155`) | — | não tem dor mapeada, mas é craft de gente que já apanhou. Mantenha |
| **Não emitir DAS/DARF oficial** | erro fiscal + confusão com gov | 126 + 83 reviews. [C §133](../../research/raw/C-br-mei-imposto.md) recomenda exatamente isso |

**Resumo:** o app já está do lado certo de **4 das 5 maiores dores do mercado** — e as
acertou por arquitetura (offline/sem cadastro/sem backend), não por esforço contínuo. Isso
é o tipo de vantagem que não apodrece.

---

## 5. Onde NÓS falhamos ou corremos risco — sem cortesia

### 🔴 Risco 1 — O banner de anúncio é o erro mais caro do plano atual

O `nav_shell.dart:141` monta um `AdSlot` colado na barra de navegação — quer dizer, **na
tela onde ficam os números de dinheiro**, em todas as abas, para todo usuário não-Pro que
já fez o primeiro cálculo (`lib/core/ads/ads.dart:53-56`). Hoje é um **placeholder** com o
footprint exato reservado, e o `05-ESCOPO` lista *"Banner AdMob discreto"* como item do MVP
grátis — ou seja, a decisão ainda é reversível, e é isso que eu peço.

- Anúncio **super-indexa 2,48×** no nosso nicho: 6,7% dos negativos vs 2,7% no mercado.
- Verbatim: *"Precisa deixar sem anúncios, pois pela importância do aplicativo, pode
  prejudicar o processo de uso"* — ★4, 37 👍. E o ★1 de 153 👍 do DAS MEI mistura erro
  fiscal com *"os 30 segundos de cada propaganda"*.
- [G §2.1](../../research/raw/G-teardown-monetizacao.md): eCPM blended BR ~**$0,53**; app
  utilitário de baixa frequência → **ARPU de anúncio em centavos por usuário/mês**.
  *"ads sozinho não sustenta o app."*
- E o `pubspec.yaml` documenta que `google_mobile_ads` **já derrubou o app no boot** por
  falta do `APPLICATION_ID`. Religá-lo é reintroduzir a dor nº1 (17,2%) para ganhar centavos.

**Veredito: trocamos o ativo mais valioso do app (o elogio "sem propaganda", que
super-indexa 1,5× no nicho) por receita de centavos, com risco de crash no boot.**
Lançar sem anúncio nenhum.

### 🔴 Risco 2 — Vamos lançar cegos para a dor nº1 do mercado

O `pubspec.yaml` diz, literalmente, que `firebase_core/analytics/crashlytics` foram
**removidos**. Não há crash reporting, não há analytics, não há telemetria.

- **Bug/trava é 17,2% das reclamações do mercado e 21,2% das do nosso nicho.** É a única
  dor onde a nossa vantagem é estrutural — e vamos entrar sem instrumento para saber se a
  perdemos.
- O próprio [05 §7](../05-ESCOPO-E-ROADMAP.md) elege *"Crash-free sessions"* como sinal de
  sucesso, e *"Conclusão do fluxo guiado"*, e *"Usos de reserva por usuário/mês"*. **Nenhum
  dos cinco sinais de sucesso do plano é mensurável no build atual.**
- Doze anos de app de consumo me ensinaram: você não descobre o crash pelo review. Você
  descobre pela nota caindo três semanas depois, quando já não dá pra reverter.

**Crashlytics antes do lançamento não é negociável.** Analytics de funil (onboarding →
resultado) é o segundo. Ambos podem ser opt-out, coerentes com a promessa de privacidade —
e já existe um `telemetryProvider` no `config_screen.dart` esperando por isso.

### 🟠 Risco 3 — O CSV do próprio histórico do usuário está atrás do paywall

`lib/features/historico/historico_screen.dart:300` — *"Exportar CSV é recurso Pro."*

Isso é **prender o dado do usuário atrás de pagamento**. É exatamente:
- o crime do MEI Fácil (1,92★, 76% negativos) que o [G §1B](../../research/raw/G-teardown-monetizacao.md) manda nunca repetir;
- a violação da regra que o próprio [05 §6](../05-ESCOPO-E-ROADMAP.md) escreveu: *"Nunca
  prender dados/atrás de pagamento — backup e o cálculo básico são livres"*;
- o oposto do pedido de 143 👍 (*"salvar os dados (backup) caso precisasse formatar"*).

**Palpite:** vale muito pouca conversão e é um vetor de ★1 do tipo "o app sequestrou meus
dados" — o review mais difícil de responder que existe. Backup/exportar do que é do
usuário: **grátis, sempre.** Cobre pelo PDF *bonito com a marca dele* — isso é trabalho
nosso, não dado dele.

### 🟠 Risco 4 — Tempo até o primeiro valor: 8 telas

3 páginas de onboarding (`onboarding_screen.dart`) + 5 passos de calculadora
(`calc_screen.dart:36 — _lastStep = 4`) antes do primeiro número:

1. Quanto você quer ganhar por mês? · 2. Quanto trabalha por semana? · 3. O que gasta pra
trabalhar? · 4. E o imposto? · 5. Férias e 13º?

Num nicho onde **"fácil/simples" é 25,0% dos elogios** e o próprio fundador diz que *"o
objetivo principal é a tela inicial pra saber quanto custa a minha hora"*, oito telas entre
a instalação e a resposta é muito. O dia 3 acontece aqui: quem não chegou ao número na
primeira sessão não volta.

**Palpite:** dá pra entregar um número provisório já no passo 1 (renda ÷ horas-padrão) e
usar os passos 2–5 para **refiná-lo na frente do usuário**. O número muda, ele vê mudando,
e cada passo passa a ter recompensa em vez de custo. É o padrão do Harvest (default de 60%
faturáveis pré-preenchido, [B §6](../../research/raw/B-internacional-rate.md)): *não peça
ao usuário adivinhar — dê o default e explique.*

### 🟡 Risco 5 — Tabelas fiscais ainda não validadas na Receita

O checklist do [05 §8](../05-ESCOPO-E-ROADMAP.md) tem `[ ] Validar tabelas fiscais na
Receita` **em aberto**, e ele mesmo diz que **bloqueia publicação**. O verbatim de 153 👍
(*"código de barras DIFERENTE do que consta no site da Receita"*) mostra o preço: erro
fiscal é ★1 na hora e destrói a credibilidade que é o nosso diferencial.

### 🟡 Risco 6 — "100% offline" com permissão de INTERNET

O `AndroidManifest` declara `android.permission.INTERNET` (para o câmbio, `http: ^1.2.0`).
A promessa de marketing é *"100% no seu aparelho"*. Não é mentira — mas a Data Safety da
Play precisa estar **exata**, e a copy precisa dizer "a única coisa que sai daqui é a
consulta de cotação, quando você pede". Num mercado com 83 reviews de desconfiança sobre
apps que se passam por outra coisa, ser pego numa imprecisão custa caro.

### 🟡 Risco 7 — O nome ainda não foi decidido, e a pesquisa não gostou dele

[E §2.1](../../research/raw/E-aso-naming.md): a busca real é *"quanto cob**rar**"*
(infinitivo), não *"cob**ro**"*; "cobro" ecoa **cobrança de dívida**; a "?" é ruído para
Play/domínio; e frase descritiva é marca fraca e difícil de registrar no INPI. Recomendação
da pesquisa: **marca própria + keywords no subtítulo** (modelo `FreelaCalc: Calculadora
Freela`), guardando "Quanto Cobro?" como tagline. Isso não bloqueia o build; **bloqueia a
loja**, e mexer no nome depois de 5 mil instalações é jogar reputação fora.

---

## 6. A maior necessidade não atendida do mercado

A resposta que o planejamento dá hoje é *"a ponte preço → reserva → lucro"*. Ela é
**verdadeira como lacuna** — três frentes independentes confirmam que ninguém faz
([A §Lacunas 1](../../research/raw/A-br-precificacao.md), [B §4](../../research/raw/B-internacional-rate.md),
[C §3](../../research/raw/C-br-mei-imposto.md)). Mas lacuna e necessidade não são a mesma
coisa, e é aqui que eu discordo do pacote.

**Uma lacuna com dor não comprovada é um mercado vazio, não um mercado desatendido.**
A dor do imposto é a única grande tese que a pesquisa **não** conseguiu comprovar na voz do
usuário (§1.B). Já a dor de "cobrei barato" tem 142 upvotes e uma thread de 80 comentários
tratando o prejuízo como rito de passagem.

### A necessidade que tem dor comprovada E tamanho medido

> **"Transformar o preço que eu calculei num documento com a minha cara, que eu mando pro
> cliente em 30 segundos" — para freelancer de SERVIÇO.**

| Evidência | Número |
|---|---|
| Categoria `invoice`/orçamento no `inventory.csv` | **51 apps, ~35,5M instalações, média ponderada 4,73★, 49% com ≥4,5★** |
| Categoria `pricing` (nosso nicho direto) | **11 apps, ~501 mil instalações** |
| Pedido mais votado de todo o corpus | *"não dá pra tirar o boleto em pdf nem compartilhar"* — **257 👍** |
| O maior app do nosso nicho (PeqArt, 100k+, 4,71★) | não é calculadora: é **precificação + orçamento PDF com logo + CRM + fluxo de caixa** ([G §1A](../../research/raw/G-teardown-monetizacao.md)) |
| Voz do freelancer | *"Medo de como enviar propostas... Resultado: perdi projetos simplesmente por insegurança"* — [D](../../research/raw/D-demanda-voz-real.md) |
| Quem serve isso para serviço no BR | **ninguém.** Invoice é genérico (fatura/recibo); PeqArt é artesanato/produto |

O `invoice` é **70× maior em instalações** que o `pricing` e é **bem avaliado** (4,73★) —
não é um mercado odiado esperando salvador, é um mercado **saudável e provado que ninguém
adaptou pro freelancer de serviço brasileiro**. E o degrau "precificação → orçamento PDF" é
literalmente o que fez o PeqArt ser o maior app do nosso nicho.

**Consequência:** a proposta em PDF não é uma feature Pro entre outras. **É candidata a
segundo pilar do produto**, ao lado do valor-hora. É onde a dor comprovada, o tamanho
medido e a disposição a pagar coincidem.

> **Meu viés, declarado:** eu puxo para o que escala e tem número. A pesquisa aponta um
> nicho que eu estou naturalmente inclinada a subestimar — o **"freela pra gringo"**
> ([F §3](../../research/raw/F-mercado-sizing.md)): +53% de contratações remotas 2023→2024,
> Brasil 5º do mundo, US$ 51,8 bi de exportação de serviços, e a dor de carnê-leão **mensal
> e obrigatória** (7,5%–27,5%, conversão pela cotação do dia). É pequeno, silencioso, e é
> **o único público do material com dor recorrente comprovada e capacidade de pagar
> assinatura**. Se existe um lugar onde a mensalidade se justifica, é esse — e não é o
> lugar que eu escolheria por instinto. Registro para que a decisão não seja só minha
> inclinação.

---

## 7. Veredicto sobre a correção de rota

**A correção:** *calculadora primeiro (grátis, simples, tela inicial), gestão como extra
pago (Área → Trabalho → Entradas), sem ritual de "recebi, recebi, recebi".*

### Veredicto curto

**Acerta em 3 dos 4 movimentos. Erra em 1 — e o erro é no lugar onde o produto vive ou
morre.**

### 7.1 — O que a pesquisa APOIA (forte)

**(a) Simplificar e pôr o valor-hora na frente.** Apoiado com números:
- Nicho de precificação: **4,42★, 11,0% de negativos, 84,8% de positivos** — o mercado
  gosta desse formato.
- **70,9% dos elogios do nicho** são "resolveu" (45,9%) + "fácil" (25,0%).
- Os 3 apps mais bem avaliados do corpus inteiro são de precificação simples
  (4,76 / 4,71 / 4,67★); os piores são apps fiscais pesados (1,95 / 1,92 / 1,30★).
- O teste de usabilidade do próprio fundador: as duas piores notas (**4 e 3**) foram nas
  telas de **uso recorrente**, não no cálculo. O produto está te dizendo onde ele quebra.

**(b) Matar o ritual de "recebi, recebi, recebi".** Apoiado:
- [C §5](../../research/raw/C-br-mei-imposto.md): *"o usuário quer um número, não uma
  planilha de regime"*; *"Lembrete é expectativa consolidada... não é diferencial, é table
  stakes"*.
- O dado da Receita (+9% de pagamento em dia com **push**) diz que as pessoas não querem
  **registrar** — querem ser **avisadas**. Nudge > log.
- `confuso_complexo` existe como queixa (108 reviews) e o inchaço é o padrão que afunda os
  concorrentes ([05 §1](../05-ESCOPO-E-ROADMAP.md)).

**(c) Gestão como camada paga.** Apoiado, e mais forte do que o pacote assumia:
- [F §4](../../research/raw/F-mercado-sizing.md): *"monetizar 'controle financeiro' puro é
  difícil (grátis é o default)... o valor pago está no específico e doloroso"*. Gestão
  financeira genérica no BR está ancorada em grátis (Organizze, Balancinho, Neon, app
  oficial do MEI). **Pôr gestão no grátis seria competir com grátis.**
- No nosso nicho, **paywall sub-indexa 0,41×** (5,8% dos negativos, 20 reviews). Quem usa
  calculadora de preço **aceita pagar**. O ódio a paywall dos 820 reviews é do mundo
  MEI/imposto (800 dos 820), não do nosso.
- É a escada exata do PeqArt: precificação grátis → orçamento/CRM/fluxo pago. O maior app
  do nicho.

**(d) Recusar a aba "Recebidos".** Apoiado, e é uma decisão fina: o nome anunciaria um
modelo mental de contabilidade que o produto não quer honrar. Nomear errado é prometer
errado. *(Isso é julgamento de produto, não dado — mas é o julgamento certo.)*

### 7.2 — O que a pesquisa CONTRARIA — com todas as letras

> **A pesquisa contraria, de forma direta e repetida, a ideia de que o núcleo grátis possa
> ser uma CALCULADORA PURA.**

Não é uma ressalva. São quatro evidências independentes:

| Evidência | Fonte |
|---|---|
| *"**Calculadora pura não retém nem monetiza** — todos viraram isca de outro produto. O app BR precisa nascer com a tool recorrente como núcleo, não como calculadora avulsa."* | [B §6 Armadilhas](../../research/raw/B-internacional-rate.md) |
| *"**A calculadora não é o produto — o hábito é.** Lá fora, o melhor app do nicho (FreelaCalc, 4.9★) tem só 100+ instalações; calculadora pura não retém nem monetiza."* | [SÍNTESE §1.2](../../research/SINTESE-PESQUISA-CONCORRENTES.md) |
| O nicho `pricing` inteiro = **11 apps, ~501 mil instalações**. O app mais instalado dos concorrentes diretos de freela tem **1 mil+** (aleckrh, que se autodescreve *"ferramenta simples"*). O nicho não é pequeno por falta de app — é pequeno porque **uma conta que se faz uma vez não justifica um ícone na tela** | `inventory.csv`; [A §1](../../research/raw/A-br-precificacao.md) |
| **Os 3 apps mais amados do corpus não são calculadoras.** Doce Lucro (4,76★) = fichas + biblioteca + backup nuvem. PeqArt (4,71★) = orçamento PDF + CRM + fluxo. Receitas–Quanto Cobrar (4,67★) = **auto-recalc de insumo compartilhado**, que o teardown chama de *"o gancho de retenção"* | [G §1A](../../research/raw/G-teardown-monetizacao.md) |

**A distinção que resolve a contradição — e que eu acho que é a peça que falta na correção
de rota:**

> O que o mercado ama **não é "uma calculadora"**, e **não é "um app de gestão"**.
> É **uma calculadora cujos números ficam salvos como um objeto que se recalcula.**

Um app onde eu guardo *"Design — Augusto — R$ 3.200"*, e quando eu mudo meu custo de vida
ou minha alíquota, **todos os meus trabalhos se atualizam sozinhos e eu vejo**. Isso não é
gestão financeira (não tem "paguei/não paguei", não tem lançamento, não tem ritual). É a
calculadora com memória. É barato de construir, é o loop dos três apps mais bem avaliados
do corpus, e **é exatamente a hierarquia Área → Trabalho → Entradas que o fundador
descreveu.**

**Onde isso muda a correção:** se "Trabalhos" for **inteiramente Pro**, o usuário grátis
tem uma calculadora sem memória — e a pesquisa diz, quatro vezes, que isso não retém.
**O primeiro Trabalho salvo precisa ser grátis.** É o que transforma instalação em hábito;
é o que dá o que vender depois. Cobrar pelo **segundo** (que é o que o
`trabalho_switcher.dart:145` já faz) está certo. Cobrar pelo **primeiro** mataria o app.

### 7.3 — A conta que ninguém fez: o custo de automatizar o ritual

Automatizar a reserva ("se cadastrei o serviço, eu recebi") remove atrito — e **remove
também o motivo mensal de abrir o app**. Isso tem consequência direta na monetização:

[G §2.2](../../research/raw/G-teardown-monetizacao.md) (RevenueCat 2025) mostra que
utilitários lideram a 1ª renovação (**58,1%**) — mas a leitura do próprio documento é
condicional: *"os 58% seguram **se** houver motivo recorrente de abrir o app"*. Sem
ritual mensal, **a assinatura fica frágil e o vitalício fica forte.** Ver §9.

### 7.4 — Veredicto final

**"Calculadora primeiro, gestão como extra pago" é ACERTO — desde que "calculadora" queira
dizer "calculadora com memória", e não "calculadora avulsa".** O fundador acertou o
diagnóstico (o app ficou extenso de gerir), acertou o corte (fora o ritual de registro),
acertou a linha de monetização (gestão é o que se paga, porque gestão genérica grátis já
existe e não se vende). O risco é o pêndulo passar do ponto: se o grátis virar uma conta
que não fica salva, a gente troca um app complexo demais por um app que ninguém reabre — e
a pesquisa já mediu o resultado disso: **100 instalações e 4,9 estrelas.**

---

## 8. Fazer / não fazer — priorizado

### FAZER — antes do lançamento (bloqueia)

| # | Ação | Porquê de negócio |
|---|---|---|
| 1 | **Crashlytics ligado** (opt-out, coerente com privacidade) | Bug é 17,2% das queixas do mercado e 21,2% no nosso nicho. É a nossa maior vantagem estrutural e hoje é **invisível**. Sem isso os 5 sinais de sucesso do [05 §7](../05-ESCOPO-E-ROADMAP.md) não existem |
| 2 | **Lançar SEM anúncio** | Anúncio super-indexa **2,48×** no nicho (6,7% dos negativos) e rende **centavos/usuário/mês** (eCPM BR ~$0,53). E o `google_mobile_ads` já derrubou o app no boot. Troca ruim em todos os eixos |
| 3 | **Backup/exportar do usuário → grátis** (tirar o CSV do paywall) | Prender dado é o crime do MEI Fácil (1,92★) e viola a regra escrita no próprio [05 §6](../05-ESCOPO-E-ROADMAP.md). Vetor de ★1 de alto custo, conversão baixa |
| 4 | **Primeiro Trabalho salvo é grátis** | §7.2: calculadora sem memória não retém (4 evidências). O 2º Trabalho em diante é Pro — já implementado |
| 5 | **Validar tabelas fiscais na Receita** | O próprio checklist diz que bloqueia. Erro fiscal = ★1 imediato (verbatim de 153 👍) |
| 6 | **Fechar o nome** (marca + keywords no subtítulo) | [E](../../research/raw/E-aso-naming.md): "cobro" ≠ "cobrar" perde o match da própria keyword. Trocar depois de instalado é jogar reputação fora |
| 7 | **Data Safety exata sobre a permissão INTERNET** | A promessa é "100% no aparelho" e existe `INTERNET` no manifesto. Precisão aqui é barata; ser pego é caro |

### FAZER — logo depois (constrói o negócio)

| # | Ação | Porquê |
|---|---|---|
| 8 | **Número provisório já no passo 1**, refinado ao vivo nos passos 2–5 | 8 telas até o primeiro valor num nicho onde "fácil" é 25% dos elogios. Ataca direto a conclusão de onboarding e o dia 3 |
| 9 | **Auto-recalc visível**: mudou custo/alíquota → todos os Trabalhos se atualizam, e o app **mostra** | É *o* gancho de retenção dos 3 apps mais bem avaliados do corpus ([G §1A](../../research/raw/G-teardown-monetizacao.md)). Barato e é o coração da "calculadora com memória" |
| 10 | **Promover a Proposta em PDF a segundo pilar** (não feature Pro entre outras) | §6: `invoice` = 35,5M instalações e 4,73★ vs `pricing` = 501 mil. Pedido nº1 do corpus (257 👍). É o degrau que fez o PeqArt ser o maior do nicho |
| 11 | **Nudge mensal em vez de log** | Receita: push de vencimento subiu pagamento em dia **+9%**. As pessoas não querem registrar; querem ser avisadas |
| 12 | **Copy anti-achômetro, sem cheiro de IA** | A comunidade dev **rejeita** texto de IA: *"parece que o texto todo foi gerado por AI"* — [D §Objeções 6](../../research/raw/D-demanda-voz-real.md) |

### NÃO FAZER

| # | Não fazer | Porquê |
|---|---|---|
| 1 | **Não construir gestão financeira** (paguei/não paguei, lançamento, fluxo de caixa) | O fundador já decidiu certo, e a pesquisa confirma: gestão genérica está **ancorada em grátis** no BR ([F §4](../../research/raw/F-mercado-sizing.md)); é o inchaço que gera bug (17,2%) e confusão |
| 2 | **Não emitir DAS/DARF oficial** | [C §133](../../research/raw/C-br-mei-imposto.md): *"é caro e é onde os concorrentes têm bugs e reclamação"*. Linkar o oficial |
| 3 | **Não perseguir precificação de PRODUTO** (confeitaria/artesanato) | Outro job. Já decidido no [00 §4](../00-PROPOSTA-DE-PRODUTO.md) e está certo — mas note a ironia: é o único nicho de precificação com tração real hoje |
| 4 | **Não usar o "reserve 25–30%"** genérico dos gringos | No BR está errado — um MEI guardaria ~**5× demais** ([B §4](../../research/raw/B-internacional-rate.md)). Destrói justamente a credibilidade que é o trunfo |
| 5 | **Não dar default de valor-hora indigno** | O *"8 USD a hora"* revoltou a comunidade gringa: *"isso nem McDonald's paga"*. Um default baixo sabota a tese "você cobra pouco" |
| 6 | **Não vender suporte** | 287 reviews · 4,9%. *"Lixo de aplicativo onde você só tem suporte se pagar"* (111 👍) |
| 7 | **Não fazer paywall anual à vista e caro** | O crime do Apreço (3,47★): *"400,00 por ano... na versão grátis não dá para usar nada"* |

---

## 9. Monetização — onde a parede Pro deve estar

### O achado que muda a estratégia

**No nosso nicho, paywall NÃO é o pecado que é no resto do mercado.**

| | Cobrança-surpresa / paywall | Anúncio |
|---|---|---|
| Mercado (GERAL) | 820 reviews · **14,1%** dos negativos | 155 · 2,7% |
| **Nicho de precificação** | **20 reviews · 5,8%** (índice 0,41×) | **23 reviews · 6,7%** (índice **2,48×**) |

**No nicho onde vamos jogar, o anúncio gera mais reclamação que o paywall.** Os 820 reviews
de ódio a paywall são 800 do mundo MEI/imposto — onde os apps cobram por serviço que o
governo dá de graça. Não é o nosso caso. **Conclusão: cobrar é seguro; anunciar não é.**

### A parede: onde ela deve estar

| Camada | O que é | Por quê |
|---|---|---|
| **Grátis pra sempre** | Calculadora completa · o número na cara · **1 Trabalho salvo** · a divisão (lucro/reserva/custos) · **backup e export dos dados dele** · montar e **ver** a proposta | §7.2 (memória é o que retém) + regra "nunca prender dado" + "ver o número básico é sempre grátis" |
| **Pro** | **Enviar a proposta em PDF com a marca dele** (âncora nº1) · Trabalhos ilimitados · previsão cliente a cliente · módulo "freela pra gringo" (USD/carnê-leão) · modo avançado por regime | Onde a dor é específica e a disposição a pagar é direta |

**A âncora de conversão é o PDF, não a gestão.** Motivo de negócio: é o único momento em
que o usuário está **na frente de quem vai pagar ele**. A disposição a pagar não vem de
"quero me organizar" — vem de "quero não parecer amador agora". `invoice` = 35,5M
instalações, 4,73★. E o padrão já implementado (*"Montar e ver é grátis. Enviar em PDF é
Pro"*) é o melhor exemplo de paywall honesto que eu vi neste código: o usuário vê o
documento pronto, com a marca dele, e **só então** decide. É o oposto exato do crime do
TurboTax. **Não mexam nisso.**

### Preço

[G §2.3](../../research/raw/G-teardown-monetizacao.md) + [F §5](../../research/raw/F-mercado-sizing.md):
teto de impulso para utilitário BR = **R$ 9,90–14,90/mês**, anual ~**R$ 90–100**
(âncora: Precifica.app R$ 97,80/ano). Renda média do conta-própria: **R$ 2.682–2.955/mês**;
**85% ganham até 3 salários mínimos**.

| Plano | Preço | Papel |
|---|---|---|
| **Vitalício** | **R$ 129–149** | **O protagonista.** Ver abaixo |
| Anual | R$ 89,90 | Alternativa; âncora de comparação |
| Mensal | R$ 12,90 | Só para fazer o resto parecer barato |

**Por que eu inverto a recomendação do [05 §6](../05-ESCOPO-E-ROADMAP.md) e boto o
vitalício na frente:** o plano original liderava com o anual, apoiado no argumento de que
*"a reserva mensal dá o motivo recorrente de voltar"*. **A correção de rota acaba de
remover esse motivo** (§7.3) — se o app calcula a reserva sozinho a partir do Trabalho
cadastrado, não há mais ritual mensal. Sem ritual, os 58,1% de 1ª renovação do RevenueCat
não se aplicam; renovação sem uso vira **estorno e ★1**. Some-se a aversão cultural
brasileira a assinatura e o ★1 literal do Apreço (*"só tem opção de pacote anual e por 400
reais... não parcela"*), e o vitalício vira a escolha certa.

**Exceção — e é a que me contraria:** para o **"freela pra gringo"** ([F §3](../../research/raw/F-mercado-sizing.md)),
o carnê-leão é **mensal e obrigatório**, com conversão pela cotação do dia. Ali o ritual
existe de verdade, é imposto pela Receita e não por nós. **É o único público onde a
assinatura anual se sustenta** — e é o público de maior renda do material. Nicho pequeno,
silencioso, que paga bem. Já registrei em §6 que é o meu ponto cego.

### As 4 regras que evitam ★1 na parede

1. **Preço e o que é Pro aparecem ANTES do esforço** — o crime do TurboTax (1,95★, 75% neg)
   é revelar depois de 30–60 min de dados digitados.
2. **Ver o valor sempre antes de pagar** — o padrão do PDF já faz isso. Replicar em tudo.
3. **Nunca prender dado do usuário** — o crime do MEI Fácil (1,92★, 76% neg). Corrigir o CSV.
4. **Continuar a ação depois da compra** — já implementado (`proposta_preview_screen.dart:82-88`).
   Quebrar a promessa logo depois do pagamento é o pior lugar para decepcionar. Mantenham.

---

## 10. O que a pesquisa NÃO responde

Registro honesto, para ninguém citar este documento como prova do que ele não prova:

1. **A dor do imposto não tem voz de usuário.** Duas frentes ([A §Tese 2](../../research/raw/A-br-precificacao.md),
   [C §85](../../research/raw/C-br-mei-imposto.md)) registram a lacuna. É a tese fundadora e
   é a menos comprovada. **Não existe evidência de que alguém abriria um app por causa dela.**
2. **Não há dado de willingness-to-pay brasileiro** para app financeiro de autônomo
   ([F §Lacunas](../../research/raw/F-mercado-sizing.md)). Todos os preços do §9 são
   hipótese a testar, não dado.
3. **A categorização é lexical**, com imprecisão de borda. Os percentuais são sinal de
   tamanho, não medida exata.
4. **97% das reviews de imposto são BR** e o corpus é **só Google Play** — iOS não entrou.
5. **`invoice`, `freelance` e `time` não foram minerados** (decisão de escopo). Eu usei o
   `inventory.csv` (instalações e notas agregadas) para dimensioná-los, mas **não há
   análise de review** dessas categorias. A recomendação do §6 (PDF como segundo pilar) se
   apoia em **tamanho e nota agregada**, mais o pedido de 257 👍 — não em análise temática.
   **Se for para minerar mais alguma coisa antes de construir, minere `invoice`.**
6. **Nada aqui foi testado com usuário real do nosso app.** O teste de 8 personas (média
   6,4) é o único sinal de uso, e é interno.

---

*Documento de leitura de mercado. Não altera plano por si só — informa a decisão do
fundador. Toda afirmação forte rastreia para `research/`, `data/` ou para o código.*
