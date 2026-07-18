# GUIA DE APLICAÇÃO DE COR — "Quanto Cobro?"

> **Escopo:** este é o guia de **aplicação e validação** da paleta que já está
> fechada no Design System §2/§3 e implementada em `lib/core/theme/`. Não inventa
> cor nova. Ele diz **onde cada token entra em cada superfície**, prova o
> contraste dos pares que de fato aparecem nas telas, e traduz as regras
> cromáticas do DS em "faça/não faça" para quem for codar a UI.
>
> **Fonte da verdade dos valores:** `color_scheme.dart` (roles M3),
> `divisao_colors.dart` (`ThemeExtension` da Divisão + selos/anúncio/4YU),
> `app_colors.dart` (sementes de marca). Se algum hex aqui divergir do código,
> **o código vence** — me atualize.
>
> **Tema padrão:** Escuro. Claro tem paridade total. Onde o comportamento muda
> entre temas (profundidade), está marcado.

---

## 0. Como ler este guia (mapa dos tokens)

Três origens de cor no app — nunca misture os canais:

| Origem | Como acessar no Flutter | Papel |
|---|---|---|
| **Roles M3** | `Theme.of(context).colorScheme.X` | Superfícies, texto neutro, ações padrão, erro. |
| **A Divisão + custom** | `Theme.of(context).extension<DivisaoColors>()!.Y` | Segmentos da barra, alerta, selo, "stale", anúncio, selo 4YU. |
| **Sementes de marca** | `BrandColors.Z` (`app_colors.dart`) | **Só referência/geração.** Não pinte UI direto com a semente — use o role derivado. |

Regra de disciplina: **texto e número neutro sempre vêm de `onSurface` /
`onSurfaceVariant`**; cor de significado (verde/azul/âmbar) só entra em número-herói,
segmento da Divisão, chip, aviso ou selo — nunca no corpo de texto corrido.

---

## 1. Guia de aplicação por superfície

Para cada contexto: o token exato, no Escuro (padrão) e no Claro, e a cor do
conteúdo (texto/número) que vai por cima.

### 1.1 Superfícies estruturais

| Contexto | Token de fundo | Escuro | Claro | Conteúdo por cima |
|---|---|---|---|---|
| **Fundo de tela** (scaffold) | `colorScheme.surface` | `#0F1513` | `#F5FBF4` | `onSurface` / `onSurfaceVariant` |
| **Fluxo guiado** (foco no campo) | `colorScheme.surface` (elev. 0) | `#0F1513` | `#F5FBF4` | idem |
| **Card de tool / pergunta** | `colorScheme.surfaceContainer` | `#1B211E` | `#E9F0E8` | `onSurface` |
| **Card-herói do valor-hora** | `colorScheme.surfaceContainerHigh` | `#252B28` | `#E4EAE2` | rótulo `onSurfaceVariant` + número `primary` |
| **Linha de perfil (Pro)** | `colorScheme.surfaceContainer` | `#1B211E` | `#E9F0E8` | `onSurface` |
| **Keypad / campo em foco** | `colorScheme.surfaceContainerHigh` | `#252B28` | `#E4EAE2` | `value.display` em `onSurface` |
| **Sheet (helper de horas, Pro)** | `colorScheme.surfaceContainerHigh`→`Highest` | `#252B28`/`#2F3633` | `#E4EAE2`/`#DFE4DE` | `onSurface` |
| **Diálogo (confirmação destrutiva)** | `colorScheme.surfaceContainerHigh` | `#252B28` | `#E4EAE2` | `onSurface`; ação destrutiva em `error` |

> **Por que o herói usa `surfaceContainerHigh` e não `surface`:** no Escuro a
> hierarquia vem do **tom de superfície**, não de sombra (§5.3). Elevar o card do
> herói meio degrau acima do fundo é o que o "levanta" sem sujar com sombra. No
> Claro, o mesmo degrau + um `outlineVariant` sutil dá o mesmo efeito (ver §3).

