# QUANTO EU COBRO? — Design System "A Divisão"

> **Agente 3 · Marca & Design System (Fase 1a do PADRÃO 4YU)**
> Escopo: identidade visual, tom de voz, cor, tipografia, tokens, temas escuro/claro, componentes, acessibilidade, brief de logo, prompt do Claude Design e checklist de revisão.
> Entrada: `QUANTO-COBRO-UX-Blueprint.md` (Agente 2). Saída → Agente 4 (Arquiteto Flutter).
> Base obrigatória: `PADRAO-4YU-APPS.md` §3 (Design System) e §7 (Claude Design → tokens).
> App: **Quanto eu Cobro?** — calculadora financeira do freelancer: valor-hora justo, reserva de imposto e lucro real, com contexto tributário BR (MEI/DAS · autônomo CPF · Simples) + modo internacional.

---

## 0. TL;DR — a tese visual em uma página

O concorrente raso é uma **calculadora de 1 campo**. O nosso valor não está na conta (a fórmula é pública) — está em **tornar visível o que o freelancer não vê** (blueprint §0). O design existe para servir isso, não para enfeitar.

**Decisões travadas com o Gabriel (rodada 2):**

1. **Cor-semente: Verde-Justo** (`#0E8C6B`) — categoria finanças, mas resolve a tensão "confiança × calor humano": verde = dinheiro, crescimento e "positivo", sem a frieza de banco nem a cara de declaração de imposto que o blueprint manda evitar (§1). Foge também do azul-fintech genérico (anti-clone, PADRÃO §3).
2. **Tema padrão: Escuro** (entrego escuro **e** claro completos, com paridade).
3. **Estética: decisão do Agente 3** → **"calculadora de confiança, humana e não fiscal — organizada pela Divisão"** (ver abaixo).

**A ideia-assinatura do sistema — "A Divisão":**

> **Todo dinheiro neste app é mostrado dividido, com honestidade.** A dor central do freelancer é não enxergar para onde vai cada real — ele vê o bruto e acha que é lucro. Então o produto inteiro gira em torno de **uma barra com legenda fixa que reparte qualquer valor em três partes que o usuário aprende uma vez**: 🟩 **Lucro (é seu)** · 🟦 **Reserva (do imposto, guardado)** · ⬜ **Custos (mantêm você trabalhando)**. A mesma barra, a mesma legenda, as mesmas cores aparecem no Painel, no Resultado, na Reserva e no Simulador. O usuário não decora fórmula — ele aprende a **ler o próprio dinheiro**.

Isso transforma a tese do blueprint ("mostrar o invisível") no recurso visual central — o equivalente, aqui, ao que a Escala de Calor é na Fervura. Cada cor tem **um** significado e nunca briga com outro: verde = seu, azul = guardado/seguro, neutro = custo, âmbar = atenção (nunca imposto), vermelho = erro. Tudo neste documento deriva daí.

**O que este DS preserva do blueprint (handoff §16):** número é o herói em toda tela · hierarquia das 3 respostas (valor-hora primeiro) · uma pergunta por tela com progresso e defaults · **selo calmo de "estimativa de planejamento"** sempre presente, nunca alarmante · os dois tools recorrentes (reserva e simulador) como protagonistas do Painel · **anúncio nunca compete com um número de dinheiro**.

---

## 1. Marca

### 1.1 Essência e posicionamento

| Atributo | Definição |
|---|---|
| **O que é** | A calculadora que diz ao freelancer **quanto cobrar, quanto guardar e quanto sobra** — e mostra a conta, em português de gente. |
| **Para quem** | Autônomos e freelancers brasileiros que precificam "no chute", chegam ansiosos ("será que cobrei errado a vida toda?") e **não são financeiramente fluentes** (blueprint §1). |
| **Promessa** | "Pare de trabalhar de graça." |
| **Personalidade** | Calmo, honesto, parceiro. Traduz o labirinto tributário sem jargão. Confiante o bastante para você decidir o preço; honesto sobre o limite ("é estimativa, não declaração"). Nunca assusta, nunca finge exatidão. |
| **Arquétipo** | O **Sócio que entende de número** — o contador-amigo que faz a conta por você e te defende de aceitar trabalho ruim. Não é o Leão assustador, nem o coach hypado de "fature 6 dígitos". |
| **O que NÃO é** | Não é app de banco frio, não é planilha de imposto de renda, não é fintech genérica azul, não é guru de enriquecimento. Tem cara de **ferramenta de trabalho confiável e tranquila**. |

### 1.2 Naming e tagline

- **Nome (loja/marca):** **Quanto eu Cobro?** — a pergunta é a marca. O **"?"** é elemento de identidade (aparece no ícone e no wordmark, na cor Verde-Justo).
- **Nome curto (header do app):** **Quanto Cobro?**
- **Tagline principal:** **"Quanto cobrar, quanto guardar, quanto sobra."** (espelha as 3 respostas).
- **Alternativas de loja/marketing:** "Pare de trabalhar de graça." · "Seu preço justo, sem chute." · "O preço justo do seu tempo." · "Descubra para onde vai cada real."
- **Tom da pronúncia:** pergunta calma de quem vai te ajudar, não cobrança. Evitar trocadilho de dinheiro forçado ("bora faturar!", "$$$").

### 1.3 Tom de voz

Três princípios, com exemplos (derivados dos princípios de UX §3 do blueprint):

1. **Fala humano, não fiscal.** O usuário responde como trabalha; o app traduz para regime/alíquota nos bastidores. → *"Como você recebe hoje?"*, nunca *"Selecione o regime tributário"*.
2. **Calmo sobre dinheiro e imposto.** Mostrar imposto sem assustar é o trabalho. Honestidade tranquila, nunca alarme. → *"Estimativa pra você se planejar"*, nunca *"Você DEVE R$ X de imposto"*.
3. **Mostra o invisível com gentileza.** Educar é o produto, não a bronca. → *"Quase ninguém fatura 160h. Vamos achar o seu número real."*, não *"Você está calculando errado."*

| Faça | Não faça |
|---|---|
| "Cobre R$ 92/hora" | "Valor-hora calculado: R$ 92,00" |
| "Recebi um pagamento" | "Registrar entrada de receita" |
| "Reserve R$ 320 — isso é do imposto" | "Provisão tributária: R$ 320,00" |
| "Como você recebe hoje?" | "Selecione o regime tributário aplicável" |
| "É uma estimativa pra te ajudar a decidir o preço" | "O cálculo não constitui consultoria fiscal" |
| "Esse projeto paga menos que seu alvo. Quer cobrar R$ 4.260?" | "Valor abaixo do parâmetro configurado" |
| "Coloque um valor maior que zero pra eu calcular" | "Erro: input inválido" |

### 1.4 Biblioteca de microcopy (PT-BR · v1)

**Ações primárias:** `Começar` · `Continuar` · `Ver resultado` · `Recalcular` · `Salvar este perfil` · `Recebi um pagamento` · `Vou orçar um projeto` · `Ver como cheguei` · `Estimar pra mim` · `Editar`.

**Estado vazio (Painel):** título *"Você provavelmente cobra menos do que deveria."* · apoio *"Descubra seu valor-hora justo em 5 perguntas."* · CTA *"Começar"* · rodapé de confiança *"Leva 2 minutos · 100% offline"*.

**Fluxo guiado (perguntas-título):**
- P1 *"Quanto você quer GANHAR por mês?"* + ⓘ *"É o que você quer que sobre pra você — não o faturamento."*
- P2 *"Quantas horas você realmente FATURA por mês?"* + ⚠ *"Não são 160h. Tire férias, feriados e o tempo sem cliente."* + ação *"Não sei → estimar pra mim"*.
- P3 *"Seus custos pra trabalhar?"* + lembrete *"Não esqueça:"* (chips).
- P4 *"Como você recebe hoje?"* (rádio sem jargão).
- P5 *"Quer provisionar férias e 13º?"* + apoio *"(autônomo não ganha de graça)"*.

