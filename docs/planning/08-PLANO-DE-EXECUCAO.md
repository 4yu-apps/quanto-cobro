# 08 — Plano de execução: tudo que falta

> **Status:** v1, escrito em 19/07/2026. As fases 1–6 estão firmes. A ordem e o
> escopo podem mudar quando a leitura de mercado dos dois donos de produto
> chegar (`docs/planning/produto/`) — o que muda é **prioridade**, não a
> direção. Marcado com ⏳ o que depende dessa leitura.
>
> Base: [07](07-PROPOSTA-E-GESTAO-DE-PROJETOS.md) + a revisão de UX em
> [`ux-revisao/`](ux-revisao/) (Ravi · fluxo · Kenji) + as decisões do dono
> tomadas em 19/07.

---

## 0. As decisões travadas (não se rediscute sem motivo novo)

| Decisão | Valor |
|---|---|
| **Vocabulário** | **Área** ("Design") → **Trabalho** ("o freela com o Augusto") → **Entradas** (os recebimentos) |
| **Abas** | **Início · Trabalhos · Configurações** |
| **Objetivo nº 1** | A tela inicial responder *"quanto custa a minha hora?"* |
| **O que é extra** | Salvar, gerir, propor. São adendos — e é neles que mora o Pro |
| **O que NÃO é** | App de gestão financeira. Nada de "paguei / não paguei imposto" |
| **Registro** | Cadastrar a entrada **é** o registro. Ninguém fica marcando "recebi, recebi" |
| **Jargão** | "Leão" está fora. O app diz **imposto** ✅ *(feito)* |

**A régua pra aceitar qualquer coisa daqui pra frente:** se não ajuda a
responder *"quanto eu cobro"* ou *"quanto entrou e quanto disso é imposto"*,
não entra.

---

## 1. Onde estamos (o que já está pronto e no ar)

✅ Calculadora → resultado → salvar · Reserva por pagamento · Histórico
✅ Proposta comercial em PDF com a marca do freelancer (Pro)
✅ Câmbio offline-first · Backup por arquivo · Tema claro/escuro · a11y
✅ **Bug do MEI corrigido** — o regime padrão voltou a funcionar (commit `384f429`)
✅ **"Leão" → "imposto"** no app inteiro
✅ 134 testes verdes, analyzer limpo

⚠️ **A aba "Projetos" está construída no modelo errado** (formulário primeiro,
lista plana, campos demais). É o principal alvo da Fase 2.

---

## 2. Fase 1 — O esqueleto novo *(a maior, e a que destrava tudo)*

**Objetivo:** o app passa a ter a estrutura que o dono descreveu.

### 1.1 Renomear os conceitos no código
`Perfil` → `Area` · `Projeto` → `Trabalho` · `ReservaEntry` → `Entrada`

Não é cosmético. O código chamar de "Perfil" o que o produto chama de "Área"
foi **exatamente** o que me fez montar a hierarquia ao contrário na entrega
passada. Nome errado no código vira feature errada na tela.

> ⚠️ **Confirmar antes:** o app já está publicado na Play com usuários reais?
> Se **não** (é o que eu suponho), renomeamos também as chaves de armazenamento
> e não precisamos de migração — economiza um dia de trabalho e uma classe
> inteira de bug. Se **sim**, mantemos as chaves antigas e migramos na leitura.

### 1.2 As três abas
- **Início** — o valor-hora e a calculadora. O objetivo nº 1.
- **Trabalhos** — a hierarquia (Áreas → Trabalhos → Entradas).
- **Configurações** — vira destino de verdade: Minha marca · Meus preços ·
  regime e imposto · backup · Pro · aparência. Sai o ícone de engrenagem do
  topo do Início.

### 1.3 A ordem de nascimento dos objetos
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

### 1.4 A hierarquia fica latente
Com **uma** área, a palavra "área" não aparece em lugar nenhum: a aba
Trabalhos mostra os trabalhos direto, em lista plana. O nível de cima só se
revela quando existe o segundo. Quem quer só calcular nunca vê a árvore.