### 1.2 O número-herói e os 3 blocos de resultado

| Contexto | Cor do número | Token | Escuro | Claro |
|---|---|---|---|---|
| **Valor-hora (herói)** | verde | `colorScheme.primary` | `#6FDEB5` | `#006C50` |
| Bloco "RESERVE" | azul | `DivisaoColors.reserva` | `#B8C4FF` | `#2C57B8` |
| Bloco "LUCRO REAL" | verde | `DivisaoColors.lucro` | `#6FDEB5` | `#006C50` |
| Rótulo dos blocos ("COBRE POR HORA") | neutro | `colorScheme.onSurfaceVariant` | `#C0C9C0` | `#404943` |
| Linha de contexto ("pra ganhar R$ 5.000/mês") | neutro | `colorScheme.onSurfaceVariant` | `#C0C9C0` | `#404943` |
| Equivalências ("≈ R$ 736/dia") | neutro | `colorScheme.onSurfaceVariant` | `#C0C9C0` | `#404943` |

> `DivisaoColors.lucro` == `colorScheme.primary` por valor nos dois temas — use
> **`primary`** para o valor-hora (é a ação/identidade) e **`DivisaoColors.lucro`**
> quando o número for explicitamente "o pedaço Lucro da Divisão" (bloco de
> resultado, legenda). Mesmo pixel, intenção diferente — mantém o código legível.

### 1.3 Botões e ações

| Contexto | Fundo | Texto/ícone | Escuro (fundo/texto) | Claro (fundo/texto) |
|---|---|---|---|---|
| **Botão primário / Recalcular / Começar** (pill) | `colorScheme.primary` | `colorScheme.onPrimary` | `#6FDEB5` / `#003828` | `#006C50` / `#FFFFFF` |
| **Cards-ação dos tools** ("Recebi um pagamento", "Vou orçar") | `colorScheme.secondaryContainer` | `colorScheme.onSecondaryContainer` | `#0B409F` / `#DCE1FF` | `#DCE1FF` / `#00174B` |
| **Botão secundário / texto** ("ver como cheguei") | transparente | `colorScheme.primary` | `#6FDEB5` | `#006C50` |
| **Botão desabilitado** | `onSurface` @12% | `onSurface` @38% | — | — |
| **Rádio de regime selecionado** | `colorScheme.secondaryContainer` + borda `primary` | `onSecondaryContainer` | `#0B409F` / `#DCE1FF` | `#DCE1FF` / `#00174B` |

> **Nota tonal Escuro:** os cards-ação usam `secondaryContainer = #0B409F`, um
> azul **cheio e escuro** (não um container claro como no M3 clássico). É
> intencional — no tema escuro esse azul "confiança" fica sólido e o texto
> `#DCE1FF` por cima passa AA folgado (7.2:1). Só não use texto neutro escuro
> sobre ele.

### 1.4 A barra da Divisão

| Elemento | Token | Escuro | Claro |
|---|---|---|---|
| Segmento **Lucro** | `DivisaoColors.lucro` | `#6FDEB5` | `#006C50` |
| Segmento **Reserva** | `DivisaoColors.reserva` | `#B8C4FF` | `#2C57B8` |
| Segmento **Custos** | `DivisaoColors.custo` (+ **hachura**) | `#A4ADA5` | `#586259` |
| Trilho vazio | `DivisaoColors.track` | `#2F3633` | `#DCE5DB` |
| Legenda: rótulo + R$ + % | `colorScheme.onSurface` (número) / `onSurfaceVariant` (rótulo) | `#DFE4DE` / `#C0C9C0` | `#171D1A` / `#404943` |
| Bolinha de cor da legenda | o token do segmento correspondente | — | — |