**Resultado (rótulos dos 3 blocos):** *"COBRE POR HORA"* · *"DE CADA PAGAMENTO, RESERVE"* · *"LUCRO REAL ESTIMADO"*. Equivalência: *"≈ R$ 736/dia · R$ 10,1k/mês faturados"*.

**Selo de estimativa (onipresente, calmo):** *"Estimativa de planejamento — não é consultoria fiscal."* (curto, ícone ⓘ, nunca em vermelho). Variante curta no rodapé de tools: *"Estimativa pra te ajudar a decidir."*

**Reserva (tool):** título *"Recebi um pagamento"* · campo *"Quanto você recebeu?"* · resultado *"RESERVE PARA IMPOSTO"* · apoio *"Sobra pra usar: R$ 1.680"* · regime *"Regime: MEI ▾ (puxa do seu perfil)"*.

**Simulador (tool):** título *"Vou orçar um projeto"* · campos *"Valor do projeto"* · *"Horas estimadas"* · *"Custos do projeto (opcional)"* · resultado *"LUCRO REAL"* + *"Valor-hora efetivo: R$ 65/h"* · aviso *"Abaixo do seu alvo (R$ 92/h). Cobre ~R$ 4.260 pra manter seu lucro."*

**Dado tributário desatualizado:** *"Valores base de 2025 — confirme as alíquotas atuais."* (faixa discreta, não alarme).

**Erros (sem susto, humanos):**
- Renda 0/negativa: *"Coloque quanto você quer ganhar pra eu calcular."*
- Horas 0: *"Preciso de pelo menos 1 hora faturável pra fazer a conta."*
- Falha ao salvar: *"Não consegui salvar. Tenta de novo."* + `Desfazer`.
- Falha ao ler perfil: *"Não consegui carregar seu cálculo. Vamos refazer?"* + `Começar`.

**Snackbars:** *"Perfil salvo"* · *"Perfil removido"* + `Desfazer` · *"Dados apagados"*.

**Pro (no momento de valor):** *"Vários perfis é recurso Pro"* · *"Exportar orçamento em PDF (Pro)"* · *"Modo avançado por regime (Pro)"* · *"Remover anúncios"*.

---

## 2. Cor

### 2.1 Cores-âncora da marca

| Papel | Nome | Hex | Significado fixo | Uso |
|---|---|---|---|---|
| **Primária** | **Verde-Justo** | `#0E8C6B` | "É seu / positivo / pode confiar" | Cor-semente, ações, número-herói, **Lucro** na Divisão, logo. |
| Secundária | **Azul-Cofre** | `#4A72D6` | "Guardado / seguro / não é seu (ainda)" | **Reserva de imposto** na Divisão, selo calmo, acentos de confiança. |
| Terciária | **Âmbar-Atenção** | `#9C6F00` | "Olha aqui / cuidado, sem alarme" | Aviso "abaixo do alvo" no simulador, destaque do custo invisível, chips de lembrança. |
| Neutro (frio-calmo) | **Tinta/Papel** | `#171D1A` / `#F5FBF4` | "O que mantém você trabalhando" | Texto e superfícies; **Custos** = segmento neutro da Divisão. |
| Erro | **Carmim** | `#BA1A1A` | "Algo quebrou / ação destrutiva" | Erros reais e confirmações destrutivas. Mais frio que o âmbar, **de propósito** — imposto nunca é vermelho. |
| Assinatura mãe | **Roxo 4YU** | `#6C4BD6` | Marca-mãe | **Só** selo "by 4YU", tela Sobre, marketing. Nunca na UI funcional. |

> **Regra de ouro 4YU (PADRÃO §3):** roxo é assinatura discreta, jamais a cor da interface. A cor da UI é o Verde-Justo, escolhido pela categoria. Pintar tudo de roxo **aumenta** o risco de spam 4.3.

> **A regra cromática deste app:** **âmbar ≠ imposto.** Em finanças, amarelo/vermelho gritam "perigo". O imposto a reservar **não é perigo** — é dinheiro guardado. Por isso a Reserva é **Azul-Cofre** (seguro, tranquilo) e o âmbar fica reservado só para *atenção sem alarme* (ex.: "esse projeto paga pouco"). Isso protege o princípio nº4 do blueprint (honestidade calma).

### 2.2 Paletas tonais (rampas 0–100)

Modelo Material 3 (tom 0 = preto, 100 = branco). O nome de marca aponta o tom ~50; os papéis de tema usam tons mais claros/escuros para garantir contraste (§3). **Geradas a partir das sementes acima** — o Agente 4 pode regenerar com `material_color_utilities` usando os mesmos hexes-semente.

**Verde-Justo (Primary)**

| Tom | 10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 95 | 99 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Hex | `#00201A` | `#003828` | `#00513C` | `#006C50` | `#0E8C6B` | `#1FA67F` | `#45C29A` | `#6FDEB5` | `#93FBD0` | `#C4FFE6` | `#F2FFF9` |

**Azul-Cofre (Secondary / reserva)**

| Tom | 10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 95 | 99 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Hex | `#00174B` | `#002B75` | `#0B409F` | `#2C57B8` | `#4A72D6` | `#6B8DF0` | `#92A9FF` | `#B8C4FF` | `#DCE1FF` | `#EEEFFF` | `#FEFBFF` |

**Âmbar-Atenção (Tertiary)**

| Tom | 10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 95 | 99 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Hex | `#261900` | `#402D00` | `#5C4200` | `#7C5800` | `#9C6F00` | `#BB8800` | `#DCA21F` | `#FBBE48` | `#FFDEAD` | `#FFEFD9` | `#FFFBFF` |

**Neutro calmo (texto/superfícies — leve toque verde para casar com a marca)**

| Tom | 4 | 6 | 10 | 12 | 17 | 20 | 22 | 24 | 90 | 92 | 94 | 96 | 98 | 99 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Hex | `#0A0F0D` | `#0F1513` | `#171D1A` | `#1B211E` | `#252B28` | `#2B312E` | `#2F3633` | `#343A37` | `#DFE4DE` | `#E4EAE2` | `#E9F0E8` | `#EFF5ED` | `#F5FBF4` | `#FBFFF8` |

**Neutro Variante (outline/surfaceVariant)**

| Tom | 30 | 40 | 50 | 60 | 70 | 80 | 90 |
|---|---|---|---|---|---|---|---|
| Hex | `#404943` | `#586259` | `#707972` | `#8A938B` | `#A4ADA5` | `#C0C9C0` | `#DCE5DB` |

**Erro (carmim — mais frio que o âmbar, de propósito)**

| Tom | 10 | 20 | 30 | 40 | 80 | 90 |
|---|---|---|---|---|---|---|
| Hex | `#410002` | `#690005` | `#93000A` | `#BA1A1A` | `#FFB4AB` | `#FFDAD6` |

### 2.3 "A Divisão" (o coração do sistema)

A barra que reparte qualquer valor em três partes com **legenda fixa**. É a mesma linguagem no Painel, Resultado, Reserva e Simulador — o usuário aprende a leitura **uma vez**.

| Parte | Token | Claro | Escuro | Significado | Sinal não-cromático (obrigatório) |
|---|---|---|---|---|---|
| **Lucro (é seu)** | `divisao.lucro` | `#006C50` | `#6FDEB5` | O que fica com você | Rótulo "Lucro" + % + posição (sempre à esquerda) |
| **Reserva (imposto)** | `divisao.reserva` | `#2C57B8` | `#B8C4FF` | Guardado pro leão, seguro | Rótulo "Reserva" + % + ícone cofre |
| **Custos** | `divisao.custo` | `#586259` | `#A4ADA5` | Mantém você trabalhando | Rótulo "Custos" + % + textura/hachura sutil |
| Trilho (vazio) | `divisao.track` | `#DCE5DB` | `#2F3633` | Fundo da barra | — |

**Como se comporta:**
- **Sempre com legenda e número, nunca só cor** (acessibilidade §7 + blueprint §9): cada segmento mostra rótulo + valor R$ + %. Daltônicos leem pela ordem fixa, pelo rótulo e pela hachura do segmento de Custos.
- **Ordem fixa da esquerda p/ direita:** Lucro → Reserva → Custos. A ordem nunca muda (memória visual).
- **Animação de preenchimento** suave ao abrir um resultado (`motion.emphasized`), os números "sobem" (count-up). Em *reduce motion*, aparece estática.
- **No tool de Reserva**, a barra colapsa para o foco do job: destaque na **Reserva** (herói) + "Sobra pra usar". No **Simulador**, destaque no **Lucro real**.