### 1.5 A tela do Trabalho — *a tela que o dono pediu literalmente*
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
Tocar no trabalho **abre** (não edita). Editar é o ⋮. A proposta comercial
também mora no ⋮.

### 1.6 Onde vive o resumo do mês
A aba Guardado morre. O resumo *"entrou X este mês, separou Y de imposto"*
vira card no **Início**, e o histórico completo é uma tela empilhada a partir
dele. É o mesmo balde em dois zooms — não precisa de slot de aba.

**Entrega:** app navegável na estrutura nova, com os dados existentes intactos.

---

## 3. Fase 2 — Os cortes *(o app emagrece)*

Tudo aqui sai por decisão explícita do dono ou por não passar na régua.

| Sai | Por quê |
|---|---|
| `ProjetoStatus` (4 estados) → um `encerrado` no ⋮ | Orçamento/Ativo/Concluído/Pausado é board de kanban |
| `Recorrencia` (4 tipos) + `intervaloMeses` + stepper | O leigo não configura ciclo |
| `proximoRecebimento`, "Nos próximos 30 dias", `avancarCiclo`, `RecebimentoPrevisto` | Previsão pressupõe agendamento — e o registro é o que acontece, não o que se agenda |
| Selo "falta separar" e o nudge "já te pagou?" | O gatilho de voltar é o dinheiro cair, não o app cutucar |
| "Já paguei o imposto deste mês", `leaoPago`, banner de vencimento do DAS | *"Não é gestão de paguei/não paguei"* |
| `tipoContrato` no perfil + a arbitragem entre dois nudges | Sobra do modelo antigo |
| Formulário do trabalho: **8 campos → 3** (nome, valor, área) | O resto era gestão que ninguém pediu |
| Chips de filtro do histórico | Complexidade sem uso |

