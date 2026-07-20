# 08 — Plano oficial: tudo que falta

> **Aprovado pelo dono em 19/07/2026.** É o documento vigente — o rascunho
> anterior foi substituído por este.
>
> Consolida: o planejamento [07](07-PROPOSTA-E-GESTAO-DE-PROJETOS.md), a revisão
> de UX de três especialistas ([`ux-revisao/`](ux-revisao/)), a leitura de mercado
> de dois donos de produto ([`produto/`](produto/)) sobre 16.961 reviews, e o
> inventário de defeitos encontrados no caminho (§8).

---

## 1. As decisões travadas

| Decisão | Valor |
|---|---|
| **Vocabulário** | **Área** ("Design") → **Trabalho** ("o freela com o Augusto") → **Entradas** |
| **Abas** | **Início · Trabalhos · Configurações** |
| **Objetivo nº 1** | A tela inicial responder *"quanto custa a minha hora?"* |
| **O que é extra** | Salvar, gerir, propor — e é neles que mora o Pro |
| **O que NÃO é** | App de gestão financeira. Nada de "paguei / não paguei imposto" |
| **Registro** | Cadastrar a entrada **é** o registro. Ninguém fica marcando "recebi, recebi" |
| **Jargão** | "Leão" está fora. O app diz **imposto** ✅ |
| **Publicação** | Ainda **não publicado**, sem Play Console → **rename livre, sem migração** |

### A régua de fronteira (use isto pra recusar feature sem rediscutir tudo)

> **O Quanto Cobro? decide preços. Ele não administra negócios.**

E o teste operacional que separa os dois casos difíceis — a síntese entre o que
os dois donos de produto disseram:

> **Lembrar o que a pessoa disse uma vez = calculadora com memória. ✅**
> **Exigir que ela alimente o app toda semana = gestão. ❌**

A Área que nasce de um cálculo passa. A lista de Trabalhos passa. Datas de
vencimento, status a atualizar, nudge de cobrança e previsão de caixa **não
passam** — todos exigem alimentação contínua pra ter valor.

---

## 2. O que a pesquisa mudou no plano

Três achados dos donos de produto que alteraram decisões, não só confirmaram:

1. **A dor de reserva de imposto tem zero verbatim em 16.961 reviews.** O loop
   que o app tratava como coração não tem demanda documentada. Não morre — mas
   deixa de ser a razão de existir e vira consequência do cálculo.
2. **"Organiza / controle" é 1,4% dos elogios** (144 de 10.455). Gestão não é o
   que faz alguém amar um app dessa categoria. "Resolveu" (37,6%) e "fácil"
   (19,7%) são.
3. **No nosso nicho, anúncio dói 2,48× mais que a média e paywall dói menos.**
   Cobrar é seguro; anunciar não é.

E dois achados que corrigem documentos anteriores (já marcados neles):
o **4,42★ vem do público errado** (precificação de produto, não de hora), e o
**"mercado de imposto é odiado" é 64% um app só** (MEI Fácil/Neon).

---

## 3. Fase 0 — Não lançar cego *(nova; vem da leitura de mercado)*

**Por quê:** bug/trava é a dor nº 1 do mercado (17,2% dos negativos; **21,2% no
nosso nicho**) e é a única onde nossa vantagem é estrutural. Crash não se
descobre por review — se descobre pela nota caindo três semanas depois, quando
a agregada já travou.

| Item | Ação |
|---|---|
| **Crashlytics + Analytics** | Religar, com opt-in de verdade (LGPD). Exige `google-services.json` |
| **Anúncio na navbar** | **Remover o slot.** Ver §9.1 |
| **CSV do histórico** | **Sair do paywall.** O dado é da pessoa; prendê-lo é o crime do MEI Fácil (1,92★) e viola a regra 3 do nosso próprio [05](05-ESCOPO-E-ROADMAP.md) |
| Sinais de sucesso | Instrumentar os 5 que o [05](05-ESCOPO-E-ROADMAP.md) define e que hoje **nenhum** é mensurável |

---

## 4. Fase 1 — O esqueleto novo *(a maior; destrava tudo)*

### 4.1 Renomear os conceitos no código
`Perfil` → `Area` · `Projeto` → `Trabalho` · `ReservaEntry` → `Entrada`