> **Por que isto, e não cor "by feeling":** a Divisão é o argumento anti-clone e anti-"calculadora rasa". Qualquer app cospe um número; só o nosso **mostra a anatomia do número** com uma linguagem visual consistente — exatamente o "tornar visível o invisível" do blueprint (§0, §3).

### 2.4 Selo de estimativa & estado "tabela desatualizada"

O momento mais delicado do app (mostrar imposto sem assustar) tem tratamento de cor próprio — **calmo por design**:

| Token | Claro | Escuro | Uso |
|---|---|---|---|
| `seal.bg` (= surfaceContainerHigh) | `#E4EAE2` | `#252B28` | Fundo do selo "estimativa de planejamento". |
| `seal.fg` (= onSurfaceVariant) | `#404943` | `#C0C9C0` | Texto + ícone ⓘ do selo. **Nunca** vermelho/âmbar. |
| `stale.bg` (= secondaryContainer) | `#DCE1FF` | `#0B409F` | Faixa "valores base de 2025". Azul calmo = informação, não erro. |
| `stale.fg` | `#00174B` | `#DCE1FF` | Texto da faixa. |

---

## 3. Temas — tokens de role (Material 3)

Dois `ColorScheme` derivados das rampas. **Os nomes de token são idênticos no Claude Design e no `core/theme` do Flutter** (PADRÃO §7 — vira de-para direto). **O Escuro é o tema padrão**; o Claro tem paridade total.

### 3.1 Tema Escuro (padrão)

| Role | Hex | Role | Hex |
|---|---|---|---|
| primary | `#6FDEB5` | surface | `#0F1513` |
| onPrimary | `#003828` | onSurface | `#DFE4DE` |
| primaryContainer | `#00513C` | surfaceVariant | `#404943` |
| onPrimaryContainer | `#93FBD0` | onSurfaceVariant | `#C0C9C0` |
| secondary | `#B8C4FF` | surfaceContainerLowest | `#0A0F0D` |
| onSecondary | `#002B75` | surfaceContainerLow | `#171D1A` |
| secondaryContainer | `#0B409F` | surfaceContainer | `#1B211E` |
| onSecondaryContainer | `#DCE1FF` | surfaceContainerHigh | `#252B28` |
| tertiary | `#FBBE48` | surfaceContainerHighest | `#2F3633` |
| onTertiary | `#402D00` | outline | `#8A938B` |
| tertiaryContainer | `#5C4200` | outlineVariant | `#404943` |
| onTertiaryContainer | `#FFDEAD` | inverseSurface | `#DFE4DE` |
| error | `#FFB4AB` | inverseOnSurface | `#2B312E` |
| onError | `#690005` | inversePrimary | `#006C50` |
| errorContainer | `#93000A` | scrim | `#000000` |
| onErrorContainer | `#FFDAD6` | shadow | `#000000` |

### 3.2 Tema Claro

| Role | Hex | Role | Hex |
|---|---|---|---|
| primary | `#006C50` | surface | `#F5FBF4` |
| onPrimary | `#FFFFFF` | onSurface | `#171D1A` |
| primaryContainer | `#93FBD0` | surfaceVariant | `#DCE5DB` |
| onPrimaryContainer | `#00201A` | onSurfaceVariant | `#404943` |
| secondary | `#2C57B8` | surfaceContainerLowest | `#FFFFFF` |
| onSecondary | `#FFFFFF` | surfaceContainerLow | `#EFF5ED` |
| secondaryContainer | `#DCE1FF` | surfaceContainer | `#E9F0E8` |
| onSecondaryContainer | `#00174B` | surfaceContainerHigh | `#E4EAE2` |
| tertiary | `#7C5800` | surfaceContainerHighest | `#DFE4DE` |
| onTertiary | `#FFFFFF` | outline | `#707972` |
| tertiaryContainer | `#FFDEAD` | outlineVariant | `#C0C9C0` |
| onTertiaryContainer | `#261900` | inverseSurface | `#2B312E` |
| error | `#BA1A1A` | inverseOnSurface | `#EFF5ED` |
| onError | `#FFFFFF` | inversePrimary | `#6FDEB5` |
| errorContainer | `#FFDAD6` | scrim | `#000000` |
| onErrorContainer | `#410002` | shadow | `#000000` |

### 3.3 Tokens customizados (ambos os temas)

Fora do `ColorScheme` padrão, num `ThemeExtension` chamado `QuantoCobroColors` (ver §9.3):

```
divisao.lucro      divisao.reserva    divisao.custo     divisao.track
seal.bg            seal.fg            stale.bg          stale.fg
alerta             alertaContainer    onAlertaContainer   (= âmbar; aviso "abaixo do alvo")
sucesso / onSucesso / sucessoContainer   (= verde; reusa lucro)
ad.surface (= surfaceContainerLow)   ad.label (= onSurfaceVariant)
brand.4yu (#6C4BD6)  — só selo/Sobre
```

Valores:

| Token | Claro | Escuro |
|---|---|---|
| `divisao.lucro` | `#006C50` | `#6FDEB5` |
| `divisao.reserva` | `#2C57B8` | `#B8C4FF` |
| `divisao.custo` | `#586259` | `#A4ADA5` |
| `divisao.track` | `#DCE5DB` | `#2F3633` |
| `alerta` (texto/ícone) | `#7C5800` | `#FBBE48` |
| `alertaContainer` | `#FFDEAD` | `#5C4200` |
| `onAlertaContainer` | `#261900` | `#FFDEAD` |
| `seal.bg` | `#E4EAE2` | `#252B28` |
| `seal.fg` | `#404943` | `#C0C9C0` |

---

## 4. Tipografia

### 4.1 Famílias

| Uso | Família | Por quê | Pesos |
|---|---|---|---|
| **Números (valor-hora, R$, %, display)** | **Sora** | Geométrica, confiante e moderna, com caráter de "dinheiro sério" sem ser fria; figuras tabulares. O número é o herói — precisa ter presença. | 600 / 700 / 800 |
| **UI, rótulos, corpo, helpers** | **Inter** | Legibilidade máxima, neutra, ótima acessibilidade, figuras tabulares. Carrega a "voz humana" do app. | 400 / 500 / 600 / 700 |
| **Wordmark "Quanto eu Cobro?"** | Sora 800 | Mantém o sistema enxuto (1 família de display); o "?" é o acento de marca. | 800 |

> **Bundle, não runtime.** App é local-first: **empacote as fontes em `assets/fonts`** (sem download em runtime). Garante offline, performance e privacidade (blueprint §8).
> **Figuras tabulares (`tnum`) obrigatórias** em tudo que mostra dinheiro — valores não podem "dançar" ao digitar/animar. Em CSS: `font-feature-settings: "tnum" 1;` · em Flutter: `fontFeatures: [FontFeature.tabularFigures()]`.
> **Moeda formatada** sempre via `intl` (`R$ 1.234,56`) — nunca concatenação manual (acessibilidade + evita erro, blueprint §9).

### 4.2 Escala — estilos de número (o número é o herói)

| Token | Tam (sp) | Peso | Uso |
|---|---|---|---|
| `value.hero` | 72 | 700 | Valor-hora no Painel e no Resultado; reserva no tool. O maior elemento da tela. |
| `value.xl` | 56 | 700 | Lucro real (Resultado), reserva (Resultado). |
| `value.lg` | 44 | 700 | Resultado dos tools inline (lucro, reserva). |
| `value.md` | 32 | 600 | Valores secundários, total de custos, equivalências fortes. |
| `value.display` | 40 | 600 | Display do campo monetário em foco ("R$ 5.000"). |
| `value.keypadKey` | 28 | 600 | Teclas 0–9 do teclado numérico (quando usado). |

