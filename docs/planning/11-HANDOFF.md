# 11 — Handoff: o que falta no app

> Escrito em 20/07/2026, no fim de uma rodada de código. Para quem pega isto
> **frio**: você não precisa ler os docs 08 e 10 inteiros pra começar. Precisa
> ler este, e ele diz quando abrir os outros.
>
> O que já foi feito está no git, com o porquê em cada mensagem de commit. Este
> documento é sobre o que **não** foi.

---

## 0. Onde as coisas estão

| | |
|---|---|
| **Branch do app** | `a11y-e-tablet`, **14 commits à frente da `main`, NÃO mergeada** |
| **Branch do site** | já mergeada na `main` e **publicada** em `4yu.com.br/quanto-cobro/` |
| Versão | `0.7.0+9` (não subiu nesta rodada) |
| Testes | 273 passando, 26 arquivos · `flutter analyze` limpo |
| Docs de referência | [08](08-PLANO-OFICIAL.md) = produto · [10](10-PLANO-A11Y-E-TABLET.md) = execução · [09](09-HANDOFF-FIREBASE-E-LOJA.md) = Firebase/loja |

**Primeira decisão que você tem que tomar:** mergear a `a11y-e-tablet` na `main`
ou abrir PR e revisar antes. Ela carrega os três P0 de acessibilidade, a
fundação de tablet, o mestre-detalhe, o ícone novo e a correção da política. Não
tem nada experimental ali, mas são 14 commits.

---

## 1. A lacuna que nenhum teste fecha

> **Nada foi buildado nem rodado num aparelho.**

Tudo que existe está verificado por 273 testes e por render determinístico. Isso
cobre lógica, semântica e layout, e **não cobre**:

- **R8/minify, que quebra em RUNTIME e não no build.** Compila liso e crasha
  quando alguém abre a tela da classe removida. O caminho mais exposto aqui é o
  **PDF da proposta** (`pdf` + `share_plus`): ninguém passa por ele por
  acidente, então é o candidato natural a só falhar com usuário real.
- O comportamento do trilho e do mestre-detalhe **num tablet de verdade**, com
  rotação ao vivo e teclado abrindo.
- O ícone no lançador (foi conferido em PNG, não em aparelho).

O playbook da casa proíbe build local em WSL (derruba a máquina, ~11 GB). O
caminho é o CI. Enquanto isso não roda, trate a rodada como **"verde nos testes,
não verificada no aparelho"**.

---

## 2. O que falta, em ordem

### 2.1 Bloqueado em passo humano (não dá pra começar)

| # | O quê | Destrava |
|---|---|---|
| 1 | Criar o projeto **Firebase**, deixando ele criar a própria propriedade GA4 | passos 3 e 4 |
| 2 | GCP → IAM → `Firebase Admin` pra `claude-automation@yu-automation.iam.gserviceaccount.com` | idem |
| 3 | Criar o app na **Play Console** | billing, ficha, Data Safety |
| 4 | Criar a **assinatura** mensal (ID irreversível) + testador de licença | o código do billing |

Detalhe de cada um em [10 §6.2](10-PLANO-A11Y-E-TABLET.md).

### 2.2 Código, assim que o humano destravar

**a) Play Billing — é o único bloqueio real de lançamento.**

Hoje não existe: `in_app_purchase` não está no `pubspec.yaml`, e
`core/billing/entitlement.dart` é uma flag booleana em `SharedPreferences`. Dá
pra virar Pro sem pagar.

Dá pra escrever ~90% antes do passo humano (dependência, serviço,
`queryPurchases` no boot, restaurar, ligar no `EntitlementRepository`), mas fica
**intestável** até a assinatura existir no console, porque o ID do produto é
irreversível e tem que bater. Escrever contra um produto que não existe é
escrever no escuro; a decisão de fazer isso é sua.

⚠️ **É assinatura, não compra única.** O [08 §9.2](08-PLANO-OFICIAL.md) decidiu
mensal de R$ 6,90. O playbook da casa fala em "compra vitalícia + Restaurar
compras" porque foi escrito a partir do Deixei Aqui: **aqui não se aplica**. O
que vale é `queryPurchases` no boot, período de graça e tratamento de renovação
falha.

**b) Firebase, depois dos passos 1 e 2.** A camada de telemetria já existe e os
eventos já disparam nos lugares certos (`core/telemetry/`). Falta só o destino:
registrar o app Android, versionar o `google-services.json` (ele **não** é
segredo, vai dentro do APK), ligar `firebase_core`/`analytics`/`crashlytics` e
trocar **uma linha** no `main.dart`, a instância `telemetry`. Nenhum call site
muda.

⚠️ Sem o `google-services.json`, o `firebase_core` não sobe e o app morre no
boot. É o mesmo tipo de crash que o `MobileAdsInitProvider` causou uma vez (está
registrado no `pubspec.yaml`).

**c) Subir a versão.** Está em `0.7.0+9` e não subiu nesta rodada. Antes de
qualquer build de teste, promova.

### 2.3 Polimento que ficou por último, de propósito

- **P2-2, P2-5, P2-6** foram feitos. **P2-7 (moeda falada) fica fora**, seguindo
  a recomendação da própria auditoria: é rigor que atrasa lançamento pra
  consertar um problema que talvez não exista. Se aparecer reclamação real de
  leitor de tela lendo "R$ 1.234" errado, o lugar é `common/money.dart`.