> **Descoberta crítica de contraste (ver §2.4):** os três segmentos têm
> **luminância quase idêntica** entre si (1.0–1.4:1 no Escuro, ~1.0:1 no Claro).
> Ou seja: **encostados na barra, um daltônico — e mesmo um olho apressado — não
> separa Lucro de Reserva de Custos por cor.** Por isso rótulo + % + ordem fixa +
> hachura em Custos **não são enfeite de acessibilidade: são o único sinal
> confiável.** Nunca renderize a barra sem eles.

### 1.5 Selos, faixas e estados informativos

| Contexto | Fundo | Texto/ícone | Escuro (fundo/texto) | Claro (fundo/texto) |
|---|---|---|---|---|
| **Selo de estimativa** (ⓘ, onipresente) | `DivisaoColors.sealBg` | `DivisaoColors.sealFg` | `#252B28` / `#C0C9C0` | `#E4EAE2` / `#404943` |
| **Faixa "valores base de 2025"** (ano defasado) | `DivisaoColors.staleBg` | `DivisaoColors.staleFg` | `#0B409F` / `#DCE1FF` | `#DCE1FF` / `#00174B` |
| **Aviso "abaixo do alvo"** (simulador) | `DivisaoColors.alertaContainer` | `DivisaoColors.onAlertaContainer` | `#5C4200` / `#FFDEAD` | `#FFDEAD` / `#261900` |
| **Ícone/texto de atenção âmbar solto** (sobre surface) | — | `DivisaoColors.alerta` | `#FBBE48` | `#7C5800` |
| **Chip de custo "não esqueça"** | `colorScheme.tertiaryContainer` | `colorScheme.onTertiaryContainer` | `#5C4200` / `#FFDEAD` | `#FFDEAD` / `#261900` |
| **Selo "by 4YU"** (só tela Sobre) | fundo neutro | `DivisaoColors.brand4yu` | `#6C4BD6` | `#6C4BD6` |

> **`stale` e `alertaContainer` são deliberadamente cores diferentes.** "Ano
> defasado" é **azul** (informação, não erro — não é culpa do usuário nem perigo).
> "Abaixo do alvo" é **âmbar** (atenção acionável). Nunca troque um pelo outro:
> pintar "ano defasado" de âmbar sugere que o dado está *errado*; pintar "abaixo
> do alvo" de azul apaga o senso de "olha isto".

### 1.6 Anúncio

| Contexto | Fundo | Rótulo | Escuro | Claro |
|---|---|---|---|---|
| **Banner AdMob** (só rodapé do Painel) | `DivisaoColors.adSurface` | "Publicidade" `labelSmall` em `DivisaoColors.adLabel` | `#171D1A` / `#C0C9C0` | `#EFF5ED` / `#404943` |

> `adSurface` == `surfaceContainerLow` — é a superfície **mais discreta** possível
> sem sumir. O anúncio nunca ganha um container elevado ou colorido: ele recua,
> nunca compete. E **nunca** entra sobre um número (ver §4).

### 1.7 Erros reais

| Contexto | Token | Escuro | Claro |
|---|---|---|---|
| Borda de campo em erro / texto de erro | `colorScheme.error` | `#FFB4AB` | `#BA1A1A` |
| Container de erro (se usado) | `colorScheme.errorContainer` / `onErrorContainer` | `#93000A` / `#FFDAD6` | `#FFDAD6` / `#410002` |
| Ação destrutiva (apagar dados) | `colorScheme.error` | `#FFB4AB` | `#BA1A1A` |

> Erro é **carmim**, mais frio que o âmbar, de propósito (§2.1). Reforce sempre
> com ícone `error` + microcopy humana — cor sozinha nunca (§4).

---

## 2. Validação de contraste WCAG AA

Método: WCAG 2.x relative luminance, calculado sobre os hexes reais do
`core/theme`. Limiar AA: **texto normal ≥ 4.5:1**, **texto grande (≥ 24sp/18.66px
bold ou ≥ 18.66sp/24px) e componentes de UI ≥ 3:1**. Número-herói e valores são
sempre "grande". Segmentos de barra e bordas são "componente de UI (não-texto)".