> Tudo `tnum`, tracking −1 a −2. O `value.hero` tem **prioridade de espaço** sobre tudo (text-scaling do SO pode encolher rótulos antes do herói).

### 4.3 Escala — Material 3 (UI, via Inter)

| Token | Tam/Linha (sp) | Peso |
|---|---|---|
| displaySmall | 36 / 44 | 600 |
| headlineMedium | 28 / 36 | 600 |
| headlineSmall | 24 / 32 | 600 |
| titleLarge | 22 / 28 | 600 |
| titleMedium | 16 / 24 | 600 |
| titleSmall | 14 / 20 | 500 |
| bodyLarge | 16 / 24 | 400 |
| bodyMedium | 14 / 20 | 400 |
| labelLarge (botões) | 16 / 20 | 600 |
| labelMedium | 13 / 16 | 500 |
| labelSmall (selo, "Publicidade") | 11 / 16 | 500 |

> **Mínimo de corpo = 16sp.** As perguntas-título do fluxo guiado usam `headlineSmall 24`. Helpers (ⓘ) usam `bodyMedium 14`. Suportar *text scaling* do SO até 130% sem quebrar layout (testar; o número-herói tem prioridade).

---

## 5. Fundamentos — espaço, raio, elevação, motion, ícones

### 5.1 Espaçamento (grid base 4dp)

| Token | dp | Token | dp |
|---|---|---|---|
| space.0 | 0 | space.5 | 20 |
| space.1 | 4 | space.6 | 24 |
| space.2 | 8 | space.8 | 32 |
| space.3 | 12 | space.10 | 40 |
| space.4 | 16 | space.12 | 48 |
| | | space.16 | 64 |

**Semânticos:** padding de tela = `space.4` (16) · gap entre cards = `space.3` (12) · padding interno do card = `space.5` (20) · gap entre seções = `space.6` (24) · respiro acima do número-herói = `space.6`.

### 5.2 Raio de canto

| Token | dp | Uso |
|---|---|---|
| radius.sm | 12 | Chips internos, snackbar, segmentos da barra da Divisão. |
| radius.md | 16 | Inputs, botões secundários, teclas. |
| radius.lg | 20 | **Cards (herói, tools, perguntas)**. |
| radius.xl | 24 | Containers grandes, banner, card-herói do Painel. |
| radius.2xl | 28 | Topo dos *sheets* (helper de horas, Pro). |
| radius.full | 999 | Botão primário (pill), chips, FAB. |

### 5.3 Elevação (Material 3)

| Nível | dp | Uso |
|---|---|---|
| 0 | 0 | Fundo, fluxo guiado (foco total no campo). |
| 1 | 1 | Cards de tool e de pergunta (sombra calma sutil). |
| 2 | 3 | Card-herói do valor-hora, botão primário. |
| 3 | 6 | *Sheets* (helper, Pro), menus. |
| 4–5 | 8–12 | Diálogos (confirmação destrutiva). |

> No claro, preferir **outline sutil** (`outlineVariant`) + sombra leve, para não "sujar" o papel. No escuro, a hierarquia vem do tom de superfície (`surfaceContainer*`), não de sombra. State layers: hover 8%, focus/press 12%.

### 5.4 Motion

| Token | ms | Easing |
|---|---|---|
| motion.quick | 120 | standard `cubic-bezier(0.2,0,0,1)` |
| motion.base | 200 | standard |
| motion.emphasized | 350 | emphasized-decel `cubic-bezier(0.05,0.7,0.1,1)` |
| motion.slow | 500 | emphasized |
| motion.countUp | 600 | ease-out (números sobem até o valor final) |
| motion.fill | 450 | emphasized (preenchimento da barra da Divisão) |

**Comportamentos-chave:**
- **Resultado nasce:** o número-herói faz *count-up* (`motion.countUp`) e a **barra da Divisão preenche** (`motion.fill`) — o usuário *vê* o dinheiro se dividir. Forte momento de "aha".
- **Tools ao vivo:** reserva e simulador recalculam enquanto digita, sem botão "calcular" — transição `motion.quick` no número.
- **Passo do fluxo guiado:** desliza lateral `motion.base`; o stepper (●●○○○) anima 1 ponto.
- **Aviso "abaixo do alvo":** entra com fade + leve deslize (`motion.base`), nunca pisca/estroboscópico — é atenção calma, não alarme.
- **Editar do detalhamento:** muda o item → número-herói faz *count-up* até o novo valor (mostra a causa→efeito).

> **Reduzir movimento (acessibilidade):** se o SO pedir *reduce motion*, trocar *count-up* e *fill* por estado final estático; o aviso usa borda/ícone, não animação.

### 5.5 Iconografia

- **Família:** Material Symbols **Rounded**, peso 400, optical size 24. Combina com o tom calmo-arredondado da marca.
- **Tamanhos:** 24 padrão · 28 em cards · **32–40** em alvos grandes.
- **Ações do Painel (posições estáveis):** Recebi pagamento `payments` · Orçar projeto `request_quote` · Ver como cheguei `receipt_long` · Recalcular `calculate` · Configurações `settings` · Perfis (Pro) `switch_account`.
- **Fluxo guiado:** renda `savings` · horas `schedule` · custos `receipt_long` · regime/trabalho `work` · férias/13º `beach_access`. Helper/info `info` (ⓘ). Estimar pra mim `auto_awesome`.
- **A Divisão (ícones de legenda, reforçam a cor):** Lucro `account_balance_wallet` (é seu) · Reserva `lock` / `savings` (guardado/cofre) · Custos `build` (mantém você trabalhando).
- **Sinais por FORMA (não só cor — §7):** atenção/abaixo do alvo `trending_down` + texto · sucesso `check_circle` (✓) · estimativa/info `info` (ⓘ) · erro `error` (carmim) + texto.
- **Chips de custo (identidade por forma):** Contador `calculate` · Coworking `chair` · Cursos `school` · Energia `bolt` · Internet/telefone `wifi` · Equipamento `devices` · Pró-labore `account_balance` · Plano de saúde `health_and_safety` · Software `apps` · Marketing `campaign` · Transporte `directions_car`.

---

## 6. Componentes

Cada um: anatomia · estados · tokens. Todos os alvos de toque **≥ 48dp** (PADRÃO §3 / blueprint §9). Campos de valor abrem **teclado numérico** com formatação de moeda automática.

### 6.1 Card-herói do valor-hora ⭐ (Painel)

**Anatomia (de cima p/ baixo):** rótulo *"SEU VALOR-HORA"* (`labelLarge`, `onSurfaceVariant`) · **número-herói** `R$ 92 /hora` (`value.hero`, `primary`) · linha de contexto *"pra ganhar R$ 5.000/mês"* (`bodyLarge`, `onSurfaceVariant`) · link *"ver como cheguei aqui"* (texto `primary`, ícone `receipt_long`).

**Fundo:** `surfaceContainerHigh` · raio `radius.xl` · elevação 2 · padding `space.6`.

**Estados:** *com cálculo* (padrão) · *sem cálculo* → não aparece (ver estado vazio §6.16) · *dado de regime desatualizado* → faixa `stale.bg` discreta abaixo do número.

### 6.2 Barra da Divisão ⭐ (a assinatura)

**Anatomia:** barra horizontal segmentada (altura 16–20dp, `radius.sm`) + **legenda** abaixo (3 itens: bolinha de cor + ícone + rótulo + R$ + %). Ordem fixa **Lucro → Reserva → Custos**.

**Onde aparece e o que destaca:**

| Tela | Base 100% | Segmento-herói |
|---|---|---|
| Painel (resumo) | Faturamento/mês | mostra os 3 de relance |
| Resultado | Faturamento necessário | Lucro (é a meta) |
| Reserva (tool) | Pagamento recebido | **Reserva** (quanto guardar) + "Sobra" |
| Simulador | Valor do projeto | **Lucro real** + Custos do projeto |

**Estados:**
- *Normal:* 3 segmentos proporcionais + legenda completa.
- *Custo > meta (input incoerente):* a barra ainda desenha, com aviso `alerta` *"Seu custo é maior que sua meta — reveja"* (blueprint §5.9). Nunca trava.
- *Reserva = 0 (regime sem imposto/erro):* segmento de reserva some, legenda mostra "—".
- *Reduce motion:* sem animação de fill.