**Sobrevive de propósito:** o DAS como *número dentro do cálculo* ("seu DAS de
R$ 86/mês já está dentro desse preço"). O app continua sabendo que você é MEI;
para de te dar tarefa por isso.

---

## 4. Fase 3 — O caminho do cálculo *(o objetivo nº 1, afiado)*

- **Onboarding 3 → 2 páginas.** Morre a pergunta "Brasil/exterior" — ela é
  feita de novo, melhor, no passo do regime.
- **Calculadora 5 → 4 passos**, com o **valor-hora vivo no topo a partir do
  passo 3**. Hoje são cinco telas de investimento com zero retorno; com o
  número vivo, os passos viram *ajuste* de uma coisa que já é dela.
- Provisão de férias/13º sai do passo 5 e vira toggle no Detalhamento.
- O botão do Resultado vira **"Salvar como…"**.

---

## 5. Fase 4 — Proposta comercial *(polimento do que já existe)*

- **Cor da marca.** Paleta curada + seletor livre. O app calcula o contraste e
  decide sozinho se o texto por cima fica preto ou branco. A cor entra só como
  **acento** — nunca como fundo de texto corrido. Assim nenhuma escolha quebra
  o documento.
- **Contato com formato de verdade.** Hoje o campo aceita qualquer lixo. Vira:
  - **WhatsApp** — seletor de país com bandeira + DDI, máscara `(44) 55555-5555`
    (cai pra 8 dígitos em fixo).
  - **E-mail** — validação leve que **avisa sem bloquear**.
  - Os dois opcionais; pelo menos um recomendado.
- **Onde ela vive:** no fim do cálculo (acabei de descobrir meu preço → mando
  pro cliente) e no ⋮ do trabalho. **Não vira aba** — é ação, não lugar.
- Gate Pro no export permanece.

---

## 6. Fase 5 — A sensação de usar

- **A microinteração-assinatura: "o cofre fecha".** Ao salvar uma entrada, o
  fio-de-ouro fecha (350ms), nasce a linha `NO COFRE ESTE MÊS`, e o valor conta
  **do total anterior pro novo** — não do zero. `0 → 412` diz "você tem 412";
  `344 → 412` diz "você acabou de crescer 68", que é a razão de voltar.
- **Cortar animação que não significa nada:** cascata na lista, `StaggerIn` com
  índice duplicado no Resultado, avisos chegando atrasados, splash de 1,7s toda
  abertura (passa a rodar completo só na primeira).
- `/reserva` deixa de abrir com transição de tela de configuração.
- Otimizar o repaint do cofre (hoje redesenha ~290 pontos de grão por frame).

---

## 7. Fase 6 — Qualidade e dívida

- Testes: reescrever os que morrem com os cortes; manter cobertura do cálculo,
  do imposto e do fluxo de entrada.
- Backup: subir de versão junto com o rename dos conceitos.
- Revisão de a11y ponta a ponta na estrutura nova (a Amara ainda não viu isso).
- Revisão de contraste e tipografia na estrutura nova.

---

## 8. ⏳ Fase 7 — O que falta pra existir na Play Store

**Isto não é polimento: sem isto o app não é um produto.** Levantado aqui
porque o pedido foi "tudo que falta".

| Item | Situação hoje |
|---|---|
| **Compra real do Pro** | ❌ **Não existe.** O Pro é uma flag local — dá pra "virar Pro" sem pagar. Precisa de billing da Play, produto criado no console e validação |
| Ficha da Play (textos, prints, ícone) | ❌ A fazer |
| Data Safety + questionário IARC | ❌ A fazer (só UI do console, não tem API) |
| Política de privacidade publicada | ⚠️ Existe texto no app; falta URL pública |
| AdMob | ⚠️ Removido do código até ter o `APPLICATION_ID` configurado (já derrubou o app no boot uma vez) |
| Analytics / Crashlytics | ⚠️ Removidos até ter o `google-services.json` |
| Conta de teste interno | ❌ A fazer |

⏳ A ordem entre "billing" e "as fases 1–5" depende da leitura de mercado: se o
Pro vai ser validado cedo com usuários reais, billing sobe de prioridade.

---

## 9. Minha recomendação de ordem

```
FASE 1  esqueleto (abas, hierarquia, tela do Trabalho, ordem de nascimento)
FASE 2  cortes                      ← pode ir junto com a 1; é o mesmo código
FASE 3  caminho do cálculo
FASE 5  sensação de usar            ← barato, e é o que faz parecer premium
FASE 4  proposta (cor + contato)
FASE 6  qualidade
FASE 7  loja                        ⏳ ordem depende da leitura de mercado
```

**Por que 1 e 2 juntas:** os cortes são no mesmo código que a reestruturação
toca. Fazer em dois passos significa mexer duas vezes nos mesmos arquivos.

**Por que a proposta depois da 5, e não antes:** ela já funciona. Polir a cor
da marca antes de a estrutura assentar é trabalhar numa tela que vai mudar de
lugar.

**Por que a 3 não vem primeiro, sendo o objetivo nº 1:** porque ela já
funciona hoje — está boa, não ótima. A estrutura é que está errada, e errada
custa mais caro a cada dia que passa.

---

## 10. O que eu preciso decidir com o dono antes de começar

1. **O app já está publicado com usuários reais?** Decide se precisamos de
   migração de dados no rename (§1.1).
2. **Fase 1+2 juntas numa entrega, ou 1 primeiro pra você ver navegando?**
   Recomendo juntas — mas se você quiser ver de pé antes, eu separo.
3. **A aba Configurações leva "Meus preços" (as áreas) ou isso vive só na aba
   Trabalhos?** Recomendo os dois caminhos: consultar em Trabalhos, ajustar em
   Configurações.
4. ⏳ **Billing entra antes ou depois do polimento?** Depende de quando você
   quer testar com gente de verdade.