### 2.1 Tema Escuro (padrão) — pares que aparecem nas telas

| # | Par (frente / fundo) | Ratio | Limiar | Veredito |
|---|---|---|---|---|
| 1 | número-herói `primary #6FDEB5` / card `surfaceContainerHigh #252B28` | **8.79:1** | 3:1 (grande) | ✓ passa até como texto normal |
| 2 | número-herói `primary` / `surface #0F1513` | **11.25:1** | 3:1 | ✓ |
| 3 | `onSurface #DFE4DE` / `surfaceContainerHigh #252B28` | **11.20:1** | 4.5:1 | ✓ |
| 4 | rótulo `onSurfaceVariant #C0C9C0` / `surfaceContainerHigh` | **8.49:1** | 4.5:1 | ✓ |
| 5 | `onSurfaceVariant #C0C9C0` / `surface #0F1513` | **10.87:1** | 4.5:1 | ✓ |
| 6 | valor "RESERVE" `reserva #B8C4FF` / `surfaceContainerHigh` | **8.51:1** | 3:1 (grande) | ✓ |
| 7 | valor "LUCRO" `lucro #6FDEB5` / `surfaceContainerHigh` | **8.79:1** | 3:1 | ✓ |
| 8 | legenda/segmento `custo #A4ADA5` / `surfaceContainer #1B211E` | **7.09:1** | 3:1 | ✓ |
| 9 | texto tool `onSecondaryContainer #DCE1FF` / `secondaryContainer #0B409F` | **7.23:1** | 4.5:1 | ✓ |
| 10 | texto botão `onPrimary #003828` / `primary #6FDEB5` | **8.01:1** | 4.5:1 | ✓ |
| 11 | selo `sealFg #C0C9C0` / `sealBg #252B28` | **8.49:1** | 4.5:1 | ✓ |
| 12 | faixa stale `staleFg #DCE1FF` / `staleBg #0B409F` | **7.23:1** | 4.5:1 | ✓ |
| 13 | aviso `onAlertaContainer #FFDEAD` / `alertaContainer #5C4200` | **7.30:1** | 4.5:1 | ✓ |
| 14 | chip `onTertiaryContainer #FFDEAD` / `tertiaryContainer #5C4200` | **7.30:1** | 4.5:1 | ✓ |
| 15 | `alerta #FBBE48` (ícone/texto) / `surface #0F1513` | **11.05:1** | 4.5:1 | ✓ |
| 16 | rótulo anúncio `adLabel #C0C9C0` / `adSurface #171D1A` | **10.07:1** | 4.5:1 | ✓ |
| 17 | `error #FFB4AB` / `surface #0F1513` | **10.88:1** | 4.5:1 | ✓ |
| 18 | link `primary #6FDEB5` / `surfaceContainerHigh` | **8.79:1** | 4.5:1 | ✓ |
| 19 | stepper/borda `outline #8A938B` / `surface` | **5.83:1** | 3:1 (UI) | ✓ |
| 20 | snackbar `inverseOnSurface #2B312E` / `inverseSurface #DFE4DE` | **10.30:1** | 4.5:1 | ✓ |

Segmentos da barra contra o trilho (não-texto, ≥3:1): Lucro/track **7.54:1**,
Reserva/track **7.30:1**, Custos/track **5.36:1** — todos ✓.

### 2.2 Tema Claro — pares que aparecem nas telas