**Acessibilidade:** cada segmento tem rótulo + valor + % (cor nunca sozinha); o segmento **Custos** carrega hachura sutil para daltônicos; leitura por TalkBack agrupa "Lucro R$ 5.000, 50%. Reserva R$ 1.600, 16%. Custos R$ 850, 8%."

### 6.3 Botões dos tools recorrentes (os 2 grandes do Painel)

- **Dois cards-ação lado a lado:** *"Recebi um pagamento"* (`payments`) e *"Vou orçar um projeto"* (`request_quote`).
- **Estilo:** fundo `secondaryContainer` (azul calmo de confiança), texto `onSecondaryContainer`, ícone 28, `radius.lg`, altura ≥ 72dp, elevação 1.
- **Por quê:** são o motor de retenção (blueprint §5.5/§5.6) — grandes, na dobra, 1 toque. Azul reforça "confiável/seguro" sem competir com o verde do herói.

### 6.4 Botão Primário & Recalcular

- **Forma:** pill (`radius.full`), altura **56dp**, label `labelLarge` 16/600, ícone opcional 24.
- **Cores:** fill `primary` · texto/ícone `onPrimary` · elevação 2.
- **Estados:** normal · press (state layer 12% + scale 0.98) · disabled (`onSurface` 12% fill, `onSurface` 38% texto — ex.: "Continuar" com renda vazia).
- **Recalcular:** botão primário no Painel (refaz o fluxo). **Começar** (estado vazio) usa o mesmo estilo, largura generosa.

### 6.5 Campo de valor monetário

- **Anatomia:** rótulo curto acima · campo grande com prefixo `R$` · valor em `value.display` 40, `tnum` · linha de ajuda ⓘ abaixo (quando há).
- **Comportamento:** **teclado numérico nativo**; formatação de moeda ao vivo (separadores, centavos); seleção total ao focar; sem permitir letras.
- **Estados:** vazio (placeholder cinza + botão primário inativo) · preenchido · erro (borda `error` + microcopy humana abaixo, ícone `error`) · foco (borda `primary` 2dp).
- **Teclado tipo forno (opcional):** quando fizer sentido um keypad próprio (display `value.display`, teclas ≥ 64dp, `radius.md`, `surfaceContainerHigh`).

### 6.6 Stepper de progresso (fluxo guiado)

- **Anatomia:** *"Passo 2 de 5"* (`labelMedium`) + 5 pontos `●●○○○` (preenchidos = `primary`, vazios = `outlineVariant`) + seta voltar (`arrow_back`, alvo 48dp).
- **Por quê:** reduz a ansiedade do "quanto falta" (blueprint §10). Anima 1 ponto por passo (`motion.base`).

### 6.7 Card de pergunta (uma pergunta por tela)

- **Anatomia:** stepper (topo) · **pergunta-título** (`headlineSmall`, no máximo 2 linhas) · 1 campo OU 1 grupo de opções · **helper** (ⓘ `bodyMedium` `onSurfaceVariant`, ou ⚠ em `tertiaryContainer` quando ensina o erro comum) · ação secundária opcional (ex.: "estimar pra mim") · botão primário (rodapé fixo).
- **Regra:** **um campo e um botão por foco** (blueprint §9). Default sempre presente — ninguém trava.
- **Fundo:** `surface` (elevação 0, foco total); o helper de erro comum usa container `tertiaryContainer` para "puxar o olho" sem alarmar.

### 6.8 Chips de custo ("não esqueça")

- **Chip de lembrança:** fundo `tertiaryContainer` (âmbar calmo = "olha isto"), texto `onTertiaryContainer`, ícone de forma, `radius.full`, alvo 48dp. Toque = adiciona o custo à lista (abre campo de valor).
- **Custo já adicionado:** linha com ✓, nome, valor editável e remover (`close`).
- **Por quê:** os chips materializam o **custo invisível** — o que a calculadora rasa não faz (blueprint §5.2, §7.1).

### 6.9 Rádio de regime ("como você trabalha?")

- **Anatomia:** 4 opções, cada uma = rádio + título humano + subtítulo de 1 linha. Selecionada: container `secondaryContainer`, borda `primary`.
- **Opções (sem jargão):** *"Sou MEI"* (DAS fixo, imposto baixo) · *"Autônomo (CPF)"* (carnê-leão + INSS) · *"Tenho empresa no Simples"* (alíquota por faixa) · *"Não sei / cliente no exterior"* (reserva padrão 25–30%).
- **Modo avançado (Pro):** expande subcampos reais por regime — nunca obrigatório (blueprint §7.2).

### 6.10 Bloco de resultado (3 respostas)

- **Hierarquia:** Bloco 1 *COBRE POR HORA* (`value.hero`, `primary`) → Bloco 2 *DE CADA PAGAMENTO, RESERVE* (`value.xl`, `divisao.reserva`) → Bloco 3 *LUCRO REAL ESTIMADO* (`value.xl`, `divisao.lucro`). Equivalências em `bodyMedium`.
- **Acompanha:** barra da Divisão (§6.2), *"ver detalhamento ▾"*, *"salvar este perfil"*, **selo de estimativa** (§6.11).
- **Por quê:** valor-hora é a pergunta-mãe (herói); reserva e lucro fecham a confiança (blueprint §5.3).

### 6.11 Selo de "estimativa de planejamento" (onipresente, calmo)

- **Anatomia:** ícone ⓘ + texto curto *"Estimativa de planejamento — não é consultoria fiscal."* (`labelMedium`).
- **Cores:** `seal.bg` + `seal.fg`. **Jamais** vermelho ou âmbar — é informação calma, não aviso.
- **Onde:** toda tela que mostra número de imposto (Resultado, Reserva, Painel). Nunca some, nunca grita (blueprint §5.9, §16).

### 6.12 Aviso comparativo do simulador ("abaixo do alvo")

- **Anatomia:** faixa `alertaContainer` (âmbar calmo) + ícone `trending_down` + texto *"Abaixo do seu alvo (R$ 92/h). Cobre ~R$ 4.260 pra manter seu lucro."* + (opcional) botão *"Usar R$ 4.260"*.
- **Cores:** `alertaContainer` / `onAlertaContainer`. Âmbar = atenção, **não** erro (não é vermelho).
- **Por quê:** é o que diferencia de uma calculadora burra — o app **defende o usuário** e sugere o preço que corrige (blueprint §5.6, §10).

### 6.13 Linha de detalhamento ("como cheguei aqui")

- **Anatomia:** tabela linha a linha (`Renda + Custos + Provisão + Imposto = Faturamento ÷ Horas = Valor-hora`), valores `tnum` à direita, separadores `outlineVariant`, **cada item editável inline** (toque → campo → recalcula com count-up).
- **Por quê:** transparência da conta = confiança em app de dinheiro (blueprint §5.4, §8). Caixa-preta + dinheiro = desinstalação.

### 6.14 Helper "estimar pra mim" (horas faturáveis) — sheet

- **Anatomia:** *sheet* (`radius.2xl`) com 3 perguntas curtas, uma por vez (slider/stepper): semanas de férias/ano · % do tempo que é trabalho pago · feriados. Devolve *"~110 h/mês"* e volta pro campo preenchido.
- **Por quê:** resolve o conceito mais difícil e de maior alavanca do app (blueprint §7.1). É o "presets" do Fervura aqui.

### 6.15 Linha de Perfil (Pro)

- **Anatomia:** rádio + nome do perfil + valor-hora `tnum` à direita. Selecionado destaca. Topo: *"+ novo"*. Rodapé: nota *"Vários perfis é recurso Pro"*.
- **Fundo:** `surfaceContainer`, `radius.lg`.

### 6.16 Estado vazio (primeiro uso)

- **Anatomia:** título-fisga `headlineSmall` *"Você provavelmente cobra menos do que deveria."* · apoio *"Descubra seu valor-hora justo em 5 perguntas."* · 1 CTA *"Começar"* (primário, largo) · rodapé *"Leva 2 minutos · 100% offline"* (ícone `lock`).
- **Por quê:** o primeiro uso define a percepção; fisga a dor, promete pouco esforço, reforça privacidade. Um único CTA, sem ruído (blueprint §5.8).

