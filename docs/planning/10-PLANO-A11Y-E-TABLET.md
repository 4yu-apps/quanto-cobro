# 10 — Plano de atuação: acessibilidade, tablet e o que falta pra loja

> Escrito em 20/07/2026, em cima de: a auditoria de a11y da estrutura nova
> ([`ux-revisao/D-*`](ux-revisao/D-A11Y-ESTRUTURA-NOVA.md)), o estado das fases
> no [plano oficial](08-PLANO-OFICIAL.md) §11.5, e uma varredura nova de
> responsividade feita hoje contra o código real.
>
> O [08](08-PLANO-OFICIAL.md) continua sendo o documento de **produto**. Este
> aqui é o de **execução** do que sobrou: ele não reabre decisão nenhuma, só
> ordena o trabalho restante e diz onde cada coisa encosta no código.

---

## 0. Estado — 20/07/2026, fim da rodada de código

Os blocos 1 a 6 do §7 estão **feitos**, em seis commits na branch
`a11y-e-tablet`. A suíte saiu de 112 para **273 testes**, `flutter analyze`
limpo.

| Bloco | Estado |
|---|---|
| P0 de a11y (§2) | ✅ os três, com teste que falha no código antigo |
| Fundação de tablet (§4.1–4.3) | ✅ breakpoints, trilho, clamp, tema |
| Matriz de layout (§5) | ✅ 144 casos — **achou 9 sítios de estouro, 6 deles em fonte normal** |
| P1 lote 1 — caminho de ouro (§3) | ✅ P1-1, P1-2, P1-12 |
| P1 lote 2 — rótulos (§3) | ✅ P1-3, P1-4, P1-5, P1-6, P1-7, P1-10 |
| Ganhos de tela larga (§4.4) | ✅ **mestre-detalhe** nos Trabalhos + calc em duas colunas |
| P1 restantes | ✅ P1-8, P1-9, P1-11, P1-13 |
| P2 | ✅ P2-1, P2-2, P2-4, P2-5, P2-6 · ❌ P2-7, com motivo |
| Manifest large-screen | ✅ declarado |
| **Infra e loja (§6)** | ⏳ **intocado — depende de passo humano** |

**O bloco de código está fechado.** Duas decisões dentro dele merecem registro,
porque as duas contrariam o que este documento dizia:

1. **O mestre-detalhe foi feito, e ele SUBSTITUIU a grade de duas colunas.** O
   §4.4 previa a grade como plano B ("se o mestre-detalhe custar caro, corta e
   fica só a grade"). Não custou — deu pra fazer sem tocar em `go_router`, com
   um construtor `.painel` que devolve o mesmo conteúdo sem a casca. E as duas
   juntas não fazem sentido: com a lista ocupando 380dp, duas colunas de card
   virariam duas tiras de 180dp. A grade viveu um commit; era o piso, e o piso
   só serve enquanto o teto não existe.

2. **O P2-6 não foi aplicado a todos os sobrolhos**, e essa é a única
   discordância real com a auditoria. O app tem dois tipos de texto em caixa
   alta, iguais na tela e opostos na fala: **seção** ("ENTRADAS", "ANOTAÇÕES") —
   nomeia um bloco e é um lugar pra onde se pula, vira `SecaoTitulo`; e
   **sobrancelha de valor** ("SEU VALOR-HORA", "LUCRO REAL") — é o nome do
   número logo abaixo, que já carrega essa frase no próprio rótulo. Marcar a
   segunda como cabeçalho encheria o sumário de legendas de número, que é ruído
   exatamente pra quem o sumário serve. Onze viraram seção; nove ficaram.

3. **O P2-7 (moeda falada) fica fora**, seguindo a recomendação da própria
   auditoria: é o tipo de rigor que atrasa lançamento pra consertar um problema
   que talvez não exista.

**O achado que mais mudou a leitura do problema:** a matriz encontrou nove
sítios de estouro, e **seis quebram em fonte normal** — no Moto E de 320dp, que
é o público. Não era um defeito de acessibilidade que só aparece no extremo de
200%: era layout quebrado no aparelho do público-alvo, todos os dias, e ninguém
tinha olhado. O onboarding — a primeira tela que a pessoa vê — estourava 24px
em pé e 148px deitado.

---

## 1. Onde estamos, sem eufemismo

As Fases 0 a 5 estão feitas. O que resta são três blocos, e eles são de
naturezas diferentes — vale não misturar:

| Bloco | O que é | Quem destrava |
|---|---|---|
| **A11y** | 3 P0 + 13 P1 auditados, nenhum corrigido ainda | código, hoje |
| **Tablet e paisagem** | o app não tem **nenhum** breakpoint, e a rotação está destravada nas duas plataformas | código, hoje |
| **Loja e billing** | compra real do Pro, ficha, Data Safety, Firebase | passo humano + código |

> **Nota de 20/07:** este diagnóstico é o de antes da rodada. Ele fica como
> está, porque é o que justifica as decisões — mas leia o §0 pro estado atual.

**A frase que resume o risco novo:** o `AndroidManifest.xml` não declara
`screenOrientation`, e o `Info.plist:62-68` anuncia as quatro orientações no
iPad. O sistema **vai** entregar ao app um viewport de 640×360 ou 1024×768 — e
não existe uma linha em `lib/` que responda a isso. Zero `MediaQuery.sizeOf`,
zero `NavigationRail`, zero clamp de largura, zero grid. Dezoito telas são
`ListView` de largura cheia.

Isso não é um defeito de polimento. É a diferença entre "o app funciona no
tablet" e "o app *foi feito* pra quem está no tablet" — e a Play Console pontua
large-screen na ficha desde 2023.

---

## 2. Os três P0 de acessibilidade — antes de qualquer outra coisa

Confirmei hoje que os três continuam abertos, exatamente onde a auditoria os
deixou. São correções pequenas e o custo de adiá-las é uma pessoa cega não
conseguir usar duas telas.

### A1 · `areas_screen.dart:125` — o `MergeSemantics` engole o menu ⋮
Tirar o `MergeSemantics`; o `ListTile` já funde título e subtítulo. O `R$ 92/h`
vira `semanticsLabel` falável ("por hora"), e o `PopupMenuButton` ganha
`tooltip: 'Opções de ${a.nome}'`. Código pronto em `D-* §P0-1`.

### A2 · `SemanticButton` — a ação que o `ExcludeSemantics` apagava
Criar o widget em `core/ui/a11y.dart` (a ação é **obrigatória por assinatura**,
é esse o ponto) e aplicar nos quatro sites: `trabalhos_screen.dart:170`,
`painel_screen.dart:285`, `core/ui/tool_action_card.dart:35`,
`core/ui/hero_value_card.dart:55`. No `hero_value_card` aproveita e corrige o
rótulo "Trabalho ativo" → "Área ativa" (P1-9), que hoje manda a pessoa pro
lugar errado do modelo mental.

Sem isso, Switch Access não alcança **nenhum** trabalho, nem os dois botões
protagonistas do Início. E o `onTapHint` que já está escrito nunca foi falado
uma vez sequer.

### A3 · `calc_screen.dart:871` — o passo 4 estoura assert em debug
`Material` recebendo `borderRadius:` **e** `shape:` juntos. Um só: o `shape`
carrega o raio e a borda. Em release ninguém vê; mas **nenhum widget test
consegue chegar no passo 4**, e é por isso que não existe nenhum. Corrigir isto
é o que destrava o §5 deste plano.

**Custo do bloco:** pequeno. É o melhor retorno por linha de todo o documento.

---

## 3. Os P1 de acessibilidade que travam o lançamento

A auditoria separou bem; mantenho a ordem dela, com uma mudança: junto os que
moram no mesmo arquivo, pra não abrir `entrada_screen.dart` quatro vezes.

**Lote 1 — o caminho de ouro (`entrada_screen.dart`)**
- P1-1: `_salvar` e `_desfazer` não cancelam o `_announceTimer`. Hoje a fala
  antiga chega **depois** do "Guardado" e soa como se o salvamento não tivesse
  pegado. Duas linhas.
- P1-2: `_salvar` é `async` e não tem trava — toque duplo grava duas entradas e
  o Desfazer só remove uma. `bool _salvando`.
- P1-3: `semanticLabel: ''` no `_CofreDoMes` (`:525`) apaga o acúmulo do leitor
  de tela. A regra que sai daqui vale pro app inteiro: **anuncie a transição,
  rotule o estado.**
- P1-12: o foco cai no vazio quando "Guardar" vira "Registrar outro · Desfazer".
  `focusNode` + `addPostFrameCallback`, simétrico nos dois sentidos.

**Lote 2 — os rótulos que apagam conteúdo**
- P1-4: `_PreviaValorHora` (`calc_screen.dart:1006`) — mesmo `''`, e o medo que
  motivou a decisão (tagarelice) não se realiza: `Text` não fala sozinho ao
  mudar. Junto vai o `assert` em `money_count_up.dart:57` que fecha essa porta
  pra sempre.
- P1-5: `trabalho_detalhe_screen.dart:308` — o `ExcludeSemantics` come a lista
  de pagamentos individuais. O `Exclude` passa a cobrir só o que o rótulo conta.
- P1-6: `historico_screen.dart:201` — "R cifrão sessenta e oito" sem dizer que
  é imposto. Rótulo por linha, com `dataPorExtenso`.
- P1-7: `trabalhos_screen.dart:113`/`:133` — os cabeçalhos de área não são
  `header: true`, então não dá pra pular de grupo em grupo. Com a contagem
  junto, a hierarquia latente passa a existir na fala como existe na tela.

**Lote 3 — o que não é rótulo**
- P1-8: os cinco estouros em fonte 200% — **vai junto com o §5**, porque é o
  mesmo tipo de defeito de layout que o tablet expõe, e o mesmo teste pega os
  dois.
- P1-10: os círculos de cor em `marca_screen.dart:226`. Alvo 44→48dp, semântica
  de rádio, `announce` da escolha, e a linha que importa: `outlineVariant` →
  `outline`. Hoje, no tema escuro (que é o padrão), **"Grafite" é um buraco
  preto sobre fundo preto** — 1.94:1, com contorno de 1.41:1.

**Depois, sem pressa:** P1-11 (a `EntradaBar` herdar a hachura/pontilhado da
`DivisaoBar` — hoje 1.16:1 entre os segmentos no tema claro), P1-13 (a máscara
de telefone que joga o cursor pro fim) e os sete P2.

---

## 4. Tablet e paisagem — o bloco novo, e o maior

Aqui não existe auditoria prévia, então o plano precisa decidir a forma antes de
listar tarefas. Proponho três decisões, e elas seguram tudo que vem depois.

### 4.1 A decisão de forma: window size classes do Material 3

Três faixas, nomes do próprio Material, num arquivo só
(`core/ui/breakpoints.dart`):

```
compact    < 600dp    celular em pé, e celular deitado estreito
medium     600–839dp  tablet pequeno em pé, dobrável aberto, celular deitado largo
expanded   ≥ 840dp    tablet em paisagem, tablet grande em pé
```

Por que M3 e não números nossos: o Flutter, o Android e a Play Console já falam
essa língua, e "tablet" não é uma coisa só — um tablet em pé se parece mais com
um celular grande do que com ele mesmo deitado. Quem manda é a **largura
disponível**, nunca o dispositivo.

**A regra dura, pra isso não virar bagunça em três meses:** nenhuma tela lê
`MediaQuery.sizeOf` direto. Todas leem `WindowClass.of(context)`. É o mesmo
espírito do `announce()` centralizado — a decisão mora num lugar só, e quando
ela mudar, muda num lugar só.

### 4.2 A decisão de navegação: rail a partir de `medium`

`nav_shell.dart` ganha um ramo. Abaixo de 600dp, a pílula de vidro atual, que
está boa e é assinatura do app. De 600dp pra cima, `NavigationRail` à esquerda,
com o mesmo vidro e a mesma semântica de aba.

Isso resolve dois problemas de uma vez: no tablet a barra de baixo com três
destinos espalhados por 1000dp é feia e é longe do polegar; e no celular
deitado, a pílula + os 88dp de `kFloatingNavReserve` comem **24% de um viewport
de 360dp de altura**.

O `kFloatingNavReserve` (`tokens.dart:44`) deixa de ser constante: vira zero
quando o rail está em pé.

### 4.3 A decisão de leitura: largura máxima de conteúdo

Texto que atravessa 1000dp não se lê — o olho perde a linha na volta. Todas as
telas de leitura e formulário passam a clampar o conteúdo em ~600dp, centrado,
com o fundo (o `_ambientWash` do Painel, o vidro) continuando a sangrar até a
borda. O clamp entra num `ContentWidth` em `core/ui/`, aplicado no corpo das
dezoito telas.

Isso é uma linha por tela e é o que separa "esticado" de "desenhado".

### 4.4 Onde a largura vira ganho de verdade, e não só respiro

Clamp é o piso. O teto é usar o espaço pra mostrar mais, e há quatro lugares
onde isso muda a experiência:

| Onde | O quê | Por quê |
|---|---|---|
| **Trabalhos** (`expanded`) | duas colunas de cards | a lista é o objeto que mais cresce; em 840dp cabem dois e a varredura fica o dobro mais rápida |
| **Trabalhos** (`expanded`) | painel mestre-detalhe: lista à esquerda, `trabalho_detalhe` à direita | é o padrão que o tablet inventou. Tocar num trabalho deixa de fazer a tela inteira dar um pulo |
| **Calculadora** (`expanded`) | pergunta à esquerda, `_PreviaValorHora` + resumo à direita, fixos | o valor-hora vivo é a alma da Fase 3. Em tela larga ele para de ser uma faixa e vira **o número, sempre à vista, mudando enquanto ela digita** |
| **Proposta preview** (`medium+`) | o papel A4 na proporção real | a promessa é "é exatamente isso que o cliente recebe". No tablet dá pra cumprir literalmente |

O mestre-detalhe é o único item deste plano que mexe em roteamento
(`go_router` com `StatefulShellRoute`) — se ele custar caro, corta e fica só a
grade de duas colunas. A grade sozinha já paga o bloco.

### 4.5 Paisagem no celular — dois estouros que já existem hoje

Independem de tablet e são bug em aparelho que já está na mão de gente:

- `onboarding_screen.dart:60-113` — `Column` **não rolável** com um círculo de
  96dp + dois blocos de texto entre um "Pular" fixo e um botão fixo. A 360dp de
  altura, sobra algo entre 160 e 190dp pra isso. **Estoura**, e estoura pior com
  fonte aumentada. É a primeira tela que a pessoa vê.
- `calc_screen.dart:203-290` — o miolo rola, então não quebra, mas a moldura
  (pontinhos + prévia + botão, todos fixos) come tanto de 360dp que o viewport
  útil fica minúsculo. Em `compact` + paisagem, os pontinhos viram uma linha
  fina e a prévia encolhe.

### 4.6 O resto da varredura, que é barato e some junto

- **Bottom sheets** (7 ocorrências): nenhuma tem `constraints`. Em tablet
  ocupam a largura toda; em paisagem, quase a altura toda. Entra um
  `BottomSheetThemeData` com `maxWidth: 640` no tema — um lugar, sete correções.
- **SnackBar** (`app_theme.dart:101-105`): `floating` sem `width`. Em 1000dp
  vira uma torrada de um quilômetro. Mesma correção, no tema.
- **`AlertDialog`** (6 ocorrências): o default do Material se comporta bem;
  conferir e provavelmente não mexer.
- **`AndroidManifest.xml`**: declarar `android:resizeableActivity="true"` e
  `android.supports_size_changes` explicitamente. Hoje funciona por default —
  mas por default é o tipo de coisa que uma versão do Gradle muda por você.

---

## 5. A rede de segurança: os testes que faltam

Este é o item que a auditoria pediu nominalmente e que eu subiria de prioridade,
porque ele é o que impede tudo acima de voltar sozinho.

**`test/layout_matrix_test.dart`** — uma matriz, não um teste. Cada tela × cada
tamanho, afirmando `expect(tester.takeException(), isNull)`:

```
320×640   celular barato em pé        (é o público — Moto E)
640×360   celular deitado
600×960   tablet pequeno em pé
1024×768  tablet deitado
```

Cruzado com `TextScaler` 1.0 e 2.0. **Oito combinações por tela**, e é assim que
os cinco estouros do P1-8 param de ser uma sonda apagada e viram uma trava.

Duas notas que a varredura de hoje trouxe e que mudam o valor disto:

1. Os testes de hoje rodam todos na superfície **padrão de 800×600** e nenhum
   chama `setSurfaceSize`. Ou seja: o `painel_smoke_test` nunca viu uma tela de
   celular. O `overflow_test.dart` inteiro tem 26 linhas e testa **um widget** a
   **uma** largura.
2. Nada disso é possível enquanto o A3 (o assert do passo 4) estiver de pé. Por
   isso ele é P0 mesmo sendo invisível pro usuário.

---

## 6. Infra e loja — seguindo o playbook da casa

Nada acima muda a frase do [08 §11.5](08-PLANO-OFICIAL.md): **não existe compra
real do Pro.** Ele é flag local e dá pra virar Pro sem pagar.

O caminho a seguir é o [`PLAYBOOK-APP-NOVO.md`](../../../PLAYBOOK-APP-NOVO.md)
da pasta `4yu-apps/` — escrito depois de publicar o Deixei Aqui inteiro, com as
armadilhas já pagas. Ele é a fonte da verdade do **processo**; o
[09](09-HANDOFF-FIREBASE-E-LOJA.md) continua sendo o do **estado** deste app.

### 6.1 Duas divergências entre o playbook e este app — resolver antes de agir

O playbook foi escrito a partir do Deixei Aqui, e o Quanto Cobro tomou duas
decisões opostas. Registro aqui pra ninguém executar o passo errado por reflexo:

| Passo do playbook | Aqui | Por quê |
|---|---|---|
| **Parte 2 §2 — AdMob** (app, blocos, mensagens de privacidade, device de teste, UMP) | **NÃO SE APLICA. Pular inteiro.** | [08 §9.1](08-PLANO-OFICIAL.md): anúncio removido. No nosso nicho ele aparece em 6,7% das reclamações contra 2,7% na média — **2,48×** — em troca de centavos de eCPM. O `ads.dart` existe hoje só pra documentar a decisão e impedir que ela seja desfeita por engano |
| **Parte 2 §4 — Billing "compra única, vitalícia"** | **Assinatura mensal de R$ 6,90** | [08 §9.2](08-PLANO-OFICIAL.md), decisão do dono em 19/07. Muda o tipo do produto na Play (*subscription*, não IAP único) e muda o código: em vez de entitlement vitalício + "Restaurar compras", é `queryPurchases` no boot, período de graça e tratamento de renovação falha |

O ganho colateral da primeira linha é grande: **sem SDK de anúncio, o app não
coleta ID de publicidade**, e o Data Safety fica muito mais enxuto — só o que
Firebase Analytics e Crashlytics levam. E com um detalhe a favor que quase
nenhum app tem: a telemetria daqui é **opt-in de verdade** (Fase 0), então a
declaração pode dizer isso.

Fica registrada a tensão que o próprio 08 §9.2 anotou: a pesquisa aponta que
este público tende a preferir compra única, e assinatura cobra confiança
recorrente de um app que ainda não a construiu. É hipótese a validar — o evento
`pro_ativado` já carrega o gatilho pra medir desde o dia 1.

### 6.2 A sequência, com dono de cada passo

Nível CONTA (Play `4935491440305715031`, GCP `yu-automation`, GA4
`accounts/401450636`, `app-ads.txt` do domínio) **já existe e não se refaz** —
app novo entra dentro dele.

| # | Passo | Dono | Estado |
|---|---|---|---|
| 1 | Criar o projeto Firebase do Quanto Cobro, deixando ele criar a **própria** propriedade GA4 | **dono** (UI) | ⏳ **é o primeiro bloqueio** |
| 2 | GCP → IAM do projeto novo → `Firebase Admin` pra `claude-automation@yu-automation.iam.gserviceaccount.com` | **dono** (UI) | ⏳ |
| 3 | Registrar o app Android, baixar e **versionar** o `google-services.json`, ligar `firebase_core`/`analytics`/`crashlytics`, trocar a instância `telemetry` em `main.dart` | agente (API) | destravado por 1 e 2 |
| 4 | Retenção GA4 de 2 → 14 meses | agente (API) | idem |
| — | ~~AdMob~~ | — | **não se aplica** (§6.1) |
| 5 | Criar o app na Play Console | **dono** (UI) | ⏳ previsto 20/07 |
| 6 | Criar a **assinatura** mensal R$ 6,90 — ID irreversível, igual ao do código — e adicionar testador de licença | **dono** (UI) | depois de 5 |
| 7 | Implementar Play Billing de assinatura + entitlement (mata a flag local) | agente | depois de 6 |
| 8 | Ficha: título, descrição curta e longa | agente (API) | depois de 5 |
| 9 | Ícone, feature graphic 1024×500, screenshots — **incluindo tablet** | dono (agente gera as artes) | ⚙️ **capturas prontas** — ver §6.5 |
| 10 | Data Safety, IARC, público-alvo, categoria, declaração de anúncios (**"não contém anúncios"**) | **dono** (UI, sem API) | depois de 5 |
| 11 | Página do produto, política de privacidade e **exclusão de dados** em `4yu.com.br/quanto-cobro/` | agente (repo `website`) | pode ir agora |
| 12 | Secrets do CI, build do AAB **no CI**, subir pro teste interno | agente | depois de 3 e 7 |
| 13 | Testar no aparelho: R8, compra real, fluxos | **dono** | depois de 12 |
| 14 | 12 testadores no **teste fechado** → 14 dias → produção | **dono** | o relógio começa do zero, é por app |

### 6.2.1 As capturas da ficha — prontas, e como refazer

`test/prints_loja_test.dart` gera as cinco capturas em
`docs/screenshots/loja/`, em celular (414×736) e tablet 10" (1280×800), a 2×:

```
flutter test test/ferramentas/prints_loja.dart --update-goldens
```

**Por que render e não emulador:** não há device nem emulador nesta máquina, e
o playbook é explícito que build local em WSL derruba a máquina (~11 GB). O
render dá o mesmo pixel, no tamanho exato, repetível — e carrega as fontes de
verdade do `assets/`, senão o texto sairia em caixas pretas (o `flutter test`
usa Ahem por padrão) e a captura não serviria pra nada.

O arquivo está **fora** da suíte normal — o nome não termina em `_test.dart`,
então o glob não o pega. Ele não é uma asserção sobre o app, é a ferramenta que
produz a arte: no CI, quebraria o build toda vez que um pixel mudasse, num
arquivo cujo trabalho é ser regenerado de propósito.

**Duas coisas que só a captura revelou** — e que nenhum teste pegaria, porque
as duas passam em qualquer asserção de layout:

- o contorno do card selecionado no mestre-detalhe **não aparecia**: o
  `DecoratedBox` pinta atrás por padrão, e o preenchimento opaco do card cobria
  a borda inteira. Existia no código e não na tela;
- o trilho esticava pela altura toda da tela, deixando ~1000px de vão embaixo
  de três ícones. A pílula agora **abraça** os destinos, ancorada no topo — que
  é o que a barra de baixo sempre fez.

Falta só o passo humano: conferir e subir na ficha. Duas das cinco são o
argumento comercial do bloco de tablet — o mestre-detalhe e a calculadora em
duas colunas.

### 6.3 As armadilhas do playbook que mordem *este* app

Nem todas se aplicam. Estas sim:

- **`google-services.json` não é segredo** — ele vai dentro do APK. **Versionar.**
  Sem ele, um clone limpo não compila.
- **R8 quebra em runtime, não no build.** Compila liso e crasha quando a pessoa
  abre a tela da classe removida. Aqui isso alcança Flutter, Firebase e Billing —
  e o `pdf`/`share_plus` da proposta, que é justamente um caminho que ninguém
  exercita por acidente. Tem que abrir a proposta num device com o build de
  release antes de confiar.
- **Build local derruba a máquina** (WSL, ~11 GB). O caminho é o CI.
- **A política hospedada e a do app têm que dizer a mesma coisa.** Aqui existe
  texto em `features/legal/legal_texts.dart`; a página do site tem que sair
  *dele*, não de um texto novo. Divergência entre as duas já reprovou app nesta
  conta.
- **Data Safety é sobre o que SAI do aparelho.** O app é offline, mas
  Firebase/Crashlytics coletam (uso, falhas) — declarar "não coleta" é
  reprovação. Dado que fica no device (as entradas, os trabalhos, a marca) **não**
  se declara.
- **12 testadores × 14 dias é por app**, não por conta. As mesmas pessoas
  servem, mas precisam entrar na faixa deste app e o relógio zera. **Teste
  interno não conta** — tem que ser fechado.
- **Caminho absoluto do `.secrets/`.** Em casa o usuário é `gabfelix`, no
  trabalho `gabrielbarbosa`. `GOOGLE_APPLICATION_CREDENTIALS` e o
  `key.properties` guardam caminho absoluto e quebram ao trocar de máquina — com
  erro de "arquivo não encontrado" que faz procurar bug no lugar errado.
- **O console mente.** Ele diz "publicado" com o mundo real dizendo outra coisa.
  Provar fora: `curl` no `app-ads.txt`, e o evento de telemetria chegando na
  propriedade GA4 certa (a **do app**, nunca a do site).

### 6.4 O que não se aplica, e vale escrever pra ninguém procurar

Sem localização, sem mapa, sem foreground service, sem câmera, sem áudio, sem
anúncio. Logo: **sem vídeo de FGS**, sem declaração de localização em segundo
plano, sem permissão sensível pra justificar, sem UMP, sem `MAPS_API_KEY`.
A única permissão do app é `INTERNET`, e ela existe pela cotação de câmbio.

É por isso que este app é o mais barato de publicar dos dois — e o item 9 é o
único que ficou **mais** caro, porque agora pede prints de tablet. Que é
exatamente o que o §4 deste plano produz.

---

## 7. A ordem que eu seguiria

```
1. A11Y P0 (A1, A2, A3)              ← pequeno, e A3 destrava os testes
2. TABLET: a fundação                ← breakpoints + rail + ContentWidth + tema
                                        (sem isto, nenhuma tela tem onde se apoiar)
3. TESTES: a matriz de layout        ← agora, não no fim: ela guia o passo 4
4. TABLET: tela a tela + P1-8        ← os estouros de fonte 200% moram aqui
5. A11Y P1 lotes 1 e 2               ← rótulo e foco, independentes do layout
6. TABLET: os ganhos (grade, mestre-detalhe, calc em duas colunas)
7. LOJA: billing + ficha + prints    ← quando o dono destravar o console
8. O resto: P1-11, P1-13, P2         ← anota e segue
```

Com uma ressalva: os passos 1 e 2 do §6.2 (Firebase) e o 11 (páginas do site)
**não dependem de nada acima** e podem andar em paralelo desde já. O dono
destrava o Firebase, o agente segue pela API, e o código do app continua no
caminho 1→6 sem se cruzar com isso.

**Por que a fundação do tablet antes das telas:** é literalmente o mesmo erro que
o [08 §12](08-PLANO-OFICIAL.md) já pagou uma vez — mexer nas telas antes de a
estrutura assentar é mexer duas vezes nos mesmos arquivos.

**Por que os testes no meio e não no fim:** porque escrever a matriz antes de
corrigir as telas transforma o passo 4 numa lista de falhas vermelhas virando
verdes, em vez de uma caçada visual em quatro emuladores.

**Por que o billing por último apesar de ser o único bloqueio real:** ele depende
de um passo humano que não está na minha mão. Todo o resto pode andar em
paralelo a ele — e deve.