| # | Par (frente / fundo) | Ratio | Limiar | Veredito |
|---|---|---|---|---|
| 1 | número-herói `primary #006C50` / card `surfaceContainerHigh #E4EAE2` | **5.26:1** | 3:1 (grande) | ✓ passa até como texto normal |
| 2 | número-herói `primary` / `surface #F5FBF4` | **6.13:1** | 3:1 | ✓ |
| 3 | `onSurface #171D1A` / `surfaceContainerHigh #E4EAE2` | **13.99:1** | 4.5:1 | ✓ |
| 4 | rótulo `onSurfaceVariant #404943` / `surfaceContainerHigh` | **7.62:1** | 4.5:1 | ✓ |
| 5 | valor "RESERVE" `reserva #2C57B8` / `surfaceContainerHigh` | **5.43:1** | 3:1 (grande) | ✓ (também passa normal) |
| 6 | valor "LUCRO" `lucro #006C50` / `surfaceContainerHigh` | **5.26:1** | 3:1 | ✓ |
| 7 | segmento `custo #586259` / `surfaceContainer #E9F0E8` | **5.47:1** | 3:1 | ✓ |
| 8 | texto tool `onSecondaryContainer #00174B` / `secondaryContainer #DCE1FF` | **13.28:1** | 4.5:1 | ✓ |
| 9 | texto botão `onPrimary #FFFFFF` / `primary #006C50` | **6.44:1** | 4.5:1 | ✓ |
| 10 | selo `sealFg #404943` / `sealBg #E4EAE2` | **7.62:1** | 4.5:1 | ✓ |
| 11 | faixa stale `staleFg #00174B` / `staleBg #DCE1FF` | **13.28:1** | 4.5:1 | ✓ |
| 12 | aviso `onAlertaContainer #261900` / `alertaContainer #FFDEAD` | **13.35:1** | 4.5:1 | ✓ |
| 13 | chip `onTertiaryContainer #261900` / `tertiaryContainer #FFDEAD` | **13.35:1** | 4.5:1 | ✓ |
| 14 | `alerta #7C5800` (ícone/texto) / `surface #F5FBF4` | **6.14:1** | 4.5:1 | ✓ |
| 15 | rótulo anúncio `adLabel #404943` / `adSurface #EFF5ED` | **8.42:1** | 4.5:1 | ✓ |
| 16 | `error #BA1A1A` / `surface #F5FBF4` | **6.15:1** | 4.5:1 | ✓ |
| 17 | link `primary #006C50` / `surfaceContainerHigh` | **5.26:1** | 4.5:1 | ✓ |
| 18 | stepper/borda `outline #707972` / `surface` | **4.28:1** | 3:1 (UI) | ✓ |

Segmentos contra o trilho (não-texto, ≥3:1): Lucro/track **4.99:1**,
Reserva/track **5.15:1**, Custos/track **4.92:1** — todos ✓.

### 2.3 Resultado

**Nenhum par que aparece nas telas falha AA.** O sistema tem folga confortável —
o par mais apertado que existe é o número-herói verde no Claro (**5.26:1** sobre o
card), e mesmo esse passa o limiar de *texto normal* (4.5:1), não só o de texto
grande. Isso é margem de segurança real: sobrevive aos overlays de elevação do M3,
a screenshots comprimidos e a telas ruins.

### 2.4 A exceção que **não** é falha, e por que ela é o ponto do sistema

Os **segmentos da Divisão comparados entre si** (não contra o trilho) têm
contraste quase nulo:

| Adjacência | Escuro | Claro |
|---|---|---|
| Lucro ↔ Reserva | 1.03:1 | 1.03:1 |
| Reserva ↔ Custos | 1.36:1 | 1.05:1 |
| Lucro ↔ Custos | 1.41:1 | 1.01:1 |

Isso **não viola WCAG** (a norma não exige contraste entre duas cores adjacentes
não-textuais quando há outro sinal), mas é a informação de acessibilidade mais
importante deste app: **a cor sozinha não distingue os segmentos.** Consequência
obrigatória na implementação:

1. **Todo segmento carrega rótulo + R$ + %.** Sem exceção, em qualquer tamanho.
2. **Ordem fixa Lucro → Reserva → Custos**, sempre — é memória posicional.
3. **Hachura/textura no segmento de Custos** (o DS já manda; aqui está o porquê
   quantitativo — sem ela, Custos e Reserva colam no Claro a 1.05:1).
4. **Divisória de 1–2px** (cor `surface` ou `track`) entre segmentos encostados,
   para dar borda visível já que a luminância não dá.

Se um dia alguém "simplificar" a barra tirando rótulos "porque as cores já
explicam" — este número (1.0:1) é a prova de que quebra.

---

## 3. Profundidade, elevação e gradiente

O DS (§5.3) define duas gramáticas de profundidade **diferentes por tema** — e é
essencial não misturar:

### 3.1 Escuro — profundidade por **tom de superfície**, quase sem sombra

- A hierarquia sobe pela rampa `surface → surfaceContainerLow → surfaceContainer
  → surfaceContainerHigh → surfaceContainerHighest`. Cada degrau é ~1 tom mais
  claro. É o que "levanta" o card-herói (`High #252B28`) acima do fundo
  (`#0F1513`) sem nenhuma sombra pesada.
- **Sombra:** mínima e opcional. No escuro sombra preta sobre fundo escuro quase
  não aparece e só suja. Prefira o degrau de tom. Se usar `elevation`, deixe o
  M3 aplicar seu overlay tonal — não empilhe sombra forte por cima.
- **State layers:** hover 8%, focus/press 12% de `onSurface`/`primary` conforme o
  componente.

### 3.2 Claro — **outline sutil + sombra leve**, para não sujar o papel

- No claro os degraus de superfície são muito próximos em luminância (o papel
  `#F5FBF4` e o card `#E4EAE2` diferem pouco). Então o card ganha definição por um
  **`outlineVariant` de 1px** (`#C0C9C0`) + sombra suave, não por cor.
- **Regra de borda:** use `outline` (`#707972`, contraste 4.28:1) para **bordas
  que significam** — repouso de input, contorno de card-herói, seleção. Use
  `outlineVariant` (`#C0C9C0`, ~1.6:1 sobre surface) **só para divisórias
  decorativas** (linhas da tabela de detalhamento, separadores de legenda).
  `outlineVariant` **não** serve como único contorno de um controle interativo —
  não atinge 3:1.

### 3.3 Escala de elevação aplicada (dos componentes)

| Componente | Elev. | Escuro (como) | Claro (como) |
|---|---|---|---|
| Fundo, fluxo guiado | 0 | `surface` | `surface` |
| Card de tool/pergunta | 1 | `surfaceContainer` | `surfaceContainer` + `outlineVariant` 1px + sombra leve |
| **Card-herói**, botão primário | 2 | `surfaceContainerHigh` | `surfaceContainerHigh` + `outline`/`outlineVariant` + sombra leve |
| Sheet, menu | 3 | `surfaceContainerHigh/Highest` | idem + sombra |
| Diálogo | 4–5 | `surfaceContainerHighest` | idem + sombra mais definida |

### 3.4 Gradiente — onde é permitido (pouco, e de propósito)

O DS usa gradiente em **um** lugar canônico: o **ícone/logo** (rounded-square
`#1FA67F → #00513C` vertical, tons 60→30 do Verde-Justo). Diretrizes para não
espalhar:

- **Permitido:** logo/ícone; opcionalmente um wash **muito** sutil no card-herói
  do Painel (ver §5, ajuste opcional) — sempre dentro da rampa Verde-Justo, nunca
  cruzando matiz.
- **Proibido:** gradiente **atrás de número** que mude o contraste local ao longo
  do dígito (o número precisa de fundo estável para ler tabular); gradiente
  verde→azul (confundiria Lucro com Reserva); gradiente nos segmentos da Divisão
  (eles são chapados, é o que os mantém legíveis e comparáveis).