### 6.17 Snackbar (com Desfazer)

- Fundo `inverseSurface`, texto `inverseOnSurface`, ação `inversePrimary`, `radius.sm`, 4–6s. Sempre em remover perfil / apagar dados.

### 6.18 Banner AdMob (rodapé do Painel)

- **Estilo:** container `ad.surface` (`surfaceContainerLow`), rótulo *"Publicidade"* `labelSmall` `ad.label`, separado por `space.4`, `radius.lg`.
- **Regra inviolável (§8):** só no rodapé do Painel quando há espaço. **Nunca** sobre um número de dinheiro, dentro do fluxo, nem nas telas de reserva/simulador no momento da resposta.

### 6.19 Tela Pro (compra única)

- **Anatomia:** lista de benefícios com ícone (vários perfis, exportar PDF, modo avançado, remover anúncios) · preço único · CTA primário · *"Restaurar compras"* (texto). Aparece no **gatilho de valor**, não como pop-up aleatório (blueprint §11).

### 6.20 Skeleton / restauração

- Raro (local-first). Se a leitura do perfil atrasar: blocos `surfaceVariant` com shimmer `motion.slow`. Caso contrário, instantâneo.

---

## 7. Acessibilidade (AA — não opcional, PADRÃO §3)

- **Contraste AA:** texto normal ≥ 4.5:1, texto grande/UI ≥ 3:1. Pares-chave verificados na §10 (tema escuro, que é o padrão, **e** claro).
- **Cor nunca sozinha:** a Divisão e todo estado têm forma + texto. Lucro/Reserva/Custos têm rótulo + R$ + %; Custos tem hachura; "abaixo do alvo" tem ícone `trending_down` + texto; sucesso ✓; estimativa ⓘ. Daltônicos (e a leitura à pressa) nunca dependem do verde×azul.
- **Alvos ≥ 48dp**; campos e botões do fluxo guiado generosos; um foco por vez.
- **Teclado numérico nativo** + formatação de moeda automática (evita erro de digitação, blueprint §9).
- **Text scaling** do SO até 130% sem quebrar; o número-herói tem prioridade de espaço, rótulos encolhem antes.
- **Semantics/TalkBack:** todo ícone-ação rotulado ("Recebi um pagamento", "Ver como cheguei"); valores lidos como dinheiro ("noventa e dois reais por hora"); a Divisão lida como conjunto Lucro/Reserva/Custos; ordem de leitura lógica (pergunta → campo → resultado).
- **Figuras tabulares** (`tnum`) em todo número — não treme ao digitar/animar.
- **Reduce motion:** *count-up* e *fill* viram estado estático; aviso usa borda/ícone, não animação.
- **Microcopy de erro humana:** *"Coloque um valor maior que zero pra eu calcular"*, nunca *"input inválido"*.

---

## 8. UI de monetização (traduz blueprint §11 em DS)

> **Princípio inviolável:** anúncio **jamais** compete com ver o número, reservar ou decidir o preço (blueprint §11, §16).

- **Onde NÃO:** sobre o resultado, dentro do fluxo de cálculo, nas telas de reserva/simulador no momento da resposta. Anúncio cobrindo um número de dinheiro = quebra de confiança = desinstalação.
- **Banner permitido:** rodapé do Painel **só quando há espaço** (sem empurrar conteúdo). Estilo discreto (§6.18): `ad.surface`, rótulo "Publicidade" `labelSmall` `ad.label`, separado por `space.4`, `radius.lg`.
- **Intersticial:** só em **momento calmo** — ex.: ao voltar pro Painel depois de fechar um resultado — com *frequency capping*. Nunca durante a digitação.
- **Gatilhos de Pro (no momento de valor, não de aflição):** ao tocar *"exportar PDF"*, ao criar um 2º perfil, ou ao abrir *"modo avançado"*. A oferta aparece **onde o recurso seria usado**. O **PDF de orçamento** é a âncora mais forte (cara de ferramenta de trabalho).
- **Remover anúncios:** entitlement `ad_free` (RevenueCat, PADRÃO §5). Quando comprado, **todo** container de anúncio some. Botão *"Restaurar compras"* em Configurações.

---

## 9. Handoff para o Agente 4 — de-para de tokens (Flutter)

### 9.1 Convenção de nomes (idêntica nos dois lados)

`color.<role>` · `color.divisao.<parte>` · `type.<token>` · `space.<n>` · `radius.<t>` · `elevation.<n>` · `motion.<token>`. Manter exatamente estes nomes no Claude Design e no `core/theme`.

### 9.2 `ColorScheme` Escuro (padrão — trecho)

```dart
const quantoCobroDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF6FDEB5),      onPrimary: Color(0xFF003828),
  primaryContainer: Color(0xFF00513C), onPrimaryContainer: Color(0xFF93FBD0),
  secondary: Color(0xFFB8C4FF),    onSecondary: Color(0xFF002B75),
  secondaryContainer: Color(0xFF0B409F), onSecondaryContainer: Color(0xFFDCE1FF),
  tertiary: Color(0xFFFBBE48),     onTertiary: Color(0xFF402D00),
  tertiaryContainer: Color(0xFF5C4200), onTertiaryContainer: Color(0xFFFFDEAD),
  error: Color(0xFFFFB4AB),        onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A), onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF0F1513),      onSurface: Color(0xFFDFE4DE),
  surfaceContainerHighest: Color(0xFF2F3633),
  onSurfaceVariant: Color(0xFFC0C9C0), outline: Color(0xFF8A938B),
  outlineVariant: Color(0xFF404943), inverseSurface: Color(0xFFDFE4DE),
  onInverseSurface: Color(0xFF2B312E), inversePrimary: Color(0xFF006C50),
  scrim: Color(0xFF000000), shadow: Color(0xFF000000),
);
```

> O `ColorScheme` Claro usa a tabela §3.2 (primary `#006C50`, surface `#F5FBF4`, etc.). `ThemeMode.dark` é o default; respeitar `ThemeMode.system` quando o usuário escolher.

### 9.3 `ThemeExtension` para a Divisão

```dart
@immutable
class QuantoCobroColors extends ThemeExtension<QuantoCobroColors> {
  final Color divisaoLucro, divisaoReserva, divisaoCusto, divisaoTrack;
  final Color alerta, alertaContainer, onAlertaContainer;
  final Color sealBg, sealFg, staleBg, staleFg, adSurface, adLabel, brand4yu;
  const QuantoCobroColors({ /* ... */ });
  // dark:  divisaoLucro 0xFF6FDEB5, divisaoReserva 0xFFB8C4FF, divisaoCusto 0xFFA4ADA5,
  //        divisaoTrack 0xFF2F3633, alerta 0xFFFBBE48, alertaContainer 0xFF5C4200,
  //        sealBg 0xFF252B28, sealFg 0xFFC0C9C0, brand4yu 0xFF6C4BD6 ...
  // light: divisaoLucro 0xFF006C50, divisaoReserva 0xFF2C57B8, divisaoCusto 0xFF586259,
  //        divisaoTrack 0xFFDCE5DB, alerta 0xFF7C5800, alertaContainer 0xFFFFDEAD,
  //        sealBg 0xFFE4EAE2, sealFg 0xFF404943 ...
  @override QuantoCobroColors copyWith(...) => ...;
  @override QuantoCobroColors lerp(...) => ...;
}
```

### 9.4 Tipografia / espaço / raio

`TextTheme` via Inter (Material 3) + estilos custom de número (Sora) numa extension `QuantoCobroType` (`value.hero`…`value.keypadKey`). Espaço e raio como `const` em `core/theme/tokens.dart`. Fontes **empacotadas** em `assets/fonts` e declaradas no `pubspec.yaml`. `tnum` ligado em tudo que é número.

### 9.5 Brief de logo para o Agente 4

Conceito, construção e SVG na §11 — entregar junto com o protótipo aprovado e esta tabela de tokens.