Não é cosmético: o código chamar de "Perfil" o que o produto chama de "Área" foi
**exatamente** o que me fez montar a hierarquia ao contrário. Nome errado no
código vira feature errada na tela.

Como o app **não está publicado**, renomeamos também as chaves de armazenamento
— sem migração, sem uma classe inteira de bug.

### 4.2 O regime sobe pra pessoa
Hoje o regime mora no `Perfil` (por área). Isso produz número **errado**: duas
áreas = dois DAS para um mesmo CNPJ. O app já admite isso em texto ("o imposto
do mês é um só") enquanto modela ao contrário. Regime e moeda passam a ser
ajuste da PESSOA, em Configurações.

### 4.3 As três abas
- **Início** — o valor-hora e o caminho do cálculo. O objetivo nº 1.
- **Trabalhos** — a hierarquia. Tocar **abre**; editar é o ⋮.
- **Configurações** — destino de verdade: Minha marca · Meus preços · regime e
  imposto · backup · Pro · aparência. Sai a engrenagem do topo do Início.

### 4.4 A ordem de nascimento dos objetos
```
CALCULAR ──► "Salvar como…" ──► nasce a ÁREA ("Design")
                                      │
                    primeira entrada  ▼
                              nasce o TRABALHO ("Augusto")
                                      │
                                      ▼
                                  ENTRADAS
```
Ninguém preenche formulário vazio antes de ganhar alguma coisa. Nomear embaixo
de um `R$ 92/h` é comemoração; nomear numa tela em branco é prova.

### 4.5 A hierarquia fica latente
Com **uma** área, a palavra "área" não aparece em lugar nenhum — a aba mostra os
Trabalhos direto, em lista plana. O nível de cima só se revela no segundo. Quem
quer só calcular nunca vê a árvore.

### 4.6 A tela do Trabalho
```
┌────────────────────────────────────┐
│ ←  Augusto                    ⋮    │
│                                    │
│  RECEBIDO NESTE TRABALHO           │
│  R$ 1.200                          │  ← número herói
│  separou R$ 135 de imposto         │  ← apoio
│                                    │
│  ENTRADAS                          │
│   jul   R$ 200    separou  R$ 22   │
│   jun   R$ 600    separou  R$ 68   │
│   mai   R$ 400    separou  R$ 45   │
│                                    │
│  ┌──────────────────────────────┐  │
│  │      + Nova entrada          │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

### 4.7 O resumo do mês
A aba Guardado morre. O resumo *"entrou X este mês, separou Y"* vira card no
**Início**, e o histórico completo é tela empilhada a partir dele.

---

## 5. Fase 2 — Os cortes *(mesma leva de código que a Fase 1)*

| Sai | Por quê |
|---|---|
| `ProjetoStatus` (4 estados) → um `encerrado` no ⋮ | Board de kanban |
| `Recorrencia` (4 tipos) + `intervaloMeses` + stepper | O leigo não configura ciclo |
| `proximoRecebimento`, "Próximos 30 dias", `avancarCiclo`, `RecebimentoPrevisto` | Exigem alimentação contínua → reprovados pela régua |
| Selo "falta separar" e o nudge "já te pagou?" | O gatilho de voltar é o dinheiro cair |
| "Já paguei o imposto deste mês", `leaoPago`, banner de vencimento do DAS | Decisão do dono |
| `tipoContrato` no perfil + arbitragem entre dois nudges | Sobra do modelo antigo |
| Formulário do Trabalho: **8 → 3 campos** | O resto era gestão que ninguém pediu |
| Chips de filtro do histórico | Complexidade sem uso |
| 3 superfícies pro mesmo objeto (`perfis_screen` + `trabalho_switcher` + chip do herói) | Colapsam na aba Trabalhos |

**Sobrevive de propósito:** o DAS como *número dentro do cálculo* ("seu DAS de
R$ 86/mês já está dentro desse preço"). O app continua sabendo que você é MEI;
para de te dar tarefa por isso.

---

## 6. Fase 3 — O caminho do cálculo *(o objetivo nº 1, afiado)*

- **Onboarding 3 → 2 páginas.** Morre a pergunta "Brasil/exterior" — ela é feita
  de novo, melhor, no passo do regime. Fazer a mesma pergunta duas vezes, a
  primeira antes de entregar qualquer valor, é o retrato do app que cobra antes
  de dar.
- **Calculadora 5 → 4 passos**, com o **valor-hora vivo no topo a partir do
  passo 3**. Hoje são cinco telas de investimento com zero retorno; com o número
  vivo, os passos viram *ajuste* de uma coisa que já é dela.
- Provisão de férias/13º sai do passo 5 → toggle no Detalhamento.
- O botão do Resultado vira **"Salvar como…"**.
- **Tela de entrada (a antiga Reserva): tirar os controles do corpo.** Hoje ela
  abre com até 11 controles antes da resposta — regime e moeda viram a linha
  *"como MEI · em reais · ajustar ›"*.

---

## 7. Fase 4 — A sensação de usar

- **A microinteração-assinatura: "o cofre fecha".** Ao salvar uma entrada, o
  fio-de-ouro fecha (350ms), nasce a linha `NO COFRE ESTE MÊS`, e o valor conta
  **do total anterior pro novo**. `0 → 412` diz "você tem 412"; `344 → 412` diz
  "você acabou de crescer 68" — e essa é a razão de voltar mês que vem.
- Cortar animação que não significa nada (lista completa em §8).
- Otimizar o repaint do cofre.

---

## 8. Inventário de defeitos encontrados no caminho

Registrado aqui pra não se perder na conversa.

### 8.1 Corrigidos ✅
| # | Defeito | Onde |
|---|---|---|
| 1 | **MEI: recebimento não se ligava ao Trabalho** — "já recebeu" zerado pra sempre | `reserva_screen` |
| 2 | **MEI: só um pagamento por mês** — tela sem saída depois do 1º registro | `reserva_screen` |
| 3 | **O gesto mais importante do app vibrava e não falava** (sem `announce()`) | `reserva_screen` |
| 4 | Pré-preenchimento mostrava `2000` em vez de `2.000` (`controller.text` não passa pelos formatters) | `money_field` |
| 5 | Jargão "Leão" incompreensível pra leigo | app inteiro |

### 8.2 Abertos — corrigir nas fases acima
| # | Defeito | Fase |
|---|---|---|
| 6 | **Billing do Pro não existe** — é flag local, dá pra virar Pro sem pagar | 6 |
| 7 | **Sem Crashlytics/Analytics** — cegos na dor nº 1 | 0 |
| 8 | **CSV do histórico atrás do paywall** — dado da pessoa | 0 |
| 9 | **Anúncio na navbar** — 2,48× de super-indexação, por centavos | 0 |
| 10 | **Regime por área** produz dois DAS pra um CNPJ | 1 |
| 11 | `MoneyCountUp` com `begin: 0` fixo — conta do zero, não do valor anterior | 4 |
| 12 | `/reserva` abre com transição de tela de configuração (`_toolPage`) | 4 |
| 13 | Dois pares de `StaggerIn` com índice **duplicado** no Resultado | 4 |
| 14 | `StaggerIn` sem clamp no histórico — 480ms de atraso no 8º mês | 4 |
| 15 | `VitrineCard` repinta ~290 pontos de grão + 2 shaders **por frame** | 4 |
| 16 | `endTint` fazendo `Color.lerp` por frame sem efeito visível | 4 |
| 17 | `pro_screen`: `AnimatedScale` = 3ª confirmação do mesmo evento | 4 |
| 18 | `pro_screen`: 600ms de tela parada segurando quem **acabou de pagar** | 4 |
| 19 | Splash de 1,7s **toda** abertura → só na primeira | 4 |
| 20 | Aba "Guardado" nomeia o número secundário | 1 |
| 21 | Onboarding pergunta BR/exterior duas vezes | 3 |

### 8.3 Dívida estrutural conhecida
| # | Item | Nota |
|---|---|---|
| 22 | **`proposta_papel.dart` e `proposta_pdf.dart` são layouts espelhados** | Mexer num exige mexer no outro, senão a promessa "é exatamente isso que o cliente recebe" vira mentira. Duplicação aceita porque renderizar PDF na tela exigiria plugin nativo de impressão |
| 23 | Docs `00` e `05` apoiados em amostra do público errado | ✅ marcado nos próprios docs |

---

## 9. Decisões abertas do dono

### 9.1 Anúncio na navbar — **minha recomendação: tirar**
No nosso nicho, anúncio aparece em **6,7% das reclamações contra 2,7% na média
geral — 2,48×**. Em troca, o eCPM de um banner num utilitário offline é de
centavos, e o AdMob já derrubou o app no boot uma vez. É risco alto de ★1 por
receita irrelevante, num app cuja promessa é justamente ser limpo e offline.
**Receita vem do Pro.** ⏳ *Aguardando seu ok.*

### 9.2 Preço — revisar a âncora
O R$ 97,80/ano do Precifica.app é **SaaS de gestão**. O comparável honesto é
*Receitas – Quanto Cobrar*: **R$ 12,90–29,90 compra única**, 100k+ instalações,
4,73★. E não há dado de willingness-to-pay do nosso público, porque não há
amostra dele. ⏳ *Decidir antes de criar os produtos na Play Console.*

### 9.3 Primeiro Trabalho grátis
O gate de multiplicidade fica no **segundo** Trabalho, não no primeiro — sem o
objeto salvo não há retenção, e calculadora pura não retém. ✅ *Adotado.*

### 9.4 A aposta de longo prazo, registrada e não agendada
O único item do dossiê com **efeito de rede** é uma **referência de mercado
brasileira** ("designers como você cobram entre X e Y") — não existe no Brasil,
e o Bonsai só cobre US/UK/CA. Não entra agora: exige base de usuários e traz
backend, o que quebra o fosso offline. Fica anotado como a direção que
justificaria preço maior no futuro.

---

## 10. Fase 5 — Proposta comercial

- **Cor da marca.** Paleta curada + seletor livre. O app calcula o contraste e
  decide sozinho se o texto por cima fica preto ou branco. A cor entra só como
  **acento** — nunca como fundo de texto corrido, pra nenhuma escolha quebrar o
  documento.
- **Contato com formato de verdade** (hoje o campo aceita qualquer lixo):
  - **WhatsApp** — seletor de país com bandeira + DDI, máscara `(44) 55555-5555`,
    caindo pra 8 dígitos em fixo.
  - **E-mail** — validação leve que **avisa sem bloquear**.
  - Os dois opcionais; ao menos um recomendado.
- **Onde vive:** no fim do cálculo e no ⋮ do Trabalho. **Não vira aba** — é ação,
  não lugar.

---

## 11. Fase 6 — Qualidade e loja

**Qualidade:** reescrever os testes que morrem com os cortes; revisão de a11y e
de contraste na estrutura nova (a Amara ainda não viu isso); backup sobe de
versão junto com o rename.

**Loja** — *sem isto o app não é um produto:*

| Item | Situação |
|---|---|
| **Compra real do Pro (Play Billing)** | ❌ não existe |
| Play Console: criar o app | ❌ o dono cria em 20/07 |
| Ficha (textos, prints, ícone) | ❌ |
| Data Safety + IARC | ❌ só UI do console, sem API |
| Política de privacidade em URL pública | ⚠️ texto existe no app, falta publicar |
| Conta de teste interno | ❌ |

---

## 12. A ordem

```
FASE 0  não lançar cego            ← rápida, e derruba risco de ★1 imediato
FASE 1  esqueleto novo         ┐
FASE 2  cortes                 ┘  ← juntas: é o mesmo código
FASE 3  caminho do cálculo
FASE 4  sensação de usar          ← barata, e é o que faz parecer premium
FASE 5  proposta (cor + contato)
FASE 6  qualidade + loja
```

**Por que a 0 primeiro:** é a mais barata e ataca a dor nº 1 do mercado. Lançar
sem crash reporting é escolher descobrir os bugs pela nota.

**Por que 1 e 2 juntas:** os cortes moram no mesmo código que a reestruturação
toca. Em dois passos, mexemos duas vezes nos mesmos arquivos.

**Por que a 3 não vem primeiro, sendo o objetivo nº 1:** porque ela já funciona
— está boa, não ótima. A estrutura é que está errada, e errada custa mais caro
a cada dia.

**Por que a proposta quase no fim:** ela já funciona. Polir a cor da marca antes
de a estrutura assentar é trabalhar numa tela que vai mudar de lugar.