- Se usar gradiente decorativo, **valide o contraste no ponto mais claro do
  gradiente** — é onde o texto por cima corre risco.

---

## 4. Regras invioláveis de cor — faça / não faça

### 4.1 Âmbar nunca é imposto

| ✅ Faça | ❌ Não faça |
|---|---|
| Reserva de imposto sempre em **azul** (`DivisaoColors.reserva`) — "guardado, seguro". | Pintar reserva/imposto de âmbar ou vermelho. Imposto **não é perigo**; é dinheiro do usuário guardado. |
| Âmbar (`alerta`/`alertaContainer`) só para **atenção acionável sem alarme** — "abaixo do alvo". | Usar âmbar para o valor de imposto a reservar, nem no selo, nem na faixa de ano defasado. |
| "Ano defasado" em **azul** (`staleBg`) — informação. | Usar âmbar em "valores base de 2025" (sugere que o número está errado). |

### 4.2 Vermelho só é erro real

| ✅ Faça | ❌ Não faça |
|---|---|
| `error` (carmim) só em falha real de input/sistema e ação destrutiva, sempre com ícone `error` + texto. | Usar carmim em imposto, em "abaixo do alvo" ou em qualquer estado financeiro normal. |
| Reforçar todo erro com forma + microcopy humana. | Sinalizar erro só pela cor da borda. |

### 4.3 Roxo 4YU é só assinatura

| ✅ Faça | ❌ Não faça |
|---|---|
| `brand4yu #6C4BD6` só no selo "by 4YU", tela Sobre e marketing. | Usar roxo em botão, ícone, header, acento ou qualquer superfície funcional. |
| Manter a UI ancorada no Verde-Justo (a cor da categoria). | "Deixar mais 4YU" pintando a interface de roxo — aumenta risco de spam e descaracteriza a marca do app. |

### 4.4 Anúncio nunca compete com número

| ✅ Faça | ❌ Não faça |
|---|---|
| Banner só no rodapé do Painel, em `adSurface` (a superfície mais recuada), rótulo "Publicidade". | Colocar anúncio sobre/adjacente a um número de dinheiro (valor-hora, reserva, lucro). |
| Intersticial só em momento calmo (voltar ao Painel), com frequency capping. | Anúncio dentro do fluxo de cálculo, na digitação, ou nas telas de reserva/simulador no momento da resposta. |
| Sumir com todo container de anúncio quando `ad_free` estiver ativo. | Dar ao anúncio container elevado/colorido que chame atenção. |

### 4.5 Cor nunca é o único sinal

| ✅ Faça | ❌ Não faça |
|---|---|
| Divisão sempre com rótulo + R$ + % + ordem fixa + hachura em Custos (§2.4 prova o porquê). | Renderizar a barra "só cor" — os segmentos têm contraste 1.0:1 entre si. |
| Atenção = `trending_down` + texto; sucesso = `check_circle` ✓; estimativa = `info` ⓘ. | Depender de verde×azul×âmbar para transmitir significado. |
| Números neutros em `onSurface`/`onSurfaceVariant`. | Colorir texto corrido com cor da Divisão (§10 do DS: "texto normal usa sempre tinta neutra"). |

### 4.6 Disciplina de token

| ✅ Faça | ❌ Não faça |
|---|---|
| Toda cor vem de `colorScheme.*` ou `DivisaoColors.*`. | Hex solto no widget (`Color(0xFF...)` fora de `core/theme`). |
| `BrandColors.*` só para gerar/documentar. | Pintar UI direto com a semente (`BrandColors.verdeJusto`) em vez do role. |

---

## 5. Ajustes finos opcionais (beleza sem quebrar o DS)

Todos abaixo são **opt-in**, ficam dentro das rampas já definidas e não mexem em
nenhum significado de cor. Nenhum é necessário para passar no DS.