---

## 10. Verificação de contraste (pares-chave)

Ratios calculados (WCAG 2.x relative luminance). "Grande/UI" = usado só em número-herói/segmento/label grande (≥ 24sp).

| Par | Tema | Aprox. | AA |
|---|---|---|---|
| onSurface `#DFE4DE` / surface `#0F1513` | Escuro | ~14.8:1 | ✓ texto normal |
| onSurfaceVariant `#C0C9C0` / surface | Escuro | ~10.7:1 | ✓ |
| primary `#6FDEB5` (número-herói) / surface | Escuro | ~12:1 | ✓ |
| onPrimary `#003828` / primary `#6FDEB5` (botão) | Escuro | ~9.6:1 | ✓ |
| secondary `#B8C4FF` / surface | Escuro | ~10:1 | ✓ |
| tertiary `#FBBE48` / surface | Escuro | ~12:1 | ✓ |
| divisao.reserva `#B8C4FF` / surfaceContainer `#1B211E` | Escuro | ~9.7:1 | ✓ (grande) |
| divisao.custo `#A4ADA5` / surfaceContainer | Escuro | ~6.8:1 | ✓ (grande) |
| onSecondaryContainer `#DCE1FF` / secondaryContainer `#0B409F` | Escuro | ~7.4:1 | ✓ |
| onSurface `#171D1A` / surface `#F5FBF4` | Claro | ~16:1 | ✓ texto normal |
| primary `#006C50` (texto) / surface `#F5FBF4` | Claro | ~6.1:1 | ✓ texto normal |
| onPrimary `#FFFFFF` / primary `#006C50` (botão) | Claro | ~6.5:1 | ✓ |
| secondary `#2C57B8` / surface | Claro | ~6.2:1 | ✓ |
| tertiary `#7C5800` (texto âmbar) / surface | Claro | ~6.0:1 | ✓ |
| error `#BA1A1A` / surface | Claro | ~6.0:1 | ✓ |
| divisao.custo `#586259` / surfaceContainer `#E9F0E8` | Claro | ~5.4:1 | ✓ |

> Ratios calculados sobre os hexes deste DS. O Agente 4 deve re-verificar com as cores renderizadas (elevação/overlay do M3 alteram levemente as superfícies escuras). Texto normal usa sempre tinta neutra (`onSurface`/`onSurfaceVariant`), nunca uma cor da Divisão.

---

## 11. Logo & ícone do app

### 11.1 Conceito

**"A Moeda Dividida"** — a leitura mais direta da assinatura "A Divisão": um anel/moeda **repartido em três arcos** (Lucro verde · Reserva azul · Custos neutro). É o produto em um símbolo: *"para onde vai cada real"*. O vão central do anel forma um **"?"** — o nome é uma pergunta. Silhueta simples, reconhecível em 48px.

### 11.2 Construção

- Fundo: rounded-square (raio 22%) com gradiente **Verde-Justo** (`#1FA67F` → `#00513C`, vertical).
- Anel: três arcos de ~118° cada, com pequeno gap entre eles — Lucro `#93FBD0`, Reserva `#B8C4FF`, Custos `#DFE4DE` (tons claros para contraste sobre o verde).
- "?": ponto e haste do "?" em branco quente (`#F5FBF4`) ocupando o vão central.
- Safe area: 12% de margem; testar em mono (notificação) e mascarado (Android adaptive icon).

### 11.3 SVG conceito (ponto de partida — original)

```svg
<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Ícone Quanto eu Cobro?">
  <defs>
    <linearGradient id="justo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1FA67F"/>
      <stop offset="1" stop-color="#00513C"/>
    </linearGradient>
  </defs>
  <rect width="1024" height="1024" rx="232" fill="url(#justo)"/>
  <!-- anel dividido em 3 arcos (Lucro / Reserva / Custos) -->
  <g fill="none" stroke-width="86" stroke-linecap="round">
    <circle cx="512" cy="470" r="250" stroke="#93FBD0" stroke-dasharray="448 1123" transform="rotate(-88 512 470)"/>
    <circle cx="512" cy="470" r="250" stroke="#B8C4FF" stroke-dasharray="448 1123" transform="rotate(32 512 470)"/>
    <circle cx="512" cy="470" r="250" stroke="#DFE4DE" stroke-dasharray="448 1123" transform="rotate(152 512 470)"/>
  </g>
  <!-- "?" no vão central -->
  <g fill="#F5FBF4">
    <path d="M512 360 a92 92 0 0 1 92 92 c0 64 -64 76 -76 116 h-44 c8 -64 76 -72 76 -116 a48 48 0 0 0 -96 0 h-44 a92 92 0 0 1 92 -92 Z"/>
    <circle cx="512" cy="600" r="30"/>
  </g>
</svg>
```

### 11.4 Wordmark e assinatura 4YU

- **Wordmark:** "Quanto eu Cobro**?**" em Sora 800, tracking −2%; o **"?"** em Verde-Justo (`#0E8C6B` no claro, `#6FDEB5` no escuro), o resto em tinta neutra. Versão curta "Quanto Cobro?" para o header do app.
- **Assinatura mãe (PADRÃO §3):** selo discreto **"by 4YU"** em Roxo `#6C4BD6` — só na tela **Sobre**, página do dev na loja e marketing. **Nunca** na UI funcional.

---

## 12. Decisões em aberto resolvidas (do blueprint §14 → Agente 3)

| Pergunta do A2 | Decisão do A3 |
|---|---|
| **Custos sugeridos (chips de lembrança)** | **11 chips**, com ícone (§5.5): Contador · Coworking · Cursos/capacitação · Energia · Internet/telefone · Equipamento (rateio) · Pró-labore · Plano de saúde · Software/ferramentas · Marketing/anúncios · Transporte. Os 3 primeiros aparecem em destaque; o resto via "+ mais". |
| **As 3 perguntas do helper de horas** | (1) *"Quantas semanas de férias/folga você tira por ano?"* (default 4) · (2) *"De cada semana, quanto é trabalho PAGO?"* (chips: ~50% / ~65% / ~80%; default 65%) · (3) *"Conta os feriados?"* (sim/não; ~12/ano). **Fórmula default:** `(52 − férias) × horas/semana × %pago − feriados` → arredonda. Base de referência ~**1.300 h/ano (~110 h/mês)**. |
| **Renda: mês × ano** | **Pedir mensal** (modelo mental mais intuitivo) e converter para anual nos bastidores. |
| **Percentuais base por regime** | Estrutura abaixo — **placeholders ilustrativos**. ⚠️ **Validar nas fontes oficiais da Receita antes de publicar** e revisar ~1×/ano (blueprint §7.2, §14). |

**Estrutura de percentuais por regime (ILUSTRATIVO — validar na Receita):**

| Regime | Como o app trata | Base ilustrativa (NÃO publicar sem validar) |
|---|---|---|
| **MEI** | DAS fixo mensal (impacto quase fixo) + alerta de teto de faturamento | DAS ~R$ 75–81/mês conforme atividade (ano da tabela) |
| **Autônomo (CPF)** | Carnê-leão (IRPF progressivo) + INSS | IRPF por faixa progressiva; INSS 11% ou 20% |
| **Simples Nacional** | % efetivo por faixa/anexo (serviços) | Anexo III começa ~6% efetivo e sobe por faixa |
| **Não sei / internacional** | Regra-padrão de reserva | **25–30%** (default 27%) |

> Toda exibição desses números carrega o **selo de estimativa** (§6.11) e o estado "tabela desatualizada" (§2.4) quando o ano da base for anterior ao corrente. A copy **nunca** afirma valor devido — diz *"estime reservar ~X%"*.

---

## 13. Prompt do Claude Design (copia-e-cola)

> Cole no Claude Design para gerar o protótipo hi-fi web (= especificação). Ele aplica este DS às telas do Agente 2 e exporta o *handoff bundle* (.zip).