- Dois nits que não valem commit sozinhos: `onPerfilTap ?? () {}` em
  `core/ui/hero_value_card.dart` é um fallback que nunca dispara, e o iPad está
  sem multi-janela (`UIApplicationSupportsMultipleScenes: false`) — mas iOS não
  é o alvo de lançamento.

---

## 3. Decisões já tomadas. Não reabra sem motivo novo

Cada uma destas custou investigação. Se você for contra alguma, tudo bem, mas
saiba o que está desfazendo.

**O `R$` no ícone fica.** A pergunta "mas o app é multi-moeda, faz sentido?"
já foi feita e checada: `moneyBRL` é usado em **toda saída** do app (reserva,
cofre, totais, histórico, proposta). As outras moedas são só **entrada** ("Marina
cobrando em USD") e o FX converte pra real. O motor é MEI, DAS, carnê-leão,
INSS, e o lançamento é na Play brasileira. Tirar o `R$` deixaria o ícone mais
genérico, não mais preciso.

**A grade de 2 colunas nos Trabalhos foi substituída pelo mestre-detalhe.** Ela
era o plano B do [10 §4.4](10-PLANO-A11Y-E-TABLET.md); o plano A não custou
caro. As duas juntas não fazem sentido: com a lista em 380dp, duas colunas de
card virariam duas tiras de 180dp.

**Nem todo sobrolho virou cabeçalho.** A auditoria pedia `header: true` em
todos; o app tem dois tipos que parecem iguais na tela e são opostos na fala.
Seção ("ENTRADAS") é lugar pra onde se pula e virou `SecaoTitulo`; sobrancelha
de valor ("SEU VALOR-HORA") é o nome do número logo abaixo, que já carrega essa
frase no rótulo. Onze viraram, nove ficaram. O raciocínio está no doc de
`core/ui/secao_titulo.dart`.

**A marca mudou de propósito:** o arco esmeralda foi de 260° pra 240°. O ouro
encostava no verde porque ninguém tinha contado as pontas redondas
(`StrokeCap.round` come ~9,3° de arco por ponta; a fresta esquerda tinha 12°
brutos, ou seja fechava antes de existir). Isso vale no splash e no cabeçalho
também, e é o certo: o defeito era da marca, o ícone só foi onde ficou óbvio.

---

## 4. As ferramentas que esta rodada deixou

Três geradores em `test/ferramentas/`. **Nenhum roda no `flutter test` normal**
(o nome não termina em `_test.dart`, então o glob não pega). São ferramentas de
produção de arte, não asserções sobre o app: no CI, quebrariam o build a cada
pixel mudado.

```bash
flutter test test/ferramentas/prints_loja.dart --update-goldens   # 5 capturas da ficha
flutter test test/ferramentas/icone_app.dart   --update-goldens   # ícone: 5+5 densidades + 512 da Play
flutter test test/ferramentas/og_site.dart     --update-goldens   # cartão 1200x630 do site
```

**A armadilha que custou tempo e vai custar de novo:** render em `flutter test`
usa a fonte **Ahem** por padrão, então todo texto vira caixa preta, e os
**ícones** vêm do cache do SDK, não do `assets/` — sem carregar o
`MaterialIcons-Regular.otf` toda `Icon()` sai como quadrado vazio. Os três
arquivos já carregam o que precisam; se você criar um quarto, copie o
`_carregarFontes` de um deles.

Se mexer na marca ou nas telas, **rode os três de novo** e copie o `icon.png` e
o `og.png` pro repo `website` (eles nascem aqui porque a marca mora aqui).

---

## 5. Armadilhas do caminho, curtas

- **`google-services.json` não é segredo.** Versione. Sem ele, clone limpo não
  compila.
- **Build local derruba a máquina** (WSL, ~11 GB). O caminho é o CI.
- **12 testadores × 14 dias é por APP**, não por conta. As mesmas pessoas
  servem, mas precisam entrar na faixa deste app e o relógio zera. **Teste
  interno não conta**, tem que ser fechado.
- **Caminho absoluto do `.secrets/`**: em casa o usuário é `gabfelix`, no
  trabalho `gabrielbarbosa`. Trocou de máquina, corrija os caminhos ou tudo
  falha com "arquivo não encontrado" e você procura bug no lugar errado.
- **O console mente.** Prove no ar: `curl` na URL, e o evento de telemetria
  chegando na propriedade GA4 **do app**, nunca a do site.
- **A política é rascunho** e precisa de olhada jurídica antes da ficha. Ela foi
  corrigida nesta rodada (declarava AdMob depois de o anúncio ter sido removido),
  mas corrigir ≠ validar.

---

## 6. O que NÃO se aplica a este app

Escrito pra você não perder tempo procurando: sem localização, sem mapa, sem
foreground service, sem câmera, sem áudio, **sem anúncio**. Logo: sem vídeo de
FGS, sem declaração de localização em segundo plano, sem UMP, sem `MAPS_API_KEY`.

A única permissão do app é `INTERNET`, e ela existe pela cotação de câmbio.

Isso deixa o **Data Safety bem mais enxuto** do que o do Deixei Aqui: só o que
Firebase Analytics e Crashlytics coletam, e com o detalhe a favor de a
telemetria ser **opt-in de verdade**, desligada por padrão.

---

## 7. Se você só tem uma hora

1. Merge (ou PR) da `a11y-e-tablet`.
2. Promove a versão.
3. Manda pro CI e roda no aparelho: **abra a proposta em PDF**, que é o caminho
   que o R8 mais provavelmente quebrou.

Isso fecha a lacuna do §1, que é a única coisa que separa "verde nos testes" de
"funciona".