1. **Wash vertical sutil no card-herói do Painel (só Escuro).** Em vez de
   `surfaceContainerHigh` chapado, um gradiente **muito** leve
   `surfaceContainerHigh #252B28 → surfaceContainer #1B211E` (top→bottom, ~8% de
   diferença). Dá "profundidade de vitrine" ao herói sem sombra e sem cruzar
   matiz. **Condição:** o número fica no terço superior, sobre a parte mais clara
   e estável — validar contraste no ponto inferior (`#1B211E`): `primary` ali dá
   ~9.5:1, folgado. No Claro, **não** aplicar (o papel não comporta, suja).

2. **Halo de marca atrás do número-herói (ambos os temas).** Um radial glow de
   `primary` a ~6–8% de opacidade, raio grande, centrado atrás do valor-hora.
   Reforça "o número é o herói" e injeta o Verde-Justo sem colorir texto vizinho.
   Manter baixíssima opacidade para não baixar o contraste do que estiver por
   cima.

3. **Tick de zebra tabular na tabela de detalhamento.** Alternar linhas entre
   `surface` e `surfaceContainerLow` (Escuro) / `surface` e `surfaceContainer`
   (Claro) em ~50% de opacidade, em vez de depender só das divisórias
   `outlineVariant`. Ajuda o olho a seguir "item → valor" na linha certa
   (números tabulares + zebra = leitura financeira clássica). Puramente
   estrutural, nenhuma cor de significado envolvida.

4. **Bolinhas da legenda como anel, não disco (ambos os temas).** Renderizar o
   *swatch* da legenda da Divisão como um anel (borda 2px na cor do segmento +
   miolo `surface`) em vez de disco cheio. Some visualmente com a hachura de
   Custos e reduz a chance de dois discos de luminância parecida "borrarem" num
   scroll rápido. Zero impacto semântico.

5. **`inversePrimary` como acento de "sucesso salvo" no snackbar.** O snackbar já
   usa `inversePrimary` na ação; nada a mudar — só registrando que é o lugar
   *certo* de um verde extra, e que ele **não** deve migrar para dentro das telas
   (lá o verde é reservado a Lucro/valor-hora).

> Se for adotar 1 ou 2, rode de novo o cálculo de contraste no ponto mais escuro
> do gradiente/halo antes de subir — é a única forma de quebrar AA por
> descuido, e é fácil de verificar.

---

## 6. Checklist rápido para a revisão de tela

- [ ] Fundo = `surface`; cards = `surfaceContainer`; herói = `surfaceContainerHigh`.
- [ ] Valor-hora em `primary`; "RESERVE" em `reserva`; "LUCRO" em `lucro`; rótulos em `onSurfaceVariant`.
- [ ] Barra da Divisão: 3 segmentos chapados, ordem Lucro→Reserva→Custos, cada um com rótulo+R$+%, hachura em Custos, divisória entre segmentos.
- [ ] Reserva/imposto azul; "abaixo do alvo" âmbar; "ano defasado" azul; erro carmim — nenhum trocado.
- [ ] Selo de estimativa presente em toda tela com número de imposto, em `sealBg/sealFg` (nunca vermelho/âmbar).
- [ ] Anúncio só no rodapé do Painel, em `adSurface`, longe de qualquer número.
- [ ] Roxo 4YU ausente da UI funcional (só Sobre/selo).
- [ ] Escuro: profundidade por tom. Claro: `outline` sutil + sombra leve; `outlineVariant` só decorativo.
- [ ] Nenhum hex solto — tudo via `colorScheme.*` ou `DivisaoColors.*`.
- [ ] Nenhum estado depende só de cor (forma + texto sempre).

---

*Guia de aplicação de cor — "Quanto Cobro?" · deriva do Design System "A Divisão"
§2/§3 e dos tokens em `lib/core/theme/`. Ratios calculados sobre os hexes reais do
código (WCAG 2.x). Reverificar com as cores renderizadas quando o M3 aplicar
overlays de elevação.*