```
Crie um protótipo hi-fi (web, React/HTML) do app QUANTO EU COBRO? — calculadora
financeira do freelancer brasileiro: valor-hora justo, reserva de imposto e lucro real.
Mobile-first (retrato 390×844). Gere TEMA ESCURO (padrão) e TEMA CLARO, ambos completos.

PERSONALIDADE: "sócio que entende de número" — calmo, honesto, humano, nada de banco frio
nem cara de imposto de renda. O NÚMERO é o herói (gigante, tabular). Mostra imposto sem
assustar.

IDEIA-ASSINATURA "A DIVISÃO": todo valor aparece repartido numa barra com legenda FIXA,
mesma ordem e cores em todas as telas — Lucro (é seu) → Reserva (imposto, guardado) →
Custos. O usuário aprende a ler o dinheiro uma vez.

USE EXATAMENTE ESTES TOKENS (mesmos nomes nos dois temas):
- color.primary (escuro #6FDEB5 / claro #006C50), onPrimary, primaryContainer, etc.
  (use as tabelas de roles dos itens 3.1 e 3.2 do Design System).
- Superfícies neutras calmas: escuro surface #0F1513 / onSurface #DFE4DE;
  claro surface #F5FBF4 / onSurface #171D1A.
- A DIVISÃO (cores fixas por significado, com rótulo + R$ + % SEMPRE, nunca só cor):
  divisao.lucro (verde #6FDEB5/#006C50) · divisao.reserva (azul #B8C4FF/#2C57B8) ·
  divisao.custo (neutro #A4ADA5/#586259, com hachura sutil). Trilho #2F3633/#DCE5DB.
- Reserva = AZUL (guardado/seguro), NUNCA vermelho ou amarelo. Imposto não é perigo.
- Aviso "abaixo do alvo" = ÂMBAR calmo (alertaContainer #5C4200/#FFDEAD) + ícone
  trending_down + texto. Erro real = carmim. São cores diferentes, de propósito.
- Selo "estimativa de planejamento" = seal.bg/seal.fg (cinza calmo), com ícone ⓘ,
  presente em TODA tela com número de imposto. Nunca vermelho, nunca alarmante.
- Tipografia: números em Sora 700 (tabular); UI em Inter. value.hero = 72sp.
- radius.lg 20 nos cards (card-herói = xl 24); botão primário em pill. space base 4dp (tela=16).

GERE ESTAS TELAS (do blueprint do Agente 2), CADA UMA com estados vazio/erro quando existir:
1. Painel (com cálculo): card-herói "SEU VALOR-HORA R$ 92/hora" + barra da Divisão de relance,
   2 botões grandes "Recebi um pagamento" e "Vou orçar um projeto", resumo reserva % + lucro,
   "ver como cheguei", Recalcular. Banner "Publicidade" discreto no rodapé (NUNCA sobre número).
2. Painel — estado vazio: "Você provavelmente cobra menos do que deveria." + "Começar" +
   "Leva 2 minutos · 100% offline".
3. Calculadora guiada (5 passos, UMA pergunta por tela, stepper ●●○○○, default em cada):
   P1 Renda desejada (mensal, no bolso) · P2 Horas faturáveis (+ aviso "não são 160h" +
   "estimar pra mim") · P3 Custos (chips de lembrança: Contador/Coworking/Cursos/Energia…) ·
   P4 "Como você recebe hoje?" (MEI / Autônomo CPF / Simples / Não sei-internacional) ·
   P5 Férias e 13º (opcional).
4. Resultado: 3 blocos hierarquizados (COBRE POR HORA herói → RESERVE → LUCRO REAL) +
   barra da Divisão preenchendo (animada) + "ver detalhamento" + "salvar perfil" + selo.
5. Detalhamento "como cheguei": tabela linha a linha, cada item editável inline.
6. Reserva (tool): 1 campo "Quanto você recebeu?" → herói "RESERVE R$ 320 (16%)" +
   "Sobra: R$ 1.680" + barra da Divisão com Reserva em destaque + regime herdado do perfil.
7. Simulador (tool): valor + horas + custos do projeto → "LUCRO REAL" herói + "valor-hora
   efetivo" + AVISO ÂMBAR "abaixo do seu alvo (R$ 92/h), cobre ~R$ 4.260" quando aplicável.
8. Perfis (Pro): lista de perfis com valor-hora; nota "recurso Pro".
9. Configurações: moeda, modo BR/internacional, ano das tabelas, apagar dados (confirmação
   dupla), restaurar compras, Sobre (selo "by 4YU").
10. Tela Pro (compra única): vários perfis, exportar PDF, modo avançado, remover anúncios.
11. Helper "estimar pra mim" (sheet): 3 perguntas curtas → devolve "~110 h/mês".

ACESSIBILIDADE: contraste AA; alvos ≥48dp; teclado numérico nos campos de R$; cor nunca é o
único sinal (rótulos + ícones + % na Divisão; hachura no segmento de Custos); figuras
tabulares nos números.

MONETIZAÇÃO: banner discreto "Publicidade" só no rodapé do Painel quando há espaço —
NUNCA sobre um número de dinheiro, no fluxo de cálculo, ou nas telas de reserva/simulador.

ENTREGA: empacote o handoff bundle (.zip) com as CSS variables/tokens nomeados como acima,
para conversão direta ao core/theme do Flutter.
```

---

## 14. Checklist de revisão do protótipo (Agente 3)

**Fidelidade ao fluxo (A2)**
- [ ] Todas as 11 telas presentes; navegação hub-and-spoke centrada no Painel.
- [ ] Caminho de ouro recorrente (Painel → tool em 1–2 toques) visível.
- [ ] Uma pergunta por tela no fluxo guiado, com stepper e defaults.
- [ ] Resultado preserva a hierarquia das 3 respostas (valor-hora primeiro).

**A Divisão & estados**
- [ ] A barra da Divisão aparece no Painel, Resultado, Reserva e Simulador, com legenda fixa (Lucro→Reserva→Custos) e R$ + %.
- [ ] Reserva é AZUL (nunca vermelho/amarelo); âmbar só para "abaixo do alvo".
- [ ] Selo de estimativa presente em toda tela com imposto, calmo (nunca vermelho).
- [ ] Vazio / loading / erro cobertos onde o A2 mapeou (§5.9 do blueprint); input incoerente devolve resultado + alerta, nunca trava.

**Tokens & temas**
- [ ] Zero valor fora de token (sem hex solto).
- [ ] Escuro (padrão) e claro completos e com paridade.

**Tipografia & legibilidade**
- [ ] Número é o maior elemento de cada tela; Sora tabular.
- [ ] Moeda formatada (R$, separadores); nada "dança" ao digitar.

**Acessibilidade**
- [ ] Contraste AA nos pares-chave (§10).
- [ ] Alvos ≥48dp; teclado numérico; cor nunca sozinha (rótulo+ícone+%).
- [ ] Semantics/labels nos ícones-ação; reduce-motion previsto.

**Marca & anti-clone**
- [ ] Tem cara de "ferramenta financeira de confiança, humana" (não fintech genérica nem planilha de imposto).
- [ ] Roxo 4YU só como assinatura (não na UI funcional).
- [ ] Anúncio nunca compete com um número de dinheiro.

**Handoff**
- [ ] .zip com tokens nomeados (de-para pronto p/ `core/theme`).
- [ ] Brief de logo + tabela de tokens anexados para o Agente 4.

---

## 15. Resumo do handoff → Agente 4 (Arquiteto Flutter)

Entregar em conjunto: **(1)** protótipo aprovado no Claude Design (.zip); **(2)** esta **tabela de tokens** (cores escuro/claro §3 + customizados §3.3 + de-para Dart §9); **(3)** **Design System** completo (este arquivo); **(4)** **brief de logo** + SVG (§11). Preservar sempre: número-herói, hierarquia das 3 respostas, **A Divisão** com legenda fixa, selo de estimativa calmo e onipresente, e a regra de ouro do anúncio. ⚠️ Lembrar o Agente 4: **validar os percentuais tributários na Receita antes de publicar** (§12).

---

*Design System "A Divisão" — Quanto eu Cobro? · Agente 3 (Marca & Design System). Segue PADRÃO-4YU-APPS §3 e §7. Tema padrão Escuro (claro com paridade). Criado em 01/06/2026.*
